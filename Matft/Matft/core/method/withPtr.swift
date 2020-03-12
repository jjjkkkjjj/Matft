//
//  withPtr.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/10.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    /*
    public func withDataUnsafeMBPtr<T, R>(_ body: (UnsafeMutableBufferPointer<Int>) throws -> R) rethrows -> R{
        self.mfdata._data.assumingMemoryBound(to: <#T##T.Type#>)
        
        return try body(UnsafeMutableBufferPointer(start: self.mfstructure._shape, count: self.ndim))
    }*/
    public func withDataUnsafeMRBPtr<R>(_ body: (UnsafeMutableRawBufferPointer) throws -> R) rethrows -> R{
        return try body(UnsafeMutableRawBufferPointer(start: self.mfdata._data + self.mfdata._byteOffset, count: self.storedSize))
    }
    public func withDataUnsafeMBPtrT<T, R>(datatype: T.Type, _ body: (UnsafeMutableBufferPointer<T>) throws -> R) rethrows -> R{
        let dataptr = self.withDataUnsafeMRBPtr{
            $0.bindMemory(to: T.self)
        }
        
        return try body(dataptr)
    }
    
    public func withShapeUnsafeMBPtr<R>(_ body: (UnsafeMutableBufferPointer<Int>) throws -> R) rethrows -> R{
        return try body(UnsafeMutableBufferPointer(start: self.mfstructure._shape, count: self.ndim))
    }
    public func withShapeUnsafeMPtr<R>(_ body: (UnsafeMutablePointer<Int>) throws -> R) rethrows -> R{
        return try body(self.mfstructure._shape)
    }
    
    public func withStridesUnsafeMBPtr<R>(_ body: (UnsafeMutableBufferPointer<Int>) throws -> R) rethrows -> R{
        return try body(UnsafeMutableBufferPointer(start: self.mfstructure._strides, count: self.ndim))
    }
    public func withStridesUnsafeMPtr<R>(_ body: (UnsafeMutablePointer<Int>) throws -> R) rethrows -> R{
        return try body(self.mfstructure._strides)
    }
    
    public func withShapeStridesUnsafeMBPtr<R>(_ body: (UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>) throws -> R) rethrows -> R{
        let ret = try self.withShapeUnsafeMBPtr{
            shapeptr in
            try self.withStridesUnsafeMBPtr{
                stridesptr in
                try body(shapeptr, stridesptr)
            }
        }
        self.mfstructure.updateContiguous()
        
        return ret
    }
}


public func withDummyShapeStridesMBPtr(_ ndim: Int, _ body: (UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>) throws -> Void) rethrows -> MfStructure{
    
    let dummyShapePtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    let dummyStridesPtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    
    try body(dummyShapePtr, dummyStridesPtr)
    
    return MfStructure(shapeptr: dummyShapePtr.baseAddress!, stridesptr: dummyStridesPtr.baseAddress!, ndim: ndim)
}
public func withDummyShapeStridesMPtr(_ ndim: Int, _ body: (UnsafeMutablePointer<Int>, UnsafeMutablePointer<Int>) throws -> Void) rethrows -> MfStructure{
    
    let dummyShapePtr = create_unsafeMPtrT(type: Int.self, count: ndim)
    let dummyStridesPtr = create_unsafeMPtrT(type: Int.self, count: ndim)
    
    try body(dummyShapePtr, dummyStridesPtr)
    
    return MfStructure(shapeptr: dummyShapePtr, stridesptr: dummyStridesPtr, ndim: ndim)
}

public func withDummyDataMRPtr(_ mftype: MfType, storedSize: Int, _ body: (UnsafeMutableRawPointer) throws -> Void) rethrows -> MfData{
    
    switch MfType.storedType(mftype) {
    case .Float:
        let dummyDataPtr = create_unsafeMRPtr(type: Float.self, count: storedSize)

        try body(dummyDataPtr)
        
        return MfData(dataptr: dummyDataPtr, storedSize: storedSize, mftype: mftype)
    case .Double:
        let dummyDataPtr = create_unsafeMRPtr(type: Double.self, count: storedSize)
        
        try body(dummyDataPtr)
        
        return MfData(dataptr: dummyDataPtr, storedSize: storedSize, mftype: mftype)
    }
}
