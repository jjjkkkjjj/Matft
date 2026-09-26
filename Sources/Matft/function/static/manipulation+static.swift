//
//  manipulation+static.swift
//  Matft
//

import Foundation

extension Matft{
    /**
       Pad an array.

       The result is always a new array with the same `mftype`. Complex arrays are not supported.
       Equivalent to `numpy.pad`.

       ```swift
       let a = MfArray([[1, 2], [3, 4]])
       let b = Matft.pad(a, pad_width: [(1, 1), (0, 2)], mode: .edge)   // shape [4, 4]
       ```
       - Parameters:
            - mfarray: The source array.
            - pad_width: The number of values padded to the edges of each axis: `[(before, after)]` for each axis, or a single `(before, after)` applied to all axes. Values must be non-negative.
            - mode: (Optional) The padding mode, by default `.constant`.
            - constant_values: (Optional) The value used for the padded elements in `.constant` mode, by default 0. It is converted into `mfarray.mftype`.
       - Returns: The padded array.
    */
    public static func pad(_ mfarray: MfArray, pad_width: [(Int, Int)], mode: MfPadMode = .constant, constant_values: Double = 0) -> MfArray{
        unsupport_complex(mfarray)
        let ndim = mfarray.ndim
        precondition(pad_width.count == 1 || pad_width.count == ndim, "pad_width must have 1 or \(ndim) elements")
        let pad_width = pad_width.count == 1 ? Array(repeating: pad_width[0], count: ndim) : pad_width
        precondition(pad_width.allSatisfy{ $0.0 >= 0 && $0.1 >= 0 }, "pad_width must not contain negative values")

        var ret = mfarray
        for axis in 0..<ndim{
            let (before, after) = pad_width[axis]
            if before == 0 && after == 0{
                continue
            }

            let size = ret.shape[axis]
            precondition(mode == .constant || size > 0, "can't extend empty axis \(axis) using modes other than 'constant'")

            // Create only the padded parts and concatenate them with the original values
            func padded_part(_ range: Range<Int>) -> MfArray{
                if mode == .constant{
                    var shape = ret.shape
                    shape[axis] = range.count
                    return Matft.nums(constant_values, shape: shape, mftype: mfarray.mftype)
                }
                let indices = range.map{ _pad_source_index($0, size: size, mode: mode) }
                return Matft.take(ret, indices: MfArray(indices, mftype: .Int), axis: axis)
            }

            var parts: [MfArray] = []
            if before > 0{
                parts.append(padded_part(-before..<0))
            }
            parts.append(ret)
            if after > 0{
                parts.append(padded_part(size..<size + after))
            }
            ret = Matft.concatenate(parts, axis: axis)
        }

        return ret === mfarray ? mfarray.deepcopy() : ret
    }

    /**
       Pad an array with the same width on all edges.

       Complex arrays are not supported.
       Equivalent to `numpy.pad` with an int `pad_width`.
       - Parameters:
            - mfarray: The source array.
            - pad_width: The number of values padded to both edges of every axis. It must be non-negative.
            - mode: (Optional) The padding mode, by default `.constant`.
            - constant_values: (Optional) The value used for the padded elements in `.constant` mode, by default 0. It is converted into `mfarray.mftype`.
       - Returns: The padded array.
    */
    public static func pad(_ mfarray: MfArray, pad_width: Int, mode: MfPadMode = .constant, constant_values: Double = 0) -> MfArray{
        return Matft.pad(mfarray, pad_width: [(pad_width, pad_width)], mode: mode, constant_values: constant_values)
    }

    /**
       Calculate the n-th discrete difference along the given axis.

       The first difference is `a[1:] - a[:-1]` along `axis`; higher differences are computed recursively.
       Equivalent to `numpy.diff`.
       - Parameters:
            - mfarray: The source array.
            - n: (Optional) The number of times values are differenced, by default 1. It must be non-negative; 0 returns `mfarray` itself.
            - axis: (Optional) The axis along which the difference is taken, by default the last axis.
       - Returns: The n-th differences, whose length along `axis` is reduced by `n`. For a `.Bool` array, `not_equal` is used instead of subtraction.
    */
    public static func diff(_ mfarray: MfArray, n: Int = 1, axis: Int = -1) -> MfArray{
        precondition(n >= 0, "order must be non-negative but got \(n)")
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)

        var ret = mfarray
        for _ in 0..<n{
            var upper: [Any] = Array(repeating: MfSlice(), count: ret.ndim)
            upper[axis] = MfSlice(start: 1)
            var lower: [Any] = Array(repeating: MfSlice(), count: ret.ndim)
            lower[axis] = MfSlice(to: -1)

            let l = ret._get_mfarray(indices: &upper)
            let r = ret._get_mfarray(indices: &lower)
            ret = ret.mftype == .Bool ? Matft.not_equal(l, r) : l - r
        }
        return ret
    }

    /**
       Return coordinate matrices from coordinate vectors.

       Variadic form of `Matft.meshgrid(_:indexing:)`.
       Equivalent to `numpy.meshgrid`.
       - Parameters:
            - xi: The coordinate vectors. Each array is flattened.
            - indexing: (Optional) Cartesian (`.xy`, default) or matrix (`.ij`) indexing.
       - Returns: The coordinate matrices, one per input. Each is a contiguous copy.
    */
    public static func meshgrid(_ xi: MfArray..., indexing: MfMeshIndexing = .xy) -> [MfArray]{
        return Matft.meshgrid(xi, indexing: indexing)
    }

    /**
       Return coordinate matrices from coordinate vectors.

       With `.xy` indexing and inputs of lengths `M` and `N`, the outputs have shape `[N, M]`; with `.ij` they have shape `[M, N]`.
       Equivalent to `numpy.meshgrid`.

       ```swift
       let x = MfArray([1, 2, 3])
       let y = MfArray([4, 5])
       let grids = Matft.meshgrid([x, y])   // two arrays of shape [2, 3]
       ```
       - Parameters:
            - xi: The coordinate vectors. Each array is flattened.
            - indexing: (Optional) Cartesian (`.xy`, default) or matrix (`.ij`) indexing.
       - Returns: The coordinate matrices, one per input. Each is a contiguous copy.
    */
    public static func meshgrid(_ xi: [MfArray], indexing: MfMeshIndexing = .xy) -> [MfArray]{
        let ndim = xi.count
        // In xy indexing, the first two axes are swapped
        let swap = indexing == .xy && ndim > 1

        var retShape = xi.map{ $0.size }
        if swap{
            retShape.swapAt(0, 1)
        }

        return xi.enumerated().map{
            (i, x) in
            var shape = Array(repeating: 1, count: ndim)
            shape[swap && i < 2 ? 1 - i : i] = x.size
            return x.flatten().reshape(shape).broadcast_to(shape: retShape).to_contiguous(mforder: .Row)
        }
    }
}

/// Get the source index of the padded position `index` (relative to the start of the original values)
fileprivate func _pad_source_index(_ index: Int, size: Int, mode: MfPadMode) -> Int{
    func mod(_ a: Int, _ b: Int) -> Int{
        return ((a % b) + b) % b
    }

    switch mode {
    case .constant:
        preconditionFailure("constant mode has no source index")
    case .edge:
        return Swift.min(Swift.max(index, 0), size - 1)
    case .wrap:
        return mod(index, size)
    case .reflect:
        if size == 1{
            return 0
        }
        let m = mod(index, 2*size - 2)
        return m < size ? m : 2*size - 2 - m
    case .symmetric:
        let m = mod(index, 2*size)
        return m < size ? m : 2*size - 1 - m
    }
}
