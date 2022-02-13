//
//  reduce+method.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import Foundation

extension MfArray{
    
    /// Return reduced MfArray applied passed ufunc
    /// - Parameters:
    ///   - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
    ///   - axis: (Optional) axis, if not given, get reduction for all axes
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    ///   - initial: Initial MfArray
    /// - Returns: Reduced mfarray
    public func ufuncReduce(ufunc: biopufuncNoargs<T>, axis: Int? = 0, keepDims: Bool = false, initial: MfArray<T>? = nil) -> MfArray<T> {
        return Matft.ufuncReduce(mfarray: self, ufunc: ufunc, axis: axis, keepDims: keepDims)
    }
    
    /// Return accumulated MfArray applied passed ufunc
    /// - Parameters:
    ///   - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
    ///   - axis: (Optional) axis, if not given, get reduction for all axes
    /// - Returns: accumulated mfarray
    public func ufuncAccumulate(ufunc: biopufuncNoargs<T>, axis: Int = 0) -> MfArray<T> {
        return Matft.ufuncAccumulate(mfarray: self, ufunc: ufunc, axis: axis)
    }
}
