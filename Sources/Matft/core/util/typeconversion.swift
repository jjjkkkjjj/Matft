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
    // an empty array is an array of every type (`[] is [UInt8]` is true). numpy's default is float64
    if flattenArray.isEmpty{
        return .Double
    }
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
        _wrap_integer_overflow(mfarray, bits: 8, signed: false)
    case .Int8:
        _wrap_integer_overflow(mfarray, bits: 8, signed: true)
    case .UInt16:
        _wrap_integer_overflow(mfarray, bits: 16, signed: false)
    case .Int16:
        _wrap_integer_overflow(mfarray, bits: 16, signed: true)
    default:
        break
    }
    return mfarray
}

/// Convert the values of a newly created integer mfarray like numpy's cast into integers: truncate toward zero and wrap around 8/16 bit integers.
/// Does nothing for the other types
/// - Parameters:
///   - mfarray: The result mfarray
///   - truncate: Whether the values may have a fractional part (false when converted from an integer type)
/// - Returns: The same mfarray
@discardableResult
internal func cast_to_integer(_ mfarray: MfArray, truncate: Bool) -> MfArray{
    switch mfarray.mftype {
    case .UInt8, .UInt16, .UInt32, .UInt64, .UInt, .Int8, .Int16, .Int32, .Int64, .Int:
        break
    default:
        return mfarray
    }
    guard mfarray.isReal, mfarray.storedType == .Float, mfarray.storedSize > 0 else { return mfarray }
    if truncate{
        var count = Int32(mfarray.storedSize)
        mfarray.withUnsafeMutableStartPointer(datatype: Float.self){
            vvintf($0, $0, &count)
        }
    }
    return wrap_integer_overflow(mfarray)
}

/// The scalar version of `cast_to_integer(_:)`: truncate toward zero and wrap around 8/16 bit integers. Returns the value as it is for the other types
internal func cast_to_integer(_ value: Float, mftype: MfType) -> Float{
    let bits: Int, signed: Bool
    switch mftype {
    case .UInt8: (bits, signed) = (8, false)
    case .Int8: (bits, signed) = (8, true)
    case .UInt16: (bits, signed) = (16, false)
    case .Int16: (bits, signed) = (16, true)
    case .UInt32, .UInt64, .UInt, .Int32, .Int64, .Int:
        return value.rounded(.towardZero)
    default:
        return value
    }
    let x = value.rounded(.towardZero)
    let modulus = Float(1 << bits)
    return x - modulus * (x / modulus + (signed ? 0.5 : 0)).rounded(.down)
}

/// Wrap x into the range of the `bits` width integer by x - 2^bits * floor((x + offset) / 2^bits), where offset is 2^(bits-1) for signed and 0 for unsigned.
/// x must be an integer (the results of add, sub, mul and neg of integers), and every step is exact in Float for |x| < 2^24.
/// vDSP's conversion into 8/16 bit integers can't be used, because its result for out of range values is undefined (wrapped on arm64, saturated on x86_64)
fileprivate func _wrap_integer_overflow(_ mfarray: MfArray, bits: Int, signed: Bool){
    let size = mfarray.storedSize
    guard size > 0 else { return }
    var negModulus = -Float(1 << bits)
    var inverse = 1 / Float(1 << bits)
    var offset: Float = signed ? 0.5 : 0 // 2^(bits-1) / 2^bits

    // process by blocks so that the temporary quotients stay in the cache
    let block = 1024
    let quotptr = allocate_unsafeMPtrT(type: Float.self, count: Swift.min(size, block), zeroed: false)
    defer { quotptr.deallocate() }

    mfarray.withUnsafeMutableStartPointer(datatype: Float.self){
        ptrF in
        for start in Swift.stride(from: 0, to: size, by: block){
            let n = Swift.min(block, size - start)
            var count = Int32(n)
            #if canImport(Accelerate)
            let length = vDSP_Length(n)
            #else
            let length = n // the fallbacks in vDSP.swift take Int
            #endif
            // floor(x / 2^bits + offset)
            vDSP_vsmsa(ptrF + start, 1, &inverse, &offset, quotptr, 1, length)
            vvfloorf(quotptr, quotptr, &count)
            // x - 2^bits * that
            vDSP_vsma(quotptr, 1, &negModulus, ptrF + start, 1, ptrF + start, 1, length)
        }
    }
}
