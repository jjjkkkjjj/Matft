//
//  creation.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

/**
   - Important: this function allocate new memory, so don't forget deallocate!
   - Parameters:
      - zeroed: Whether to fill the memory with zeros. Pass false only when every element is written before being read
*/
internal func allocate_unsafeMPtrT<T: MfTypable>(type: T.Type, count: Int, zeroed: Bool) -> UnsafeMutablePointer<T>{
    let ret = UnsafeMutablePointer<T>.allocate(capacity: count)
    fill_allocated(UnsafeMutableRawPointer(ret), byteCount: MemoryLayout<T>.stride * count, zeroed: zeroed)
    return ret
}

/**
   - Important: this function allocate new memory, so don't forget deallocate!
   - Parameters:
      - zeroed: Whether to fill the memory with zeros. Pass false only when every element is written before being read
*/
internal func allocate_unsafeMRPtr<T: MfTypable>(type: T.Type, count: Int, zeroed: Bool) -> UnsafeMutableRawPointer{
    let ret = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<T>.stride * count, alignment: MemoryLayout<T>.alignment)
    fill_allocated(ret, byteCount: MemoryLayout<T>.stride * count, zeroed: zeroed)
    return ret
}

/// Zero-fill with memset, which is fast even without optimization unlike the generic `initialize(repeating:)`.
/// In debug builds, uninitialized memory is filled with NaN while `MfData._poisonUninitialized` is true
@inline(__always)
private func fill_allocated(_ ptr: UnsafeMutableRawPointer, byteCount: Int, zeroed: Bool){
    if zeroed{
        memset(ptr, 0, byteCount)
        return
    }
    #if DEBUG
    if MfData._poisonUninitialized{
        // all bits set is NaN for both Float and Double
        memset(ptr, 0xFF, byteCount)
    }
    #endif
}
