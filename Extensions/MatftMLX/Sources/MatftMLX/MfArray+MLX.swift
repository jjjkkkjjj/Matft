//
//  MfArray+MLX.swift
//  MatftMLX
//
//  MLXArray -> MfArray
//

import Foundation
import Accelerate
import Matft
import MLX

/// Keeps a MLXArray alive while a MfArray refers to its backing.
/// Holding the MLXArray also prevents MLX from donating (overwriting in place) the backing to another array.
final class MLXArrayOwner: MfDataBasable {
    let array: MLXArray

    init(_ array: MLXArray) {
        self.array = array
    }
}

extension MfArray {
    /// Create a MfArray from a MLXArray. The MLXArray is evaluated.
    ///
    /// The memory is shared when all of the below are satisfied, otherwise the elements are copied once.
    /// - `share` is true
    /// - The dtype is float32 or float64
    /// - The backing is row contiguous
    ///
    /// - Parameters:
    ///   - mlx: A MLXArray
    ///   - share: Whether to share the memory if possible, by default to true
    /// - Note: The integers, bool, float16 and bfloat16 are held as Float in Matft. complex64 is held as complex Float.
    public convenience init(mlx: MLXArray, share: Bool = true) {
        let shape = mlx.shape
        let size = mlx.size
        let mftype = mlx.dtype.mftype

        if mlx.dtype == .complex64 {
            // interleaved -> separated real / imag
            let mfdata = MfData(size: size, mftype: mftype, complex: true)
            if size > 0 {
                mlx.asData(access: .copy).data.withUnsafeBytes{ buf in
                    mfdata.withUnsafeMutablevDSPComplexPointer(datatype: DSPSplitComplex.self){
                        vDSP_ctoz(buf.bindMemory(to: DSPComplex.self).baseAddress!, 2, $0, 1, vDSP_Length(size))
                    }
                }
            }
            self.init(mfdata: mfdata, mfstructure: MfStructure(shape: shape, mforder: .Row))
            return
        }

        guard size > 0 else {
            self.init(mfdata: MfData(size: 0, mftype: mftype), mfstructure: MfStructure(shape: shape, mforder: .Row))
            return
        }

        // Matft stores all types except for Double as Float
        var source = mlx
        if mlx.dtype != .float32 && mlx.dtype != .float64 {
            source = source.asType(.float32)
        }
        if !source.isBackingRowContiguous {
            source = contiguous(source)
        }
        // A converted array is referred only from here, so sharing it is not observable
        let isPrivate = source !== mlx

        let mfdata: MfData
        if share || isPrivate, let address = source.backingAddress {
            mfdata = MfData(source: MLXArrayOwner(source), data_real_ptr: address, storedSize: size, mftype: mftype, offset: 0)
        }
        else {
            mfdata = source.asData(access: .noCopyIfContiguous).data.withUnsafeBytes{
                MfData(source: nil, data_real_ptr: UnsafeMutableRawPointer(mutating: $0.baseAddress!), storedSize: size, mftype: mftype, offset: 0)
            }
        }
        self.init(mfdata: mfdata, mfstructure: MfStructure(shape: shape, mforder: .Row))
    }
}
