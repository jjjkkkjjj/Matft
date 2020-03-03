//
//  creation.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

//Note that returned value (UnsafeMutableBufferPointer<T>) will not be freed and was not initialized
internal func create_unsafeMPtrT<T: Numeric>(type: T.Type, count: Int) -> UnsafeMutablePointer<T>{
    typealias pointer = UnsafeMutablePointer<T>
    let ret = pointer.allocate(capacity: count)
    ret.initialize(repeating: T.zero, count: count)

    return ret
}

//Note that returned value (UnsafeMutableRawBufferPointer) will not be freed and was not initialized
internal func create_unsafeMRPtr<T: Numeric>(type: T.Type, count: Int) -> UnsafeMutableRawPointer{
    typealias pointer = UnsafeMutableRawPointer
    let ret = pointer.allocate(byteCount: MemoryLayout<T>.stride * count, alignment: MemoryLayout<T>.alignment)
    ret.initializeMemory(as: T.self, repeating: T.zero, count: count)
    
    return ret
}
