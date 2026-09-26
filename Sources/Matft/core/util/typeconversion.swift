//
//  pointer.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif
// Note: WASI fallback implementations for vDSP functions are defined in vDSP.swift

/// Get mftype from a flatten array
/// - Parameter flattenArray: Flatten array.
/// - Returns: MfType of flatten array
internal func get_mftype(_ flattenArray: inout [Any]) -> MfType{
    if flattenArray is [UInt8]{
        return .UInt8
    }
    else if flattenArray is [UInt16]{
        return .UInt16
    }
    else if flattenArray is [UInt32]{
        return .UInt32
    }
    else if flattenArray is [UInt64]{
        return .UInt64
    }
    else if flattenArray is [UInt]{
        return .UInt
    }
    //Int
    else if flattenArray is [Int8]{
        return .Int8
    }
    else if flattenArray is [Int16]{
        return .Int16
    }
    else if flattenArray is [Int32]{
        return .Int32
    }
    else if flattenArray is [Int64]{
        return .Int64
    }
    else if flattenArray is [Int]{
        return .Int
    }
    else if flattenArray is [Float]{
        return .Float
    }
    else if flattenArray is [Bool]{
        return .Bool
    }
    else if flattenArray is [Double]{
        return .Double
    }
    else if flattenArray is [DSPComplex]{
        return .ComplexFloat
    }
    else if flattenArray is [DSPDoubleComplex]{
        return .ComplexDouble
    }
    else{
        fatalError("flattenArray couldn't cast MfTypable.")
    }
}

/**
   - Important: this function allocate new memory, so don't forget deallocate!
*/
internal func array2UnsafeMPtrT<T: MfTypable>(_ array: inout [T]) -> UnsafeMutablePointer<T>{
    let ptr = allocate_unsafeMPtrT(type: T.self, count: array.count, zeroed: false)
    array.withUnsafeBufferPointer{
        ptr.update(from: $0.baseAddress!, count: $0.count)
    }
    return ptr
}

