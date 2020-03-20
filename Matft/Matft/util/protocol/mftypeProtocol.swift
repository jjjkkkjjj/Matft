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

public protocol MfStorable: MfTypable{

    static func num(_ number: Int) -> Self
}

extension Float: MfStorable{
    
    public static func num(_ number: Int) -> Float {
        return Float(number)
    }
}
extension Double: MfStorable{
    
    public static func num(_ number: Int) -> Double {
        return Double(number)
    }
}
