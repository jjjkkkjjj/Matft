//
//  orderstats+static.swift
//  Matft
//
//  Order statistics (median, percentile, quantile) and the nan-functions
//

import Foundation

extension Matft.stats{
    /**
       Compute the median along the axis. Same as `np.median`. NaN propagates
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, compute the median of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
       - Returns: The median. Float for Float and integer types, Double for Double
    */
    public static func median(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _median(&lane, ignoreNaN: false)
        }
    }

    /**
       Compute the q-th percentile along the axis. Same as `np.percentile`. NaN propagates
       - parameters:
            - mfarray: mfarray
            - q: The percentile in [0, 100]
            - axis: (Optional) axis, if not given, compute the percentile of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the percentile, by default linear
       - Returns: The percentile. Float for Float and integer types, Double for Double
    */
    public static func percentile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return Matft.stats.quantile(mfarray, q: q / 100, axis: axis, keepDims: keepDims, method: method)
    }

    /**
       Compute the percentiles along the axis. Same as `np.percentile` with a sequence of q
       - parameters:
            - mfarray: mfarray
            - q: The percentiles in [0, 100]
            - axis: (Optional) axis, if not given, compute the percentiles of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the percentile, by default linear
       - Returns: The percentiles, whose shape is `[q.count] + reduced shape`
    */
    public static func percentile(_ mfarray: MfArray, q: [Double], axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return Matft.stats.quantile(mfarray, q: q.map{ $0 / 100 }, axis: axis, keepDims: keepDims, method: method)
    }

    /**
       Compute the q-th quantile along the axis. Same as `np.quantile`. NaN propagates
       - parameters:
            - mfarray: mfarray
            - q: The quantile in [0, 1]
            - axis: (Optional) axis, if not given, compute the quantile of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the quantile, by default linear
       - Returns: The quantile. Float for Float and integer types, Double for Double
    */
    public static func quantile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: [q], axis: axis, keepDims: keepDims, method: method, ignoreNaN: false, multiple: false)
    }

    /**
       Compute the quantiles along the axis. Same as `np.quantile` with a sequence of q
       - parameters:
            - mfarray: mfarray
            - q: The quantiles in [0, 1]
            - axis: (Optional) axis, if not given, compute the quantiles of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the quantile, by default linear
       - Returns: The quantiles, whose shape is `[q.count] + reduced shape`
    */
    public static func quantile(_ mfarray: MfArray, q: [Double], axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: q, axis: axis, keepDims: keepDims, method: method, ignoreNaN: false, multiple: true)
    }

    /**
       Sum ignoring NaN. Same as `np.nansum`
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, sum all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
    */
    public static func nansum(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _same_type(mfarray)){
            lane, out in
            out[0] = lane.reduce(0){ $1.isNaN ? $0 : $0 + $1 }
        }
    }

    /**
       Mean ignoring NaN. Same as `np.nanmean`. All-NaN slice returns NaN
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, compute the mean of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
    */
    public static func nanmean(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            let (sum, count) = _nansum_count(lane)
            out[0] = count == 0 ? Double.nan : sum / Double(count)
        }
    }

    /**
       Maximum ignoring NaN. Same as `np.nanmax`. All-NaN slice returns NaN
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, compute the maximum of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
    */
    public static func nanmax(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _same_type(mfarray)){
            lane, out in
            out[0] = lane.reduce(Double.nan){ $1.isNaN ? $0 : ($0.isNaN || $1 > $0 ? $1 : $0) }
        }
    }

    /**
       Minimum ignoring NaN. Same as `np.nanmin`. All-NaN slice returns NaN
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, compute the minimum of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
    */
    public static func nanmin(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _same_type(mfarray)){
            lane, out in
            out[0] = lane.reduce(Double.nan){ $1.isNaN ? $0 : ($0.isNaN || $1 < $0 ? $1 : $0) }
        }
    }

    /**
       Index of the maximum ignoring NaN. Same as `np.nanargmax`
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, return the index of the flattened mfarray
       - Important: All-NaN slice is not allowed
    */
    public static func nanargmax(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: false, outType: .Int){
            lane, out in
            out[0] = Double(_nanargbest(lane, >))
        }
    }

    /**
       Index of the minimum ignoring NaN. Same as `np.nanargmin`
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, return the index of the flattened mfarray
       - Important: All-NaN slice is not allowed
    */
    public static func nanargmin(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: false, outType: .Int){
            lane, out in
            out[0] = Double(_nanargbest(lane, <))
        }
    }

    /**
       Variance ignoring NaN. Same as `np.nanvar`. It returns NaN when the degrees of freedom <= 0
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, compute the variance of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - ddof: (Optional) Delta degrees of freedom. The divisor is `N - ddof`, where N is the number of non-NaN elements. By default 0
    */
    public static func nanvar(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _nanvar(lane, ddof: ddof)
        }
    }

    /**
       Standard deviation ignoring NaN. Same as `np.nanstd`. It returns NaN when the degrees of freedom <= 0
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, compute the standard deviation of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - ddof: (Optional) Delta degrees of freedom. The divisor is `N - ddof`, where N is the number of non-NaN elements. By default 0
    */
    public static func nanstd(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _nanvar(lane, ddof: ddof).squareRoot()
        }
    }

    /**
       Median ignoring NaN. Same as `np.nanmedian`. All-NaN slice returns NaN
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, compute the median of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
    */
    public static func nanmedian(_ mfarray: MfArray, axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return _reduce_lanes(mfarray, axis: axis, keepDims: keepDims, outType: _float_type(mfarray)){
            lane, out in
            out[0] = _median(&lane, ignoreNaN: true)
        }
    }

    /**
       Percentile ignoring NaN. Same as `np.nanpercentile`. All-NaN slice returns NaN
       - parameters:
            - mfarray: mfarray
            - q: The percentile in [0, 100]
            - axis: (Optional) axis, if not given, compute the percentile of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the percentile, by default linear
    */
    public static func nanpercentile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: [q / 100], axis: axis, keepDims: keepDims, method: method, ignoreNaN: true, multiple: false)
    }

    /**
       Percentiles ignoring NaN. Same as `np.nanpercentile` with a sequence of q
       - parameters:
            - mfarray: mfarray
            - q: The percentiles in [0, 100]
            - axis: (Optional) axis, if not given, compute the percentiles of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the percentile, by default linear
       - Returns: The percentiles, whose shape is `[q.count] + reduced shape`
    */
    public static func nanpercentile(_ mfarray: MfArray, q: [Double], axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: q.map{ $0 / 100 }, axis: axis, keepDims: keepDims, method: method, ignoreNaN: true, multiple: true)
    }

    /**
       Quantile ignoring NaN. Same as `np.nanquantile`. All-NaN slice returns NaN
       - parameters:
            - mfarray: mfarray
            - q: The quantile in [0, 1]
            - axis: (Optional) axis, if not given, compute the quantile of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the quantile, by default linear
    */
    public static func nanquantile(_ mfarray: MfArray, q: Double, axis: Int? = nil, keepDims: Bool = false, method: MfQuantileMethod = .linear) -> MfArray{
        return _quantile(mfarray, q: [q], axis: axis, keepDims: keepDims, method: method, ignoreNaN: true, multiple: false)
    }

    /**
       Quantiles ignoring NaN. Same as `np.nanquantile` with a sequence of q
       - parameters:
            - mfarray: mfarray
            - q: The quantiles in [0, 1]
            - axis: (Optional) axis, if not given, compute the quantiles of all elements
            - keepDims: (Optional) whether to keep original dimension, default is false
            - method: (Optional) The method to estimate the quantile, by default linear
       - Returns: The quantiles, whose shape is `[q.count] + reduced shape`
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
    let laneCount = laneSize == 0 ? 0 : x.size / laneSize
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
    var best = -1
    for (i, v) in lane.enumerated() where !v.isNaN{
        if best < 0 || isBetter(v, lane[best]){
            best = i
        }
    }
    precondition(best >= 0, "All-NaN slice encountered")
    return best
}
