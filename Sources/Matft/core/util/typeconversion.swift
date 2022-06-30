//
//  pointer.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

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
    else{
        fatalError("flattenArray couldn't cast MfTypable.")
    }
}

/**
   - Important: this function allocate new memory, so don't forget deallocate!
*/
internal func array2UnsafeMPtrT<T: MfTypable>(_ array: inout [T]) -> UnsafeMutablePointer<T>{
    let ptr = allocate_unsafeMPtrT(type: T.self, count: array.count)
    array.withUnsafeBufferPointer{
        ptr.assign(from: $0.baseAddress!, count: $0.count)
    }
    return ptr
}

/// convert flattenarray to rawpointer via Float array
/// - Parameters:
///     - flattenArray: An input flatten array
///     - toBool: Whether to be bool or not
/// - Important: this function allocate new memory, so don't forget deallocate!
internal func allocate_UnsafeMRPtrF_from_flattenArray(_ flattenArray: inout [Any], toBool: Bool) -> UnsafeMutableRawPointer{
    
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
        let ptrF = allocate_unsafeMPtrT(type: Float.self, count: flattenArray.count)
        let _ = flattenArray.withUnsafeMutableBufferPointer{
            ptrF.assign(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrF)
    }
    else if let flattenArray = flattenArray as? [Bool]{
        let ptrF = allocate_unsafeMPtrT(type: Float.self, count: flattenArray.count)
        //convert bool to float
        // true = 1, false = 0
        var flattenBoolarray = flattenArray.map{ $0 ? Float.num(1) : Float.zero }
        let _ = flattenBoolarray.withUnsafeMutableBufferPointer{
            ptrF.moveAssign(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrF)
    }
    else if var flattenArray = flattenArray as? [Double]{
        return _array2ptrU(&flattenArray, vDSP_func: vDSP_vdpsp, toBool: toBool)
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
internal func allocate_UnsafeMRPtrD_from_flattenArray(_ flattenArray: inout [Any], toBool: Bool) -> UnsafeMutableRawPointer {
    
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
        let ptrD = allocate_unsafeMPtrT(type: Double.self, count: flattenArray.count)
        //convert bool to float
        // true = 1, false = 0
        var flattenBoolarray = flattenArray.map{ $0 ? Double.num(1) : Double.zero }
        let _ = flattenBoolarray.withUnsafeMutableBufferPointer{
            ptrD.moveAssign(from: $0.baseAddress!, count: $0.count)
        }
        return UnsafeMutableRawPointer(ptrD)
    }
    else if var flattenArray = flattenArray as? [Double]{
        let ptrD = allocate_unsafeMPtrT(type: Double.self, count: flattenArray.count)
        let _ = flattenArray.withUnsafeMutableBufferPointer{
            ptrD.assign(from: $0.baseAddress!, count: $0.count)
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
        ptrU.baseAddress!.moveAssign(from: $0.baseAddress!, count: size)
    }
}

fileprivate func _array2ptrU<T: MfTypable, U: MfStorable>(_ flattenArray: inout [T], vDSP_func: vDSP_convert_func<T, U>, toBool: Bool) -> UnsafeMutableRawPointer{
    let ptrU = allocate_unsafeMPtrT(type: U.self, count: flattenArray.count)
    
    // convert into Float
    flattenArray.withUnsafeBufferPointer{
        wrap_vDSP_convert(flattenArray.count, $0.baseAddress!, 1, ptrU, 1, vDSP_func)
    }
    
    if toBool{
        _U2Binary(UnsafeMutableBufferPointer(start: ptrU, count: flattenArray.count))
    }
    return UnsafeMutableRawPointer(ptrU)
}

