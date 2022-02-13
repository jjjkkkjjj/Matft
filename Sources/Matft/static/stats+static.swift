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
    
    
    /// Element-wise  minimum of mfarray and mfarray
    /// - Parameters:
    ///   - l_mfarray: An input left mfarray
    ///   - r_mfarray;  An input right mfarray
    /// - Returns: The minimum mfarray
    public static func minimum<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_minimum_func)
    }
    /// Element-wise  maximum of mfarray and mfarray
    /// - Parameters:
    ///   - l_mfarray: An input left mfarray
    ///   - r_mfarray;  An input right mfarray
    /// - Returns: The maximum mfarray
    public static func maximum<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_maximum_func)
    }
    
    /// Calculate cumulative sum of MfArray along axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis; (Optional) axis, if not given, get mean for all elements
    /// - Returns: The mean mfarray
    public static func cumsum<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil) -> MfArray<T>{
        if let axis = axis{
            return mfarray.ufuncAccumulate(ufunc: Matft.add, axis: axis)
        }
        else{
            return mfarray.flatten().ufuncAccumulate(ufunc: Matft.add)
        }
    }
}
