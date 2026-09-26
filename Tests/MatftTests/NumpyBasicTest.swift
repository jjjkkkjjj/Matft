import XCTest
//@testable import Matft
import Matft

final class NumpyBasicTests: XCTestCase {
    func testScalarFirst(){
        // numpy: np.array([True]).item() -> True
        XCTAssertEqual(MfArray([true]).scalar as? Bool, true)
        XCTAssertEqual(MfArray([false, true]).scalarFirst as? Bool, false)
        // the first element in the logical order like a.flat[0]
        let a = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])
        // numpy: a[::-1].flat[0] -> 3, a[:, ::-1].flat[0] -> 2, a[1:].flat[0] -> 3, a.T[::-1].flat[0] -> 2
        XCTAssertEqual(a[Matft.reverse].scalarFirst as? Int, 3)
        XCTAssertEqual(a[Matft.all, Matft.reverse].scalarFirst as? Int, 2)
        XCTAssertEqual(a[1~<].scalarFirst as? Int, 3)
        XCTAssertEqual(a.T[Matft.reverse].scalarFirst as? Int, 2)
        XCTAssertEqual(MfArray([false, true])[Matft.reverse].scalarFirst as? Bool, true)
    }


    func test_var_std() {
        let a = MfArray([[1.0, 2.0, 4.0],
                         [3.0, -1.0, 7.0]], mftype: .Double)

        XCTAssertEqual(Matft.stats.var(a), MfArray([6.222222222222222], mftype: .Double))
        XCTAssertEqual(Matft.stats.var(a, axis: 0), MfArray([1.0, 2.25, 2.25], mftype: .Double))
        XCTAssertEqual(Matft.stats.var(a, axis: 1), MfArray([1.5555555555555554, 10.666666666666666], mftype: .Double))
        XCTAssertEqual(Matft.stats.var(a, axis: 1, ddof: 1), MfArray([2.333333333333333, 16.0], mftype: .Double))
        XCTAssertEqual(Matft.stats.var(a, axis: 0, keepDims: true), MfArray([[1.0, 2.25, 2.25]], mftype: .Double))

        XCTAssertEqual(Matft.stats.std(a), MfArray([2.494438257849294], mftype: .Double))
        XCTAssertEqual(Matft.stats.std(a, axis: 0), MfArray([1.0, 1.5, 1.5], mftype: .Double))
        XCTAssertEqual(Matft.stats.std(a, axis: -1, ddof: 1), MfArray([1.5275252316519465, 4.0], mftype: .Double))

        // method
        XCTAssertEqual(a.var(axis: 0), MfArray([1.0, 2.25, 2.25], mftype: .Double))
        XCTAssertEqual(a.std(axis: 0), MfArray([1.0, 1.5, 1.5], mftype: .Double))

        // Int input and non-contiguous input
        let b = MfArray([[[0, 1, 4, 2], [2, 4, 1, 0], [1, 4, 2, 2]],
                         [[4, 1, 0, 1], [4, 2, 2, 4], [1, 0, 1, 4]]])
        XCTAssertEqual(Matft.stats.var(b, axis: 1), MfArray([[0.6666666666666666, 2.0, 1.5555555555555556, 0.888888888888889],
                                                             [2.0, 0.6666666666666666, 0.6666666666666666, 2.0]], mftype: .Float))
        XCTAssertEqual(Matft.stats.var(b.transpose(axes: [2, 0, 1]), axis: 0), MfArray([[2.1875, 2.1875, 1.1875],
                                                                                        [2.25, 1.0, 2.25]], mftype: .Float))
    }

    func test_diff() {
        let x = MfArray([1, 2, 4, 7, 0])
        XCTAssertEqual(Matft.diff(x), MfArray([1, 2, 3, -7]))
        XCTAssertEqual(Matft.diff(x, n: 2), MfArray([1, 1, -10]))

        let m = MfArray([[1, 3, 6, 10],
                         [0, 5, 6, 8]])
        XCTAssertEqual(Matft.diff(m), MfArray([[2, 3, 4], [5, 1, 2]]))
        XCTAssertEqual(Matft.diff(m, axis: 0), MfArray([[-1, 2, 0, -2]]))
        XCTAssertEqual(Matft.diff(m, n: 2, axis: 1), MfArray([[1, 1], [-4, 1]]))
        XCTAssertEqual(m.diff(axis: 0), MfArray([[-1, 2, 0, -2]]))

        // bool: not_equal
        let b = Matft.diff(MfArray([true, false, false, true]))
        XCTAssertEqual(b.mftype, .Bool)
        XCTAssertEqual(b, MfArray([true, false, true]))
    }

    func test_meshgrid() {
        do {
            let ret = Matft.meshgrid(MfArray([1, 2, 3]), MfArray([4, 5]))
            XCTAssertEqual(ret.count, 2)
            XCTAssertEqual(ret[0], MfArray([[1, 2, 3], [1, 2, 3]]))
            XCTAssertEqual(ret[1], MfArray([[4, 4, 4], [5, 5, 5]]))
        }
        do {
            let ret = Matft.meshgrid(MfArray([1, 2, 3]), MfArray([4, 5]), indexing: .ij)
            XCTAssertEqual(ret[0], MfArray([[1, 1], [2, 2], [3, 3]]))
            XCTAssertEqual(ret[1], MfArray([[4, 5], [4, 5], [4, 5]]))
        }
        do {
            let ret = Matft.meshgrid(MfArray([1, 2]), MfArray([3, 4, 5]), MfArray([6, 7]))
            XCTAssertEqual(ret[0].shape, [3, 2, 2])
            XCTAssertEqual(ret[0], MfArray([[[1, 1], [2, 2]], [[1, 1], [2, 2]], [[1, 1], [2, 2]]]))
            XCTAssertEqual(ret[1], MfArray([[[3, 3], [3, 3]], [[4, 4], [4, 4]], [[5, 5], [5, 5]]]))
            XCTAssertEqual(ret[2], MfArray([[[6, 7], [6, 7]], [[6, 7], [6, 7]], [[6, 7], [6, 7]]]))
        }
        do {
            // outputs are copies (writable, independent)
            let ret = Matft.meshgrid(MfArray([1, 2]), MfArray([3, 4]))
            ret[0][0, 0] = MfArray([100])
            XCTAssertEqual(ret[0], MfArray([[100, 2], [1, 2]]))
        }
    }

    func test_isnan_isinf_isfinite() {
        let v = MfArray([1.0, Double.nan, Double.infinity, -Double.infinity, 0.0], mftype: .Double)
        XCTAssertEqual(Matft.math.isnan(v).mftype, .Bool)
        XCTAssertEqual(Matft.math.isnan(v), MfArray([false, true, false, false, false]))
        XCTAssertEqual(Matft.math.isinf(v), MfArray([false, false, true, true, false]))
        XCTAssertEqual(Matft.math.isfinite(v), MfArray([true, false, false, false, true]))

        let f = MfArray([Float.nan, Float(2), -Float.infinity], mftype: .Float)
        XCTAssertEqual(Matft.math.isnan(f), MfArray([true, false, false]))
        XCTAssertEqual(Matft.math.isinf(f), MfArray([false, false, true]))
        XCTAssertEqual(Matft.math.isfinite(f[Matft.reverse]), MfArray([false, true, false]))
    }
}
