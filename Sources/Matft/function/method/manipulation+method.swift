//
//  manipulation+method.swift
//  Matft
//

import Foundation

extension MfArray{
    /**
       Pad the array.

       Method version of `Matft.pad(_:pad_width:mode:constant_values:)`. The result is always a new array. Complex arrays are not supported.
       Equivalent to `numpy.pad`.
       - Parameters:
            - pad_width: The number of values padded to the edges of each axis: `[(before, after)]` for each axis, or a single `(before, after)` applied to all axes. Values must be non-negative.
            - mode: (Optional) The padding mode, by default `.constant`.
            - constant_values: (Optional) The value used for the padded elements in `.constant` mode, by default 0. It is converted into the array's `mftype`.
       - Returns: The padded array.
    */
    public func pad(pad_width: [(Int, Int)], mode: MfPadMode = .constant, constant_values: Double = 0) -> MfArray{
        return Matft.pad(self, pad_width: pad_width, mode: mode, constant_values: constant_values)
    }

    /**
       Pad the array with the same width on all edges.

       Method version of `Matft.pad(_:pad_width:mode:constant_values:)`. Complex arrays are not supported.
       Equivalent to `numpy.pad` with an int `pad_width`.
       - Parameters:
            - pad_width: The number of values padded to both edges of every axis. It must be non-negative.
            - mode: (Optional) The padding mode, by default `.constant`.
            - constant_values: (Optional) The value used for the padded elements in `.constant` mode, by default 0. It is converted into the array's `mftype`.
       - Returns: The padded array.
    */
    public func pad(pad_width: Int, mode: MfPadMode = .constant, constant_values: Double = 0) -> MfArray{
        return Matft.pad(self, pad_width: pad_width, mode: mode, constant_values: constant_values)
    }

    /**
       Calculate the n-th discrete difference along the given axis.

       Method version of `Matft.diff(_:n:axis:)`.
       Equivalent to `numpy.diff`.
       - Parameters:
            - n: (Optional) The number of times values are differenced, by default 1. It must be non-negative; 0 returns the array itself.
            - axis: (Optional) The axis along which the difference is taken, by default the last axis.
       - Returns: The n-th differences, whose length along `axis` is reduced by `n`. For a `.Bool` array, `not_equal` is used instead of subtraction.
    */
    public func diff(n: Int = 1, axis: Int = -1) -> MfArray{
        return Matft.diff(self, n: n, axis: axis)
    }
}
