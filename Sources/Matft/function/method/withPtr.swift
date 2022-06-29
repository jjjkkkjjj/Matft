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
        return try body(self.mfdata.data + self.mfdata.byteOffset)
    }
    public func withDataUnsafeMBPtrT<T, R>(datatype: T.Type, _ body: (UnsafeMutableBufferPointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withDataUnsafeMRPtr{
            [unowned self](ptr) -> R in
            let dataptr = ptr.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(UnsafeMutableBufferPointer(start: dataptr, count: self.storedSize))
        }
        
        return ret
    }
    public func withContiguousDataUnsafeMPtrT<T>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> Void) rethrows -> Void{
        var shape = self.shape
        var strides = self.strides
        try self.withDataUnsafeMBPtrT(datatype: T.self){
            ptr in
            for ind in FlattenIndSequence(shape: &shape, strides: &strides){
                try body(ptr.baseAddress! + ind.flattenIndex)
            }
        }
    }
    

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



internal func withDataMBPtr_multi<T, R>(datatype: T.Type, _ a: MfArray, _ b: MfArray, _ body: ((UnsafeMutableBufferPointer<T>, UnsafeMutableBufferPointer<T>) throws -> R)) rethrows -> R{
    return try a.withDataUnsafeMBPtrT(datatype: T.self){
        aptr in
        try b.withDataUnsafeMBPtrT(datatype: T.self){
            bptr in
            return try body(aptr, bptr)
        }
    }
}

internal func withContiguousDataUnsafeMPtrT_multi<T>(datatype: T.Type, _ a: MfArray, _ b: MfArray, _ body: (UnsafeMutablePointer<T>, UnsafeMutablePointer<T>) throws -> Void) rethrows -> Void{
    assert(a.size == b.size, "must have same size. call biop_broadcast_to first.")
    var a_shape = a.shape
    var a_strides = a.strides
    var b_shape = b.shape
    var b_strides = b.strides
    try a.withDataUnsafeMBPtrT(datatype: T.self){
        a_ptr in
        try b.withDataUnsafeMBPtrT(datatype: T.self){
            b_ptr in
            for (a_ind, b_ind) in zip(FlattenIndSequence(shape: &a_shape, strides: &a_strides), FlattenIndSequence(shape: &b_shape, strides: &b_strides)){
                try body(a_ptr.baseAddress! + a_ind.flattenIndex, b_ptr.baseAddress! + b_ind.flattenIndex)
            }
        }
    }
}
