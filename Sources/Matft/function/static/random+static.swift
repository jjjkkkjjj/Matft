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

       Same as `numpy.random.randint`: when `high` is `nil` the range is `[0, low)`.
       - Parameters:
            - low: The lowest value (included).
            - high: (Optional) The upper bound (excluded). If `nil`, the range is `[0, low)`.
            - shape: The shape of the result.
            - mftype: (Optional) An integer type, by default `.Int`.
       - Returns: The array of random integers.
       - Precondition: `mftype` must be an integer type, the range must not be empty, and its values must be representable in `mftype` (e.g. `high` may be 256 for `.UInt8`).
    */
    public static func randint(low: Int, high: Int? = nil, shape: [Int], mftype: MfType = .Int) -> MfArray{
        
        var shape = shape
        let size = shape2size(&shape)

        let l = high == nil ? 0 : low
        let h = high ?? low
        precondition(l < h, "low >= high")

        // draw in Int and convert: the exclusive high may be one beyond the type (e.g. 256 for .UInt8)
        func draw<T: MfTypable & FixedWidthInteger>(_ type: T.Type) -> MfArray{
            precondition(T(exactly: l) != nil && T(exactly: h - 1) != nil, "low and high are out of bounds for \(mftype)")
            let array = (0..<size).map{ _ in T(Int.random(in: l..<h)) }
            return MfArray(array, shape: shape)
        }

        switch mftype {
        case .UInt8:
            return draw(UInt8.self)
        case .UInt16:
            return draw(UInt16.self)
        case .UInt32:
            return draw(UInt32.self)
        case .UInt64:
            return draw(UInt64.self)
        case .UInt:
            return draw(UInt.self)
        case .Int8:
            return draw(Int8.self)
        case .Int16:
            return draw(Int16.self)
        case .Int32:
            return draw(Int32.self)
        case .Int64:
            return draw(Int64.self)
        case .Int:
            return draw(Int.self)
        default:
            preconditionFailure("mftype must be Interger, but got \(mftype)")
        }
    }
}
