//
//  random.swift
//  
//
//  Created by Junnosuke Kado on 2021/07/31.
//

import Foundation

extension Matft.random{
    /**
       Return random values drawn uniformly from `[0, 1)`.

       Equivalent to `numpy.random.rand` (the shape is passed as an array).
       - Parameters:
            - shape: The shape of the result.
            - mftype: (Optional) `.Float` (default) or `.Double`.
       - Returns: The array of random values.
       - Precondition: `mftype` must be `.Float` or `.Double`.
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
       Return random integers drawn uniformly from `[low, high)`.

       Similar to `numpy.random.randint`, but when `high` is `nil` the range is `[low, max)` where `max` is the maximum value of `mftype` (Numpy uses `[0, low)` instead).
       - Parameters:
            - low: The lowest value (included).
            - high: (Optional) The upper bound (excluded). If `nil`, the maximum value of `mftype` is used.
            - shape: The shape of the result.
            - mftype: (Optional) An integer type, by default `.Int`.
       - Returns: The array of random integers.
       - Precondition: `mftype` must be an integer type, and `low` and `high` must be representable in it.
    */
    public static func randint(low: Int, high: Int? = nil, shape: [Int], mftype: MfType = .Int) -> MfArray{
        
        var shape = shape
        let size = shape2size(&shape)
        
        switch mftype {
        case .UInt8:
            let l = UInt8(low)
            let h = high == nil ? UInt8.max : UInt8(high!)
            let array = (0..<size).map{ _ in UInt8.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt16:
            let l = UInt16(low)
            let h = high == nil ? UInt16.max : UInt16(high!)
            let array = (0..<size).map{ _ in UInt16.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt32:
            let l = UInt32(low)
            let h = high == nil ? UInt32.max : UInt32(high!)
            let array = (0..<size).map{ _ in UInt32.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt64:
            let l = UInt64(low)
            let h = high == nil ? UInt64.max : UInt64(high!)
            let array = (0..<size).map{ _ in UInt64.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .UInt:
            let l = UInt(low)
            let h = high == nil ? UInt.max : UInt(high!)
            let array = (0..<size).map{ _ in UInt.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int8:
            let l = Int8(low)
            let h = high == nil ? Int8.max : Int8(high!)
            let array = (0..<size).map{ _ in Int8.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int16:
            let l = Int16(low)
            let h = high == nil ? Int16.max : Int16(high!)
            let array = (0..<size).map{ _ in Int16.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int32:
            let l = Int32(low)
            let h = high == nil ? Int32.max : Int32(high!)
            let array = (0..<size).map{ _ in Int32.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int64:
            let l = Int64(low)
            let h = high == nil ? Int64.max : Int64(high!)
            let array = (0..<size).map{ _ in Int64.random(in: l..<h) }
            return MfArray(array, shape: shape)
        case .Int:
            let l = Int(low)
            let h = high == nil ? Int.max : Int(high!)
            let array = (0..<size).map{ _ in Int.random(in: l..<h) }
            return MfArray(array, shape: shape)
        default:
            preconditionFailure("mftype must be Interger, but got \(mftype)")
        }
    }
}
