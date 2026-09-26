//
//  searching+static.swift
//  Matft
//
//  Searching and counting whose output shape depends on the data
//

import Foundation

extension Matft{
    /**
       Return the indices of the elements that are non-zero. Same as `np.nonzero`
       - parameters:
            - mfarray: mfarray
       - Returns: The Int indices for each dimension
    */
    public static func nonzero(_ mfarray: MfArray) -> [MfArray]{
        let (indices, count) = _nonzero_indices(mfarray)
        return indices.map{ _mfarray($0, shape: [count], mftype: .Int) }
    }

    /**
       Find the indices of the elements that are non-zero, grouped by element. Same as `np.argwhere`
       - parameters:
            - mfarray: mfarray
       - Returns: The Int indices (N, ndim)
    */
    public static func argwhere(_ mfarray: MfArray) -> MfArray{
        let (indices, count) = _nonzero_indices(mfarray)
        let ndim = mfarray.ndim
        var values = [Double](repeating: 0, count: count * ndim)
        for axis in 0..<ndim{
            for i in 0..<count{
                values[i * ndim + axis] = indices[axis][i]
            }
        }
        return _mfarray(values, shape: [count, ndim], mftype: .Int)
    }

    /**
       Return the indices of the elements that are non-zero. Same as `np.where` with one argument (`np.nonzero`)
       - parameters:
            - condition: mfarray
       - Returns: The Int indices for each dimension
    */
    public static func `where`(_ condition: MfArray) -> [MfArray]{
        return Matft.nonzero(condition)
    }

    /**
       Return the elements chosen from x or y depending on the condition. Same as `np.where` with three arguments
       - parameters:
            - condition: Where true, yield x, otherwise yield y
            - x: The values chosen where the condition is true
            - y: The values chosen where the condition is false
       - Returns: The broadcasted mfarray. The type is the priority type of x and y
    */
    public static func `where`(_ condition: MfArray, _ x: MfArray, _ y: MfArray) -> MfArray{
        unsupport_complex(x)
        unsupport_complex(y)
        let shape = _broadcast_shape([condition.shape, x.shape, y.shape])
        let c = condition.broadcast_to(shape: shape).astype(.Double)
        let ret = x.broadcast_to(shape: shape).astype(.Double)
        let yv = y.broadcast_to(shape: shape).astype(.Double)
        c.withUnsafeMutableStartPointer(datatype: Double.self){
            cptr in
            yv.withUnsafeMutableStartPointer(datatype: Double.self){
                yptr in
                ret.withUnsafeMutableStartPointer(datatype: Double.self){
                    for i in 0..<ret.size where cptr[i] == 0{
                        $0[i] = yptr[i]
                    }
                }
            }
        }
        let mftype = MfType.priority(x.mftype, y.mftype)
        return mftype == .Double ? ret : ret.astype(mftype)
    }

    /// Same as `np.where` with three arguments. y is a scalar
    public static func `where`<T: MfTypable>(_ condition: MfArray, _ x: MfArray, _ y: T) -> MfArray{
        return Matft.where(condition, x, MfArray([y]))
    }

    /// Same as `np.where` with three arguments. x is a scalar
    public static func `where`<T: MfTypable>(_ condition: MfArray, _ x: T, _ y: MfArray) -> MfArray{
        return Matft.where(condition, MfArray([x]), y)
    }

    /// Same as `np.where` with three arguments. x and y are scalars
    public static func `where`<T: MfTypable, U: MfTypable>(_ condition: MfArray, _ x: T, _ y: U) -> MfArray{
        return Matft.where(condition, MfArray([x]), MfArray([y]))
    }

    /**
       Find the indices where the values should be inserted to keep the order. Same as `np.searchsorted`
       - parameters:
            - a: The sorted 1d mfarray. NaN must be at the end, as `sort` does
            - v: The values to insert
            - side: (Optional) If left, the first suitable index is returned. If right, the last one. By default left
       - Returns: The Int indices with the same shape as v
    */
    public static func searchsorted(_ a: MfArray, _ v: MfArray, side: MfSearchSide = .left) -> MfArray{
        precondition(a.ndim == 1, "a must be 1d")
        let sorted = _doubles(a)
        let values = _doubles(v).map{ Double(_searchsorted(sorted, $0, side: side)) }
        return _mfarray(values, shape: v.shape, mftype: .Int)
    }

