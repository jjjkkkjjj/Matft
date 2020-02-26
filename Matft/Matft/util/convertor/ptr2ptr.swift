//
//  ptr2ptr.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

internal func unsafeMBPtrT2UnsafeMRBPtr<T>(_ ptrT: UnsafeMutableBufferPointer<T>) -> UnsafeMutableRawBufferPointer{
    typealias retptr = UnsafeMutableRawBufferPointer
    let ret = retptr.allocate(byteCount: MemoryLayout<T>.size * ptrT.count, alignment: MemoryLayout<T>.alignment)
    
    memcpy(ret.baseAddress!, ptrT.baseAddress!, MemoryLayout<T>.size * ptrT.count)
    
    return ret
}
