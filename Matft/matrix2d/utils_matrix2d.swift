//
//  utils.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public func _check_same_matrixshape<T>(a: Matrix2d<T>, b: Matrix2d<T>) -> Bool{
    return _check_same_shape(a: a.shape, b: b.shape)
}

public func _check_same_shape(a: [Int], b: [Int]) -> Bool{
    for axis in 0..<2{
        if a[axis] != b[axis]{
            return false
        }
    }
    return true
}
