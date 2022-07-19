//
//  mftypeProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate
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
public protocol MfTypable: Equatable{
    static var zero: Self { get }
    static func from<T: MfNumeric & BinaryInteger>(_ value: T) -> Self
    static func from<T: MfNumeric & BinaryFloatingPoint>(_ value: T) -> Self
    static func from<T: MfBinary>(_ value: T) -> Self
}

public protocol StoredFloat: MfTypable{}
public protocol StoredDouble: MfTypable{}

public protocol MfSignedNumeric {}

public protocol MfNumeric: Numeric, Strideable{}
public protocol MfBinary: Equatable{
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

public protocol MfStorable: MfTypable, FloatingPoint{
    associatedtype vDSPType: vDSP_ComplexTypable
    associatedtype blasType: blas_ComplexTypable
    
    static func num(_ number: Int) -> Self
    static func from<T: MfTypable>(_ value: T) -> Self
    static func from(_ str: String) -> Self?
    static func from(_ str: String.SubSequence) -> Self?
    static func toInt(_ number: Self) -> Int
}

extension Float: MfStorable{
    public typealias vDSPType = DSPSplitComplex
    public typealias blasType = DSPComplex
    
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
    public typealias vDSPType = DSPDoubleSplitComplex
    public typealias blasType = DSPDoubleComplex
    
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
public protocol vDSP_ComplexTypable{
    associatedtype T: MfStorable
    associatedtype blasType: blas_ComplexTypable
    
    var realp: UnsafeMutablePointer<T> { get set }
    var imagp: UnsafeMutablePointer<T> { get set }
    
    init(realp: UnsafeMutablePointer<T>, imagp: UnsafeMutablePointer<T>)
}

extension DSPSplitComplex: vDSP_ComplexTypable{
    public typealias blasType = DSPComplex
}
extension DSPDoubleSplitComplex: vDSP_ComplexTypable{
    public typealias blasType = DSPDoubleComplex
}

// DSPComplex
public protocol blas_ComplexTypable{
    associatedtype T: MfStorable
    associatedtype vDSPType: vDSP_ComplexTypable
    
    var real: T { get set }
    var imag: T { get set }
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
