import XCTest
import Matft
import MLX
import MatftMLX

/// The first element address of the MLXArray's backing
private func dataPointer(_ mlx: MLXArray) -> UnsafeRawPointer? {
    return mlx.asData(access: .noCopy).data.withUnsafeBytes{ $0.baseAddress }
}
/// The first element address of the MfArray
private func dataPointer(_ mfarray: MfArray) -> UnsafeRawPointer {
    return mfarray.withUnsafeMutableStartRawPointer{ UnsafeRawPointer($0) }
}

final class MLXToMatftTests: XCTestCase {

    func testFloat32Shares() {
        let mlx = MLXArray([1, 2, 3, 4, 5, 6] as [Float], [2, 3])
        let a = MfArray(mlx: mlx)

        XCTAssertEqual(a.mftype, .Float)
        XCTAssertEqual(a.shape, [2, 3])
        XCTAssertEqual(a, MfArray([[1, 2, 3], [4, 5, 6]], mftype: .Float))

        // memory is shared
        XCTAssertEqual(dataPointer(a), dataPointer(mlx))
        XCTAssertTrue(a.isSharingMemory(with: mlx))
        a[0, 1] = MfArray([10] as [Float])
        XCTAssertEqual(mlx.asArray(Float.self), [1, 10, 3, 4, 5, 6])
    }

    func testFloat32Copy() {
        let mlx = MLXArray([1, 2, 3, 4] as [Float], [2, 2])
        let a = MfArray(mlx: mlx, share: false)

        XCTAssertEqual(a, MfArray([[1, 2], [3, 4]], mftype: .Float))
        XCTAssertNotEqual(dataPointer(a), dataPointer(mlx))
        XCTAssertFalse(a.isSharingMemory(with: mlx))
        a[0, 0] = MfArray([10] as [Float])
        XCTAssertEqual(mlx.asArray(Float.self), [1, 2, 3, 4])
    }

    func testFloat64Shares() {
        Stream.withNewDefaultStream(device: .cpu){
            let mlx = MLXArray([0.1, 0.2, 0.3, 0.4] as [Double], [4]).asType(.float64) * 2
            let a = MfArray(mlx: mlx)

            XCTAssertEqual(a.mftype, .Double)
            XCTAssertEqual(a, MfArray([0.2, 0.4, 0.6, 0.8] as [Double]))
            XCTAssertTrue(a.isSharingMemory(with: mlx))
        }
    }

    func testLazyArrayIsEvaluated() {
        let mlx = MLXArray(0 ..< 6, [2, 3]).asType(.float32) + 1
        let a = MfArray(mlx: mlx)
        XCTAssertEqual(a, MfArray([[1, 2, 3], [4, 5, 6]], mftype: .Float))
    }

