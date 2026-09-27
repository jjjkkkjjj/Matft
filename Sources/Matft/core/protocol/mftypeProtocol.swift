//
//  mftypeProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#else
/// Fallback complex type for non-Apple platforms (split complex format for Float).
/// Mirrors Accelerate's `DSPSplitComplex`.
public struct DSPSplitComplex {
    /// A pointer to the real parts.
    public var realp: UnsafeMutablePointer<Float>
    /// A pointer to the imaginary parts.
    public var imagp: UnsafeMutablePointer<Float>

    /// Creates a split complex pointer pair.
    /// - Parameters:
    ///   - realp: A pointer to the real parts.
    ///   - imagp: A pointer to the imaginary parts.
    public init(realp: UnsafeMutablePointer<Float>, imagp: UnsafeMutablePointer<Float>) {
        self.realp = realp
        self.imagp = imagp
    }
}

/// Fallback complex type for non-Apple platforms (split complex format for Double).
/// Mirrors Accelerate's `DSPDoubleSplitComplex`.
public struct DSPDoubleSplitComplex {
    /// A pointer to the real parts.
    public var realp: UnsafeMutablePointer<Double>
    /// A pointer to the imaginary parts.
    public var imagp: UnsafeMutablePointer<Double>

    /// Creates a split complex pointer pair.
    /// - Parameters:
    ///   - realp: A pointer to the real parts.
    ///   - imagp: A pointer to the imaginary parts.
    public init(realp: UnsafeMutablePointer<Double>, imagp: UnsafeMutablePointer<Double>) {
        self.realp = realp
        self.imagp = imagp
    }
}

/// Fallback complex type for non-Apple platforms (interleaved complex format for Float).
/// Mirrors Accelerate's `DSPComplex`.
public struct DSPComplex {
    /// The real part.
    public var real: Float
    /// The imaginary part.
    public var imag: Float

    /// Creates a complex value.
    /// - Parameters:
    ///   - real: The real part.
    ///   - imag: The imaginary part.
    public init(real: Float, imag: Float) {
        self.real = real
        self.imag = imag
    }
}

/// Fallback complex type for non-Apple platforms (interleaved complex format for Double).
/// Mirrors Accelerate's `DSPDoubleComplex`.
public struct DSPDoubleComplex {
    /// The real part.
    public var real: Double
    /// The imaginary part.
    public var imag: Double

    /// Creates a complex value.
    /// - Parameters:
    ///   - real: The real part.
    ///   - imag: The imaginary part.
    public init(real: Double, imag: Double) {
        self.real = real
        self.imag = imag
    }
}
#endif
/*
public protocol MfTypable: Numeric{}

extension UInt8: MfTypable {}
extension UInt16: MfTypable {}
extension UInt32: MfTypable {}
extension UInt64: MfTypable {}
extension UInt: MfTypable {}

extension Int8: MfTypable {}
extension Int16: MfTypable {}
extension Int32: MfTypable {}
extension Int64: MfTypable {}
extension Int: MfTypable {}

extension Float: MfTypable {}
extension Double: MfTypable {}
*/
/// A Swift scalar type that can be an element of an `MfArray`.
///
/// `Bool`, `UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt`, `Int8`, `Int16`, `Int32`, `Int64`, `Int`,
/// `Float` and `Double` conform to this protocol. Scalars of these types can be used with the arithmetic
/// and comparison operators (e.g. `a + 1`) and with functions such as `item(index:type:)`.
public protocol MfTypable: Equatable{
    /// The zero value (`false` for `Bool`).
    static var zero: Self { get }
    /// Converts an integer value into this type.
    /// - Parameters:
    ///   - value: The value to convert.
    /// - Returns: The converted value. For `Bool`, `value != 0`.
    static func from<T: MfNumeric & BinaryInteger>(_ value: T) -> Self
    /// Converts a floating point value into this type, truncating toward zero for integer types.
    /// - Parameters:
    ///   - value: The value to convert.
    /// - Returns: The converted value. For `Bool`, `value != 0`.
    static func from<T: MfNumeric & BinaryFloatingPoint>(_ value: T) -> Self
    /// Converts a binary (`Bool`) value into this type.
    /// - Parameters:
    ///   - value: The value to convert.
    /// - Returns: 1 if `value` is non-zero (`true`), otherwise 0.
    static func from<T: MfBinary>(_ value: T) -> Self
}

