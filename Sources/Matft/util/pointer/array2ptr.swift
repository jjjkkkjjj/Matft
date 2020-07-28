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
    if var flattenarray = flattenarray as? [UInt8]{
        return (_array2ptrF(&flattenarray, vDSP_func: vDSP_vfltu8, mftypeBool: mftypeBool), .UInt8)
    }
    else if var flattenarray = flattenarray as? [UInt16]{
        return (_array2ptrF(&flattenarray, vDSP_func: vDSP_vfltu16, mftypeBool: mftypeBool), .UInt16)
    }
    else if var flattenarray = flattenarray as? [UInt32]{
        return (_array2ptrF(&flattenarray, vDSP_func: vDSP_vfltu32, mftypeBool: mftypeBool), .UInt32)
    }
    else if let flattenarray = flattenarray as? [UInt64]{
        //convert uint64 to uint32
        var flatten32array = flattenarray.map{ UInt32($0) }
        
        return (_array2ptrF(&flatten32array, vDSP_func: vDSP_vfltu32, mftypeBool: mftypeBool), .UInt64)
    }
    else if let flattenarray = flattenarray as? [UInt]{
        //convert uint to uint32
        //Note that UInt and Int will be handled as uint32 and Int32 respectively
        //Also Int will be handled as int64
        var flatten32array = flattenarray.map{ UInt32($0) }
        
        return (_array2ptrF(&flatten32array, vDSP_func: vDSP_vfltu32, mftypeBool: mftypeBool), .UInt)
    }
    //Int
    else if var flattenarray = flattenarray as? [Int8]{
        return (_array2ptrF(&flattenarray, vDSP_func: vDSP_vflt8, mftypeBool: mftypeBool), .Int8)
    }
    else if var flattenarray = flattenarray as? [Int16]{
        return (_array2ptrF(&flattenarray, vDSP_func: vDSP_vflt16, mftypeBool: mftypeBool), .Int16)
    }
    else if var flattenarray = flattenarray as? [Int32]{
        return (_array2ptrF(&flattenarray, vDSP_func: vDSP_vflt32, mftypeBool: mftypeBool), .Int32)
    }
    else if let flattenarray = flattenarray as? [Int64]{
        //convert int64 to int32
        var flatten32array = flattenarray.map{ Int32($0) }
        
        return (_array2ptrF(&flatten32array, vDSP_func: vDSP_vflt32, mftypeBool: mftypeBool), .Int64)
    }
    else if let flattenarray = flattenarray as? [Int]{
        //convert int to int32
        var flatten32array = flattenarray.map{ Int32($0) }
        
        return (_array2ptrF(&flatten32array, vDSP_func: vDSP_vflt32, mftypeBool: mftypeBool), .Int)
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
        mftype = .Bool
        return (UnsafeMutableRawPointer(ptrF), mftype)
    }
    else if var flattenarray = flattenarray as? [Double]{
        if mftypeBool{
            return (_array2ptrF(&flattenarray, vDSP_func: vDSP_vdpsp, mftypeBool: mftypeBool), .Bool)
        }
        else{
            let ptrD = create_unsafeMPtrT(type: Double.self, count: flattenarray.count)
            let _ = flattenarray.withUnsafeMutableBufferPointer{
                ptrD.assign(from: $0.baseAddress!, count: $0.count)
            }
            mftype = .Double
            
            return (UnsafeMutableRawPointer(ptrD), mftype)
        }
    }
    else{
        fatalError("flattenarray couldn't cast MfTypable.")
    }
}

fileprivate func _Float2Binary(_ ptrF: UnsafeMutableBufferPointer<Float>){
    let size = ptrF.count
    var arrBinary = ptrF.map{ $0 == Float.zero ? Float.zero : Float.num(1) }
    arrBinary.withUnsafeMutableBufferPointer{
        ptrF.baseAddress!.moveAssign(from: $0.baseAddress!, count: size)
    }
}

fileprivate func _array2ptrF<T: MfTypable>(_ flattenarray: inout [T], vDSP_func: vDSP_convert_func<T, Float>, mftypeBool: Bool) -> UnsafeMutableRawPointer{
    let ptrF = create_unsafeMPtrT(type: Float.self, count: flattenarray.count)
    
    // convert into Float
    flattenarray.withUnsafeBufferPointer{
        unsafePtrT2UnsafeMPtrU($0.baseAddress!, ptrF, vDSP_func, flattenarray.count)
    }
    
    if mftypeBool{
        _Float2Binary(UnsafeMutableBufferPointer(start: ptrF, count: flattenarray.count))
    }
    return UnsafeMutableRawPointer(ptrF)
}

