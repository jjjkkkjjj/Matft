//
//  random.swift
//  
//
//  Created by Junnosuke Kado on 2021/07/31.
//

import Foundation

extension Matft.random{
    /**
       Get random mfarray in [0,1)
       - parameters:
            - shape: shape
            - mftype: MfType
    */
    public static func rand(shape: [Int], mftype: MfType = .Float) -> MfArray{
        precondition(mftype == .Float || mftype == .Double, "mftype must be Float or Double, but got \(mftype)")
        
        var shape = shape
        let size = shape2size(&shape)
        switch MfType.storedType(mftype) {
        case .Float:
            let array = (0..<size).map{ _ in Float.random(in: 0..<1) }
            return MfArray(array, shape: shape)
        case .Double:
            let array = (0..<size).map{ _ in Double.random(in: 0..<1) }
            return MfArray(array, shape: shape)
        }
    }
    
    /**
       Get random int mfarray in [low, high), or [0, low) when high is nil like numpy
       - parameters:
            - low: low value
            - high: (optional) high value. When nil, the range is [0, low)
            - shape: shape
            - mftype: MfType
    */
    public static func randint(low: Int, high: Int? = nil, shape: [Int], mftype: MfType = .Int) -> MfArray{
        
        var shape = shape
        let size = shape2size(&shape)
        
        switch mftype {
        case .UInt8:
            let l = UInt8(high == nil ? 0 : low)
            let h = UInt8(high ?? low)
            let array = (0..<size).map{ _ in UInt8.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt16:
            let l = UInt16(high == nil ? 0 : low)
            let h = UInt16(high ?? low)
            let array = (0..<size).map{ _ in UInt16.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt32:
            let l = UInt32(high == nil ? 0 : low)
            let h = UInt32(high ?? low)
            let array = (0..<size).map{ _ in UInt32.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt64:
            let l = UInt64(high == nil ? 0 : low)
            let h = UInt64(high ?? low)
            let array = (0..<size).map{ _ in UInt64.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt:
            let l = UInt(high == nil ? 0 : low)
            let h = UInt(high ?? low)
            let array = (0..<size).map{ _ in UInt.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int8:
            let l = Int8(high == nil ? 0 : low)
            let h = Int8(high ?? low)
            let array = (0..<size).map{ _ in Int8.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int16:
            let l = Int16(high == nil ? 0 : low)
            let h = Int16(high ?? low)
            let array = (0..<size).map{ _ in Int16.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int32:
            let l = Int32(high == nil ? 0 : low)
            let h = Int32(high ?? low)
            let array = (0..<size).map{ _ in Int32.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int64:
            let l = Int64(high == nil ? 0 : low)
            let h = Int64(high ?? low)
            let array = (0..<size).map{ _ in Int64.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int:
            let l = Int(high == nil ? 0 : low)
            let h = Int(high ?? low)
            let array = (0..<size).map{ _ in Int.random(in: l..<h) }
            return MfArray(array, shape: shape)
        default:
            preconditionFailure("mftype must be Interger, but got \(mftype)")
        }
    }
}
