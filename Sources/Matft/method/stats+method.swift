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
}
