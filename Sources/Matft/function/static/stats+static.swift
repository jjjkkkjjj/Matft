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
       Compute the arithmetic mean along the given axis.

       Equivalent to `numpy.mean`.

       ```swift
       let a = MfArray([[3, -19],
                        [-22, 4]])
       Matft.stats.mean(a)          // MfArray([-8.5], mftype: .Float)
       Matft.stats.mean(a, axis: 0) // MfArray([-9.5, -7.5], mftype: .Float)
       ```

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to average. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The mean. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs give `.Float`).
       - Precondition: Complex arrays are not supported.
       - Note: Unlike Numpy, reducing all elements (`axis == nil`, `keepDims == false`) returns a 1-d array of shape `[1]` instead of a scalar. NaN handling follows vDSP and is not guaranteed to propagate like Numpy; use the `nan*` functions to ignore NaN.
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
       Return the maximum along the given axis.

       Equivalent to `numpy.max`.

       ```swift
       let a = MfArray([[3, -19],
                        [-22, 4]])
       Matft.stats.max(a)           // MfArray([4])
       Matft.stats.max(a, axis: 0)  // MfArray([3, 4])
       Matft.stats.max(a, axis: -1) // MfArray([3, 4])
       ```

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to reduce. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The maximum with the same `mftype` as `mfarray`.
       - Precondition: Complex arrays are not supported.
       - Note: Unlike Numpy, reducing all elements (`axis == nil`, `keepDims == false`) returns a 1-d array of shape `[1]` instead of a scalar. As in Numpy, NaN propagates (a lane containing NaN gives NaN); use the `nan*` functions to ignore NaN.
    */
    public static func max(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return _propagate_nan(stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxv), mfarray, axis: axis, keepDims: keepDims)
        case .Double:
            return _propagate_nan(stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_maxvD), mfarray, axis: axis, keepDims: keepDims)
        }
    }
    /**
       Return the indices of the maximum values along the given axis.

       Equivalent to `numpy.argmax`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to search. If `nil` (default), the index is into the flattened (row-major) array.
       - Returns: The `.Int` indices of the maximum values, with the reduced axis removed. As in Numpy, the first index is returned when the extreme value appears multiple times, and the index of the first NaN when there is NaN.
       - Precondition: Complex arrays are not supported. The searched axis (all the elements for `axis == nil`) must not be empty.
       - Note: Unlike Numpy, `axis == nil` (or a 1-d input) returns shape `[1]` instead of a scalar.
    */
    public static func argmax(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_maxvi, vDSP_sum_func: vDSP_sve)
        case .Double:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_maxviD, vDSP_sum_func: vDSP_sveD)
        }
    }
    /**
       Return the minimum along the given axis.

       Equivalent to `numpy.min`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to reduce. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The minimum with the same `mftype` as `mfarray`.
       - Precondition: Complex arrays are not supported.
       - Note: Unlike Numpy, reducing all elements (`axis == nil`, `keepDims == false`) returns a 1-d array of shape `[1]` instead of a scalar. As in Numpy, NaN propagates (a lane containing NaN gives NaN); use the `nan*` functions to ignore NaN.
    */
    public static func min(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return _propagate_nan(stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minv), mfarray, axis: axis, keepDims: keepDims)
        case .Double:
            return _propagate_nan(stats_by_vDSP(mfarray, axis: axis, keepDims: keepDims, vDSP_func: vDSP_minvD), mfarray, axis: axis, keepDims: keepDims)
        }
    }
    /**
       Return the indices of the minimum values along the given axis.

       Equivalent to `numpy.argmin`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to search. If `nil` (default), the index is into the flattened (row-major) array.
       - Returns: The `.Int` indices of the minimum values, with the reduced axis removed. As in Numpy, the first index is returned when the extreme value appears multiple times, and the index of the first NaN when there is NaN.
       - Precondition: Complex arrays are not supported. The searched axis (all the elements for `axis == nil`) must not be empty.
       - Note: Unlike Numpy, `axis == nil` (or a 1-d input) returns shape `[1]` instead of a scalar.
    */
    public static func argmin(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_minvi, vDSP_sum_func: vDSP_sve)
        case .Double:
            return stats_index_by_vDSP(mfarray, axis: axis, keepDims: false, vDSP_func: vDSP_minviD, vDSP_sum_func: vDSP_sveD)
        }
    }
    
    /**
       Compute the element-wise maximum of two arrays with broadcasting.

       Equivalent to `numpy.maximum`.

       - Parameters:
            - l_mfarray: The first array.
            - r_mfarray: The second array. It is broadcast against `l_mfarray`.
       - Returns: A new array with the broadcast shape and the promoted `mftype` of the two inputs.
       - Precondition: Complex arrays are not supported.
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
       Compute the element-wise minimum of two arrays with broadcasting.

       Equivalent to `numpy.minimum`.

       - Parameters:
            - l_mfarray: The first array.
            - r_mfarray: The second array. It is broadcast against `l_mfarray`.
       - Returns: A new array with the broadcast shape and the promoted `mftype` of the two inputs.
       - Precondition: Complex arrays are not supported.
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
       Compute the sum of the elements along the given axis.

       Equivalent to `numpy.sum`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to sum. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The sum with the same `mftype` as `mfarray`, except that `.Bool` input gives `.Float` (Numpy gives an integer).
       - Precondition: Complex arrays are not supported.
       - Note: Unlike Numpy, reducing all elements (`axis == nil`, `keepDims == false`) returns a 1-d array of shape `[1]` instead of a scalar. NaN handling follows vDSP and is not guaranteed to propagate like Numpy; use the `nan*` functions to ignore NaN.
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
       Compute the square root of the sum along the given axis, i.e. `sqrt(sum(mfarray, axis:))`.

       There is no direct Numpy counterpart; it is `numpy.sqrt(numpy.sum(a, axis))`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to sum. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
    */
    public static func sumsqrt(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        unsupport_complex(mfarray)
        
        return Matft.math.sqrt(Matft.stats.sum(mfarray, axis: axis, keepDims: keepDims))
    }
    /**
       Compute the sum of the squared elements along the given axis, i.e. `sum(mfarray * mfarray, axis:)`.

       There is no direct Numpy counterpart; it is `numpy.sum(numpy.square(a), axis)`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to sum. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The sum of squares with the same `mftype` as `mfarray`, except that `.Bool` input gives `.Float`.
       - Precondition: Complex arrays are not supported.
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
       Return the cumulative sum of the elements along the given axis.

       Equivalent to `numpy.cumsum`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which the cumulative sum is computed. If `nil` (default), the array is flattened first and a 1-d result is returned.
       - Returns: An array with the same shape as `mfarray` (1-d for `axis == nil`) and the same `mftype`, except that `.Bool` is summed as `.Int` like Numpy.
       - Precondition: Complex arrays are not supported.
    */
    public static func cumsum(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        let (mfarray, axis) = axis == nil ? (mfarray.flatten(), 0) : (mfarray, axis!)
        switch mfarray.storedType{
        case .Float:
            return _cumsum(mfarray, axis: axis, Float.self){
                #if canImport(Accelerate)
                vDSP_vadd($0, 1, $1, 1, $2, 1, vDSP_Length($3))
                #else
                vDSP_vadd($0, 1, $1, 1, $2, 1, $3)
                #endif
            }
        case .Double:
            return _cumsum(mfarray, axis: axis, Double.self){
                #if canImport(Accelerate)
                vDSP_vaddD($0, 1, $1, 1, $2, 1, vDSP_Length($3))
                #else
                vDSP_vaddD($0, 1, $1, 1, $2, 1, $3)
                #endif
            }
        }
    }

    /**
       Compute the variance along the given axis.

       Equivalent to `numpy.var`. The variance is `sum((x - mean)^2) / (N - ddof)`, where `N` is the number of elements reduced.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to compute the variance. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - ddof: Delta degrees of freedom. The divisor is `N - ddof` (clamped to 0). Default is 0.
       - Returns: The variance. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
       - Note: NaN propagates. Use `nanvar(_:axis:keepDims:ddof:)` to ignore NaN.
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
       Compute the standard deviation along the given axis.

       Equivalent to `numpy.std`. It is the square root of `var(_:axis:keepDims:ddof:)`.

       - Parameters:
            - mfarray: The input array.
            - axis: The axis along which to compute the standard deviation. Negative values count from the last axis. If `nil` (default), the reduction is over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - ddof: Delta degrees of freedom. The divisor is `N - ddof` (clamped to 0). Default is 0.
       - Returns: The standard deviation. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
       - Note: NaN propagates. Use `nanstd(_:axis:keepDims:ddof:)` to ignore NaN.
    */
    public static func std(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return Matft.math.sqrt(Matft.stats.var(mfarray, axis: axis, keepDims: keepDims, ddof: ddof))
    }
}

