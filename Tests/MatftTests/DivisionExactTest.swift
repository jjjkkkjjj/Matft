import XCTest
import Matft

/// Real division must be correctly rounded, like numpy (IEEE division). The expected values are Swift's own `/`,
/// which is IEEE division and gives the same bits as numpy's `np.divide`.
/// These cover the paths that the literal tests in BugHuntNumericTest don't: arrays longer than one internal chunk,
/// broadcast operands (stride 0), strided / reversed / transposed views and the special values.
final class DivisionExactTest: XCTestCase {

    /// Deterministic values with 0, -0, ±inf, NaN and tiny / huge magnitudes mixed in
    private func values(_ count: Int, seed: UInt64) -> [Double] {
        var state = seed
        let specials: [Double] = [0, -0.0, .infinity, -.infinity, .nan, 1e-30, 3e30, 255, 10, 7.3]
        return (0..<count).map{ i in
            if i % 37 == 0 { return specials[(i / 37) % specials.count] }
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let u = Double(state >> 11) / Double(1 << 53)
            return (u - 0.5) * 2000
        }
    }

    /// `l / r` element-wise by Swift's `/` in `T`, after broadcasting both to `shape`
    private func expected<T: BinaryFloatingPoint>(_ l: MfArray, _ r: MfArray, shape: [Int], _ type: T.Type) -> MfArray {
        let lv = rowValues(Matft.broadcast_to(l, shape: shape)).map{ T($0) }
        let rv = rowValues(Matft.broadcast_to(r, shape: shape)).map{ T($0) }
        let ret = zip(lv, rv).map{ Double($0 / $1) }
        return MfArray(ret, shape: shape).astype(l.mftype)
    }

    private func check(_ mftype: MfType, _ l: MfArray, _ r: MfArray, shape: [Int], _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let exp = mftype == .Float ? expected(l, r, shape: shape, Float.self) : expected(l, r, shape: shape, Double.self)
        XCTAssertClose(l / r, exp, rtol: 0, atol: 0, checkType: true, message, file: file, line: line)
    }

    func testLongContiguous() {
        for mftype in [MfType.Float, .Double] {
            let n = 10_007 // longer than one chunk and not a multiple of it
            let a = MfArray(values(n, seed: 1)).astype(mftype)
            let b = MfArray(values(n, seed: 2)).astype(mftype)
            check(mftype, a, b, shape: [n], "vv \(mftype)")

            let s: Double = 7.3
            let sArr = MfArray([s]).astype(mftype)
            let expVS = mftype == .Float ? expected(a, sArr, shape: [n], Float.self) : expected(a, sArr, shape: [n], Double.self)
            let expSV = mftype == .Float ? expected(sArr, a, shape: [n], Float.self) : expected(sArr, a, shape: [n], Double.self)
            if mftype == .Float {
                XCTAssertClose(a / Float(s), expVS, rtol: 0, atol: 0, checkType: true, "vs Float")
                XCTAssertClose(Float(s) / a, expSV, rtol: 0, atol: 0, checkType: true, "sv Float")
            }
            else {
                XCTAssertClose(a / s, expVS, rtol: 0, atol: 0, checkType: true, "vs Double")
                XCTAssertClose(s / a, expSV, rtol: 0, atol: 0, checkType: true, "sv Double")
            }
        }
    }

    func testLayouts() {
        for mftype in [MfType.Float, .Double] {
            let a = MfArray(values(100 * 103, seed: 3), shape: [100, 103]).astype(mftype)
            let b = MfArray(values(100 * 103, seed: 4), shape: [100, 103]).astype(mftype)
            for (name, x) in layoutVariants(a) {
                check(mftype, x, b, shape: [100, 103], "\(name) / contiguous \(mftype)")
                check(mftype, b, x, shape: [100, 103], "contiguous / \(name) \(mftype)")
                check(mftype, x, x, shape: [100, 103], "\(name) / itself \(mftype)")
            }
            check(mftype, a[~<<-1], b, shape: [100, 103], "reversed rows \(mftype)")
            check(mftype, a[Matft.all, ~<<-2], b[Matft.all, 0~<52], shape: [100, 52], "strided columns \(mftype)")
        }
    }

    func testBroadcast() {
        for mftype in [MfType.Float, .Double] {
            let a = MfArray(values(100 * 103, seed: 5), shape: [100, 103]).astype(mftype)
            let row = MfArray(values(103, seed: 6)).astype(mftype)
            let col = MfArray(values(100, seed: 7), shape: [100, 1]).astype(mftype)
            check(mftype, a, row, shape: [100, 103], "a / row \(mftype)")
            check(mftype, row, a, shape: [100, 103], "row / a \(mftype)")
            check(mftype, a, col, shape: [100, 103], "a / col \(mftype)")
            check(mftype, col, a, shape: [100, 103], "col / a \(mftype)")
            check(mftype, col, row, shape: [100, 103], "col / row \(mftype)")
            check(mftype, a.T, col.T, shape: [103, 100], "a.T / col.T \(mftype)")
        }
    }
}
