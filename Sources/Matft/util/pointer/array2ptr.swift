//
//  pointer.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate


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

typealias pre_convert_func<T: MfTypable, U: MfTypable> = (_ flattenarray: inout [T]) -> [U]
fileprivate protocol ToRawPtrProtocol{
    associatedtype ArrayType: MfTypable
    associatedtype StoredType: MfStorable
    static var vDSP_func: vDSP_convert_func<ArrayType, StoredType>? { get }
    
    static func convert(_ flattenarray: inout [ArrayType]) -> UnsafeMutableRawPointer
}
extension ToRawPtrProtocol{
    static func convert(_ flattenarray: inout [ArrayType]) -> UnsafeMutableRawPointer{
        if let vDSP_func = Self.vDSP_func{
            let retptr = create_unsafeMPtrT(type: StoredType.self, count: flattenarray.count)
            flattenarray.withUnsafeBufferPointer{
                unsafePtrT2UnsafeMPtrU($0.baseAddress!, retptr, vDSP_func, flattenarray.count)
            }
            return UnsafeMutableRawPointer(retptr)
        }
        else{
            let retptr = create_unsafeMPtrT(type: ArrayType.self, count: flattenarray.count)
            let _ = flattenarray.withUnsafeMutableBufferPointer{
                retptr.assign(from: $0.baseAddress!, count: $0.count)
            }
            return UnsafeMutableRawPointer(retptr)
        }
    }
}

struct ToRawPtr {
    struct u8tf: ToRawPtrProtocol {
        typealias ArrayType = UInt8
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<UInt8, Float>? = vDSP_vfltu8
    }
    struct u16tf: ToRawPtrProtocol {
        typealias ArrayType = UInt16
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<UInt16, Float>? = vDSP_vfltu16
    }
    struct u32tf: ToRawPtrProtocol {
        typealias ArrayType = UInt32
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<UInt32, Float>? = vDSP_vfltu32
    }
    
    struct i8tf: ToRawPtrProtocol {
        typealias ArrayType = Int8
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Int8, Float>? = vDSP_vflt8
    }
    struct i16tf: ToRawPtrProtocol {
        typealias ArrayType = Int16
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Int16, Float>? = vDSP_vflt16
    }
    struct i32tf: ToRawPtrProtocol {
        typealias ArrayType = Int32
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Int32, Float>? = vDSP_vflt32
    }
    struct ftf: ToRawPtrProtocol {
        typealias ArrayType = Float
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Float, Float>? = nil
    }
    struct dtd: ToRawPtrProtocol {
        typealias ArrayType = Double
        typealias StoredType = Double
        static var vDSP_func: vDSP_convert_func<Double, Double>? = nil
    }
}

internal func flattenarray2UnsafeMRPtr_viaForD<T: MfTypable>(_ flattenarray: inout [T]) -> UnsafeMutableRawPointer {
    
    //UInt
    if var flattenarray = flattenarray as? [UInt8]{
        return ToRawPtr.u8tf.convert(&flattenarray)
    }
    else if var flattenarray = flattenarray as? [UInt16]{
        return ToRawPtr.u16tf.convert(&flattenarray)
    }
    else if var flattenarray = flattenarray as? [UInt32]{
        return ToRawPtr.u32tf.convert(&flattenarray)
    }
    else if let flattenarray = flattenarray as? [UInt64]{
        //convert uint64 to uint32
        var flatten32array = flattenarray.map{ UInt32($0) }
        return ToRawPtr.u32tf.convert(&flatten32array)
    }
    else if let flattenarray = flattenarray as? [UInt]{
        //convert uint to uint32
        //Note that UInt and Int will be handled as uint32 and Int32 respectively
        //Also Int will be handled as int64
        var flatten32array = flattenarray.map{ UInt32($0) }
        return ToRawPtr.u32tf.convert(&flatten32array)
    }
    //Int
    else if var flattenarray = flattenarray as? [Int8]{
        return ToRawPtr.i8tf.convert(&flattenarray)
    }
    else if var flattenarray = flattenarray as? [Int16]{
        return ToRawPtr.i16tf.convert(&flattenarray)
    }
    else if var flattenarray = flattenarray as? [Int32]{
        return ToRawPtr.i32tf.convert(&flattenarray)
    }
    else if let flattenarray = flattenarray as? [Int64]{
        //convert int64 to int32
        var flatten32array = flattenarray.map{ Int32($0) }
        return ToRawPtr.i32tf.convert(&flatten32array)
    }
    else if let flattenarray = flattenarray as? [Int]{
        //convert int to int32
        var flatten32array = flattenarray.map{ Int32($0) }
        return ToRawPtr.i32tf.convert(&flatten32array)
    }
    else if var flattenarray = flattenarray as? [Float]{
        return ToRawPtr.ftf.convert(&flattenarray)
    }
    else if let flattenarray = flattenarray as? [Bool]{
        //convert bool to float
        // true = 1, false = 0
        var flattenBoolarray = flattenarray.map{ $0 ? Float.num(1) : Float.zero }
        return ToRawPtr.ftf.convert(&flattenBoolarray)
    }
    else if var flattenarray = flattenarray as? [Double]{
        return ToRawPtr.dtd.convert(&flattenarray)
    }
    else{
        fatalError("flattenarray couldn't cast MfTypable.")
    }
}
