//
//  stats.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray.stats{
    /**
       Get mean value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get mean for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func mean(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_meanv)
        case .Double:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_meanvD)
        }
    }
    /**
       Get maximum value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get maximum for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func max(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxv)
        case .Double:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxvD)
        }
    }
    /**
       Get index of maximum value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get index of maximum for all elements (flattenarray)
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func argmax(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc_index(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxvi, vDSP_conv_func: vDSP_vflt32)
        case .Double:
            return _stats_calc_index(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxviD, vDSP_conv_func: vDSP_vflt32D)
        }
    }
    /**
       Get minimum value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get minimum for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func min(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minv)
        case .Double:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minvD)
        }
    }
    /**
       Get index of minimum value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get index of minimum for all elements (flattenarray)
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func argmin(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc_index(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minvi, vDSP_conv_func: vDSP_vflt32)
        case .Double:
            return _stats_calc_index(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minviD, vDSP_conv_func: vDSP_vflt32D)
        }
    }
    /**
       Get summation value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func sum(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_sve)
        case .Double:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_sveD)
        }
    }
}


fileprivate func _stats_calc<T: MfStorable>(_ typedArray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_func<T>) -> MfArray{
    
    if axis != nil && typedArray.ndim > 1{// for given axis
        let axis = axis! >= 0 ? axis! : axis! + typedArray.ndim
        precondition(0 <= axis && axis < typedArray.ndim, "Invalid axis")
        let ret = stats_axis_by_vDSP(typedArray, axis: axis, vDSP_func: vDSP_func)
        return keepDims ? Matft.mfarray.expand_dims(ret, axis: axis) : ret
    }
    else{// for all elements
        let ret = stats_all_by_vDSP(typedArray, vDSP_func: vDSP_func)
        if keepDims{
            let shape = Array(repeating: 1, count: typedArray.ndim)
            return Matft.mfarray.reshape(ret, newshape: shape)
        }
        return ret
    }
}

fileprivate func _stats_calc_index<T: MfStorable>(_ mfarray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_index_func<T>, vDSP_conv_func: vDSP_convert_func<Int32, T>) -> MfArray{
    
    if axis != nil && mfarray.ndim > 1{// for given axis
        let axis = axis! >= 0 ? axis! : axis! + mfarray.ndim
        precondition(0 <= axis && axis < mfarray.ndim, "Invalid axis")
        
        let ret = stats_index_axis_by_vDSP(mfarray, axis: axis, vDSP_func: vDSP_func, vDSP_conv_func: vDSP_conv_func)
        return keepDims ? Matft.mfarray.expand_dims(ret, axis: axis) : ret
    }
    else{// for all elements
        let ret = stats_index_all_by_vDSP(mfarray.flatten(), vDSP_func: vDSP_func)
        if keepDims{
            let shape = Array(repeating: 1, count: mfarray.ndim)
            return Matft.mfarray.reshape(ret, newshape: shape)
        }
        return ret
    }
}
