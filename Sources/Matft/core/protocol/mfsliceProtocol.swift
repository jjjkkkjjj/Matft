//
//  mfsliceProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/13.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// A type that can be used as an index in `MfArray` subscripts: `Int`, `MfSlice` or `SubscriptOps`.
public protocol MfSubscriptable{}

extension Int: MfSubscriptable{}
extension MfSlice: MfSubscriptable{}

/// Special subscript markers. Usually accessed via `Matft.newaxis`, `Matft.all` and `Matft.reverse`.
public enum SubscriptOps: MfSubscriptable{
    /// Inserts a new axis of length 1 (`numpy.newaxis`).
    case newaxis
    /// Selects all elements along an axis (`:` in Numpy).
    case all
    /// Selects all elements along an axis in reverse order (`::-1` in Numpy).
    case reverse
}
