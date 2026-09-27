//
//  orderstats+static.swift
//  Matft
//
//  Order statistics (median, percentile, quantile) and the nan-functions
//

import Foundation

extension Matft.stats{
    /**
       Compute the median along the given axis.

       Equivalent to `numpy.median`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the median. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The median. For an even number of elements it is the mean of the two middle values. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
       - Note: NaN propagates: a lane containing NaN gives NaN. Use `nanmedian(_:axis:keepDims:)` to ignore NaN.
    */
    public static func median(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _median(&lane, ignoreNaN: false)
        }
    }

    /**
       Compute the q-th percentile along the given axis.

       Equivalent to `numpy.percentile`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The percentile to compute, in the range [0, 100].
            - axis: The axis along which to compute the percentile. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The percentile. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
       - Note: NaN propagates. Use `nanpercentile` to ignore NaN.
    */
    public static func percentile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return Matft.stats.quantile(mfarray, q: q / 100, axis: axis, keepDims: keepDims, method: method)
    }

    /**
       Compute several percentiles along the given axis.

       Equivalent to `numpy.percentile`.

       This is the overload for a sequence of `q`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The percentiles to compute, each in the range [0, 100].
            - axis: The axis along which to compute the percentiles. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The percentiles with shape `[q.count] + reduced shape`. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
       - Note: NaN propagates. Use `nanpercentile` to ignore NaN.
    */
    public static func percentile(_ mfarray: MfArray, q: [Double], axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return Matft.stats.quantile(mfarray, q: q.map{ $0 / 100 }, axis: axis, keepDims: keepDims, method: method)
    }

    /**
       Compute the q-th quantile along the given axis.

       Equivalent to `numpy.quantile`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The quantile to compute, in the range [0, 1].
            - axis: The axis along which to compute the quantile. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The quantile. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
       - Note: NaN propagates. Use `nanquantile` to ignore NaN.
    */
    public static func quantile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: [q], axis: axis, keepDims: keepDims, method: method, ignoreNaN: false, multiple: false)
    }

    /**
       Compute several quantiles along the given axis.

       Equivalent to `numpy.quantile`.

       This is the overload for a sequence of `q`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The quantiles to compute, each in the range [0, 1].
            - axis: The axis along which to compute the quantiles. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The quantiles with shape `[q.count] + reduced shape`. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
       - Note: NaN propagates. Use `nanquantile` to ignore NaN.
    */
    public static func quantile(_ mfarray: MfArray, q: [Double], axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: q, axis: axis, keepDims: keepDims, method: method, ignoreNaN: false, multiple: true)
    }

    /**
       Compute the sum along the given axis, treating NaN as zero.

       Equivalent to `numpy.nansum`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the sum. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The sum. The result has the same `mftype` as `mfarray` (`.Bool` gives `.Float`). A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
    */
    public static func nansum(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _same_type(mfarray)){
            lane, out in
            out[0] = lane.reduce(0){ $1.isNaN ? $0 : $0 + $1 }
        }
    }

    /**
       Compute the arithmetic mean along the given axis, ignoring NaN.

       Equivalent to `numpy.nanmean`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the mean. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The mean. An all-NaN lane gives NaN. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
    */
    public static func nanmean(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            let (sum, count) = _nansum_count(lane)
            out[0] = count == 0 ? Double.nan : sum / Double(count)
        }
    }

    /**
       Return the maximum along the given axis, ignoring NaN.

       Equivalent to `numpy.nanmax`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the maximum. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The maximum. An all-NaN lane gives NaN. The result has the same `mftype` as `mfarray` (`.Bool` gives `.Float`). A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported. The reduced axis (all the elements for `axis == nil`) must not be empty, as numpy raises for it.
    */
    public static func nanmax(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        precondition_nonempty_lanes(mfarray, axis: axis, "fmax")
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _same_type(mfarray)){
            lane, out in
            out[0] = lane.reduce(Double.nan){ $1.isNaN ? $0 : ($0.isNaN || $1 > $0 ? $1 : $0) }
        }
    }

    /**
       Return the minimum along the given axis, ignoring NaN.

       Equivalent to `numpy.nanmin`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the minimum. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The minimum. An all-NaN lane gives NaN. The result has the same `mftype` as `mfarray` (`.Bool` gives `.Float`). A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported. The reduced axis (all the elements for `axis == nil`) must not be empty, as numpy raises for it.
    */
    public static func nanmin(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        precondition_nonempty_lanes(mfarray, axis: axis, "fmin")
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _same_type(mfarray)){
            lane, out in
            out[0] = lane.reduce(Double.nan){ $1.isNaN ? $0 : ($0.isNaN || $1 < $0 ? $1 : $0) }
        }
    }

    /**
       Return the indices of the maximum values along the given axis, ignoring NaN.

       Equivalent to `numpy.nanargmax`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to search. If `nil` (default), the index is into the flattened (row-major) array.
       - Returns: The `.Int` indices of the first maximum, with the reduced axis removed. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
       - Precondition: A lane consisting only of NaN is not allowed (it traps with "All-NaN slice encountered").
    */
    public static func nanargmax(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: false, outType: .Int){
            lane, out in
            out[0] = Double(_nanargbest(lane, >))
        }
    }

    /**
       Return the indices of the minimum values along the given axis, ignoring NaN.

       Equivalent to `numpy.nanargmin`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to search. If `nil` (default), the index is into the flattened (row-major) array.
       - Returns: The `.Int` indices of the first minimum, with the reduced axis removed. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
       - Precondition: A lane consisting only of NaN is not allowed (it traps with "All-NaN slice encountered").
    */
    public static func nanargmin(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: false, outType: .Int){
            lane, out in
            out[0] = Double(_nanargbest(lane, <))
        }
    }

    /**
       Compute the variance along the given axis, ignoring NaN.

       Equivalent to `numpy.nanvar`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the variance. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - ddof: Delta degrees of freedom. The divisor is `N - ddof`, where `N` is the number of non-NaN elements. Default is 0.
       - Returns: The variance. NaN when `N - ddof <= 0`. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
    */
    public static func nanvar(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _nanvar(lane, ddof: ddof)
        }
    }

    /**
       Compute the standard deviation along the given axis, ignoring NaN.

       Equivalent to `numpy.nanstd`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the standard deviation. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - ddof: Delta degrees of freedom. The divisor is `N - ddof`, where `N` is the number of non-NaN elements. Default is 0.
       - Returns: The standard deviation. NaN when `N - ddof <= 0`. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
    */
    public static func nanstd(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _nanvar(lane, ddof: ddof).squareRoot()
        }
    }

    /**
       Compute the median along the given axis, ignoring NaN.

       Equivalent to `numpy.nanmedian`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - axis: The axis along which to compute the median. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
       - Returns: The median. An all-NaN lane gives NaN. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
    */
    public static func nanmedian(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _median(&lane, ignoreNaN: true)
        }
    }

    /**
       Compute the q-th percentile along the given axis, ignoring NaN.

       Equivalent to `numpy.nanpercentile`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The percentile to compute, in the range [0, 100].
            - axis: The axis along which to compute the percentile. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The percentile. An all-NaN lane gives NaN. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
    */
    public static func nanpercentile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: [q / 100], axis: axis, keepDims: keepDims, method: method, ignoreNaN: true, multiple: false)
    }

    /**
       Compute several percentiles along the given axis, ignoring NaN.

       Equivalent to `numpy.nanpercentile`.

       This is the overload for a sequence of `q`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The percentiles to compute, each in the range [0, 100].
            - axis: The axis along which to compute the percentiles. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The percentiles with shape `[q.count] + reduced shape`. An all-NaN lane gives NaN. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
    */
    public static func nanpercentile(_ mfarray: MfArray, q: [Double], axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: q.map{ $0 / 100 }, axis: axis, keepDims: keepDims, method: method, ignoreNaN: true, multiple: true)
    }

    /**
       Compute the q-th quantile along the given axis, ignoring NaN.

       Equivalent to `numpy.nanquantile`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The quantile to compute, in the range [0, 1].
            - axis: The axis along which to compute the quantile. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The quantile. An all-NaN lane gives NaN. The result is `.Double` for `.Double` input and `.Float` otherwise. A full reduction returns shape `[1]` instead of a scalar.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
    */
    public static func nanquantile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: [q], axis: axis, keepDims: keepDims, method: method, ignoreNaN: true, multiple: false)
    }

    /**
       Compute several quantiles along the given axis, ignoring NaN.

       Equivalent to `numpy.nanquantile`.

       This is the overload for a sequence of `q`.

       - Parameters:
            - mfarray: The input array. Any real `mftype`; values are processed as `Double` internally.
            - q: The quantiles to compute, each in the range [0, 1].
            - axis: The axis along which to compute the quantiles. Negative values count from the last axis. If `nil` (default), it is computed over all elements.
            - keepDims: If `true`, the reduced axis is kept with size 1 (all axes for `axis == nil`). Default is `false`.
            - method: The interpolation method used when the quantile lies between two data points (`.linear`, `.lower`, `.higher`, `.nearest` or `.midpoint`). Default is `.linear`.
       - Returns: The quantiles with shape `[q.count] + reduced shape`. An all-NaN lane gives NaN. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
       - Precondition: Every `q` must be in the range [0, 100] for percentiles ([0, 1] for quantiles).
    */
    public static func nanquantile(_ mfarray: MfArray, q: [Double], axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: q, axis: axis, keepDims: keepDims, method: method, ignoreNaN: true, multiple: true)
    }
}

