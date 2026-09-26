//
//  prefix.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/29.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

prefix operator -
/// Element-wise negation. Equivalent to `numpy.negative` (`-a` in Numpy).
///
/// Same as `Matft.neg(_:)`. Complex arrays are supported.
/// - Parameters:
///   - mfarray: The input array.
/// - Returns: A new array with the same type.
public prefix func -(_ mfarray: MfArray) -> MfArray{
    return Matft.neg(mfarray)
}

prefix operator !
/// Element-wise logical NOT. Equivalent to `numpy.logical_not`.
///
/// Same as `Matft.logical_not(_:)`.
/// - Parameters:
///   - mfarray: The input array. Non-zero elements are treated as `true`.
/// - Returns: A new `.Bool` array.
public prefix func !(_ mfarray: MfArray) -> MfArray{
    return Matft.logical_not(mfarray)
}
