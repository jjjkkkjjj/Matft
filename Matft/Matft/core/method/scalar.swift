//
//  scalar.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/16.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    public var first: Any?{
        if self.size == 0{
            return nil
        }
        let strides = self.strides
        let shape = self.shape
        var flattenIndex = 0
        for axis in 0..<ndim{
            flattenIndex += strides[axis] >= 0 ? 0 : -strides[axis]*shape[axis] + strides[axis]
        }
        
        switch self.storedType {
        case .Float:
            let valueF = self.withDataUnsafeMBPtrT(datatype: Float.self){
                dataptr in
                dataptr[flattenIndex]
            }
            return _T2U2Any(valueF, mftype: self.mftype)
        case .Double:
            let valueD = self.withDataUnsafeMBPtrT(datatype: Double.self){
                dataptr in
                dataptr[flattenIndex]
            }
            return _T2U2Any(valueD, mftype: self.mftype)
        }
    }
    
    public var scalar: Any?{
        return self.size == 1 ? self.first! : nil
    }
    public func scalar<T>(_ type: T.Type) -> T?{
        return self.size == 1 ? self.first! as? T : nil
    }
    
}


fileprivate func _T2U2Any<T: BinaryFloatingPoint>(_ value: T, mftype: MfType) -> Any{
    switch mftype {
        case .Int8:
            return Int8(exactly: value) as Any
        case .Int16:
            return Int16(exactly: value) as Any
        case .Int32:
            return Int32(exactly: value) as Any
        case .Int64:
            return Int64(exactly: value) as Any
        case .Int:
            return Int(exactly: value) as Any
        case .UInt8:
            return UInt8(exactly: value) as Any
        case .UInt16:
            return UInt16(exactly: value) as Any
        case .UInt32:
            return UInt32(exactly: value) as Any
        case .UInt64:
            return UInt64(exactly: value) as Any
        case .UInt:
            return UInt(exactly: value) as Any
        case .Float:
            return Float(exactly: value) as Any
        case .Double:
            return Double(exactly: value) as Any
        default:
            fatalError("Unexpected type was detected")
    }
}
