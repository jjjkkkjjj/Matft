//
//  scalar.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/16.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    public var first: ArrayType?{
        if self.size == 0{
            return nil
        }
        return self.data[0]
    }
    
    public var scalar: ArrayType?{
        return self.size == 1 ? self.data[self.offsetIndex] : nil
    }
    
    /**
    FlatMap function for scalar.
        - Parameters:
            - datatype: MfTypable Type. This must be same as corresponding MfType
        - Important:
            If you want flatten array, use `a.flatten().data as! [T]`
     */
    public func scalarFlatMap<R>(_ body: (ArrayType) throws -> R) rethrows -> [R]{
        var ret: [R] = []
        switch self.storedType {
        case .Float:
            try self.withContiguousDataUnsafeMPtrT(datatype: Float.self){
                ret.append(try body(T.from($0.pointee)))
            }
        case .Double:
            try self.withContiguousDataUnsafeMPtrT(datatype: Double.self){
                ret.append(try body(T.from($0.pointee)))
            }
        }
        
        return ret
    }
}


fileprivate func _T2U2Any<T: BinaryFloatingPoint>(_ value: T, mftype: MfType) -> AnyObject{
    switch mftype {
        case .Int8:
            return Int8(exactly: value) as AnyObject
        case .Int16:
            return Int16(exactly: value) as AnyObject
        case .Int32:
            return Int32(exactly: value) as AnyObject
        case .Int64:
            return Int64(exactly: value) as AnyObject
        case .Int:
            return Int(exactly: value) as AnyObject
        case .UInt8:
            return UInt8(exactly: value) as AnyObject
        case .UInt16:
            return UInt16(exactly: value) as AnyObject
        case .UInt32:
            return UInt32(exactly: value) as AnyObject
        case .UInt64:
            return UInt64(exactly: value) as AnyObject
        case .UInt:
            return UInt(exactly: value) as AnyObject
        case .Float:
            return Float(exactly: value) as AnyObject
        case .Double:
            return Double(exactly: value) as AnyObject
        default:
            fatalError("Unexpected type was detected")
    }
}
