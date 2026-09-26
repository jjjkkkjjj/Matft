//
//  File.swift
//
//
//  Created by AM19A0 on 2020/05/11.
//

import Foundation

extension MfArray{
    /**
       Return the ceiling of each element.

       Method version of `Matft.math.ceil(_:)`. Complex arrays are not supported.
       Equivalent to `numpy.ceil`.
       - Returns: A new array of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public func ceil() -> MfArray{
        return Matft.math.ceil(self)
    }

    /**
       Return the floor of each element.

       Method version of `Matft.math.floor(_:)`. Complex arrays are not supported.
       Equivalent to `numpy.floor`.
       - Returns: A new array of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public func floor() -> MfArray{
        return Matft.math.floor(self)
    }

    /**
       Return the integer truncation (rounding toward zero) of each element.

       Method version of `Matft.math.trunc(_:)`. Complex arrays are not supported.
       Equivalent to `numpy.trunc`.
       - Returns: A new array of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public func trunc() -> MfArray{
        return Matft.math.trunc(self)
    }

    /**
       Return the nearest integer of each element.

       Method version of `Matft.math.nearest(_:)`. Complex arrays are not supported.
       Similar to `numpy.rint`.
       - Returns: A new array of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public func nearest() -> MfArray{
        return Matft.math.nearest(self)
    }

    /**
       Round each element to the given number of decimals.

       Method version of `Matft.math.round(_:decimals:)`. Complex arrays are not supported.
       Equivalent to `numpy.round`.
       - Parameters:
            - decimals: (Optional) The number of decimal places, by default 0 (same as `nearest()`). Negative values round to the left of the decimal point.
       - Returns: The rounded array.
    */
    public func round(decimals: Int = 0) -> MfArray{
        return Matft.math.round(self, decimals: decimals)
    }

    /**
       Return the sign of each element: -1 for negative, 0 for zero and 1 for positive values.

       Method version of `Matft.math.sign(_:)`. Complex arrays are not supported.
       Equivalent to `numpy.sign`.
       - Returns: The array of signs.
    */
    public func sign() -> MfArray{
        Matft.math.sign(self)
    }
}
