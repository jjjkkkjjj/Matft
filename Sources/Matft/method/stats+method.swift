//
//  stats+method.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import Foundation

extension MfArray{
    /// Get mean value along axis
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The mean mfarray
    public func mean(axis: Int? = nil, keepDims: Bool = false) -> MfArray<Float> where T.StoredType == Float{
        return Matft.stats.mean(self, axis: axis, keepDims: keepDims)
    }
    /// Get mean value along axis
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The mean mfarray
    public func mean(axis: Int? = nil, keepDims: Bool = false) -> MfArray<Double> where T.StoredType == Double{
        return Matft.stats.mean(self, axis: axis, keepDims: keepDims)
    }
    
    /// Get summation value along axis
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The sum mfarray
    public func sum(axis: Int? = nil, keepDims: Bool = false) -> MfArray<T>{
        return Matft.stats.sum(self, axis: axis, keepDims: keepDims)
    }
    
    /// Get max value along axis
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The max mfarray
    public func max(axis: Int? = nil, keepDims: Bool = false) -> MfArray<T>{
        return Matft.stats.max(self, axis: axis, keepDims: keepDims)
    }
    
    /// Get min value along axis
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The min mfarray
    public func min(axis: Int? = nil, keepDims: Bool = false) -> MfArray<T>{
        return Matft.stats.min(self, axis: axis, keepDims: keepDims)
    }
    
    /// Calculate root of sum MfArray
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The result mfarray
    public func sumsqrt(axis: Int? = nil, keepDims: Bool = false) -> MfArray<Float> where T.StoredType == Float{
        return Matft.stats.sumsqrt(self, axis: axis, keepDims: keepDims)
    }
    /// Calculate root of sum MfArray
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The result mfarray
    public func sumsqrt(axis: Int? = nil, keepDims: Bool = false) -> MfArray<Double> where T.StoredType == Double{
        return Matft.stats.sumsqrt(self, axis: axis, keepDims: keepDims)
    }
    
    /// Calculate sum of squared MfArray
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The mean mfarray
    public func squaresum(axis: Int? = nil, keepDims: Bool = false) -> MfArray<T>{
        return Matft.stats.squaresum(self, axis: axis, keepDims: keepDims)
    }
    
    /// Calculate cumulative sum of MfArray along axis
    /// - Parameters:
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    /// - Returns: The mean mfarray
    public func cumsum(axis: Int? = nil) -> MfArray<T>{
        return Matft.stats.cumsum(self, axis: axis)
    }
}