    /**
       Return the indices of the bins to which each value belongs. Same as `np.digitize`
       - parameters:
            - x: The values
            - bins: The 1d monotonic bins
            - right: (Optional) Whether the interval includes the right edge. By default false, i.e. bins[i-1] <= x < bins[i] for increasing bins
       - Returns: The Int indices with the same shape as x
    */
    public static func digitize(_ x: MfArray, bins: MfArray, right: Bool = false) -> MfArray{
        precondition(bins.ndim == 1, "bins must be 1d")
        let b = _doubles(bins)
        let increasing = zip(b, b.dropFirst()).allSatisfy{ $0 <= $1 }
        let decreasing = zip(b, b.dropFirst()).allSatisfy{ $0 >= $1 }
        precondition(increasing || decreasing, "bins must be monotonically increasing or decreasing")

        let side: MfSearchSide = right ? .left : .right
        if decreasing && !increasing{
            let reversed = Array(b.reversed())
            let values = _doubles(x).map{ Double(b.count - _searchsorted(reversed, $0, side: side)) }
            return _mfarray(values, shape: x.shape, mftype: .Int)
        }
        let values = _doubles(x).map{ Double(_searchsorted(b, $0, side: side)) }
        return _mfarray(values, shape: x.shape, mftype: .Int)
    }

    /**
       Count the number of occurrences of each non-negative integer. Same as `np.bincount`
       - parameters:
            - x: The 1d non-negative integers
            - weights: (Optional) The weights with the same shape as x
            - minlength: (Optional) The minimum number of bins
       - Returns: The Int counts, or the Double sums of weights
    */
    public static func bincount(_ x: MfArray, weights: MfArray? = nil, minlength: Int = 0) -> MfArray{
        precondition(x.ndim == 1, "x must be 1d")
        let indices = _doubles(x).map{ Int($0) }
        precondition(indices.allSatisfy{ $0 >= 0 }, "x must be non-negative")
        let w = weights.map{ _doubles($0) }
        if let w = w{
            precondition(w.count == indices.count, "The weights and x don't have the same length")
        }

        var counts = [Double](repeating: 0, count: Swift.max((indices.max() ?? -1) + 1, minlength))
        for (i, index) in indices.enumerated(){
            counts[index] += w?[i] ?? 1
        }
        return _mfarray(counts, shape: [counts.count], mftype: weights == nil ? .Int : .Double)
    }

    /**
       Compute the histogram with equal-width bins. Same as `np.histogram` with an int bins
       - parameters:
            - a: The input values (flattened)
            - bins: (Optional) The number of bins, by default 10
            - range: (Optional) The lower and upper range of the bins. By default, (a.min(), a.max())
            - density: (Optional) If true, return the probability density function, by default false
            - weights: (Optional) The weights with the same shape as a
       - Returns: The Int counts (Double for density or weights), and the Double bin edges
    */
    public static func histogram(_ a: MfArray, bins: Int = 10, range: (Double, Double)? = nil, density: Bool = false, weights: MfArray? = nil) -> (hist: MfArray, bin_edges: MfArray){
        precondition(bins > 0, "bins must be positive")
        let values = _doubles(a)
        var (first, last) = range ?? (values.min() ?? 0, values.max() ?? 1)
        precondition(first <= last, "max must be larger than min in range parameter")
        precondition(first.isFinite && last.isFinite, "range must be finite")
        if first == last{
            first -= 0.5
            last += 0.5
        }

        // np.linspace(first, last, bins + 1)
        let step = (last - first) / Double(bins)
        var edges = (0...bins).map{ Double($0) * step + first }
        edges[bins] = last

        // Same as numpy's fast path for equal-width bins
        let norm_denom = last - first
        let binIndex: (Double) -> Int? = {
            v in
            guard first <= v && v <= last else { return nil }
            var index = Int((v - first) / norm_denom * Double(bins))
            if index == bins{
                index -= 1
            }
            if v < edges[index]{
                index -= 1
            }
            else if index != bins - 1 && v >= edges[index + 1]{
                index += 1
            }
            return index
        }
        let hist = _histogram_counts(values, weights: weights, count: bins, binIndex: binIndex)
        return (_histogram_result(hist, edges: edges, density: density, weighted: weights != nil), _mfarray(edges, shape: [edges.count], mftype: .Double))
    }

    /**
       Compute the histogram with the given bin edges. Same as `np.histogram` with a sequence of bins
       - parameters:
            - a: The input values (flattened)
            - bins: The monotonically increasing 1d bin edges. The last bin includes the right edge
            - density: (Optional) If true, return the probability density function, by default false
            - weights: (Optional) The weights with the same shape as a
       - Returns: The Int counts (Double for density or weights), and the Double bin edges
    */
    public static func histogram(_ a: MfArray, bins: MfArray, density: Bool = false, weights: MfArray? = nil) -> (hist: MfArray, bin_edges: MfArray){
        precondition(bins.ndim == 1 && bins.size >= 2, "bins must be 1d and have at least 2 edges")
        let edges = _doubles(bins)
        precondition(zip(edges, edges.dropFirst()).allSatisfy{ $0 <= $1 }, "bins must increase monotonically")

        let n = edges.count - 1
        let binIndex: (Double) -> Int? = {
            v in
            guard edges[0] <= v && v <= edges[n] else { return nil }
            // the last bin includes the right edge
            return v == edges[n] ? n - 1 : _searchsorted(edges, v, side: .right) - 1
        }
        let hist = _histogram_counts(_doubles(a), weights: weights, count: n, binIndex: binIndex)
        return (_histogram_result(hist, edges: edges, density: density, weighted: weights != nil), _mfarray(edges, shape: [edges.count], mftype: .Double))
    }
}