/// Double for Double, otherwise Float (same as `Matft.stats.mean`)
fileprivate func _float_type(_ mfarray: MfArray) -> MfType{
    return mfarray.storedType == .Double ? .Double : .Float
}

/// The same type as the input (Bool is Float)
fileprivate func _same_type(_ mfarray: MfArray) -> MfType{
    return mfarray.mftype == .Bool ? .Float : mfarray.mftype
}

/// Apply `body` to each 1d lane along the axis.
/// The lane is a Double copy, so that `body` can modify it (e.g. sort). `body` writes `outCount` values into the second argument.
/// - Returns: The mfarray of `[outCount] + reduced shape` if `multiple` is true, otherwise the reduced shape
internal func _reduce_lanes(_ mfarray: MfArray, axis: Int?, keepDims: Bool, outType: MfType, outCount: Int = 1, multiple: Bool = false, _ body: (inout [Double], UnsafeMutablePointer<Double>) -> Void) -> MfArray{
    unsupport_complex(mfarray)

    let x: MfArray
    var reducedShape: [Int]
    if let axis = axis{
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        x = Matft.moveaxis(mfarray, src: axis, dst: -1).astype(.Double)
        reducedShape = mfarray.shape
        if keepDims{
            reducedShape[axis] = 1
        }
        else{
            reducedShape.remove(at: axis)
        }
    }
    else{
        x = mfarray.astype(.Double)
        reducedShape = keepDims ? Array(repeating: 1, count: mfarray.ndim) : []
    }

    var shape = multiple ? [outCount] + reducedShape : reducedShape
    if shape.isEmpty{
        // Matft returns [1] instead of a scalar
        shape = [1]
    }

    let laneSize = axis == nil ? x.size : x.shape[x.ndim - 1]
    // zero-length lanes are still lanes: `body` gives their value (e.g. NaN for the median, 0 for nansum) like numpy
    let laneCount = laneSize > 0 ? x.size / laneSize : (axis == nil ? 1 : x.shape.dropLast().reduce(1, *))
    let ret = Matft.nums(Double.zero, shape: shape, mftype: .Double)
    let out = UnsafeMutablePointer<Double>.allocate(capacity: outCount)
    defer { out.deallocate() }

    var lane: [Double] = []
    lane.reserveCapacity(laneSize)
    x.withUnsafeMutableStartPointer(datatype: Double.self){
        ptr in
        ret.withUnsafeMutableStartPointer(datatype: Double.self){
            // retptr[k * laneCount + lane]
            retptr in
            for l in 0..<laneCount{
                // reuse the buffer, because body may shrink it (e.g. removing NaN)
                lane.removeAll(keepingCapacity: true)
                lane.append(contentsOf: UnsafeBufferPointer(start: ptr + l * laneSize, count: laneSize))
                body(&lane, out)
                for k in 0..<outCount{
                    retptr[k * laneCount + l] = out[k]
                }
            }
        }
    }

    return outType == .Double ? ret : ret.astype(outType)
}

