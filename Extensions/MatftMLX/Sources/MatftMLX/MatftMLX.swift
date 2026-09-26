//
//  MatftMLX.swift
//  MatftMLX
//
//  Conversion between Matft's MfArray and MLX's MLXArray.
//
//  - float32 / float64 contiguous arrays can share their memory (zero-copy).
//  - The other types (integers, bool, float16, bfloat16, complex) are always copied, because Matft stores
//    every type except for Double as Float, and stores complex numbers as the separated real / imag buffers.
//

import Foundation
import Accelerate
import Matft
import MLX

// MARK: - dtype mapping

extension MfType {
    /// The MLX dtype holding this type without loss
    var mlxDType: DType {
        switch self {
        case .Bool:
            return .bool
        case .UInt8:
            return .uint8
        case .UInt16:
            return .uint16
        case .UInt32:
            return .uint32
        case .UInt64, .UInt:
            return .uint64
        case .Int8:
            return .int8
        case .Int16:
            return .int16
        case .Int32:
            return .int32
        case .Int64, .Int:
            return .int64
        case .Float:
            return .float32
        case .Double:
            return .float64
        case .ComplexFloat:
            return .complex64
        case .ComplexDouble, .None, .Object:
            preconditionFailure("\(self) cannot be converted into MLXArray")
        }
    }
}

extension DType {
    /// The MfType holding this dtype. float16 and bfloat16 are held as Float
    var mftype: MfType {
        switch self {
        case .bool:
            return .Bool
        case .uint8:
            return .UInt8
        case .uint16:
            return .UInt16
        case .uint32:
            return .UInt32
        case .uint64:
            return .UInt64
        case .int8:
            return .Int8
        case .int16:
            return .Int16
        case .int32:
            return .Int32
        case .int64:
            return .Int64
        case .float16, .bfloat16, .float32, .complex64:
            return .Float
        case .float64:
            return .Double
        }
    }
}

// MARK: - memory helpers

/// Row major strides of a given shape
func rowMajorStrides(_ shape: [Int]) -> [Int] {
    var strides = Array(repeating: 1, count: shape.count)
    var s = 1
    for i in stride(from: shape.count - 1, through: 0, by: -1) {
        strides[i] = s
        s *= shape[i]
    }
    return strides
}

/// Whether the elements are laid out in row major order without gaps. Axes of length 1 are ignored like Numpy
func isRowContiguous(shape: [Int], strides: [Int]) -> Bool {
    var expected = 1
    for i in stride(from: shape.count - 1, through: 0, by: -1) where shape[i] != 1 {
        if strides[i] != expected {
            return false
        }
        expected *= shape[i]
    }
    return true
}

/// `Data(bytesNoCopy:)` copies a small buffer into its inline storage,
/// so the address given by `MLXArray.asData(access: .noCopy)` is the backing address only when this returns true
func dataKeepsAddress(byteCount: Int) -> Bool {
    guard byteCount > 0 else { return false }
    let ptr = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 16)
    defer { ptr.deallocate() }
    return Data(bytesNoCopy: ptr, count: byteCount, deallocator: .none).withUnsafeBytes{ $0.baseAddress == UnsafeRawPointer(ptr) }
}

extension MLXArray {
    /// The address of the first element of the evaluated backing. nil if the address cannot be obtained
    var backingAddress: UnsafeMutableRawPointer? {
        let data = self.asData(access: .noCopy)
        guard dataKeepsAddress(byteCount: data.data.count) else { return nil }
        return data.data.withUnsafeBytes{ $0.baseAddress.map{ UnsafeMutableRawPointer(mutating: $0) } }
    }

    /// Whether the evaluated backing is laid out in row major order without gaps
    var isBackingRowContiguous: Bool {
        return isRowContiguous(shape: self.shape, strides: self.asData(access: .noCopy).strides)
    }
}

extension MfArray {
    /// Whether the elements are laid out in row major order without gaps
    var isRowContiguous: Bool {
        return MatftMLX.isRowContiguous(shape: self.shape, strides: self.strides)
    }

    /// Whether this MfArray and a given MLXArray refer to the same memory.
    /// - Note: Always false for tiny arrays (a few bytes) whose backing address MLX does not expose.
    public func isSharingMemory(with mlx: MLXArray) -> Bool {
        guard self.size > 0, self.isRowContiguous, self.shape == mlx.shape, mlx.isBackingRowContiguous, let address = mlx.backingAddress else {
            return false
        }
        return self.withUnsafeMutableStartRawPointer{ $0 == address }
    }
}
