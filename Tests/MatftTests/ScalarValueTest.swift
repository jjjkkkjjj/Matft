import XCTest

import Matft

/// Scalars taken out of an array (`scalar`, `scalarFirst`, `item`) and complex arrays with real scalars
final class ScalarValueTests: XCTestCase {

    func testScalarOfNonFiniteValues(){
        // numpy: np.array([np.nan]).item() -> nan, np.array([np.inf], dtype=np.float32).item() -> inf
        for v in [Double.nan, .infinity, -.infinity, -0.0, 1.5]{
            let d = MfArray([v])
            let f = MfArray([Float(v)])
            let name = "\(v)"
            XCTAssertNotNil(d.scalar(Double.self), name)
            XCTAssertNotNil(f.scalar(Float.self), name)
            XCTAssertNotNil(d.scalar, name)
            XCTAssertNotNil(f.scalarFirst, name)
            if v.isNaN{
                XCTAssertTrue(d.scalar(Double.self)?.isNaN ?? false, name)
                XCTAssertTrue(f.scalar(Float.self)?.isNaN ?? false, name)
                XCTAssertTrue((d.scalar as? Double)?.isNaN ?? false, name)
                XCTAssertTrue((f.scalarFirst as? Float)?.isNaN ?? false, name)
                XCTAssertTrue(d.item(index: 0, type: Double.self).isNaN, name)
                XCTAssertTrue(f.item(indices: [0], type: Float.self).isNaN, name)
            }
            else{
                XCTAssertEqual(d.scalar(Double.self), v, name)
                XCTAssertEqual(f.scalar(Float.self), Float(v), name)
                XCTAssertEqual(d.scalar as? Double, v, name)
                XCTAssertEqual(f.scalarFirst as? Float, Float(v), name)
                XCTAssertEqual(f.item(indices: [0], type: Float.self), Float(v), name)
            }
        }
        // the sign of -0.0 is kept
        XCTAssertEqual(MfArray([-0.0]).scalar(Double.self)?.sign, .minus)
        // reductions giving NaN
        XCTAssertTrue(MfArray([1.0, .nan]).sum().scalar(Double.self)?.isNaN ?? false)
    }

    func testScalarOfIntegers(){
        XCTAssertEqual(MfArray([-5] as [Int]).scalar(Int.self), -5)
        XCTAssertEqual(MfArray([255] as [Int], mftype: .UInt8).scalar(UInt8.self), 255)
        XCTAssertEqual(MfArray([true]).scalar(Bool.self), true)
    }

    #if !os(WASI)
    func testComplexWithRealScalarKeepsType(){
        // numpy (NEP 50): complex64 array + 2.5 -> complex64, complex128 array * 2 -> complex128
        let zf = MfArray(real: MfArray([1, -2, 3] as [Float]), imag: MfArray([0.5, 4, -1] as [Float]))
        let zd = MfArray(real: MfArray([1, -2, 3] as [Double]), imag: MfArray([0.5, 4, -1] as [Double]))

        for (name, r) in [("+ 2.5", zf + 2.5), ("2.5 - z", 2.5 - zf), ("* Double", zf * Double(2)), ("/ 2", zf / 2)]{
            XCTAssertTrue(r.isComplex, name)
            XCTAssertEqual(r.mftype, .Float, name)
        }
        XCTAssertClose((zf + 2.5).real, MfArray([3.5, 0.5, 5.5] as [Float]), rtol: 1e-6, checkType: true)
        XCTAssertClose((zf + 2.5).imag!, MfArray([0.5, 4, -1] as [Float]), rtol: 1e-6, checkType: true)
        XCTAssertClose((2.5 - zf).imag!, MfArray([-0.5, -4, 1] as [Float]), rtol: 1e-6, checkType: true)
        XCTAssertClose((zf / 2).real, MfArray([0.5, -1, 1.5] as [Float]), rtol: 1e-6, checkType: true)

        for (name, r) in [("+ 2", zd + 2), ("* Float", zd * Float(0.5)), ("2 - z", 2 - zd)]{
            XCTAssertTrue(r.isComplex, name)
            XCTAssertEqual(r.mftype, .Double, name)
        }
        XCTAssertClose((zd * Float(0.5)).imag!, MfArray([0.25, 2, -0.5] as [Double]), rtol: 1e-12, checkType: true)
    }
    #endif
}
