//
//  creation.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

//Note that returned value (UnsafeMutableBufferPointer<T>) will not be freed and was not initialized
internal func create_unsafeMBPtrT<T: Numeric>(type: T.Type, count: Int) -> UnsafeMutableBufferPointer<T>{
    typealias pointer = UnsafeMutableBufferPointer<T>
    return pointer.allocate(capacity: count)
}

//Note that returned value (UnsafeMutableRawBufferPointer) will not be freed and was not initialized
internal func create_unsafeMRBPtr<T>(type: T.Type, count: Int) -> UnsafeMutableRawBufferPointer{
    typealias pointer = UnsafeMutableRawBufferPointer
    return pointer.allocate(byteCount: MemoryLayout<T>.stride * count, alignment: MemoryLayout<T>.alignment)
}
