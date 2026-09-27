//
//  scalar.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/16.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    /// The first element of the array (the element at index `[0, 0, ...]`, like `a.flat[0]` also for views with negative strides) as a Swift scalar.
    ///
    /// The value is boxed into `AnyObject` with the Swift type corresponding to `mftype` (e.g. `Int` for `.Int`, `Float` for `.Float`, `Bool` for `.Bool`).
    /// Only the real part is returned for complex arrays.
    /// - Returns: The first element, or `nil` if the array is empty.
    public var scalarFirst: AnyObject?{
        if self.size == 0{
            return nil
        }
        // the start pointer (offset) points to the first element in the logical order even for negative strides
        let flattenIndex = 0
        
        func _T2U2Any<T: BinaryFloatingPoint>(_ type: T.Type) -> AnyObject{
            let valueT = self.withUnsafeMutableStartPointer(datatype: T.self){
                dataptr in
                dataptr[flattenIndex]
            }
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
                // not `exactly:`, which gives nil for NaN
                case .Float:
                    return Float(valueT) as AnyObject
                case .Double:
                    return Double(valueT) as AnyObject
                case .Bool:
                    return (valueT != 0) as AnyObject
                default:
                    fatalError("Unexpected type was detected")
            }
        }
        
        switch self.storedType {
        case .Float:
            return _T2U2Any(Float.self)
        case .Double:
            return _T2U2Any(Double.self)
        }
    }
    
    /// The single element of a size-1 array as a Swift scalar.
    ///
    /// Similar to `numpy.ndarray.item()` without arguments. See `scalarFirst` for how the value is boxed.
    /// - Returns: The element if `size == 1`, otherwise `nil`.
    public var scalar: AnyObject?{
        return self.size == 1 ? self.scalarFirst! : nil
    }
    /// The single element of a size-1 array as a value of the given Swift type.
    ///
    /// ```swift
    /// let s = MfArray([1, 2, 3] as [Float]).sum().scalar(Float.self)!
    /// ```
    /// - Parameters:
    ///   - type: The Swift type of the element. It must correspond to `mftype` (e.g. `Float.self` for `.Float`).
    /// - Returns: The element if `size == 1`, otherwise `nil`.
    /// - Precondition: `type` must match `mftype`.
    public func scalar<T: MfTypable>(_ type: T.Type) -> T?{
        precondition(MfType.mftype(value: T.zero) == self.mftype, "could not cast \(T.self) from \(self.mftype)")
        return self.size == 1 ? self.scalarFirst! as? T : nil
    }
    
    
    /// Get an element of the array as a Swift scalar by its flat index.
    ///
    /// Equivalent to `numpy.ndarray.item` with an int argument.
    /// - Parameters:
    ///   - index: The index into the flattened (row-major) array.
    ///   - type: The Swift type of the element. It must correspond to `mftype` (e.g. `Int.self` for `.Int`).
    /// - Returns: The element as a value of type `T`. Only the real part is returned for complex arrays.
    /// - Precondition: `type` must match `mftype`.
    public func item<T: MfTypable>(index: Int, type: T.Type) -> T{
        precondition(MfType.mftype(value: T.zero) == self.mftype, "could not cast \(T.self) from \(self.mftype)")

        let index = get_flatten_index(index, shape: self.shape, strides: self.strides)
        
        switch (self.storedType) {
        case .Float:
            let ret = self.withUnsafeMutableStartPointer(datatype: Float.self){
                dataptr in
                dataptr[index]
            }
            return T.from(ret)
        case .Double:
            let ret = self.withUnsafeMutableStartPointer(datatype: Double.self){
                dataptr in
                dataptr[index]
            }
            return T.from(ret)
        }
    }
    
    /// Get an element of the array as a Swift scalar by its multi-dimensional index.
    ///
    /// Equivalent to `numpy.ndarray.item` with a tuple argument.
    /// - Parameters:
    ///   - indices: One index per axis. Its count must equal `ndim`. Negative values count from the end.
    ///   - type: The Swift type of the element. It must correspond to `mftype` (e.g. `Int.self` for `.Int`).
    /// - Returns: The element as a value of type `T`.
    /// - Precondition: `type` must match `mftype`, and `indices.count == ndim`.
    public func item<T: MfTypable>(indices: [Int], type: T.Type) -> T{
        precondition(MfType.mftype(value: T.zero) == self.mftype, "could not cast \(T.self) from \(self.mftype)")
        precondition(indices.count == self.ndim, "incorrect number of indices for array")
        var indices: [Any] = indices
        let ret = self._get_mfarray(indices: &indices)
        return ret.scalar! as! T
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
