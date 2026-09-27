import XCTest

import Matft

/// Mutation and aliasing of the arithmetic operators, which the generated ArithmeticCoverageTests can't express
final class ArithmeticAliasingTests: XCTestCase {

    /// The operands, including views of a shared base, must be unchanged after the operations
    func testOperandsUnchanged(){
        let base = MfArray([[3, -1, 0, 1], [5, 9, -2, 6], [5, -3, 5, 8]] as [[Double]])
        let before = rowValues(base)
        let v = base[1~<3]
        let t = base.T
        _ = v + t.T[0~<2]
        _ = v - 1
        _ = 2 / v
        _ = -v
        _ = v > t.T[0~<2]
        _ = !v
        _ = Matft.stats.maximum(v, base[0~<1])
        _ = base * base
        XCTAssertEqual(rowValues(base), before)

        let u8 = MfArray([[0, 255], [128, 1]] as [[Int]], mftype: .UInt8)
        _ = u8 + u8.T
        _ = u8 - UInt8(1)
        XCTAssertEqual(rowValues(u8), [0, 255, 128, 1])
    }

    /// `a += b` assigns a new array (documented Matft behavior, unlike numpy's in-place update),
    /// so a view taken before it keeps the old values
    func testCompoundAssignmentIsNotInPlace(){
        var a = MfArray([[3, -1, 0, 1], [5, 9, -2, 6]] as [[Double]])
        let view = a[0~<1]
        a += MfArray([1, 2, 3, 4] as [Double])
        // numpy: a + np.array([1, 2, 3, 4]) -> [[4, 1, 3, 5], [6, 11, 1, 10]]
        XCTAssertClose(a, MfArray([[4, 1, 3, 5], [6, 11, 1, 10]] as [[Double]]), rtol: 0, atol: 0, checkType: true)
        XCTAssertEqual(rowValues(view), [3, -1, 0, 1])

        a -= 1
        a *= 2
        a /= 4
        // numpy: ((a - 1) * 2) / 4 -> [[1.5, 0, 1, 2], [2.5, 5, 0, 4.5]]
        XCTAssertClose(a, MfArray([[1.5, 0, 1, 2], [2.5, 5, 0, 4.5]] as [[Double]]), rtol: 0, atol: 0, checkType: true)

        // the result type follows the operation: UInt8 wraps, Int / Int gives Float
        var u8 = MfArray([250, 5] as [Int], mftype: .UInt8)
        u8 += UInt8(10)
        // numpy: np.array([250, 5], np.uint8) + np.uint8(10) -> [4, 15] (uint8)
        XCTAssertClose(u8, MfArray([4, 15] as [Int], mftype: .UInt8), rtol: 0, atol: 0, checkType: true)
        var i = MfArray([3, -1] as [Int])
        i /= 2
        // numpy: np.array([3, -1]) / 2 -> [1.5, -0.5]
        XCTAssertClose(i, MfArray([1.5, -0.5] as [Double], mftype: .Float), rtol: 0, atol: 0, checkType: true)
    }

    /// The result of an operation on views must be an independent array
    func testResultIsIndependent(){
        let base = MfArray([[1, 2], [3, 4]] as [[Double]])
        let ret = base[0~<1] + 0
        ret[0, 0] = MfArray([100] as [Double])
        XCTAssertEqual(rowValues(base), [1, 2, 3, 4])
        // the result can be used by the next operations
        // numpy: (np.array([[100, 2]]) + np.array([[1, 2], [3, 4]]).T).T -> [[101, 102], [5, 6]]
        XCTAssertClose((ret + base.T).T, MfArray([[101, 102], [5, 6]] as [[Double]]), rtol: 0, atol: 0, checkType: true)
    }
}
