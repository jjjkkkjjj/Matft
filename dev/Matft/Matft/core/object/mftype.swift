//
//  mftype.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public enum MfType: Int{
    case None
    case UInt8
    case UInt16
    case UInt32
    case UInt64
    case UInt
    case Int8
    case Int16
    case Int32
    case Int64
    case Int
    case Float
    case Double
    case Object
    
    static internal func mftype(value: Any) -> MfType{
        switch value{
        case is UInt8:
            return .UInt8
        case is UInt16:
            return .UInt16
        case is UInt32:
            return .UInt32
        case is UInt64:
            return .UInt64
        case is UInt:
            return .UInt
        case is Int8:
            return .Int8
        case is Int16:
            return .Int16
        case is Int32:
            return .Int32
        case is Int64:
            return .Int64
        case is Int:
            return .Int
        case is Float:
            return .Float
        case is Double:
            return .Double
        default:
            return .Object
        }
    }
    
    static public func priority(_ a: MfType, _ b: MfType) -> MfType{
        if a.rawValue < b.rawValue{
            return b
        }
        else{
            return a
        }
    }
    
    static internal func storedType(_ mftype: MfType) -> StoredType{
        switch mftype {
        case .Double:
            return .Double
        default: // all mftypes are stored as float except for double
            return .Float
        }
    }
    
    static public func is32bit() -> Bool{
        return MemoryLayout<Int>.size == MemoryLayout<Int32>.size
    }
    static public func is64bit() -> Bool{
        return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
    }
    //return MemoryLayout<Float>.stride
    
    //static internal func initializer<T: Numeric, U: Numeric>(_ mftype: MfType, value: T) -> U{
        
    //}
}

public enum StoredType: Int{
    case Float
    case Double
    
    static public func priority(_ a: StoredType, _ b: StoredType) -> StoredType{
        if a.rawValue < b.rawValue{
            return b
        }
        else{
            return a
        }
    }
}