    func testOtherDtypesAreCopied() {
        do {
            let mlx = MLXArray([1, -2, 3, -4] as [Int32], [2, 2])
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.mftype, .Int32)
            XCTAssertEqual(a, MfArray([[1, -2], [3, -4]], mftype: .Int32))
        }
        do {
            let mlx = MLXArray([1, -2, 3] as [Int64], [3])
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.mftype, .Int64)
            XCTAssertEqual(a, MfArray([1, -2, 3], mftype: .Int64))
        }
        do {
            let mlx = MLXArray([0, 128, 255] as [UInt8], [3])
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.mftype, .UInt8)
            XCTAssertEqual(a, MfArray([0, 128, 255], mftype: .UInt8))
        }
        do {
            let mlx = MLXArray([true, false, true] as [Bool], [3])
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.mftype, .Bool)
            XCTAssertEqual(a, MfArray([true, false, true]))
        }
        do {
            let mlx = MLXArray([0.5, 1.5, -2] as [Float], [3]).asType(.float16)
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.mftype, .Float)
            XCTAssertEqual(a, MfArray([0.5, 1.5, -2] as [Float]))
        }
        do {
            let mlx = MLXArray([0.5, 1.5, -2] as [Float], [3]).asType(.bfloat16)
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.mftype, .Float)
            XCTAssertEqual(a, MfArray([0.5, 1.5, -2] as [Float]))
        }
    }

    func testNonContiguous() {
        // transposed
        do {
            let mlx = MLXArray([1, 2, 3, 4, 5, 6] as [Float], [2, 3]).T
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a, MfArray([[1, 4], [2, 5], [3, 6]], mftype: .Float))
        }
        // step slice
        do {
            let mlx = MLXArray(0 ..< 10).asType(.float32)[.stride(by: 3)]
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a, MfArray([0, 3, 6, 9], mftype: .Float))
        }
        // negative step slice
        do {
            let mlx = MLXArray(0 ..< 5).asType(.float32)[.stride(by: -1)]
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a, MfArray([4, 3, 2, 1, 0], mftype: .Float))
        }
    }

    func testContiguousSliceShares() {
        let base = MLXArray(0 ..< 12, [3, 4]).asType(.float32)
        let mlx = base[1 ..< 3]
        let a = MfArray(mlx: mlx)
        XCTAssertEqual(a, MfArray([[4, 5, 6, 7], [8, 9, 10, 11]], mftype: .Float))
        XCTAssertTrue(a.isSharingMemory(with: mlx))
    }

    func testComplex64() {
        let mlx = MLXArray([1, 2, 3] as [Float]).asType(.complex64) + MLXArray([-1, 0, 5] as [Float]).asType(.complex64) * MLXArray(real: 0, imaginary: 1)
        XCTAssertEqual(mlx.dtype, .complex64)
        let a = MfArray(mlx: mlx)
        XCTAssertTrue(a.isComplex)
        XCTAssertEqual(a.mftype, .Float)
        XCTAssertEqual(a.real, MfArray([1, 2, 3] as [Float]))
        XCTAssertEqual(a.imag!, MfArray([-1, 0, 5] as [Float]))
    }

    func testLifetime() {
        var a: MfArray? = nil
        var ptr: UnsafeRawPointer? = nil
        do {
            let mlx = MLXArray(0 ..< 1000).asType(.float32) * 2
            a = MfArray(mlx: mlx)
            ptr = dataPointer(mlx)
        }
        // the source MLXArray is released here, but the buffer must be alive
        for _ in 0 ..< 10 {
            _ = MLXArray(0 ..< 1000).asType(.float32) + 3
        }
        XCTAssertEqual(dataPointer(a!), ptr)
        XCTAssertEqual(a!, Matft.arange(start: 0, to: 2000, by: 2, mftype: .Float))
    }

    func testSharedBufferIsNotDonated() {
        // MLX reuses the input buffer for the output when the input is a temporary.
        // The Matft array keeps the buffer alive, so MLX must not overwrite it.
        let values: [Float] = [1, 2, 3, 4, 5, 6, 7, 8]
        let a = MfArray(mlx: MLXArray(values))
        var mlx: MLXArray? = MLXArray(values)
        let b = MfArray(mlx: mlx!)
        XCTAssertTrue(b.isSharingMemory(with: mlx!))
        let c = mlx! + 10
        mlx = nil
        eval(c)
        XCTAssertEqual(c.asArray(Float.self), values.map{ $0 + 10 })
        XCTAssertEqual(a, MfArray(values))
        XCTAssertEqual(b, MfArray(values))
    }

    func testScalarAndEmpty() {
        do {
            let mlx = MLXArray(Float(3.5))
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.shape, [])
            XCTAssertEqual(a.size, 1)
            XCTAssertEqual(a.item(index: 0, type: Float.self), 3.5)
        }
        do {
            let mlx = MLXArray.zeros([0, 3], dtype: .float32)
            let a = MfArray(mlx: mlx)
            XCTAssertEqual(a.shape, [0, 3])
            XCTAssertEqual(a.size, 0)
        }
    }
}

final class MatftToMLXTests: XCTestCase {

