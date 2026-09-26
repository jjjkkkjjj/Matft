//
//  mforder.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/07.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// The memory layout order of an array.
///
/// Equivalent to the `order` argument (`'C'` / `'F'`) in Numpy.
public enum MfOrder: Int{
    /// Row-major (C-style) order: the last axis varies fastest.
    case Row
    /// Column-major (Fortran-style) order: the first axis varies fastest.
    case Column
    
    /// Returns the order in which the given structure is contiguous.
    /// - Parameters:
    ///   - mfstructure: The structure (shape and strides) to inspect.
    /// - Returns: `.Row` if the structure is row contiguous, `.Column` if it is only column contiguous,
    ///   and `.Row` if it is neither.
    public static func get_order(mfstructure: MfStructure) -> MfOrder{
        if mfstructure.row_contiguous{
            return .Row
        }
        
        if mfstructure.column_contiguous{
            return .Column
        }
        // in case neither contiguous, return row major
        return .Row
    }
}

/// The direction of sorting.
public enum MfSortOrder: Int32{
    /// Ascending order (smallest first).
    case Ascending = 1
    /// Descending order (largest first).
    case Descending = -1
}

