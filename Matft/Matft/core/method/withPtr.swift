//
//  withPtr.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/10.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    
    public func withShapeUnsafeMBPtr<R>(_ body: (UnsafeMutableBufferPointer<Int>) throws -> R) rethrows -> R{
        try body()
    }
    
    
}
