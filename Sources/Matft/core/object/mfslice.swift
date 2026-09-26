//
//  mfindex.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/01.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// A slice used in `MfArray` subscripts, the counterpart of Python's `start:stop:step`.
///
/// An `MfSlice` is usually created with the `~<` family of operators rather than directly.
/// Negative `start` / `to` count from the end of the axis, as in Numpy.
/// Slicing returns a view that shares memory with the original array.
///
/// ```swift
/// let b = Matft.arange(start: 0, to: 10, by: 1)
/// b[1~<8~<3]                        // b[1:8:3] -> [1, 4, 7]
/// b[~<<-3]                          // b[::-3]  -> [9, 6, 3, 0]
/// b[MfSlice(start: 2, by: -4)]      // b[2::-4] -> [2]
/// ```
public struct MfSlice {
    /// The end index (exclusive). `nil` means up to the end of the axis (or the beginning when `by` is negative).
    public let to: Int? // nil means all value
    /// The start index. `nil` means the beginning of the axis (or the end when `by` is negative).
    public let start: Int?
    /// The step. Negative values traverse the axis in reverse.
    public let by: Int
    
    /// Creates a slice equivalent to Python's `start:to:by`.
    /// - Parameters:
    ///   - start: The start index, or `nil` for the default start.
    ///   - to: The end index (exclusive), or `nil` for the default end.
    ///   - by: The step. Defaults to 1.
    /// - Precondition: `by` must not be 0.
    public init(start: Int? = nil, to: Int? = nil, by: Int = 1){
        precondition(by != 0, "by must not be 0")
        self.to = to
        self.start = start
        self.by = by
    }
    
}
