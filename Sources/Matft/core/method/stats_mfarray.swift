//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/15.
//

import Foundation

extension MfArray where ArrayType: MfNumeric{
    /**
       Get maximum value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get maximum for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func max(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.max(self, axis: axis, keepDims: keepDims)
    }
    /**
       Get index of maximum value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get index of maximum for all elements (flattenarray)
    */
    public func argmax(axis: Int? = nil) -> MfArray<Int>{
        return Matft.stats.argmax(self, axis: axis)
    }
    /**
       Get minimum value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get minimum for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func min(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.min(self, axis: axis, keepDims: keepDims)
    }
    /**
       Get index of minimum value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get index of minimum for all elements (flattenarray)
    */
    public func argmin(axis: Int? = nil) -> MfArray<Int>{
        return Matft.stats.argmin(self, axis: axis)
    }
    /**
       Get summation value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get summation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func sum(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.sum(self, axis: axis, keepDims: keepDims)
    }
    /**
       Calculate root of sum MfArray
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    //public func sumsqrt(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
    //    return Matft.stats.sumsqrt(self, axis: axis, keepDims: keepDims)
    //}
    /**
       Calculate sum of squared MfArray
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func squaresum(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.squaresum(self, axis: axis, keepDims: keepDims)
    }
}

extension MfArray where ArrayType: StoredFloat{
    /**
       Get mean value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get mean for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func mean(axis: Int? = nil, keepDims: Bool = false) -> MfArray<Float>{
        return Matft.stats.mean(self, axis: axis, keepDims: keepDims)
    }
}

extension MfArray where ArrayType: StoredDouble{
    /**
       Get mean value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get mean for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func mean(axis: Int? = nil, keepDims: Bool = false) -> MfArray<Double>{
        return Matft.stats.mean(self, axis: axis, keepDims: keepDims)
    }
}

extension MfArray where ArrayType: MfBinary{
    /**
       Get summation value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get summation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func sum(axis: Int? = nil, keepDims: Bool = false) -> MfArray<Float>{
        return Matft.stats.sum(self, axis: axis, keepDims: keepDims)
    }
}
