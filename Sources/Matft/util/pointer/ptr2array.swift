//
//  ptr2array.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

fileprivate typealias pre_convert_func<T: MfTypable, U: MfTypable> = (_ flattenarray: inout [T]) -> [U]
fileprivate protocol ToArrayProtocol{
    associatedtype ArrayType: MfTypable
    associatedtype StoredType: MfStorable
    static var vDSP_func: vDSP_convert_func<StoredType, ArrayType>? { get }
    
    static func convert(_ ptr: UnsafeMutableRawPointer, size: Int) -> [ArrayType]
}
extension ToArrayProtocol{
    static func convert(_ ptr: UnsafeMutableRawPointer, size: Int) -> [ArrayType]{
        if let vDSP_func = Self.vDSP_func{
            let srcptr = ptr.bindMemory(to: StoredType.self, capacity: size)
            let dstptr = create_unsafeMPtrT(type: ArrayType.self, count: size)
            unsafePtrT2UnsafeMPtrU(srcptr, dstptr, vDSP_func, size)
            let ret = Array(UnsafeMutableBufferPointer(start: dstptr, count: size))
            
            //free
            dstptr.deinitialize(count: size)
            dstptr.deallocate()

            return ret
        }
        else{
            let srcptr = ptr.bindMemory(to: ArrayType.self, capacity: size)
            let ret = Array(UnsafeMutableBufferPointer(start: srcptr, count: size))
            return ret
        }
    }
}

struct ToArray {
    struct ftu8: ToArrayProtocol {
        typealias ArrayType = UInt8
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Float, UInt8>? = vDSP_vfixu8
    }
    struct ftu16: ToArrayProtocol {
        typealias ArrayType = UInt16
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Float, UInt16>? = vDSP_vfixu16
    }
    struct dtu32: ToArrayProtocol {
        typealias ArrayType = UInt32
        typealias StoredType = Double
        static var vDSP_func: vDSP_convert_func<Double, UInt32>? = vDSP_vfixu32D
    }
    
    struct fti8: ToArrayProtocol {
        typealias ArrayType = Int8
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Float, Int8>? = vDSP_vfix8
    }
    struct fti16: ToArrayProtocol {
        typealias ArrayType = Int16
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Float, Int16>? = vDSP_vfix16
    }
    struct fti32: ToArrayProtocol {
        typealias ArrayType = Int32
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Float, Int32>? = vDSP_vfix32
    }
    struct ftf: ToArrayProtocol {
        typealias ArrayType = Float
        typealias StoredType = Float
        static var vDSP_func: vDSP_convert_func<Float, Float>? = nil
    }
    struct dtd: ToArrayProtocol {
        typealias ArrayType = Double
        typealias StoredType = Double
        static var vDSP_func: vDSP_convert_func<Double, Double>? = nil
    }
}


//convert rawpointer to flattenarray via float or Double array
//All kinds of int and uint has been handled as float
internal func unsafeMRBPtr2array_viaForD<T: MfTypable>(_ ptr: UnsafeMutableRawPointer, size: Int) -> [T]{
    
    switch T.self {
    case is UInt8.Type:
        return ToArray.ftu8.convert(ptr, size: size) as! [T]
    case is UInt16.Type:
        return ToArray.ftu16.convert(ptr, size: size) as! [T]
    case is UInt32.Type:
        return ToArray.dtu32.convert(ptr, size: size) as! [T]
    case is UInt64.Type:
        let u32array = ToArray.dtu32.convert(ptr, size: size)
        return u32array.map{ UInt64($0) } as! [T]
    case is UInt.Type:
        let u32array = ToArray.dtu32.convert(ptr, size: size)
        return u32array.map{ UInt($0) } as! [T]
    case is Int8.Type:
        return ToArray.fti8.convert(ptr, size: size) as! [T]
    case is Int16.Type:
        return ToArray.fti16.convert(ptr, size: size) as! [T]
    case is Int32.Type:
        return ToArray.fti32.convert(ptr, size: size) as! [T]
    case is Int64.Type:
        let i32array = ToArray.fti32.convert(ptr, size: size)
        return i32array.map{ Int64($0) } as! [T]
    case is Int.Type:
        let i32array = ToArray.fti32.convert(ptr, size: size)
        return i32array.map{ Int($0) } as! [T]
    case is Float.Type:
        return ToArray.ftf.convert(ptr, size: size) as! [T]
    case is Double.Type:
        return ToArray.dtd.convert(ptr, size: size) as! [T]
    case is Bool.Type:
        let farray = ToArray.ftf.convert(ptr, size: size)
        return farray.map{ $0 != Float.zero } as! [T]
    default:
        fatalError("Unsupported type \(T.self).")
    }
    
}

