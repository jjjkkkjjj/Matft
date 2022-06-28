//
//  ptr2ptr.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

/**
   - Important: this function allocate new memory, so don't forget deallocate!
*/
internal func unsafeMBPtrT2UnsafeMRBPtr<T: MfTypable>(_ ptrT: UnsafeMutableBufferPointer<T>) -> UnsafeMutableRawBufferPointer{
    let ret = create_unsafeMRPtr(type: T.self, count: ptrT.count)
    
    return UnsafeMutableRawBufferPointer(start: ret, count: ptrT.count)
}