/// convert flattenarray to rawpointer via Float array
/// - Parameters:
///     - flattenArray: An input flatten array
///     - toBool: Whether to be bool or not
/// - Important: this function allocate new memory, so don't forget deallocate!
internal func allocate_floatdata_from_flattenArray(_ flattenArray: inout [Any], toBool: Bool) -> UnsafeMutableRawPointer{
    
    //UInt
    if var flattenArray = flattenArray as? [UInt8]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vfltu8, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [UInt16]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vfltu16, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [UInt32]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vfltu32, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [UInt64]{
        //convert uint64 to uint32
        var flatten32array = flattenArray.map{ UInt32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vfltu32, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [UInt]{
        //convert uint to uint32
        //Note that UInt and Int will be handled as uint32 and Int32 respectively
        //Also Int will be handled as int64
        var flatten32array = flattenArray.map{ UInt32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vfltu32, toBool: toBool)
    }
    //Int
    else if var flattenArray = flattenArray as? [Int8]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vflt8, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [Int16]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vflt16, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [Int32]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vflt32, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [Int64]{
        //convert int64 to int32
        var flatten32array = flattenArray.map{ Int32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vflt32, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [Int]{
        //convert int to int32
        var flatten32array = flattenArray.map{ Int32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vflt32, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [Float]{
        let ptrF = allocate_unsafeMPtrT(type: Float.self, count: flattenArray.count, zeroed: false)
        let _ = flattenArray.withUnsafeMutableBufferPointer{
            ptrF.update(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrF)
    }
    else if let flattenArray = flattenArray as? [Bool]{
        let ptrF = allocate_unsafeMPtrT(type: Float.self, count: flattenArray.count, zeroed: false)
        //convert bool to float
        // true = 1, false = 0
        var flattenBoolarray = flattenArray.map{ $0 ? Float.num(1) : Float.zero }
        let _ = flattenBoolarray.withUnsafeMutableBufferPointer{
            ptrF.moveUpdate(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrF)
    }
    else if var flattenArray = flattenArray as? [Double]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vdpsp, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [DSPComplex]{
        let ptrF = allocate_unsafeMPtrT(type: Float.self, count: flattenArray.count*2, zeroed: false)
        let _ = flattenArray.withUnsafeBytes{
            ptrF.update(from: $0.bindMemory(to: Float.self).baseAddress!, count: flattenArray.count*2)
        }
        return UnsafeMutableRawPointer(ptrF)
    }
    else if let flattenArray = flattenArray as? [DSPDoubleComplex]{
        let ptrF = allocate_unsafeMPtrT(type: Float.self, count: flattenArray.count*2, zeroed: false)
        
        let _ = flattenArray.withUnsafeBytes{
            wrap_vDSP_convert(flattenArray.count*2, $0.bindMemory(to: Double.self).baseAddress!, 1, ptrF, 1, vDSP_vdpsp)
        }
        return UnsafeMutableRawPointer(ptrF)
    }
    else{
        fatalError("flattenArray couldn't cast MfTypable.")
    }
}


/// convert flattenarray to rawpointer via Double array
/// - Parameters:
///     - flattenArray: An input flatten array
///     - toBool: Whether to be bool or not
/// - Important: this function allocate new memory, so don't forget deallocate!
internal func allocate_doubledata_from_flattenArray(_ flattenArray: inout [Any], toBool: Bool) -> UnsafeMutableRawPointer {
    
    //UInt
    if var flattenArray = flattenArray as? [UInt8]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vfltu8D, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [UInt16]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vfltu16D, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [UInt32]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vfltu32D, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [UInt64]{
        //convert uint64 to uint32
        var flatten32array = flattenArray.map{ UInt32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vfltu32D, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [UInt]{
        //convert uint to uint32
        //Note that UInt and Int will be handled as uint32 and Int32 respectively
        //Also Int will be handled as int64
        var flatten32array = flattenArray.map{ UInt32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vfltu32D, toBool: toBool)
    }
    //Int
    else if var flattenArray = flattenArray as? [Int8]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vflt8D, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [Int16]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vflt16D, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [Int32]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vflt32D, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [Int64]{
        //convert int64 to int32
        var flatten32array = flattenArray.map{ Int32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vflt32D, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [Int]{
        //convert int to int32
        var flatten32array = flattenArray.map{ Int32($0) }
        
        return _array2ptrU(&flatten32array, vDSP_func: vDSP_vflt32D, toBool: toBool)
    }
    else if var flattenArray = flattenArray as? [Float]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vspdp, toBool: toBool)
    }
    else if let flattenArray = flattenArray as? [Bool]{
        let ptrD = allocate_unsafeMPtrT(type: Double.self, count: flattenArray.count, zeroed: false)
        //convert bool to float
        // true = 1, false = 0
        var flattenBoolarray = flattenArray.map{ $0 ? Double.num(1) : Double.zero }
        let _ = flattenBoolarray.withUnsafeMutableBufferPointer{
            ptrD.moveUpdate(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrD)
    }
    else if var flattenArray = flattenArray as? [Double]{
        let ptrD = allocate_unsafeMPtrT(type: Double.self, count: flattenArray.count, zeroed: false)
        let _ = flattenArray.withUnsafeMutableBufferPointer{
            ptrD.update(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrD)
    }
    else if let flattenArray = flattenArray as? [DSPComplex]{
        let ptrD = allocate_unsafeMPtrT(type: Double.self, count: flattenArray.count*2, zeroed: false)
        
        let _ = flattenArray.withUnsafeBytes{
            wrap_vDSP_convert(flattenArray.count*2, $0.bindMemory(to: Float.self).baseAddress!, 1, ptrD, 1, vDSP_vspdp)
        }
        return UnsafeMutableRawPointer(ptrD)
    }
    else if let flattenArray = flattenArray as? [DSPDoubleComplex]{
        let ptrD = allocate_unsafeMPtrT(type: Double.self, count: flattenArray.count*2, zeroed: false)
        let _ = flattenArray.withUnsafeBytes{
            ptrD.update(from: $0.bindMemory(to: Double.self).baseAddress!, count: flattenArray.count*2)
        }
        return UnsafeMutableRawPointer(ptrD)
    }
    else{
        fatalError("flattenArray couldn't cast MfTypable.")
    }
}

fileprivate func _U2Binary<U: MfStorable>(_ ptrU: UnsafeMutableBufferPointer<U>){
    let size = ptrU.count
    var arrBinary = ptrU.map{ $0 == U.zero ? U.zero : U.num(1) }
    arrBinary.withUnsafeMutableBufferPointer{
        ptrU.baseAddress!.moveUpdate(from: $0.baseAddress!, count: size)
    }
}

fileprivate func _array2ptrU<T: MfTypable, U: MfStorable>(_ flattenArray: inout [T], vDSP_func: vDSP_convert_func<T, U>, toBool: Bool) -> UnsafeMutableRawPointer{
    let ptrU = allocate_unsafeMPtrT(type: U.self, count: flattenArray.count, zeroed: false)
    
    // convert into Float
    flattenArray.withUnsafeBufferPointer{
        wrap_vDSP_convert(flattenArray.count, $0.baseAddress!, 1, ptrU, 1, vDSP_func)
    }
    
    if toBool{
        _U2Binary(UnsafeMutableBufferPointer(start: ptrU, count: flattenArray.count))
    }
    return UnsafeMutableRawPointer(ptrU)
}


/// Wrap around the out of range values of 8/16 bit integer mfarray in place like numpy's fixed width integers (e.g. UInt8: -5 -> 251).
/// Call this only on a newly created result. Wider integers are left as they are because Float can't hold their wrapped values exactly
/// - Parameter mfarray: The result mfarray
/// - Returns: The same mfarray
@discardableResult
internal func wrap_integer_overflow(_ mfarray: MfArray) -> MfArray{
    switch mfarray.mftype {
    case .UInt8:
        _wrap_integer_overflow(mfarray, Int8.self, UInt8.self, vDSP_vfixr8, vDSP_vfltu8)
    case .Int8:
        _wrap_integer_overflow(mfarray, Int8.self, Int8.self, vDSP_vfixr8, vDSP_vflt8)
    case .UInt16:
        _wrap_integer_overflow(mfarray, Int16.self, UInt16.self, vDSP_vfixr16, vDSP_vfltu16)
    case .Int16:
        _wrap_integer_overflow(mfarray, Int16.self, Int16.self, vDSP_vfixr16, vDSP_vflt16)
    default:
        break
    }
    return mfarray
}

/// Convert Float into the signed integer T, which wraps around both sides, and read its bits back as U (the same width)
fileprivate func _wrap_integer_overflow<T, U>(_ mfarray: MfArray, _: T.Type, _: U.Type, _ fix_func: vDSP_convert_func<Float, T>, _ flt_func: vDSP_convert_func<U, Float>){
    precondition(MemoryLayout<T>.size == MemoryLayout<U>.size)
    let size = mfarray.storedSize
    let tmpptr = UnsafeMutableRawPointer.allocate(byteCount: size * MemoryLayout<T>.stride, alignment: MemoryLayout<T>.alignment)
    defer { tmpptr.deallocate() }

    mfarray.withUnsafeMutableStartPointer(datatype: Float.self){
        ptrF in
        wrap_vDSP_convert(size, ptrF, 1, tmpptr.bindMemory(to: T.self, capacity: size), 1, fix_func)
        wrap_vDSP_convert(size, tmpptr.bindMemory(to: U.self, capacity: size), 1, ptrF, 1, flt_func)
    }
}