/// Cumulative sum along the axis. The axis is moved to the front, and each row is accumulated onto the previous one.
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis: The axis
///   - vadd: c = a + b for n elements
/// - Returns: The cumulative sum. Bool is summed as Int like numpy
fileprivate func _cumsum<T: MfStorable>(_ mfarray: MfArray, axis: Int, _ type: T.Type, _ vadd: (UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, Int) -> Void) -> MfArray{
    let axis = get_positive_axis(axis, ndim: mfarray.ndim)
    let src = check_contiguous(mfarray.moveaxis(src: axis, dst: 0), .Row)
    let size = src.size
    let newdata = MfData(uninitializedSize: size, mftype: mfarray.mftype == .Bool ? .Int : mfarray.mftype)
    
    if size > 0{
        let length = src.shape[0]
        let rest = size / length
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptr in
            src.withUnsafeMutableStartPointer(datatype: T.self){
                srcptr in
                dstptr.update(from: srcptr, count: rest)
                if rest >= 16{
                    for k in 1..<length{
                        vadd(dstptr + (k - 1)*rest, srcptr + k*rest, dstptr + k*rest, rest)
                    }
                }
                else{
                    // short rows (e.g. 1d): sequential in the same order as numpy
                    for i in rest..<size{
                        dstptr[i] = dstptr[i - rest] + srcptr[i]
                    }
                }
            }
        }
    }
    
    return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: src.shape, mforder: .Row)).moveaxis(src: 0, dst: axis)
}


/// numpy propagates NaN through max / min, but vDSP drops it (for strided lanes, at some positions, and on x86_64).
/// The lanes containing NaN are set to NaN. Without NaN this costs one vectorized sum.
fileprivate func _propagate_nan(_ ret: MfArray, _ mfarray: MfArray, axis: Int?, keepDims: Bool) -> MfArray{
    guard mfarray.mftype == .Float || mfarray.mftype == .Double, mfarray.size > 0 else{
        return ret
    }
    // the sum is NaN whenever NaN exists (inf - inf only costs the extra work below)
    let total = Matft.stats.sum(mfarray).astype(.Double).data[0] as! Double
    guard total.isNaN else{
        return ret
    }
    let nanCount = Matft.stats.sum(Matft.math.isnan(mfarray).astype(mfarray.mftype), axis: axis, keepDims: keepDims)
    return Matft.where(nanCount > 0, Double.nan, ret).astype(ret.mftype)
}
