//
//  reduce.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

public typealias biopufuncNoargs = (MfArray, MfArray) -> MfArray

extension Matft{
    /**
        Return reduced MfArray applied passed ufunc
        - Parameters:
            - mfarray: mfarray
            - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
            - axis: (Optional) axis, if not given, get reduction for all axes
            - keepDims: (Optional) whether to keep original dimension, default is true
            - initial: Initial MfArray
     */
    public static func ufuncReduce(mfarray: MfArray, ufunc: biopufuncNoargs, axis: Int? = 0, keepDims: Bool = false, initial: MfArray? = nil) -> MfArray {
        
        if let axis = axis{
            let axis = get_axis(axis, ndim: mfarray.ndim)
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
            let movedMfArray = mfarray.transpose(axes: saxes + laxes).conv_order(mforder: .Row)// to Row order
            
            // get initial value
            let first: MfArray
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
            var first: MfArray
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
    
    /**
        Return accumulated MfArray applied passed ufunc along axis
        - Parameters:
            - mfarray: mfarray
            - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
            - axis: axis
     */
    public static func ufuncAccumulate(mfarray: MfArray, ufunc: biopufuncNoargs, axis: Int = 0) -> MfArray {
        let axis = get_axis(axis, ndim: mfarray.ndim)
        
        
        // conversion
        var saxes = Array(axis..<mfarray.ndim)
        var laxes = Array(0..<axis)
        let movedMfArray = mfarray.transpose(axes: saxes + laxes).conv_order(mforder: .Row)// to Row order
        let accums = Matft.nums_like(0, mfarray: movedMfArray) // note that this ret must be converted
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

extension Array where Element == MfArray{
    /**
        Return reduced MfArray applied passed ufunc
        - Parameters:
            - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
            - initial: Initial MfArray
     */
    public func ufuncReduce(_ ufunc: biopufuncNoargs, initial: MfArray? = nil) -> MfArray {
        precondition(self.count > 0, "must be more than one element")
        let first: MfArray
        if let initial = initial{
            first = ufunc(initial, self.first!)
        }
        else{
            first = self.first!
        }
        
        return self.dropFirst().reduce(first){ ufunc($0, $1) }
    }
}

