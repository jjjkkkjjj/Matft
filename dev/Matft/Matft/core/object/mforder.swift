//
//  mforder.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/07.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public enum MfOrder: Int{
    case Row
    case Column
    
    public static func get_order(mfflags: MfFlags) -> MfOrder{
        if mfflags.row_contiguous{
            return .Row
        }
        
        if mfflags.column_contiguous{
            return .Column
        }
        // in case neither contiguous, return row major
        return .Row
    }
}

public struct MfFlags{
    public var row_contiguous: Bool
    public var column_contiguous: Bool
    
    public init(shapeptr: UnsafeMutablePointer<Int>, stridesptr: UnsafeMutablePointer<Int>, ndim: Int){
        (self.row_contiguous, self.column_contiguous) = _check_contiguous(shapeptr: shapeptr, stridesptr: stridesptr, ndim: ndim)
    }
    
    public mutating func updateContiguous(shapeptr: UnsafeMutablePointer<Int>, stridesptr: UnsafeMutablePointer<Int>, ndim: Int){
        (self.row_contiguous, self.column_contiguous) = _check_contiguous(shapeptr: shapeptr, stridesptr: stridesptr, ndim: ndim)
    }
}

fileprivate func _check_contiguous(shapeptr: UnsafeMutablePointer<Int>, stridesptr: UnsafeMutablePointer<Int>, ndim: Int) -> (row_contiguous: Bool, column_contiguous: Bool){
    var sd = 1
    let shapeptr = UnsafeMutableBufferPointer(start: shapeptr, count: ndim)
    let stridesptr = UnsafeMutableBufferPointer(start: stridesptr, count: ndim)
    
    //check row contiguous
    var is_c_contig = true
    for i in stride(from: shapeptr.count - 1, through: 0, by: -1){
        let dim = shapeptr[i]
        if dim == 0{
            return (true, true)
        }
        if dim != 1{
            if stridesptr[i] != sd{
                is_c_contig = false
            }
            sd *= dim
        }
    }

    sd = 1
    //check column contiguous
    for i in 0..<shapeptr.count{
        let dim = shapeptr[i]
        if dim != 1{
            if stridesptr[i] != sd{
                return (is_c_contig, false)
            }
            sd *= dim
        }
    }
    return (is_c_contig, true)
}