/// A marker for scalar types that are stored as `Float`.
/// - Note: This is an implementation detail of Matft and may change.
public protocol StoredFloat: MfTypable{}
/// A marker for scalar types that are stored as `Double`.
/// - Note: This is an implementation detail of Matft and may change.
public protocol StoredDouble: MfTypable{}

/// A marker for signed scalar types (`Int8` ... `Int`, `Float`, `Double`).
public protocol MfSignedNumeric {}

/// A numeric scalar type that can be an element of an `MfArray` (all integer types, `Float` and `Double`).
public protocol MfNumeric: Numeric, Strideable{}
/// A binary scalar type that can be an element of an `MfArray` (`Bool`).
public protocol MfBinary: Equatable{
    /// The zero value (`false` for `Bool`).
    static var zero: Self { get }
}

extension UInt8: MfNumeric, StoredFloat {
    public static func from<T>(_ value: T) -> UInt8 where T : MfNumeric & BinaryFloatingPoint {
        return UInt8(value)
    }
    public static func from<T>(_ value: T) -> UInt8 where T : MfNumeric & BinaryInteger {
        return UInt8(value)
    }
    public static func from<T>(_ value: T) -> UInt8 where T : MfBinary {
        return value != T.zero ? UInt8(1) : UInt8.zero
    }
}
extension UInt16: MfNumeric, StoredFloat {
    public static func from<T>(_ value: T) -> UInt16 where T : MfNumeric, T : BinaryInteger {
        return UInt16(value)
    }
    public static func from<T>(_ value: T) -> UInt16 where T : MfNumeric, T : BinaryFloatingPoint {
        return UInt16(value)
    }
    public static func from<T>(_ value: T) -> UInt16 where T : MfBinary {
        return value != T.zero ? UInt16(1) : UInt16.zero
    }
}
extension UInt32: MfNumeric, StoredDouble {
    public static func from<T>(_ value: T) -> UInt32 where T : MfNumeric, T : BinaryInteger {
        return UInt32(value)
    }
    public static func from<T>(_ value: T) -> UInt32 where T : MfNumeric, T : BinaryFloatingPoint {
        return UInt32(value)
    }
    public static func from<T>(_ value: T) -> UInt32 where T : MfBinary {
        return value != T.zero ? UInt32(1) : UInt32.zero
    }
}
extension UInt64: MfNumeric, StoredDouble {
    public static func from<T>(_ value: T) -> UInt64 where T : MfNumeric, T : BinaryInteger {
        return UInt64(value)
    }
    public static func from<T>(_ value: T) -> UInt64 where T : MfNumeric, T : BinaryFloatingPoint {
        return UInt64(value)
    }
    public static func from<T>(_ value: T) -> UInt64 where T : MfBinary {
        return value != T.zero ? UInt64(1) : UInt64.zero
    }
}
extension UInt: MfNumeric, StoredDouble {
    public static func from<T>(_ value: T) -> UInt where T : MfNumeric, T : BinaryInteger {
        return UInt(value)
    }
    public static func from<T>(_ value: T) -> UInt where T : MfNumeric, T : BinaryFloatingPoint {
        return UInt(value)
    }
    public static func from<T>(_ value: T) -> UInt where T : MfBinary {
        return value != T.zero ? UInt(1) : UInt.zero
    }
}

extension Int8: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int8 where T : MfNumeric, T : BinaryInteger {
        return Int8(value)
    }
    public static func from<T>(_ value: T) -> Int8 where T : MfNumeric, T : BinaryFloatingPoint {
        return Int8(value)
    }
    public static func from<T>(_ value: T) -> Int8 where T : MfBinary {
        return value != T.zero ? Int8(1) : Int8.zero
    }
}
extension Int16: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int16 where T : MfNumeric, T : BinaryInteger {
        return Int16(value)
    }
    public static func from<T>(_ value: T) -> Int16 where T : MfNumeric, T : BinaryFloatingPoint {
        return Int16(value)
    }
    public static func from<T>(_ value: T) -> Int16 where T : MfBinary {
        return value != T.zero ? Int16(1) : Int16.zero
    }
}
extension Int32: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int32 where T : MfNumeric, T : BinaryInteger {
        return Int32(value)
    }
    public static func from<T>(_ value: T) -> Int32 where T : MfNumeric, T : BinaryFloatingPoint {
        return Int32(value)
    }
    public static func from<T>(_ value: T) -> Int32 where T : MfBinary {
        return value != T.zero ? Int32(1) : Int32.zero
    }
}
extension Int64: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int64 where T : MfNumeric, T : BinaryInteger {
        return Int64(value)
    }
    public static func from<T>(_ value: T) -> Int64 where T : MfNumeric, T : BinaryFloatingPoint {
        return Int64(value)
    }
    public static func from<T>(_ value: T) -> Int64 where T : MfBinary {
        return value != T.zero ? Int64(1) : Int64.zero
    }
}
extension Int: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int where T : MfNumeric, T : BinaryInteger {
        return Int(value)
    }
    public static func from<T>(_ value: T) -> Int where T : MfNumeric, T : BinaryFloatingPoint {
        return Int(value)
    }
    public static func from<T>(_ value: T) -> Int where T : MfBinary {
        return value != T.zero ? Int(1) : Int.zero
    }
}

