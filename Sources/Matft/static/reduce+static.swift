//
//  reduce+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import Foundation
import Accelerate

public typealias biopufuncNoargs<T: MfTypeUsable> = (MfArray<T>, MfArray<T>) -> MfArray<T>

extension Matft{

    /// Return reduced MfArray applied passed ufunc
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
    ///   - axis: (Optional) axis, if not given, get reduction for all axes
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    ///   - initial: Initial MfArray
    /// - Returns: Reduced mfarray
    public static func ufuncReduce<T: MfTypeUsable>(mfarray: MfArray<T>, ufunc: biopufuncNoargs<T>, axis: Int? = 0, keepDims: Bool = false, initial: MfArray<T>? = nil) -> MfArray<T> {
        
        if let axis = axis{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
            /*
             e.g.) ndim=6, axis=2
             shape = (a,b,c,d,e,f)
             //conversion
             axes = (4,5,0,1,2,3)    //saxes = (4,5):snum=2 laxes = (0,1,2,3):lnum=4
             shape = (c,d,e,f,a,b)
                   = (-,d,e,f,a,b)
             //re-conversion
             axes = (2,3,4,0,1)      //saxes = (2,3,4) laxes = (0,1)
             shape = (a,b,d,e,f)
             */
            // conversion
            var saxes = Array(axis..<mfarray.ndim)
            var laxes = Array(0..<axis)
            let movedMfArray = mfarray.transpose(axes: saxes + laxes).to_contiguous(mforder: .Row)// to Row order
            
            // get initial value
            let first: MfArray<T>
            if let initial = initial{
                first = ufunc(initial, movedMfArray.first!)
            }
            else{
                first = movedMfArray.first!
            }
            
            // run reduction
            let reducedArray = movedMfArray.dropFirst().reduce(first){ ufunc($0, $1) }
            
            //re-conversion
            saxes = Array(axis..<reducedArray.ndim)
            laxes = Array(0..<axis)
            let ret = reducedArray.transpose(axes: saxes + laxes)
            
            return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
        }
        else{
            var ret = mfarray
            // get initial value
            var first: MfArray<T>
            if let initial = initial{
                first = ufunc(initial, ret.first!)
            }
            else{
                first = ret.first!
            }
            
            for _ in 0..<mfarray.ndim{
                first = ret.first!
                // run reduction
                ret = ret.dropFirst().reduce(first){ ufunc($0, $1) }
            }
            
            if keepDims{
                let shape = Array(repeating: 1, count: mfarray.ndim)
                return ret.reshape(shape)
            }
            else{
                return ret
            }
        }
    }
    

    /// Return accumulated MfArray applied passed ufunc
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
    ///   - axis: (Optional) axis, if not given, get reduction for all axes
    /// - Returns: accumulated mfarray
    public static func ufuncAccumulate<T: MfTypeUsable>(mfarray: MfArray<T>, ufunc: biopufuncNoargs<T>, axis: Int = 0) -> MfArray<T> {
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        
        
        // conversion
        var saxes = Array(axis..<mfarray.ndim)
        var laxes = Array(0..<axis)
        let movedMfArray = mfarray.transpose(axes: saxes + laxes).to_contiguous(mforder: .Row)// to Row order
        let accums = Matft.nums_like(T.zero, mfarray: movedMfArray) // note that this ret must be converted
        // get initial value
        let first = movedMfArray.first!
        
        // run reduction
        var ind = 0
        accums[ind] = first
        let _ = movedMfArray.dropFirst().reduce(first){
            l, r in
            ind += 1
            let next = ufunc(l, r)
            accums[ind] = next
            return next
        }
        
        //re-conversion
        saxes = Array(axis..<accums.ndim)
        laxes = Array(0..<axis)
        let ret = accums.transpose(axes: saxes + laxes)
        return ret
    }
}

// ref: https://stackoverflow.com/questions/45552561/extension-on-array-where-element-is-a-generic-struct-in-swift/45556248
public protocol MfArrayCollectionProtocol {
    associatedtype MfArrayGenericType: MfTypeUsable
}

extension MfArray: MfArrayCollectionProtocol{
    public typealias MfArrayGenericType = MfArrayType
}

extension Array where Element: MfArrayCollectionProtocol {
    
    /// Return reduced MfArray applied passed ufunc
    /// - Parameters:
    ///   - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
    ///   - initial: Initial MfArray
    /// - Returns: Reduced MfArray
    public func ufuncReduce(_ ufunc: biopufuncNoargs<Element.MfArrayGenericType>, initial: MfArray<Element.MfArrayGenericType>? = nil) -> MfArray<Element.MfArrayGenericType> {
        precondition(self.count > 0, "must be more than one element")
        let first: MfArray<Element.MfArrayGenericType>
        if let initial = initial{
            first = ufunc(initial, self.first! as! MfArray<Element.MfArrayGenericType>)
        }
        else{
            first = self.first! as! MfArray<Element.MfArrayGenericType>
        }
        
        return self.dropFirst().reduce(first){ ufunc($0, $1 as! MfArray<Element.MfArrayGenericType>) }
    }
}
