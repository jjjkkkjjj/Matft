//
//  scalar.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/16.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    public var scalarFirst: AnyObject?{
        if self.size == 0{
            return nil
        }
        let strides = self.strides
        let shape = self.shape
        var flattenIndex = 0
        for axis in 0..<ndim{
            flattenIndex += strides[axis] >= 0 ? 0 : -strides[axis]*shape[axis] + strides[axis]
        }
        
        func _T2U2Any<T: BinaryFloatingPoint>(_ valueT: T) -> AnyObject{
            
            switch self.mftype {
                case .Int8:
                    return Int8(exactly: valueT) as AnyObject
                case .Int16:
                    return Int16(exactly: valueT) as AnyObject
                case .Int32:
                    return Int32(exactly: valueT) as AnyObject
                case .Int64:
                    return Int64(exactly: valueT) as AnyObject
                case .Int:
                    return Int(exactly: valueT) as AnyObject
                case .UInt8:
                    return UInt8(exactly: valueT) as AnyObject
                case .UInt16:
                    return UInt16(exactly: valueT) as AnyObject
                case .UInt32:
                    return UInt32(exactly: valueT) as AnyObject
                case .UInt64:
                    return UInt64(exactly: valueT) as AnyObject
                case .UInt:
                    return UInt(exactly: valueT) as AnyObject
                case .Float:
                    return Float(exactly: valueT) as AnyObject
                case .Double:
                    return Double(exactly: valueT) as AnyObject
                default:
                    fatalError("Unexpected type was detected")
            }
        }
        
        switch self.storedType {
        case .Bool:
            let valueT = self.withDataUnsafeMBPtrT(datatype: Bool.self){
                dataptr in
                dataptr[flattenIndex]
            }
            return valueT as AnyObject
        case .Float:
            let valueT = self.withDataUnsafeMBPtrT(datatype: Float.self){
                dataptr in
                dataptr[flattenIndex]
            }
            return _T2U2Any(valueT)
        case .Double:
            let valueT = self.withDataUnsafeMBPtrT(datatype: Double.self){
                dataptr in
                dataptr[flattenIndex]
            }
            return _T2U2Any(valueT)
        }
    }
    
    public var scalar: AnyObject?{
        return self.size == 1 ? self.scalarFirst! : nil
    }
    public func scalar<T: MfTypable>(_ type: T.Type) -> T?{
        precondition(MfType.mftype(value: T.zero) == self.mftype, "could not cast \(T.self) from \(self.mftype)")
        return self.size == 1 ? self.scalarFirst! as? T : nil
    }
    
    /**
       Map function for contiguous array.
        - Parameters:
            - datatype: MfTypable Type. This must be same as corresponding MfType
        - Important:
            If you want flatten array, use `a.flatten().data as! [T]`
     */
    /*
    public func scalarFlatMap<T: MfTypable, R>(datatype: T.Type, _ body: (T) throws -> R) rethrows -> R{
        switch self.storedType{
            case .Float:
                try self.withContiguousDataUnsafeMPtrT(datatype: Float.self){
                    return body(T.from($0.pointee))
                }
            case .Double:
                try self.withContiguousDataUnsafeMPtrT(datatype: Double.self){
                    try body(T.from($0.pointee))
                }
        }
        
    }*/
}
