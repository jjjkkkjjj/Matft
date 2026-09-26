import XCTest
//@testable import Matft
import Matft

/// unique and the set routines. Expected values are the outputs of numpy 2.x
final class SetOpsTests: XCTestCase {
    let nan = Double.nan

    func test_unique() {
        let u = MfArray([[3, 1, 2], [3, 1, 5]])
        XCTAssertEqual(Matft.unique(u), MfArray([1, 2, 3, 5]))
        XCTAssertEqual(Matft.unique_values(u), MfArray([1, 2, 3, 5]))
        XCTAssertEqual(Matft.unique(u).mftype, .Int)

        let all = Matft.unique_all(u)
        XCTAssertEqual(all.values, MfArray([1, 2, 3, 5]))
        XCTAssertEqual(all.indices, MfArray([1, 2, 0, 5]))
        // inverse_indices has the same shape as the input (numpy 2.x)
        XCTAssertEqual(all.inverse_indices, MfArray([[2, 0, 1], [2, 0, 3]]))
        XCTAssertEqual(all.counts, MfArray([2, 1, 2, 1]))
        XCTAssertEqual(all.counts.mftype, .Int)

        let counts = Matft.unique_counts(u)
        XCTAssertEqual(counts.values, MfArray([1, 2, 3, 5]))
        XCTAssertEqual(counts.counts, MfArray([2, 1, 2, 1]))
        let inverse = Matft.unique_inverse(u)
        XCTAssertEqual(inverse.inverse_indices, MfArray([[2, 0, 1], [2, 0, 3]]))
        // values[inverse_indices] reconstructs the input
        XCTAssertEqual(inverse.values[inverse.inverse_indices.flatten()].reshape([2, 3]), u)

        // float and NaN (NaNs are collapsed to one at the end)
        XCTAssertEqual(Matft.unique(MfArray([0.5, -1.25, 0.5, 3.0], mftype: .Double)), MfArray([-1.25, 0.5, 3.0], mftype: .Double))
        let n = Matft.unique_counts(MfArray([2.0, nan, 1.0, nan, 2.0], mftype: .Double))
        XCTAssertEqual(n.values.shape, [3])
        XCTAssertEqual(n.values[0~<2], MfArray([1.0, 2.0], mftype: .Double))
        XCTAssertTrue(n.values.item(index: 2, type: Double.self).isNaN)
        XCTAssertEqual(n.counts, MfArray([1, 2, 2]))
    }

    func test_unique_large() {
        // large input uses the radix sort: negative values, duplicates, -0.0, infinity and NaN
        var values: [Double] = []
        for i in 0..<5000 {
            let sign: Double = i % 3 == 0 ? -0.25 : 1.5
            values.append(Double((i * 7919) % 1237) * sign)
        }
        values += [-0.0, 0.0, Double.infinity, -Double.infinity, -1e300, 1e-300, nan, nan]
        let ret = Matft.unique(MfArray(values, mftype: .Double))
        // -0.0 and 0.0 are the same value
        let nonNaN: [Double] = values.filter{ !$0.isNaN }.map{ $0 == 0 ? 0.0 : $0 }
        let expected: [Double] = Array(Set(nonNaN)).sorted()
        XCTAssertEqual(ret.shape, [expected.count + 1])
        // compare as Swift arrays, because Matft's == can't compare infinity (inf - inf = NaN)
        let actual = ret.data as! [Double]
        XCTAssertEqual(Array(actual[0..<expected.count]), expected)
        XCTAssertTrue(actual[expected.count].isNaN)
    }

    func test_isin() {
        let ret = Matft.isin(MfArray([[1, 2], [3, 4]]), MfArray([2, 4, 7]))
        XCTAssertEqual(ret.mftype, .Bool)
        XCTAssertEqual(ret, MfArray([[false, true], [false, true]]))
        // NaN is not equal to NaN
        XCTAssertEqual(Matft.isin(MfArray([1.0, nan], mftype: .Double), MfArray([nan], mftype: .Double)), MfArray([false, false]))
        XCTAssertEqual(Matft.isin(MfArray([1, 5]), MfArray([1]), invert: true), MfArray([false, true]))
    }

    func test_set_routines() {
        XCTAssertEqual(Matft.intersect1d(MfArray([1, 3, 4, 3]), MfArray([3, 1, 2, 1])), MfArray([1, 3]))
        XCTAssertEqual(Matft.union1d(MfArray([-1, 0, 1]), MfArray([-2, 0, 2])), MfArray([-2, -1, 0, 1, 2]))
        XCTAssertEqual(Matft.setdiff1d(MfArray([1, 2, 3, 2, 4, 1]), MfArray([3, 4, 5, 6])), MfArray([1, 2]))
        // type priority
        XCTAssertEqual(Matft.union1d(MfArray([1, 2]), MfArray([1.5], mftype: .Double)).mftype, .Double)
    }
}
