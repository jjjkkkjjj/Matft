//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/15.
//

import Foundation

extension MfArray{
    /**
       Get mean value along axis
       - parameters:
            - axis: (Optional) axis, if not given, get mean for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public func mean(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.mean(self, axis: axis, keepDims: keepDims)
    }
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
    public func argmax(axis: Int? = nil) -> MfArray{
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
    public func argmin(axis: Int? = nil) -> MfArray{
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
    public func sumsqrt(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.sumsqrt(self, axis: axis, keepDims: keepDims)
    }
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
    
    /**
       Calculate cumulative sum of MfArray along axis
       - parameters:
            - axis: (Optional) axis, if not given, get cumulative summation for flatten array
    */
    public func cumsum(axis: Int? = nil) -> MfArray{
        return Matft.stats.cumsum(self, axis: axis)
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