fileprivate func _quantile(_ mfarray: MfArray, q: [Double], axis: Int?, keepDims: Bool, method: MfQuantileMethod, ignoreNaN: Bool, multiple: Bool) -> MfArray{
    precondition(q.allSatisfy{ 0 <= $0 && $0 <= 1 }, "Quantiles must be in the range [0, 1]")
    return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray), outCount: q.count, multiple: multiple){
        lane, out in
        if !_remove_nan(&lane, ignoreNaN: ignoreNaN){
            for k in 0..<q.count{
                out[k] = Double.nan
            }
            return
        }
        if q.count > 1{
            lane.sort()
        }
        for (k, qk) in q.enumerated(){
            out[k] = _quantile_select(&lane, q: qk, method: method, sorted: q.count > 1)
        }
    }
}

/// Remove NaN if `ignoreNaN`. Returns false if the result must be NaN (NaN is included or the lane is empty)
fileprivate func _remove_nan(_ lane: inout [Double], ignoreNaN: Bool) -> Bool{
    if ignoreNaN{
        lane.removeAll{ $0.isNaN }
    }
    else if lane.contains(where: { $0.isNaN }){
        return false
    }
    return !lane.isEmpty
}

/// Rearrange the values so that `values[k]` is the k-th smallest, the preceding ones are smaller or equal and the following ones are larger or equal (Wirth's selection)
fileprivate func _select(_ values: inout [Double], _ k: Int){
    values.withUnsafeMutableBufferPointer{
        a in
        var l = 0, r = a.count - 1
        while l < r{
            let x = a[k]
            var i = l, j = r
            repeat{
                while a[i] < x{ i += 1 }
                while x < a[j]{ j -= 1 }
                if i <= j{
                    a.swapAt(i, j)
                    i += 1
                    j -= 1
                }
            } while i <= j
            if j < k{ l = i }
            if k < i{ r = j }
        }
    }
}

