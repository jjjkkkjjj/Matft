import XCTest

@testable import Matft

/// Operations whose copies were removed must keep values, types and the operands
final class RedundantCopyTests: XCTestCase {

    func testReshape(){
        let a = Matft.arange(start: 0, to: 12, by: 1, shape: [3, 4])
        XCTAssertEqual(a.reshape([2, 6]), MfArray([[0, 1, 2, 3, 4, 5], [6, 7, 8, 9, 10, 11]]))
        XCTAssertEqual(a.T.reshape([2, 6]), MfArray([[0, 4, 8, 1, 5, 9], [2, 6, 10, 3, 7, 11]]))
        XCTAssertEqual(Matft.reshape(a, newshape: [2, 6], order: .Column), MfArray([[0, 8, 5, 2, 10, 7], [4, 1, 9, 6, 3, 11]]))
        XCTAssertEqual(a[1~<3].reshape([-1]), MfArray([4, 5, 6, 7, 8, 9, 10, 11]))
        XCTAssertEqual(a.astype(.Double).reshape([4, 3]).mftype, .Double)
        XCTAssertEqual((a > 5).reshape([12]).mftype, .Bool)
        // copy: writing into the result does not change the source
        let r = a.reshape([12])
        r[0] = MfArray([100])
        XCTAssertEqual(a[0, 0].scalar(Int.self), 0)

        #if canImport(Accelerate)
        // the imaginary part is kept
        let z = MfArray(real: a, imag: -a)
        let zr = z.reshape([2, 6])
        XCTAssertEqual(zr.real, a.reshape([2, 6]))
        XCTAssertEqual(zr.imag!, (-a).reshape([2, 6]))
        #endif
    }

    // indices given as a view must be read from the view's own elements
    func testFancyIndicesView(){
        let a = Matft.arange(start: 0, to: 10, by: 1) * 10
        let idx = MfArray([9, 1, 2, 7])
        XCTAssertEqual(a[idx[1~<3]], MfArray([10, 20]))
        XCTAssertEqual(a[idx[Matft.reverse]], MfArray([70, 20, 10, 90]))

        let m = Matft.arange(start: 0, to: 12, by: 1, shape: [4, 3])
        XCTAssertEqual(m[idx[1~<3] - 1], MfArray([[0, 1, 2], [3, 4, 5]]))
        XCTAssertEqual(m[MfArray([3, 0]), idx[1~<3]], MfArray([10, 2]))

        let s = Matft.arange(start: 0, to: 10, by: 1)
        s[idx[1~<3]] = MfArray([-1, -2])
        XCTAssertEqual(s, MfArray([0, -1, -2, 3, 4, 5, 6, 7, 8, 9]))
    }

    func testPowerScalarExponent(){
        let x = MfArray([-2, -0.5, 0, 1.5, 3] as [Float])
        XCTAssertEqual(Matft.math.power(bases: x, exponents: 2), MfArray([4, 0.25, 0, 2.25, 9] as [Float]))
        XCTAssertEqual(Matft.math.power(bases: x, exponents: 3), MfArray([-8, -0.125, 0, 3.375, 27] as [Float]))
        XCTAssertEqual(Matft.math.power(bases: x.T, exponents: 1), x)
        XCTAssertEqual(Matft.math.power(bases: MfArray([0, 4, 9] as [Float]), exponents: 0.5), MfArray([0, 2, 3] as [Float]))
        XCTAssertEqual(Matft.math.power(bases: MfArray([1, 2, 4] as [Float]), exponents: -1), MfArray([1, 0.5, 0.25] as [Float]))

        // an integer array with an Int exponent keeps the integer type like numpy
        let i = MfArray([[1, 2], [3, 4]])
        let p = Matft.math.power(bases: i, exponents: 2)
        XCTAssertEqual(p.mftype, .Int)
        XCTAssertEqual(p, MfArray([[1, 4], [9, 16]]))
        XCTAssertEqual(Matft.math.power(bases: i.T, exponents: 2), MfArray([[1, 9], [4, 16]]))
        XCTAssertEqual(Matft.math.power(bases: i[1~<2], exponents: 2), MfArray([[9, 16]]))
        XCTAssertEqual(Matft.math.power(bases: i, exponents: 2.0).mftype, .Float)

        let d = MfArray([1.5, -2] as [Double])
        let pd = Matft.math.power(bases: d, exponents: 2)
        XCTAssertEqual(pd.mftype, .Double)
        XCTAssertEqual(pd, MfArray([2.25, 4] as [Double]))

        let nan = Matft.math.power(bases: MfArray([Float.nan, Float.infinity, -Float.infinity] as [Float]), exponents: 2)
        XCTAssertTrue((nan.data[0] as! Float).isNaN)
        XCTAssertEqual(nan.data[1] as! Float, Float.infinity)
        XCTAssertEqual(nan.data[2] as! Float, Float.infinity)
    }

