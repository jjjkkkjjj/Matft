//
//  File.swift
//
//
//  Created by AM19A0 on 2020/05/15.
//

import Foundation

extension MfArray{
    /**
       Compute the arithmetic mean along the given axis.

       Method version of `Matft.stats.mean(_:axis:keepDims:)`. Complex arrays are not supported.
       Equivalent to `numpy.mean`.
       - Parameters:
            - axis: (Optional) The axis along which the mean is computed. If `nil` (default), the mean of all elements is returned.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
       - Returns: The mean, of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public func mean(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.mean(self, axis: axis, keepDims: keepDims)
    }
    /**
       Return the maximum along the given axis.

       Method version of `Matft.stats.max(_:axis:keepDims:)`. Complex arrays are not supported.
       Equivalent to `numpy.max`.
       - Parameters:
            - axis: (Optional) The axis along which to operate. If `nil` (default), the maximum of all elements is returned.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
       - Returns: The maximum values.
    */
    public func max(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.max(self, axis: axis, keepDims: keepDims)
    }
    /**
       Return the indices of the maximum values along the given axis.

       Method version of `Matft.stats.argmax(_:axis:)`. Complex arrays are not supported.
       Equivalent to `numpy.argmax`.
       - Parameters:
            - axis: (Optional) The axis along which to operate. If `nil` (default), the index into the flattened array is returned.
       - Returns: The `.Int` indices of the maximum values.
    */
    public func argmax(axis: Int? = nil) -> MfArray{
        return Matft.stats.argmax(self, axis: axis)
    }
    /**
       Return the minimum along the given axis.

       Method version of `Matft.stats.min(_:axis:keepDims:)`. Complex arrays are not supported.
       Equivalent to `numpy.min`.
       - Parameters:
            - axis: (Optional) The axis along which to operate. If `nil` (default), the minimum of all elements is returned.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
       - Returns: The minimum values.
    */
    public func min(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.min(self, axis: axis, keepDims: keepDims)
    }
    /**
       Return the indices of the minimum values along the given axis.

       Method version of `Matft.stats.argmin(_:axis:)`. Complex arrays are not supported.
       Equivalent to `numpy.argmin`.
       - Parameters:
            - axis: (Optional) The axis along which to operate. If `nil` (default), the index into the flattened array is returned.
       - Returns: The `.Int` indices of the minimum values.
    */
    public func argmin(axis: Int? = nil) -> MfArray{
        return Matft.stats.argmin(self, axis: axis)
    }
    /**
       Sum the elements along the given axis.

       Method version of `Matft.stats.sum(_:axis:keepDims:)`. Complex arrays are not supported.
       Equivalent to `numpy.sum`.
       - Parameters:
            - axis: (Optional) The axis along which to sum. If `nil` (default), all elements are summed.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
       - Returns: The sum.
    */
    public func sum(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.sum(self, axis: axis, keepDims: keepDims)
    }
    /**
       Compute the square root of the sum along the given axis, i.e. `sqrt(sum(a))`.

       Method version of `Matft.stats.sumsqrt(_:axis:keepDims:)`. Complex arrays are not supported.
       - Parameters:
            - axis: (Optional) The axis along which to sum. If `nil` (default), all elements are summed.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
       - Returns: The square root of the sum.
    */
    public func sumsqrt(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.sumsqrt(self, axis: axis, keepDims: keepDims)
    }
    /**
       Compute the sum of squares along the given axis, i.e. `sum(a * a)`.

       Method version of `Matft.stats.squaresum(_:axis:keepDims:)`. Complex arrays are not supported.
       - Parameters:
            - axis: (Optional) The axis along which to sum. If `nil` (default), all elements are summed.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
       - Returns: The sum of squares.
    */
    public func squaresum(axis: Int? = nil, keepDims: Bool = false) -> MfArray{
        return Matft.stats.squaresum(self, axis: axis, keepDims: keepDims)
    }

    /**
       Compute the cumulative sum along the given axis.

       Method version of `Matft.stats.cumsum(_:axis:)`. Complex arrays are not supported.
       Equivalent to `numpy.cumsum`.
       - Parameters:
            - axis: (Optional) The axis along which the cumulative sum is computed. If `nil` (default), the flattened array is used.
       - Returns: The cumulative sum (1-D when `axis` is `nil`). A `.Bool` array is summed as integers.
    */
    public func cumsum(axis: Int? = nil) -> MfArray{
        return Matft.stats.cumsum(self, axis: axis)
    }

    /**
       Compute the variance along the given axis.

       Method version of `Matft.stats.var(_:axis:keepDims:ddof:)`. Complex arrays are not supported.
       Equivalent to `numpy.var`.
       - Parameters:
            - axis: (Optional) The axis along which the variance is computed. If `nil` (default), the variance of all elements is returned.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
            - ddof: (Optional) Delta degrees of freedom. The divisor is `N - ddof`, by default 0.
       - Returns: The variance, of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public func `var`(axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return Matft.stats.var(self, axis: axis, keepDims: keepDims, ddof: ddof)
    }

    /**
       Compute the standard deviation along the given axis.

       Method version of `Matft.stats.std(_:axis:keepDims:ddof:)`. Complex arrays are not supported.
       Equivalent to `numpy.std`.
       - Parameters:
            - axis: (Optional) The axis along which the standard deviation is computed. If `nil` (default), the standard deviation of all elements is returned.
            - keepDims: (Optional) Whether to keep the reduced axis as a dimension of length 1, by default `false`.
            - ddof: (Optional) Delta degrees of freedom. The divisor is `N - ddof`, by default 0.
       - Returns: The standard deviation, of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public func std(axis: Int? = nil, keepDims: Bool = false, ddof: Int = 0) -> MfArray{
        return Matft.stats.std(self, axis: axis, keepDims: keepDims, ddof: ddof)
    }
}