/// The side of searchsorted. Same as `side` of `np.searchsorted`
public enum MfSearchSide: Int{
    /// The first suitable index
    case left
    /// The last suitable index
    case right
}

/// The row major Double values
internal func _doubles(_ mfarray: MfArray) -> [Double]{
    unsupport_complex(mfarray)
    if mfarray.size == 0{
        return []
    }
    let x = mfarray.astype(.Double)
    return x.withUnsafeMutableStartPointer(datatype: Double.self){
        Array(UnsafeBufferPointer(start: $0, count: x.size))
    }
}

/// Create mfarray from the row major Double values (without converting via [Any])
internal func _mfarray(_ values: [Double], shape: [Int], mftype: MfType) -> MfArray{
    if values.isEmpty{
        return MfArray([] as [Double], mftype: mftype, shape: shape)
    }
    let ret = Matft.nums(Double.zero, shape: shape, mftype: .Double)
    ret.withUnsafeMutableStartPointer(datatype: Double.self){
        dst in
        values.withUnsafeBufferPointer{
            dst.update(from: $0.baseAddress!, count: values.count)
        }
    }
    return mftype == .Double ? ret : ret.astype(mftype)
}

/// The broadcasted shape of numpy's rule
internal func _broadcast_shape(_ shapes: [[Int]]) -> [Int]{
    let ndim = shapes.map{ $0.count }.max() ?? 0
    return (0..<ndim).map{
        axis in
        let sizes = shapes.compactMap{ shape -> Int? in
            let i = axis - (ndim - shape.count)
            return i >= 0 ? shape[i] : nil
        }
        let size = sizes.max() ?? 1
        precondition(sizes.allSatisfy{ $0 == 1 || $0 == size }, "operands could not be broadcast together with shapes \(shapes)")
        return size
    }
}

/// The indices of the non-zero elements (NaN is non-zero) for each axis, and the number of them
fileprivate func _nonzero_indices(_ mfarray: MfArray) -> (indices: [[Double]], count: Int){
    let values = _doubles(mfarray)
    let shape = mfarray.shape
    let ndim = shape.count
    let count = values.reduce(0){ $1 != 0 ? $0 + 1 : $0 }
    var ret = [[Double]](repeating: [Double](repeating: 0, count: count), count: ndim)

    // the multi-dimensional index is incremented in row major order
    var index = [Int](repeating: 0, count: ndim)
    var n = 0
    for v in values{
        if v != 0{
            for axis in 0..<ndim{
                ret[axis][n] = Double(index[axis])
            }
            n += 1
        }
        var axis = ndim - 1
        while axis >= 0{
            index[axis] += 1
            if index[axis] < shape[axis]{
                break
            }
            index[axis] = 0
            axis -= 1
        }
    }
    return (ret, count)
}

/// Binary search on the sorted values, where NaN is the largest as numpy
internal func _searchsorted(_ sorted: [Double], _ v: Double, side: MfSearchSide) -> Int{
    func less(_ a: Double, _ b: Double) -> Bool{
        return !a.isNaN && (b.isNaN || a < b)
    }
    var lo = 0, hi = sorted.count
    while lo < hi{
        let mid = (lo + hi) / 2
        // left: the first index where !(sorted[i] < v), right: the first index where v < sorted[i]
        let goRight = side == .left ? less(sorted[mid], v) : !less(v, sorted[mid])
        if goRight{
            lo = mid + 1
        }
        else{
            hi = mid
        }
    }
    return lo
}

fileprivate func _histogram_counts(_ values: [Double], weights: MfArray?, count: Int, binIndex: (Double) -> Int?) -> [Double]{
    let w = weights.map{ _doubles($0) }
    if let w = w{
        precondition(w.count == values.count, "weights should have the same shape as a")
    }
    var hist = [Double](repeating: 0, count: count)
    for (i, v) in values.enumerated(){
        if let index = binIndex(v){
            hist[index] += w?[i] ?? 1
        }
    }
    return hist
}

fileprivate func _histogram_result(_ hist: [Double], edges: [Double], density: Bool, weighted: Bool) -> MfArray{
    if density{
        let total = hist.reduce(0, +)
        let values = hist.enumerated().map{ $1 / (edges[$0 + 1] - edges[$0]) / total }
        return _mfarray(values, shape: [values.count], mftype: .Double)
    }
    return _mfarray(hist, shape: [hist.count], mftype: weighted ? .Double : .Int)
}
