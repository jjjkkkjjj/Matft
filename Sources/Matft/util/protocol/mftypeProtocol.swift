//
//  mftypeProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

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

public protocol MfStorable: MfTypable, FloatingPoint{

    static func num(_ number: Int) -> Self
    static func from<T: MfTypable>(_ value: T) -> Self
    static func toInt(_ number: Self) -> Int
}

extension Float: MfStorable{
    
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
    public static func toInt(_ number: Float) -> Int {
        return Int(number)
    }
}
extension Double: MfStorable{
    
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
    public static func toInt(_ number: Double) -> Int {
        return Int(number)
    }
}
