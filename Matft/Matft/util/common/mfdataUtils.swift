//
//  array.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

extension MfStructure{
    public func updateContiguous(){
        self._flags.updateContiguous(shapeptr: self._shape, stridesptr: self._strides, ndim: self._ndim)
    }
    
}

internal func shape2ndim(_ shape: inout [Int]) -> Int{
    return shape.count
}
internal func shape2ndim(_ shapeptr: UnsafeMutableBufferPointer<Int>) -> Int{
    return shapeptr.count
}

internal func shape2size(_ shapeptr: UnsafeMutableBufferPointer<Int>) -> Int{
    return shapeptr.reduce(1, *)
    //return shapeptr.filter{ $0 != 0 }.reduce(1, *)
}
internal func shape2size(_ shape: inout [Int]) -> Int{
    return shape.withUnsafeMutableBufferPointer{
        shape2size($0)
    }
}

/**
    - Important: this function allocate new memory, so don't forget deallocate!
 */
internal func shape2strides(_ shapeptr: UnsafeMutableBufferPointer<Int>, mforder: MfOrder) -> UnsafeMutableBufferPointer<Int>{
    let stridesptr = create_unsafeMPtrT(type: Int.self, count: shapeptr.count)
    let ret = UnsafeMutableBufferPointer(start: stridesptr, count: shapeptr.count)
    
    switch mforder {
    case .Row://, .None:
        var prevAxisNum = shape2size(shapeptr)
        for index in 0..<shapeptr.count{
            ret[index] = prevAxisNum / shapeptr[index]
            prevAxisNum = ret[index]
        }
    case .Column:
        ret[0] = 1
        for index in 1..<shapeptr.count{
            ret[index] = ret[index - 1] * shapeptr[index - 1]
        }
    }
    
    return ret
}

internal func get_storedSize(_ shapeptr: UnsafeMutableBufferPointer<Int>, _ stridesptr: UnsafeMutableBufferPointer<Int>) -> Int{
    
    var ret = 1
    let _ = zip(shapeptr, stridesptr).map{
        (dim, st) in
        ret *= st != 0 && dim != 0 ? dim : 1
    }
    return ret
}
