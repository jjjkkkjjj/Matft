//
//  stats.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

extension Matft.stats{
    /**
       Get mean value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get mean for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func mean(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return boolean2float(stats_by_vDSP(astype_or_view(mfarray, .Float), axis: axis, keepDims: keepDims, vDSP_func: vDSP_meanv))
        case .Double:
            return stats_by_vDSP(astype_or_view(mfarray, .Double), axis: axis, keepDims: keepDims, vDSP_func: vDSP_meanvD)
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
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxv)
        case .Double:
            return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxvD)
        }
    }
    /**
       Get index of maximum value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get index of maximum for all elements (flattenarray)
    */
    public static func argmax(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_maxvi)
        case .Double:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_maxviD)
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
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minv)
        case .Double:
            return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minvD)
        }
    }
    /**
       Get index of minimum value along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get index of minimum for all elements (flattenarray)
    */
    public static func argmin(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_minvi)
        case .Double:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_minviD)
        }
    }
    
    /**
       Element-wise  maximum of mfarray and mfarray
       - parameters:
            - l_mfarray: mfarray
            - r_mfarray: mfarray
    */
    public static func maximum(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        precondition(isReal, "Complex is not supported")
        
        switch MfType.storedType(rettype) {
        case .Float:
            return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmax)
        case .Double:
            return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmaxD)
        }
    }

    /**
       Element-wise  minimum of mfarray and mfarray
       - parameters:
            - l_mfarray: mfarray
            - r_mfarray: mfarray
    */
    public static func minimum(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        precondition(isReal, "Complex is not supported")
        
        switch MfType.storedType(rettype) {
        case .Float:
            return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmin)
        case .Double:
            return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vminD)
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
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return boolean2float(stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_sve))
        case .Double:
            return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_sveD)
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
        unsupport_complex(mfarray)
        
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
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return boolean2float(stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_svesq))
        case .Double:
            return stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_svesqD)
        }
    }
    
    /**
       Calculate cumulative sum of MfArray along axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get cumulative summation for flatten array
    */
    public static func cumsum(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        if let axis = axis{
            return mfarray.ufuncAccumulate(Matft.add, axis: axis)
        }
        else{
            return mfarray.flatten().ufuncAccumulate(Matft.add)
        }
    }

    /**
       Calculate variance along axis. Same as `np.var`
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get variance for all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - ddof: (Optional) Delta degrees of freedom. The divisor is `N - ddof`, by default 0
    */
    public static func `var`(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        unsupport_complex(mfarray)

        let count = axis == nil ? mfarray.size : mfarray.shape[get_positive_axis(axis!, ndim: mfarray.ndim)]
        let divisor = Swift.max(count - ddof, 0)

        switch mfarray.storedType {
        case .Float:
            let x = mfarray.astype(.Float)
            let dev = x - Matft.stats.mean(x, axis: axis, keepDims: true)
            return Matft.stats.squaresum(dev, axis: axis, keepDims: keepDims) / Float(divisor)
        case .Double:
            let x = mfarray.astype(.Double)
            let dev = x - Matft.stats.mean(x, axis: axis, keepDims: true)
            return Matft.stats.squaresum(dev, axis: axis, keepDims: keepDims) / Double(divisor)
        }
    }

    /**
       Calculate standard deviation along axis. Same as `np.std`
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get standard deviation for all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - ddof: (Optional) Delta degrees of freedom. The divisor is `N - ddof`, by default 0
    */
    public static func std(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return Matft.math.sqrt(Matft.stats.var(mfarray, axis: axis, keepDims: keepDims, ddof: ddof))
    }
}

