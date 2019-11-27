//
//  utils_vector.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

func _check_index(index: Int, size: Int) -> Bool{
    return (index >= 0) && (index < size)
}

func _check_same_vectorshape<T>(a: Vector<T>, b: Vector<T>) -> Bool{

    return (a.size == b.size) && (a.columned == b.columned)
}