extension Float: MfNumeric, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Float where T : MfNumeric, T : BinaryInteger {
        return Float(value)
    }
    public static func from<T>(_ value: T) -> Float where T : MfNumeric, T : BinaryFloatingPoint {
        return Float(value)
    }
    public static func from<T>(_ value: T) -> Float where T : MfBinary {
        return value != T.zero ? Float(1) : Float.zero
    }
}
extension Double: MfNumeric, StoredDouble, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Double where T : MfNumeric, T : BinaryInteger {
        return Double(value)
    }
    public static func from<T>(_ value: T) -> Double where T : MfNumeric, T : BinaryFloatingPoint {
        return Double(value)
    }
    public static func from<T>(_ value: T) -> Double where T : MfBinary {
        return value != T.zero ? Double(1) : Double.zero
    }
}

extension Bool: MfBinary, StoredFloat {
    public static func from<T>(_ value: T) -> Bool where T : MfNumeric, T : BinaryInteger {
        return value != T.zero
    }
    public static func from<T>(_ value: T) -> Bool where T : MfNumeric, T : BinaryFloatingPoint {
        return value != T.zero
    }
    public static func from<T>(_ value: T) -> Bool where T : MfBinary {
        return value != T.zero ? true : false
    }
    public static var zero: Bool {
        return false
    }
}

/// A floating point type used to store the elements of an `MfArray` in memory: `Float` or `Double`.
public protocol MfStorable: MfTypable, FloatingPoint{
    /// The vDSP split-complex type for this type (`DSPSplitComplex` or `DSPDoubleSplitComplex`).
    associatedtype vDSPComplexType: vDSP_ComplexTypable
    /// The interleaved complex type for this type (`DSPComplex` or `DSPDoubleComplex`).
    associatedtype blasComplexType: blas_ComplexTypable

    /// Converts an integer into this type.
    /// - Parameters:
    ///   - number: The integer to convert.
    /// - Returns: The converted value.
    static func num(_ number: Int) -> Self
    /// Converts any numeric `MfTypable` value into this type.
    /// - Parameters:
    ///   - value: The value to convert. Integer, `Float` and `Double` values are supported.
    /// - Returns: The converted value.
    /// - Note: `Bool` values are not handled by this conversion and cause a runtime error.
    static func from<T: MfTypable>(_ value: T) -> Self
    /// Parses a string into this type.
    /// - Parameters:
    ///   - str: The string to parse.
    /// - Returns: The parsed value, or `nil` if the string is not a valid number.
    static func from(_ str: String) -> Self?
    /// Parses a substring into this type.
    /// - Parameters:
    ///   - str: The substring to parse.
    /// - Returns: The parsed value, or `nil` if the substring is not a valid number.
    static func from(_ str: String.SubSequence) -> Self?
    /// Converts a value of this type into `Int`, truncating toward zero.
    /// - Parameters:
    ///   - number: The value to convert.
    /// - Returns: The converted integer.
    static func toInt(_ number: Self) -> Int
}

extension Float: MfStorable{
    public typealias vDSPComplexType = DSPSplitComplex
    public typealias blasComplexType = DSPComplex
    
