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
    public func withDataUnsafeMRPtr<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R{
        return try body(self.mfdata._data + self.mfdata._byteOffset)
    }
    public func withDataUnsafeMBPtrT<T, R>(datatype: T.Type, _ body: (UnsafeMutableBufferPointer<T>) throws -> R) rethrows -> R{
        let dataptr = self.withDataUnsafeMRPtr{
            [unowned self] in
            $0.bindMemory(to: T.self, capacity: self.storedSize)
        }
        
        return try body(UnsafeMutableBufferPointer(start: dataptr, count: self.storedSize))
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
            [unowned self](shapeptr) in
            try self.withStridesUnsafeMBPtr{
                stridesptr in
                try body(shapeptr, stridesptr)
            }
        }
        self.mfstructure.updateContiguous()
        
        return ret
    }
}


internal func withDummyShapeStridesMBPtr(_ ndim: Int, _ body: (UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>) throws -> Void) rethrows -> MfStructure{
    
    let dummyShapePtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    let dummyStridesPtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    
    try body(dummyShapePtr, dummyStridesPtr)
    
    return MfStructure(shapeptr: dummyShapePtr.baseAddress!, stridesptr: dummyStridesPtr.baseAddress!, ndim: ndim)
}
internal func withDummyShapeStridesMPtr(_ ndim: Int, _ body: (UnsafeMutablePointer<Int>, UnsafeMutablePointer<Int>) throws -> Void) rethrows -> MfStructure{
    
    let dummyShapePtr = create_unsafeMPtrT(type: Int.self, count: ndim)
    let dummyStridesPtr = create_unsafeMPtrT(type: Int.self, count: ndim)
    
    try body(dummyShapePtr, dummyStridesPtr)
    
    return MfStructure(shapeptr: dummyShapePtr, stridesptr: dummyStridesPtr, ndim: ndim)
}

internal func withDummyDataMRPtr(_ mftype: MfType, storedSize: Int, _ body: (UnsafeMutableRawPointer) throws -> Void) rethrows -> MfData{
    
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

internal func withDummy(mftype: MfType, storedSize: Int, ndim: Int, _ body: (UnsafeMutableRawPointer, UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>) throws -> Void) rethrows -> MfArray{
    let dummyShapePtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    let dummyStridesPtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    
    let newmfdata = try withDummyDataMRPtr(mftype, storedSize: storedSize){
        try body($0, dummyShapePtr, dummyStridesPtr)
    }
    
    let newmfstructure = MfStructure(shapeptr: dummyShapePtr.baseAddress!, stridesptr: dummyStridesPtr.baseAddress!, ndim: ndim)
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

internal func withDummy2ShapeStridesMBPtr(_ ndim: Int, _ body: (UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>) throws -> Void) rethrows -> (l: MfStructure, r: MfStructure){
    
    let l_dummyShapePtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    let l_dummyStridesPtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    
    let r_dummyShapePtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    let r_dummyStridesPtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
    
    try body(l_dummyShapePtr, l_dummyStridesPtr, r_dummyShapePtr, r_dummyStridesPtr)
    
    return (MfStructure(shapeptr: l_dummyShapePtr.baseAddress!, stridesptr: l_dummyStridesPtr.baseAddress!, ndim: ndim), MfStructure(shapeptr: r_dummyShapePtr.baseAddress!, stridesptr: r_dummyStridesPtr.baseAddress!, ndim: ndim))
}
