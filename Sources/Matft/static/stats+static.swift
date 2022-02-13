//
//  stats+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import Foundation

extension Matft.stats {
    
    /// Get mean value along axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The mean mfarray
    public static func mean<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil, keepDims: Bool = false) -> MfArray<Float> where T.StoredType == Float{
        return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: Float.StoredType.vDSP_mean_func)
    }
    /// Get mean value along axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The mean mfarray
    public static func mean<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil, keepDims: Bool = false) -> MfArray<Double> where T.StoredType == Double{
        return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: Double.StoredType.vDSP_mean_func)
    }
    
    /// Get summation value along axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The sum mfarray
    public static func sum<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil, keepDims: Bool = false) -> MfArray<T>{
        return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: T.StoredType.vDSP_sum_func)
    }
    
    /// Calculate root of sum MfArray
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The result mfarray
    public static func sumsqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil, keepDims: Bool = false) -> MfArray<Float> where T.StoredType == Float{
        return Matft.math.sqrt(Matft.stats.sum(mfarray, axis: axis, keepDims: keepDims))
    }
    /// Calculate root of sum MfArray
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The result mfarray
    public static func sumsqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil, keepDims: Bool = false) -> MfArray<Double> where T.StoredType == Double{
        return Matft.math.sqrt(Matft.stats.sum(mfarray, axis: axis, keepDims: keepDims))
    }
    
    /// Calculate sum of squared MfArray
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    ///   - keepDims: (Optional) whether to keep original dimension, default is true
    /// - Returns: The mean mfarray
    public static func squaresum<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil, keepDims: Bool = false) -> MfArray<T>{
        return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: T.StoredType.vDSP_sqsum_func)
    }

}
