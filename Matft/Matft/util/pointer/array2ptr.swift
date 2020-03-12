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

internal func array2UnsafeMPtrT<T: Numeric>(_ array: inout [T]) -> UnsafeMutablePointer<T>{
    let ptr = create_unsafeMPtrT(type: T.self, count: array.count)
    array.withUnsafeBufferPointer{
        ptr.assign(from: $0.baseAddress!, count: $0.count)
    }
    return ptr
}



//convert flattenarray to rawpointer via float or Double array
//All kinds of int and uint will be handled as float
internal func flattenarray2UnsafeMRPtr_viaForD(_ flattenarray: inout [Any]) -> UnsafeMutableRawPointer {
    
    let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
    
    //UInt
    if let flattenarray = flattenarray as? [UInt8]{
        
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu8, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [UInt16]{
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu16, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [UInt32]{
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu32, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [UInt64]{
        //convert uint64 to uint32
        let flatten32array = flattenarray.map{ UInt32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu32, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [UInt]{
        //convert uint to uint32
        //Note that UInt and Int will be handled as uint32 and Int32 respectively
        //Also Int will be handled as int64
        let flatten32array = flattenarray.map{ UInt32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vfltu32, flattenarray.count)
        }
    }
    //Int
    else if let flattenarray = flattenarray as? [Int8]{
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt8, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [Int16]{
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt16, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [Int32]{
        flattenarray.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt32, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [Int64]{
        //convert int64 to int32
        let flatten32array = flattenarray.map{ Int32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt32, flattenarray.count)
        }
    }
    else if let flattenarray = flattenarray as? [Int]{
        //convert int to int32
        let flatten32array = flattenarray.map{ Int32($0) }
        
        flatten32array.withUnsafeBufferPointer{
            unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_vflt32, flattenarray.count)
        }
    }
    else if var flattenarray = flattenarray as? [Float]{
        let _ = flattenarray.withUnsafeMutableBufferPointer{
            ptrF.assign(from: $0.baseAddress!, count: $0.count)
        }
        
        return UnsafeMutableRawPointer(ptrF)
    }
    else if var flattenarray = flattenarray as? [Double]{
        ptrF.deinitialize(count: flattenarray.count)
        ptrF.deallocate()
        
        let ptrD = create_unsafeMPtrT(type: Double.self, count: flattenarray.count)
        let _ = flattenarray.withUnsafeMutableBufferPointer{
            ptrD.assign(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrD)
    }
    else{
        fatalError("Cannot cast flattenarray")
    }
    
    //create raw pointer
    let ret = UnsafeMutableRawPointer(ptrF)

    //free
    //ptrF.deinitialize(count: flattenarray.count)
    //ptrF.deallocate()
    
    return ret
}

