//
//  ptr2ptr.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

internal func unsafeMBPtrT2UnsafeMRBPtr<T: Numeric>(_ ptrT: UnsafeMutableBufferPointer<T>) -> UnsafeMutableRawBufferPointer{
    let ret = create_unsafeMRPtr(type: T.self, count: ptrT.count)
    
    return UnsafeMutableRawBufferPointer(start: ret, count: ptrT.count)
}
