//
//  creation.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

//Note that return value (UnsafeMutableBufferPointer<T>) will not be freed and was not initialized
internal func create_unsafeMBPtrT<T: Numeric>(type: T.Type, count: Int) -> UnsafeMutableBufferPointer<T>{
    typealias pointer = UnsafeMutableBufferPointer<T>
    return pointer.allocate(capacity: count)
}