    public static func num(_ number: Int) -> Float {
        return Float(number)
    }
    public static func from<T: MfTypable>(_ value: T) -> Float{
        switch value {
        case is UInt8:
            return Float(value as! UInt8)
        case is UInt16:
            return Float(value as! UInt16)
        case is UInt32:
            return Float(value as! UInt32)
        case is UInt64:
            return Float(value as! UInt64)
        case is UInt:
            return Float(value as! UInt)
        case is Int8:
            return Float(value as! Int8)
        case is Int16:
            return Float(value as! Int16)
        case is Int32:
            return Float(value as! Int32)
        case is Int64:
            return Float(value as! Int64)
        case is Int:
            return Float(value as! Int)
        case is Float:
            return value as! Float
        case is Double:
            return Float(value as! Double)
        case is Bool:
            return (value as! Bool) ? 1 : 0
        default:
            fatalError("cannot convert value to Float")
        }
    }
    public static func from(_ str: String) -> Float?{
        return Float(str)
    }
    public static func from(_ str: String.SubSequence) -> Float?{
        return Float(str)
    }
    public static func toInt(_ number: Float) -> Int {
        return Int(number)
    }
}
extension Double: MfStorable{
    public typealias vDSPComplexType = DSPDoubleSplitComplex
    public typealias blasComplexType = DSPDoubleComplex
    
    public static func num(_ number: Int) -> Double {
        return Double(number)
    }
    public static func from<T: MfTypable>(_ value: T) -> Double{
        switch value {
        case is UInt8:
            return Double(value as! UInt8)
        case is UInt16:
            return Double(value as! UInt16)
        case is UInt32:
            return Double(value as! UInt32)
        case is UInt64:
            return Double(value as! UInt64)
        case is UInt:
            return Double(value as! UInt)
        case is Int8:
            return Double(value as! Int8)
        case is Int16:
            return Double(value as! Int16)
        case is Int32:
            return Double(value as! Int32)
        case is Int64:
            return Double(value as! Int64)
        case is Int:
            return Double(value as! Int)
        case is Float:
            return Double(value as! Float)
        case is Double:
            return value as! Double
        case is Bool:
            return (value as! Bool) ? 1 : 0
        default:
            fatalError("cannot convert value to Double")
        }
    }
    public static func from(_ str: String) -> Double?{
        return Double(str)
    }
    public static func from(_ str: String.SubSequence) -> Double?{
        return Double(str)
    }
    public static func toInt(_ number: Double) -> Int {
        return Int(number)
    }
}

// DSPSplitComplex
/// A vDSP split-complex type (`DSPSplitComplex` or `DSPDoubleSplitComplex`), which holds separate real and imaginary pointers.
/// - Note: This is an implementation detail of Matft and may change.
public protocol vDSP_ComplexTypable{
    /// The scalar type of each part (`Float` or `Double`).
    associatedtype T: MfStorable
    /// The corresponding interleaved complex type.
    associatedtype blasType: blas_ComplexTypable

    /// A pointer to the real parts.
    var realp: UnsafeMutablePointer<T> { get set }
    /// A pointer to the imaginary parts.
    var imagp: UnsafeMutablePointer<T> { get set }

    /// Creates a split-complex pointer pair.
    /// - Parameters:
    ///   - realp: A pointer to the real parts.
    ///   - imagp: A pointer to the imaginary parts.
    init(realp: UnsafeMutablePointer<T>, imagp: UnsafeMutablePointer<T>)
}

extension DSPSplitComplex: vDSP_ComplexTypable{
    public typealias blasType = DSPComplex
}
extension DSPDoubleSplitComplex: vDSP_ComplexTypable{
    public typealias blasType = DSPDoubleComplex
}

// DSPComplex
/// An interleaved complex type (`DSPComplex` or `DSPDoubleComplex`) used with BLAS/LAPACK.
/// - Note: This is an implementation detail of Matft and may change.
public protocol blas_ComplexTypable{
    /// The scalar type of each part (`Float` or `Double`).
    associatedtype T: MfStorable
    /// The corresponding split-complex type.
    associatedtype vDSPType: vDSP_ComplexTypable

    /// The real part.
    var real: T { get set }
    /// The imaginary part.
    var imag: T { get set }
    /// Creates a complex value.
    /// - Parameters:
    ///   - real: The real part.
    ///   - imag: The imaginary part.
    init(real: T, imag: T)
}
extension DSPComplex: blas_ComplexTypable{
    public typealias vDSPType = DSPSplitComplex
}
extension DSPDoubleComplex: blas_ComplexTypable{
    public typealias vDSPType = DSPDoubleSplitComplex
}


