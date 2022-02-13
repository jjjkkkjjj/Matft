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
}