    func testFloat32Copy() {
        let a = MfArray([[1, 2, 3], [4, 5, 6]], mftype: .Float)
        let mlx = a.toMLXArray()

        XCTAssertEqual(mlx.dtype, .float32)
        XCTAssertEqual(mlx.shape, [2, 3])
        XCTAssertEqual(mlx.asArray(Float.self), [1, 2, 3, 4, 5, 6])
        XCTAssertFalse(a.isSharingMemory(with: mlx))

        // the default mode never writes into the Matft buffer
        let c = MLXArray(matft: a) + 10
        eval(c)
        XCTAssertEqual(c.asArray(Float.self), [11, 12, 13, 14, 15, 16])
        XCTAssertEqual(a, MfArray([[1, 2, 3], [4, 5, 6]], mftype: .Float))
    }

    func testFloat32Shares() {
        let a = MfArray([[1, 2, 3], [4, 5, 6]], mftype: .Float)
        let mlx = a.toMLXArray(share: true)

        XCTAssertEqual(mlx.asArray(Float.self), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(dataPointer(a), dataPointer(mlx))
        XCTAssertTrue(a.isSharingMemory(with: mlx))

        // the change on Matft side is visible from MLX (CPU and GPU)
        a[1, 2] = MfArray([60] as [Float])
        for device in [Device.cpu, Device.gpu] {
            let sum = Stream.withNewDefaultStream(device: device){ mlx.sum().item(Float.self) }
            XCTAssertEqual(sum, 75)
        }

        let mlx2 = MLXArray(matft: a, share: true)
        XCTAssertTrue(a.isSharingMemory(with: mlx2))
    }

    func testFloat64() {
        let a = MfArray([0.1, 0.2, 0.3] as [Double])
        let mlx = a.toMLXArray(share: true)
        XCTAssertEqual(mlx.dtype, .float64)
        XCTAssertTrue(a.isSharingMemory(with: mlx))
        let sum = Stream.withNewDefaultStream(device: .cpu){ (mlx * 2).sum().item(Double.self) }
        XCTAssertEqual(sum, 1.2, accuracy: 1e-12)
    }

    func testOtherDtypes() {
        do {
            let a = MfArray([[1, -2], [3, -4]], mftype: .Int32)
            let mlx = a.toMLXArray()
            XCTAssertEqual(mlx.dtype, .int32)
            XCTAssertEqual(mlx.asArray(Int32.self), [1, -2, 3, -4])
        }
        do {
            let a = MfArray([1, -2, 3], mftype: .Int64)
            let mlx = a.toMLXArray()
            XCTAssertEqual(mlx.dtype, .int64)
            XCTAssertEqual(mlx.asArray(Int64.self), [1, -2, 3])
        }
        do {
            let a = MfArray([1, -2, 3], mftype: .Int)
            let mlx = a.toMLXArray()
            XCTAssertEqual(mlx.dtype, .int64)
        }
        do {
            let a = MfArray([0, 128, 255], mftype: .UInt8)
            let mlx = MLXArray(matft: a)
            XCTAssertEqual(mlx.dtype, .uint8)
            XCTAssertEqual(mlx.asArray(UInt8.self), [0, 128, 255])
        }
        do {
            let a = MfArray([true, false, true])
            let mlx = a.toMLXArray(share: true) // falls back to copy
            XCTAssertEqual(mlx.dtype, .bool)
            XCTAssertEqual(mlx.asArray(Bool.self), [true, false, true])
            XCTAssertFalse(a.isSharingMemory(with: mlx))
        }
        do {
            let a = MfArray([0.5, 1.5, -2] as [Float])
            let mlx = a.toMLXArray(dtype: .float16)
            XCTAssertEqual(mlx.dtype, .float16)
            XCTAssertEqual(mlx.asArray(Float.self), [0.5, 1.5, -2])
        }
        do {
            let a = MfArray([0.5, 1.5, -2] as [Float])
            let mlx = a.toMLXArray(dtype: .bfloat16)
            XCTAssertEqual(mlx.dtype, .bfloat16)
            XCTAssertEqual(mlx.asArray(Float.self), [0.5, 1.5, -2])
        }
    }

    func testNonContiguousView() {
        let a = Matft.arange(start: 0, to: 12, by: 1, mftype: .Float).reshape([3, 4])
        // transposed
        do {
            let mlx = a.T.toMLXArray(share: true) // falls back to copy
            XCTAssertEqual(mlx.shape, [4, 3])
            XCTAssertEqual(mlx.asArray(Float.self), [0, 4, 8, 1, 5, 9, 2, 6, 10, 3, 7, 11])
            XCTAssertFalse(a.T.isSharingMemory(with: mlx))
        }
        // step slice
        do {
            let mlx = a[0~<, ~<<2].toMLXArray()
            XCTAssertEqual(mlx.shape, [3, 2])
            XCTAssertEqual(mlx.asArray(Float.self), [0, 2, 4, 6, 8, 10])
        }
        // negative step
        do {
            let mlx = a[~<<-1].toMLXArray()
            XCTAssertEqual(mlx.asArray(Float.self), [8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3])
        }
        // contiguous view with offset is shared
        do {
            let v = a[1~<3]
            let mlx = v.toMLXArray(share: true)
            XCTAssertEqual(mlx.asArray(Float.self), [4, 5, 6, 7, 8, 9, 10, 11])
            XCTAssertTrue(v.isSharingMemory(with: mlx))
        }
    }

    func testComplex() {
        let a = MfArray(real: MfArray([1, 2, 3] as [Float]), imag: MfArray([-1, 0, 5] as [Float]))
        let mlx = a.toMLXArray()
        XCTAssertEqual(mlx.dtype, .complex64)
        XCTAssertEqual(mlx.realPart().asArray(Float.self), [1, 2, 3])
        XCTAssertEqual(mlx.imaginaryPart().asArray(Float.self), [-1, 0, 5])

        // complex128 does not exist in MLX, so it is narrowed only when explicitly asked
        let b = MfArray(real: MfArray([1, 2] as [Double]), imag: MfArray([3, 4] as [Double]))
        let mlxb = b.toMLXArray(dtype: .complex64)
        XCTAssertEqual(mlxb.dtype, .complex64)
        XCTAssertEqual(mlxb.realPart().asArray(Float.self), [1, 2])
        XCTAssertEqual(mlxb.imaginaryPart().asArray(Float.self), [3, 4])

        // round trip
        XCTAssertEqual(MfArray(mlx: mlx), a)
    }

    func testLifetime() {
        var mlx: MLXArray? = nil
        do {
            let a = Matft.arange(start: 0, to: 1000, by: 1, mftype: .Float)
            mlx = a.toMLXArray(share: true)
        }
        for _ in 0 ..< 10 {
            _ = Matft.arange(start: 0, to: 1000, by: 1, mftype: .Float) + 3
        }
        XCTAssertEqual(mlx!.sum().item(Float.self), 499500)
    }

    func testRoundTrip() {
        let a = Matft.arange(start: 0, to: 24, by: 1, mftype: .Double).reshape([2, 3, 4])
        let b = MfArray(mlx: a.toMLXArray(share: true))
        XCTAssertEqual(a, b)
        XCTAssertEqual(b.mftype, .Double)
        XCTAssertEqual(dataPointer(a), dataPointer(b))
    }

    func testScalarAndEmpty() {
        do {
            let a = Matft.nums(0, shape: [0, 3], mftype: .Float)
            let mlx = a.toMLXArray()
            XCTAssertEqual(mlx.shape, [0, 3])
            XCTAssertEqual(mlx.dtype, .float32)
        }
        do {
            let a = MfArray(mlx: MLXArray(Float(3.5)))
            let mlx = a.toMLXArray()
            XCTAssertEqual(mlx.shape, [])
            XCTAssertEqual(mlx.item(Float.self), 3.5)
        }
    }
}