/*
extension DSPComplex: MfStorable{
    
    public static func == (lhs: DSPComplex, rhs: DSPComplex) -> Bool {
        return (lhs.real == rhs.real) && (lhs.imag == rhs.imag)
    }

    public static func num(_ number: Int) -> DSPComplex {
        let val = Float(number)
        return DSPComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPComplex where T : MfTypable {
        let val = Float.from(value)
        return DSPComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPComplex where T : MfNumeric, T : BinaryInteger {
        let val = Float.from(value)
        return DSPComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPComplex where T : MfBinary {
        let val = Float.from(value)
        return DSPComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPComplex where T : MfNumeric, T : BinaryFloatingPoint {
        let val = Float.from(value)
        return DSPComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String) -> DSPComplex? {
        guard let val = Float(str) else { return nil }
        return DSPComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String.SubSequence) -> DSPComplex? {
        guard let val = Float(str) else { return nil }
        return DSPComplex(real: val, imag: val)
    }
    
    public static func toInt(_ number: DSPComplex) -> Int {
        return Int(number.real)
    }
    
    public static var zero: DSPComplex {
        return DSPComplex(real: Float.zero, imag: Float.zero)
    }
    
    
}

extension DSPDoubleComplex: MfStorable{
    
    public static func == (lhs: DSPDoubleComplex, rhs: DSPDoubleComplex) -> Bool {
        return (lhs.real == rhs.real) && (lhs.imag == rhs.imag)
    }

    public static func num(_ number: Int) -> DSPDoubleComplex {
        let val = Double(number)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfTypable {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfNumeric, T : BinaryInteger {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfBinary {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfNumeric, T : BinaryFloatingPoint {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String) -> DSPDoubleComplex? {
        guard let val = Double(str) else { return nil }
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String.SubSequence) -> DSPDoubleComplex? {
        guard let val = Double(str) else { return nil }
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func toInt(_ number: DSPDoubleComplex) -> Int {
        return Int(number.real)
    }
    
    public static var zero: DSPDoubleComplex {
        return DSPDoubleComplex(real: Double.zero, imag: Double.zero)
    }
    
    
}


extension DSPSplitComplex: MfStorable{
    
    public static func == (lhs: DSPSplitComplex, rhs: DSPSplitComplex) -> Bool {
        if !((lhs.imagp.count == rhs.realp.count) && (lhs.imagp.count == rhs.imagp.count)){
            return false
        }
        DSPSplitComplex
        return zip(lhs, rhs).allSatisfy{
            $0.0 == $0.1 && $1.0 == $1.1
        }
    }

    public static func num(_ number: Int) -> DSPSplitComplex {
        let val = Float(number)
        return DSPSplitComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPSplitComplex where T : MfTypable {
        let val = Float.from(value)
        return DSPSplitComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPSplitComplex where T : MfNumeric, T : BinaryInteger {
        let val = Float.from(value)
        return DSPSplitComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPSplitComplex where T : MfBinary {
        let val = Float.from(value)
        return DSPSplitComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPSplitComplex where T : MfNumeric, T : BinaryFloatingPoint {
        let val = Float.from(value)
        return DSPSplitComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String) -> DSPSplitComplex? {
        guard let val = Float(str) else { return nil }
        return DSPSplitComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String.SubSequence) -> DSPSplitComplex? {
        guard let val = Float(str) else { return nil }
        return DSPSplitComplex(real: val, imag: val)
    }
    
    public static func toInt(_ number: DSPSplitComplex) -> Int {
        return Int(number.real)
    }
    
    public static var zero: DSPSplitComplex {
        return DSPSplitComplex(real: Float.zero, imag: Float.zero)
    }
    
    
}

extension DSPDoubleComplex: MfStorable{
    
    public static func == (lhs: DSPDoubleComplex, rhs: DSPDoubleComplex) -> Bool {
        return (lhs.real == rhs.real) && (lhs.imag == rhs.imag)
    }

    public static func num(_ number: Int) -> DSPDoubleComplex {
        let val = Double(number)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfTypable {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfNumeric, T : BinaryInteger {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfBinary {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from<T>(_ value: T) -> DSPDoubleComplex where T : MfNumeric, T : BinaryFloatingPoint {
        let val = Double.from(value)
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String) -> DSPDoubleComplex? {
        guard let val = Double(str) else { return nil }
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func from(_ str: String.SubSequence) -> DSPDoubleComplex? {
        guard let val = Double(str) else { return nil }
        return DSPDoubleComplex(real: val, imag: val)
    }
    
    public static func toInt(_ number: DSPDoubleComplex) -> Int {
        return Int(number.real)
    }
    
    public static var zero: DSPDoubleComplex {
        return DSPDoubleComplex(real: Double.zero, imag: Double.zero)
    }
    
    
}
*/
