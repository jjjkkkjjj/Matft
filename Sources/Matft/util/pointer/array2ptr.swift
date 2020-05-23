//
//  pointer.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

/*
//Note that return value (UnsafeMutableRawBufferPointer) will not be freed
internal func array2UnsafeRawPtr(_ anyarray: inout [Any], mftype: MfType) -> UnsafeMutableRawBufferPointer{
    switch mftype {
        case .UInt32:
            var ret = anyarray as? [UInt32]
            return _array2UnsafeRawPtr(&ret)
        case .UInt64:
            var ret = anyarray as? [UInt64]
            return _array2UnsafeRawPtr(&ret)
        case .UInt:
            var ret = anyarray as? [UInt]
            return _array2UnsafeRawPtr(&ret)
        case .Int32:
            var ret = anyarray as? [Int32]
            return _array2UnsafeRawPtr(&ret)
        case .Int64:
            var ret = anyarray as? [Int64]
            return _array2UnsafeRawPtr(&ret)
        case .Int:
            var ret = anyarray as? [Int]
            return _array2UnsafeRawPtr(&ret)
        case .Float:
            var ret = anyarray as? [Float]
            return _array2UnsafeRawPtr(&ret)
        case .Double:
            var ret = anyarray as? [Double]
            return _array2UnsafeRawPtr(&ret)
        default:
            fatalError("Unsupported type \(mftype).")
    }
    
}

fileprivate func _array2UnsafeRawPtr<T: Numeric>(_ array: inout [T]?) -> UnsafeMutableRawBufferPointer{
    if var array = array{
        typealias ptr = UnsafeMutableRawBufferPointer
        let ret = ptr.allocate(byteCount: MemoryLayout<T>.size * array.count, alignment: MemoryLayout<T>.alignment)
        
        let _ = array.withUnsafeMutableBytes{
            memcpy(ret.baseAddress!, $0.baseAddress!, $0.count)
        }
        
        return ret
    }
    else{
        fatalError("Cannot cast, this was caused by internal bug")
    }
}

*/

/**
   - Important: this function allocate new memory, so don't forget deallocate!
*/
internal func array2UnsafeMPtrT<T: MfTypable>(_ array: inout [T]) -> UnsafeMutablePointer<T>{
    let ptr = create_unsafeMPtrT(type: T.self, count: array.count)
    array.withUnsafeBufferPointer{
        ptr.assign(from: $0.baseAddress!, count: $0.count)
    }
    return ptr
}



//convert flattenarray to rawpointer via float or Double array
//All kinds of int and uint will be handled as float
/**
   - Important: this function allocate new memory, so don't forget deallocate!
*/
internal func flattenarray2UnsafeMRPtr_viaForD(_ flattenarray: inout [Any], mftypeBool: Bool) -> (ptr: UnsafeMutableRawPointer, mftype: MfType) {
    
    var mftype = MfType.None
    //UInt
    if let flattenarray = flattenarray as? [UInt8]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu8, flattenarray.count)
        }
        mftype = .UInt8
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [UInt16]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu16, flattenarray.count)
        }
        mftype = .UInt16
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [UInt32]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu32, flattenarray.count)
        }
        mftype = .UInt32
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [UInt64]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        //convert uint64 to uint32
        let flatten32array = flattenarray.map{ UInt32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu32, flattenarray.count)
        }
        mftype = .UInt64
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [UInt]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        //convert uint to uint32
        //Note that UInt and Int will be handled as uint32 and Int32 respectively
        //Also Int will be handled as int64
        let flatten32array = flattenarray.map{ UInt32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu32, flattenarray.count)
        }
        mftype = .UInt
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    //Int
    else if let flattenarray = flattenarray as? [Int8]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt8, flattenarray.count)
        }
        mftype = .Int8
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [Int16]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt16, flattenarray.count)
        }
        mftype = .Int16
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [Int32]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt32, flattenarray.count)
        }
        mftype = .Int32
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [Int64]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        //convert int64 to int32
        let flatten32array = flattenarray.map{ Int32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt32, flattenarray.count)
        }
        mftype = .Int64
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [Int]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        //convert int to int32
        let flatten32array = flattenarray.map{ Int32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt32, flattenarray.count)
        }
        mftype = .Int
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if var flattenarray = flattenarray as? [Float]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        let _ = flattenarray.withUnsafeMutableBufferPointer{
            ptrF.assign(from: $0.baseAddress!, count: $0.count)
        }
        mftype = .Float
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if let flattenarray = flattenarray as? [Bool]{
        let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
        //convert bool to float
        // true = 1, false = 0
        var flattenBoolarray = flattenarray.map{ $0 ? Float.num(1) : Float.zero }
        let _ = flattenBoolarray.withUnsafeMutableBufferPointer{
            ptrF.moveAssign(from: $0.baseAddress!, count: $0.count)
        }
        _T2Binary(UnsafeMutableBufferPointer(start: ptrF, count: flattenarray.count))
        mftype = .Bool
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if var flattenarray = flattenarray as? [Double]{
        let ptrD = create_unsafeMPtrT(type: Double.self, count: flattenarray.count)
        let _ = flattenarray.withUnsafeMutableBufferPointer{
            ptrD.assign(from: $0.baseAddress!, count: $0.count)
        }
        mftype = .Double
        
        if mftypeBool{
            _T2Binary(UnsafeMutableBufferPointer(start: ptrD, count: flattenarray.count))
            mftype = .Bool
        }
        
        return (UnsafeMutableRawPointer(ptrD), mftype)
    }
    else{
        fatalError("flattenarray couldn't cast MfTypable.")
    }
}

fileprivate func _T2Binary<T: MfStorable>(_ ptrT: UnsafeMutableBufferPointer<T>){
    let size = ptrT.count
    var arrBinary = ptrT.map{ $0 == T.zero ? T.zero : T.num(1) }
    arrBinary.withUnsafeMutableBufferPointer{
        ptrT.baseAddress!.moveAssign(from: $0.baseAddress!, count: size)
    }
}
