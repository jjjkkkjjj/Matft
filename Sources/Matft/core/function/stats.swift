//
//  stats.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.stats{
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
            return boolean2float(_stats_calc(mfarray.astype(.Float), axis: axis, keepDims: keepDims, vDSP_func: vDSP_meanv))
        case .Double:
            return _stats_calc(mfarray.astype(.Double), axis: axis, keepDims: keepDims, vDSP_func: vDSP_meanvD)
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
    */
    public static func argmax(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc_index(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_maxvi)
        case .Double:
            return _stats_calc_index(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_maxviD)
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
    */
    public static func argmin(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return _stats_calc_index(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_minvi)
        case .Double:
            return _stats_calc_index(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_minviD)
        }
    }
    
    /**
       Element-wise  maximum of mfarray and mfarray
       - parameters:
            - l_mfarray: mfarray
            - r_mfarray: mfarray
    */
    public static func maximum(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(rettype) {
        case .Float:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmax)
        case .Double:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmaxD)
        }
    }

    /**
       Element-wise  minimum of mfarray and mfarray
       - parameters:
            - l_mfarray: mfarray
            - r_mfarray: mfarray
    */
    public static func minimum(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(rettype) {
        case .Float:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmin)
        case .Double:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vminD)
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
            return boolean2float(_stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_sve))
        case .Double:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_sveD)
        }
    }
    /**
       Calculate root of sum MfArray
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func sumsqrt(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.math.sqrt(Matft.stats.sum(mfarray, axis: axis, keepDims: keepDims))
    }
    /**
       Calculate sum of squared MfArray
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func squaresum(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            return boolean2float(_stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_svesq))
        case .Double:
            return _stats_calc(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_svesqD)
        }
    }
}


fileprivate func _stats_calc<T: MfStorable>(_ typedArray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_func<T>) -> MfArray{
    
    if axis != nil && typedArray.ndim > 1{// for given axis
        let axis = get_axis(axis!, ndim: typedArray.ndim)
        let ret = stats_axis_by_vDSP(typedArray, axis: axis, vDSP_func: vDSP_func)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{// for all elements
        let ret = stats_all_by_vDSP(typedArray, vDSP_func: vDSP_func)
        if keepDims{
            let shape = Array(repeating: 1, count: typedArray.ndim)
            return Matft.reshape(ret, newshape: shape)
        }
        return ret
    }
}

fileprivate func _stats_calc_index<T: MfStorable>(_ mfarray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_index_func<T>) -> MfArray{
    
    if axis != nil && mfarray.ndim > 1{// for given axis
        let axis = get_axis(axis!, ndim: mfarray.ndim)
        
        let ret = stats_index_axis_by_vDSP(mfarray, axis: axis, vDSP_func: vDSP_func)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{// for all elements
        let ret = stats_index_all_by_vDSP(mfarray.flatten(), vDSP_func: vDSP_func)
        if keepDims{
            let shape = Array(repeating: 1, count: mfarray.ndim)
            return Matft.reshape(ret, newshape: shape)
        }
        return ret
    }
}
