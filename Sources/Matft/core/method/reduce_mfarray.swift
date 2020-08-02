//
//  reduce_mfarray.swift
//
//
//  Created by Junnosuke Kado on 2020/08/01.
//
import Foundation

extension MfArray{
    /**
       Return reduced MfArray applied passed ufunc
       - Parameters:
           - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
           - axis: (Optional) axis, if not given, get reduction for all axes
           - keepDims: (Optional) whether to keep original dimension, default is true
           - initial: Initial MfArray
    */
    public func ufuncReduce(_ ufunc: biopufuncNoargs<ArrayType>, axis: Int? = 0, keepDims: Bool = false, initial: MfArray<ArrayType>? = nil) -> MfArray<T>{
        return Matft.ufuncReduce(mfarray: self, ufunc: ufunc, axis: axis, keepDims: keepDims, initial: initial)
    }
    
    /**
        Return accumulated MfArray applied passed ufunc along axis
        - Parameters:
            - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
            - axis: axis
     */
    public func ufuncAccumulate(_ ufunc: biopufuncNoargs<ArrayType>, axis: Int = 0) -> MfArray<ArrayType> {
        return Matft.ufuncAccumulate(mfarray: self, ufunc: ufunc, axis: axis)
    }
}
