//
//  reduce.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// A binary array function `(MfArray, MfArray) -> MfArray`, such as `Matft.add`, used by `ufuncReduce` and `ufuncAccumulate`.
public typealias biopufuncNoargs = (MfArray, MfArray) -> MfArray

extension Matft{
    /**
       Reduce an array by repeatedly applying a binary function.

       Equivalent to `numpy.ufunc.reduce` (e.g. `Matft.ufuncReduce(mfarray: a, ufunc: Matft.add)` is like `np.add.reduce(a)`).

       ```swift
       let a = MfArray([[1, 2], [3, 4]])
       let s = Matft.ufuncReduce(mfarray: a, ufunc: Matft.add, axis: 0)   // shape [2]
       ```
       - Parameters:
            - mfarray: The source array.
            - ufunc: A binary function `(MfArray, MfArray) -> MfArray`, such as `Matft.add`.
            - axis: (Optional) The axis to reduce, by default 0. If `nil`, all axes are reduced.
            - keepDims: (Optional) Whether to keep the reduced axes as dimensions of length 1, by default `false`.
            - initial: (Optional) The value combined with the first element, as `ufunc(initial, first)`. Note that it is ignored when `axis` is `nil`.
       - Returns: The reduced array.
    */
    public static func ufuncReduce(mfarray: MfArray, ufunc: biopufuncNoargs, axis: Int? = 0, keepDims: Bool = false, initial: MfArray? = nil) -> MfArray {
        
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
       Accumulate the result of applying a binary function along the given axis.

       Equivalent to `numpy.ufunc.accumulate` (e.g. `Matft.ufuncAccumulate(mfarray: a, ufunc: Matft.add)` is like `np.add.accumulate(a)`).
       - Parameters:
            - mfarray: The source array.
            - ufunc: A binary function `(MfArray, MfArray) -> MfArray`, such as `Matft.add`.
            - axis: (Optional) The axis along which to accumulate, by default 0.
       - Returns: The accumulated array, which has the same shape and `mftype` as `mfarray`.
    */
    public static func ufuncAccumulate(mfarray: MfArray, ufunc: biopufuncNoargs, axis: Int = 0) -> MfArray {
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        
        
        // conversion
        let saxes = Array(axis..<mfarray.ndim)
        let laxes = Array(0..<axis)
        let movedMfArray = mfarray.transpose(axes: saxes + laxes).to_contiguous(mforder: .Row)// to Row order
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
        
        //re-conversion: the inverse of the permutation above
        let perm = saxes + laxes
        var inverse = [Int](repeating: 0, count: perm.count)
        for (i, p) in perm.enumerated(){
            inverse[p] = i
        }
        return accums.transpose(axes: inverse)
    }
}

extension Array where Element == MfArray{
    /**
       Reduce an array of `MfArray`s by repeatedly applying a binary function from left to right.

       ```swift
       let total = [a, b, c].ufuncReduce(Matft.add)   // a + b + c
       ```
       - Parameters:
            - ufunc: A binary function `(MfArray, MfArray) -> MfArray`, such as `Matft.add`.
            - initial: (Optional) The value combined with the first element, as `ufunc(initial, first)`.
       - Returns: The reduced array.
       - Precondition: The array must not be empty.
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

