//
//  protocol.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public protocol MfNumeric: ExpressibleByIntegerLiteral, Numeric {
    static func + (left: Self, right: Self) -> Self
    static func - (left: Self, right: Self) -> Self
    static func * (left: Self, right: Self) -> Self
    static func / (left: Self, right: Self) -> Self
    
    static func += (left: inout Self, right: Self)
    static func -= (left: inout Self, right: Self)
    static func *= (left: inout Self, right: Self)
    static func /= (left: inout Self, right: Self)
    
    static func zero() -> Self
    static func one() -> Self
    
    static func num(_ value: Self) -> Double
    static func num(_ value: Double) -> Self
}

public protocol MfInt {
    static func % (left: Self, right: Self) -> Self
}

extension Int: MfNumeric, MfInt {
    public static func zero() -> Int {
        return 0
    }
    public static func one() -> Int {
        return 1
    }
    public static func num(_ value: Int) -> Double {
        return Double(value)
    }
    public static func num(_ value: Double) -> Int {
        return Int(value)
    }
}
/*
extension UInt: MfNumeric, MfInt {
    public static func zero() -> UInt {
        return 0
    }
    public static func one() -> UInt {
        return 1
    }
    
}*/
extension Float: MfNumeric {
    public static func zero() -> Float {
        return 0
    }
    public static func one() -> Float {
        return 1
    }
    public static func num(_ value: Float) -> Double {
        return Double(value)
    }
    public static func num(_ value: Double) -> Float {
        return Float(value)
    }
}
extension Double: MfNumeric {
    public static func zero() -> Double {
        return 0
    }
    public static func one() -> Double {
        return 1
    }
    public static func num(_ value: Double) -> Double {
        return value
    }
}


