//
//  MLXArray+Matft.swift
//  MatftMLX
//
//  MfArray -> MLXArray
//

import Foundation
import Accelerate
import Matft
import MLX

extension MLXArray {
    /// Create a MLXArray from a MfArray with the corresponding dtype.
    ///
    /// The memory is shared when all of the below are satisfied, otherwise the elements are copied once.
    /// - `share` is true
    /// - The mftype is Float or Double (real)
    /// - The MfArray is row contiguous
    ///
    /// - Parameters:
    ///   - matft: A MfArray. complex Double is not supported because MLX has no complex128, use `toMLXArray(dtype: .complex64)` instead.
    ///   - share: Whether to share the memory if possible, by default to false
    /// - Important: In share mode, MLX may write the result of an operation into the shared memory
    ///   when the returned MLXArray is released before the operation is evaluated (buffer donation),
    ///   e.g. `MLXArray(matft: a, share: true) + 1` can overwrite `a`. Use share mode only when that is acceptable.
    public convenience init(matft mfarray: MfArray, share: Bool = false) {
        let buffer = makeRawBuffer(mfarray, share: share)
        self.init(rawPointer: buffer.pointer, mfarray.shape, dtype: buffer.dtype, finalizer: buffer.finalizer)
    }
}

extension MfArray {
    /// Convert into MLXArray. See `MLXArray.init(matft:share:)` for the sharing conditions.
    /// - Parameters:
    ///   - share: Whether to share the memory if possible, by default to false
    ///   - dtype: (Optional) The dtype of the returned MLXArray. The conversion is done by MLX (copy).
    ///     complex Double must be given `.complex64` explicitly because MLX has no complex128.
    /// - Returns: A MLXArray
    public func toMLXArray(share: Bool = false, dtype: DType? = nil) -> MLXArray {
        var mfarray = self
        if self.isComplex && self.storedType == .Double {
            precondition(dtype == .complex64, "MLX does not support complex128. Pass dtype: .complex64 to narrow it explicitly")
            mfarray = MfArray(real: self.real.astype(.Float), imag: self.imag!.astype(.Float))
        }

        let ret = MLXArray(matft: mfarray, share: share)
        if let dtype = dtype, dtype != ret.dtype {
            return ret.asType(dtype)
        }
        return ret
    }
}

/// Make a row contiguous buffer which MLXArray takes over
/// - Parameters:
///   - mfarray: A source MfArray
///   - share: Whether to share the memory if possible
/// - Returns:
///   - pointer: The first element address
///   - dtype: The dtype of the buffer
///   - finalizer: The closure releasing the buffer
fileprivate func makeRawBuffer(_ mfarray: MfArray, share: Bool) -> (pointer: UnsafeMutableRawPointer, dtype: DType, finalizer: () -> Void) {
    let size = mfarray.size

    if mfarray.isComplex {
        precondition(mfarray.storedType == .Float, "MLX does not support complex128. Use toMLXArray(dtype: .complex64) instead")
        // separated real / imag -> interleaved
        let src = mfarray.isRowContiguous ? mfarray : mfarray.to_contiguous(mforder: .Row)
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: Swift.max(size, 1) * MemoryLayout<DSPComplex>.stride, alignment: 16)
        if size > 0 {
            src.withUnsafeMutablevDSPComplexPointer(datatype: DSPSplitComplex.self){
                vDSP_ztoc($0, 1, ptr.assumingMemoryBound(to: DSPComplex.self), 2, vDSP_Length(size))
            }
        }
        return (ptr, .complex64, { ptr.deallocate() })
    }

    let dtype = mfarray.mftype.mlxDType
    switch dtype {
    case .float32, .float64:
        // Float and Double are stored as they are
        let src = share && mfarray.isRowContiguous ? mfarray : mfarray.to_contiguous(mforder: .Row)
        let ptr = src.withUnsafeMutableStartRawPointer{ $0 }
        return (ptr, dtype, { withExtendedLifetime(src){} })
    default:
        // integers and bool are stored as Float
        let src = mfarray.isRowContiguous ? mfarray : mfarray.to_contiguous(mforder: .Row)
        let ptr = src.withUnsafeMutableStartPointer(datatype: Float.self){
            convert(UnsafePointer($0), count: size, to: dtype)
        }
        return (ptr, dtype, { ptr.deallocate() })
    }
}

/// Convert Float elements into a newly allocated buffer of a given integer or bool dtype
fileprivate func convert(_ src: UnsafePointer<Float>, count: Int, to dtype: DType) -> UnsafeMutableRawPointer {
    func cast<T>(_ type: T.Type, _ transform: (Float) -> T) -> UnsafeMutableRawPointer {
        let dst = UnsafeMutablePointer<T>.allocate(capacity: Swift.max(count, 1))
        for i in 0 ..< count {
            dst[i] = transform(src[i])
        }
        return UnsafeMutableRawPointer(dst)
    }

    switch dtype {
    case .bool:
        return cast(Bool.self){ $0 != 0 }
    case .uint8:
        return cast(UInt8.self){ UInt8($0) }
    case .uint16:
        return cast(UInt16.self){ UInt16($0) }
    case .uint32:
        return cast(UInt32.self){ UInt32($0) }
    case .uint64:
        return cast(UInt64.self){ UInt64($0) }
    case .int8:
        return cast(Int8.self){ Int8($0) }
    case .int16:
        return cast(Int16.self){ Int16($0) }
    case .int32:
        return cast(Int32.self){ Int32($0) }
    case .int64:
        return cast(Int64.self){ Int64($0) }
    default:
        preconditionFailure("Unsupported dtype: \(dtype)")
    }
}
