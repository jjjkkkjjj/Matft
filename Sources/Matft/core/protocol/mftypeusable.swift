//
//  type.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/05.
//

import Foundation
import Accelerate

/// The type comformed to this protocol can use MfArray
public protocol MfTypeUsable: Equatable{
    associatedtype StoredType: MfStoredTypeUsable
    
    /// Return zero with this type
    static var zero: Self { get }
    
    /// Convert a given value into this type's one
    /// - Parameter value: The value comformed to MfInterger
    static func from<T: MfInterger>(_ value: T) -> Self
    
    /// Convert a given value into this type's one
    /// - Parameter value: The value comformed to MfFloatingPoint
    static func from<T: MfFloatingPoint>(_ value: T) -> Self
    
    /// Convert a given value into this type's one
    /// - Parameter value: The value comformed to MfBinary
    static func from<T: MfBinary>(_ value: T) -> Self
}

/// The numeric protocol for Matft
public protocol MfNumeric: Numeric, Strideable{}
/// The interger protocol for Matft
public protocol MfInterger: MfNumeric, BinaryInteger{}
/// The floating point protocol for Matft
public protocol MfFloatingPoint: MfNumeric, BinaryFloatingPoint{}
/// The binary (boolean) protocol for Matft
public protocol MfBinary: Equatable{
    /// Return zero with this type
    static var zero: Self { get }
}

/// The signed numeric protocol for Matft
public protocol MfSignedNumeric: SignedNumeric {}

/// The protocol to store raw data as Float type
public protocol StoredFloat: MfTypeUsable{
    associatedtype StoredType = Float
}
/// The protocol to store raw data as Double type
public protocol StoredDouble: MfTypeUsable{
    associatedtype StoredType = Double
}


extension UInt8: MfNumeric, StoredFloat {
    public static func from<T>(_ value: T) -> UInt8 where T : MfInterger {
        return UInt8(value)
    }
    public static func from<T>(_ value: T) -> UInt8 where T : MfFloatingPoint {
        return UInt8(value)
    }
    public static func from<T>(_ value: T) -> UInt8 where T : MfBinary {
        return value != T.zero ? UInt8(1) : UInt8.zero
    }
}
extension UInt16: MfNumeric, StoredFloat {
    public static func from<T>(_ value: T) -> UInt16 where T : MfInterger {
        return UInt16(value)
    }
    public static func from<T>(_ value: T) -> UInt16 where T : MfFloatingPoint {
        return UInt16(value)
    }
    public static func from<T>(_ value: T) -> UInt16 where T : MfBinary {
        return value != T.zero ? UInt16(1) : UInt16.zero
    }
}
extension UInt32: MfNumeric, StoredDouble {
    public static func from<T>(_ value: T) -> UInt32 where T : MfInterger {
        return UInt32(value)
    }
    public static func from<T>(_ value: T) -> UInt32 where T : MfFloatingPoint {
        return UInt32(value)
    }
    public static func from<T>(_ value: T) -> UInt32 where T : MfBinary {
        return value != T.zero ? UInt32(1) : UInt32.zero
    }
}
extension UInt64: MfNumeric, StoredDouble {
    public static func from<T>(_ value: T) -> UInt64 where T : MfInterger {
        return UInt64(value)
    }
    public static func from<T>(_ value: T) -> UInt64 where T : MfFloatingPoint {
        return UInt64(value)
    }
    public static func from<T>(_ value: T) -> UInt64 where T : MfBinary {
        return value != T.zero ? UInt64(1) : UInt64.zero
    }
}
extension UInt: MfNumeric, StoredDouble {
    public static func from<T>(_ value: T) -> UInt where T : MfInterger {
        return UInt(value)
    }
    public static func from<T>(_ value: T) -> UInt where T : MfFloatingPoint {
        return UInt(value)
    }
    public static func from<T>(_ value: T) -> UInt where T : MfBinary {
        return value != T.zero ? UInt(1) : UInt.zero
    }
}

extension Int8: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int8 where T : MfInterger {
        return Int8(value)
    }
    public static func from<T>(_ value: T) -> Int8 where T : MfFloatingPoint {
        return Int8(value)
    }
    public static func from<T>(_ value: T) -> Int8 where T : MfBinary {
        return value != T.zero ? Int8(1) : Int8.zero
    }
}
extension Int16: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int16 where T : MfInterger {
        return Int16(value)
    }
    public static func from<T>(_ value: T) -> Int16 where T : MfFloatingPoint {
        return Int16(value)
    }
    public static func from<T>(_ value: T) -> Int16 where T : MfBinary {
        return value != T.zero ? Int16(1) : Int16.zero
    }
}
extension Int32: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int32 where T : MfInterger {
        return Int32(value)
    }
    public static func from<T>(_ value: T) -> Int32 where T : MfFloatingPoint {
        return Int32(value)
    }
    public static func from<T>(_ value: T) -> Int32 where T : MfBinary {
        return value != T.zero ? Int32(1) : Int32.zero
    }
}

extension Int64: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int64 where T : MfInterger {
        return Int64(value)
    }
    public static func from<T>(_ value: T) -> Int64 where T : MfFloatingPoint {
        return Int64(value)
    }
    public static func from<T>(_ value: T) -> Int64 where T : MfBinary {
        return value != T.zero ? Int64(1) : Int64.zero
    }
}
extension Int: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int where T : MfInterger {
        return Int(value)
    }
    public static func from<T>(_ value: T) -> Int where T : MfFloatingPoint {
        return Int(value)
    }
    public static func from<T>(_ value: T) -> Int where T : MfBinary {
        return value != T.zero ? Int(1) : Int.zero
    }
}


extension Float: MfNumeric, StoredFloat, MfSignedNumeric, MfStoredTypeUsable {
    public static var vDSP_vcmprs_func: vDSP_vcmprs_func<Float> = vDSP_vcmprs
    
    public static var cblas_copy_func: cblas_copy_func<Float> = cblas_scopy
    
    public static func from<T>(_ value: T) -> Float where T : MfInterger {
        return Float(value)
    }
    public static func from<T>(_ value: T) -> Float where T : MfFloatingPoint {
        return Float(value)
    }
    public static func from<T>(_ value: T) -> Float where T : MfBinary {
        return value != T.zero ? Float(1) : Float.zero
    }
}
extension Double: MfNumeric, StoredDouble, MfSignedNumeric, MfStoredTypeUsable {
    public static var vDSP_vcmprs_func: vDSP_vcmprs_func<Double> = vDSP_vcmprsD
    
    public static var cblas_copy_func: cblas_copy_func<Double> = cblas_dcopy
    
    public static func from<T>(_ value: T) -> Double where T : MfInterger {
        return Double(value)
    }
    public static func from<T>(_ value: T) -> Double where T : MfFloatingPoint {
        return Double(value)
    }
    public static func from<T>(_ value: T) -> Double where T : MfBinary {
        return value != T.zero ? Double(1) : Double.zero
    }
}

extension Bool: MfBinary, StoredFloat {
    public static func from<T>(_ value: T) -> Bool where T : MfInterger {
        return value != T.zero
    }
    public static func from<T>(_ value: T) -> Bool where T : MfFloatingPoint {
        return value != T.zero
    }
    public static func from<T>(_ value: T) -> Bool where T : MfBinary {
        return value != T.zero ? true : false
    }
    public static var zero: Bool {
        return false
    }
}