    // vForce binary ops over layouts
    func testVForceBinaryLayouts(){
        let a = Matft.arange(start: 1, to: 25, by: 1, shape: [2, 3, 4], mftype: .Float)
        let b = Matft.nums(Float(2), shape: [2, 3, 4]) - (a > 12).astype(.Float) // 1 or 2
        let ac = a.to_contiguous(mforder: .Row), bc = b.to_contiguous(mforder: .Row)
        let expected = Matft.math.power(bases: ac, exponents: bc)
        XCTAssertEqual(Matft.math.power(bases: a.T, exponents: b.T), expected.T)
        XCTAssertEqual(Matft.math.power(bases: a.transpose(axes: [1, 0, 2]), exponents: b.transpose(axes: [1, 0, 2])), expected.transpose(axes: [1, 0, 2]))
        XCTAssertEqual(Matft.math.power(bases: a.T, exponents: bc.T.to_contiguous(mforder: .Row)), expected.T)
        XCTAssertEqual(Matft.math.power(bases: a[1~<2], exponents: b[0~<1]), Matft.math.power(bases: ac[1~<2].to_contiguous(mforder: .Row), exponents: bc[0~<1].to_contiguous(mforder: .Row)))
        let e = MfArray([1, 2, 1, 2] as [Float])
        XCTAssertEqual(Matft.math.power(bases: a, exponents: e), Matft.math.power(bases: ac, exponents: e.broadcast_to(shape: [2, 3, 4]).to_contiguous(mforder: .Row)))
        XCTAssertEqual(Matft.math.arctan2(x1: a.T, x2: b.T), Matft.math.arctan2(x1: ac, x2: bc).T)
        // the operands are not modified
        XCTAssertEqual(a, ac)
        XCTAssertEqual(b, bc)
    }

    func testAllEqual(){
        let a = Matft.arange(start: 0, to: 12, by: 1, shape: [3, 4])
        XCTAssertTrue(a == a.T.T)
        XCTAssertTrue(a == a.to_contiguous(mforder: .Column))
        XCTAssertFalse(a == a + 1)
        XCTAssertFalse(a == a.reshape([4, 3]))
        XCTAssertTrue(a[1~<2] == MfArray([[4, 5, 6, 7]]))
        // Int and Bool are exact
        XCTAssertTrue((a > 3) == (a >= 4))
        XCTAssertFalse((a > 3) == (a > 4))
        // integers are compared after the conversion into the type, which wraps around
        XCTAssertTrue(MfArray([-5, 3], mftype: .UInt8) == MfArray([251, 3], mftype: .UInt8))
        XCTAssertFalse(MfArray([250, 3], mftype: .UInt8) == MfArray([5, 3], mftype: .UInt8))
        XCTAssertFalse(MfArray([1, 2]) == MfArray([1, 3]))
        // Float within 1e-5, Double within 1e-10
        let f = MfArray([1, 2] as [Float])
        XCTAssertTrue(f == f + Float(1e-6))
        XCTAssertFalse(f == f + Float(1e-3))
        let d = MfArray([1, 2] as [Double])
        XCTAssertTrue(d == d + 1e-11)
        XCTAssertFalse(d == d + 1e-8)
        // NaN is never equal
        XCTAssertFalse(MfArray([1, Float.nan] as [Float]) == MfArray([1, Float.nan] as [Float]))
        XCTAssertFalse(MfArray([1, Double.nan] as [Double]) == MfArray([1, Double.nan] as [Double]))
        // the same infinities are equal like np.array_equal
        XCTAssertTrue(MfArray([Float.infinity] as [Float]) == MfArray([Float.infinity] as [Float]))
        XCTAssertFalse(MfArray([Float.infinity] as [Float]) == MfArray([-Float.infinity] as [Float]))
        #if canImport(Accelerate)
        let z = MfArray(real: f, imag: f)
        XCTAssertTrue(z == MfArray(real: f, imag: f + Float(1e-6)))
        XCTAssertFalse(z == MfArray(real: f, imag: f + Float(1e-3)))
        XCTAssertFalse(z == MfArray(real: f, imag: -f))
        #endif
    }

    // converting only the type label must not copy, and must not change the operands
    func testMixedTypes(){
        let i = MfArray([[1, 2], [3, 4]])
        let r = i + Float(1.5)
        XCTAssertEqual(r.mftype, .Float)
        XCTAssertEqual(r, MfArray([[2.5, 3.5], [4.5, 5.5]] as [[Float]]))
        XCTAssertEqual(i.mftype, .Int)
        XCTAssertEqual(Float(1.5) - i.T, MfArray([[0.5, -1.5], [-0.5, -2.5]] as [[Float]]))

        let f = MfArray([[0.5, 0.5], [0.5, 0.5]] as [[Float]])
        XCTAssertEqual((i + f).mftype, .Float)
        XCTAssertEqual(i.T * f, MfArray([[0.5, 1.5], [1, 2]] as [[Float]]))
        XCTAssertEqual(i.mftype, .Int)

        let b = i > 2
        XCTAssertEqual((b + i).mftype, .Int)
        XCTAssertEqual(b + i, MfArray([[1, 2], [4, 5]]))
        XCTAssertEqual(b.mftype, .Bool)

        XCTAssertEqual(i.mean(), MfArray([2.5] as [Float]))
        XCTAssertEqual(i.mean(axis: 0), MfArray([2, 3] as [Float]))
        XCTAssertEqual(b.mean(), MfArray([0.5] as [Float]))
        XCTAssertEqual(i.mftype, .Int)

        let s = MfArray([0, 0, 0] as [Float])
        s[MfArray([0, 2])] = MfArray([1, 2])
        XCTAssertEqual(s, MfArray([1, 0, 2] as [Float]))
        XCTAssertEqual(s.mftype, .Float)
    }
}