/// The k-th smallest value. If `sorted` is false, the values are rearranged by the selection
fileprivate func _kth(_ values: inout [Double], _ k: Int, sorted: Bool) -> Double{
    if !sorted{
        _select(&values, k)
    }
    return values[k]
}

/// The (k+1)-th smallest value after `_kth(values, k)`, i.e. the minimum of the following ones
fileprivate func _next_kth(_ values: [Double], _ k: Int, sorted: Bool) -> Double{
    if sorted || k + 1 >= values.count{
        return values[Swift.min(k + 1, values.count - 1)]
    }
    return values[(k + 1)...].min()!
}

/// Same as `np.median`: the mean of the two middle values
fileprivate func _median(_ lane: inout [Double], ignoreNaN: Bool) -> Double{
    if !_remove_nan(&lane, ignoreNaN: ignoreNaN){
        return Double.nan
    }
    let n = lane.count
    let upper = _kth(&lane, n / 2, sorted: false)
    if n % 2 == 1{
        return upper
    }
    // the lower middle is the maximum of the preceding ones
    return (lane[..<(n / 2)].max()! + upper) / 2
}

/// Same as `_quantile` of numpy. The values are sorted if `sorted` is true, otherwise they are rearranged by the selection
fileprivate func _quantile_select(_ values: inout [Double], q: Double, method: MfQuantileMethod, sorted: Bool) -> Double{
    let n = values.count
    let virtual_index = q * Double(n - 1)
    let lower = Int(virtual_index.rounded(.down))

    // Same as `_lerp` of numpy
    func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double{
        let diff = b - a
        return t >= 0.5 ? b - diff * (1 - t) : a + diff * t
    }

    switch method {
    case .linear:
        let a = _kth(&values, lower, sorted: sorted)
        return lerp(a, _next_kth(values, lower, sorted: sorted), virtual_index - Double(lower))
    case .lower:
        return _kth(&values, lower, sorted: sorted)
    case .higher:
        return _kth(&values, Int(virtual_index.rounded(.up)), sorted: sorted)
    case .nearest:
        // numpy rounds half to even
        return _kth(&values, Int(virtual_index.rounded(.toNearestOrEven)), sorted: sorted)
    case .midpoint:
        let a = _kth(&values, lower, sorted: sorted)
        return Double(lower) == virtual_index ? a : lerp(a, _next_kth(values, lower, sorted: sorted), 0.5)
    }
}

fileprivate func _nansum_count(_ lane: [Double]) -> (sum: Double, count: Int){
    var sum = 0.0
    var count = 0
    for v in lane where !v.isNaN{
        sum += v
        count += 1
    }
    return (sum, count)
}

fileprivate func _nanvar(_ lane: [Double], ddof: Int) -> Double{
    let (sum, count) = _nansum_count(lane)
    if count - ddof <= 0{
        return Double.nan
    }
    let mean = sum / Double(count)
    var sq = 0.0
    for v in lane where !v.isNaN{
        sq += (v - mean) * (v - mean)
    }
    return sq / Double(count - ddof)
}

/// The index of the first best value ignoring NaN
fileprivate func _nanargbest(_ lane: [Double], _ isBetter: (Double, Double) -> Bool) -> Int{
    precondition(!lane.isEmpty, "attempt to get argmax/argmin of an empty sequence")
    var best = -1
    for (i, v) in lane.enumerated() where !v.isNaN{
        if best < 0 || isBetter(v, lane[best]){
            best = i
        }
    }
    precondition(best >= 0, "All-NaN slice encountered")
    return best
}
