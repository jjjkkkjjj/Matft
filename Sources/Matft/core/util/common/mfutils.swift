//
//  array.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation


internal func get_storedSize(_ shapeptr: UnsafeMutableBufferPointer<Int>, _ stridesptr: UnsafeMutableBufferPointer<Int>) -> Int{
    
    var ret = 1
    let _ = zip(shapeptr, stridesptr).map{
        (dim, st) in
        ret *= st != 0 && dim != 0 ? dim : 1
    }
    return ret
}

/**
        return boolean represents whether to contain reverse
 */
internal func isReverse(_ strides: inout [Int]) -> Bool{
    return strides.contains{ $0 < 0 }
}
