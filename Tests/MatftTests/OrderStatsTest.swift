import XCTest
//@testable import Matft
import Matft

/// median, percentile, quantile and the nan-functions. Expected values are the outputs of numpy 2.x
final class OrderStatsTests: XCTestCase {
    let A = MfArray([[3.0, 1.0, 4.0, 1.0, 5.0],
                     [9.0, 2.0, 6.0, 5.0, 3.0],
                     [5.0, 8.0, 9.0, 7.0, 9.0]], mftype: .Double)
    // (np.arange(24).reshape(2,3,4)*5)%7
    let B = MfArray([[[0, 5, 3, 1], [6, 4, 2, 0], [5, 3, 1, 6]],
                     [[4, 2, 0, 5], [3, 1, 6, 4], [2, 0, 5, 3]]] as [[[Int]]])
    let C = MfArray([[1.0, Double.nan, 3.0, 4.0],
                     [Double.nan, Double.nan, Double.nan, Double.nan],
                     [2.0, 5.0, Double.nan, 1.0]], mftype: .Double)
    let D = MfArray([[1.0, Double.nan, 3.0],
                     [Double.nan, 7.0, 2.0],
                     [4.0, 5.0, Double.nan]], mftype: .Double)
    let nan = Double.nan

    func test_median() {
        _assertClose(Matft.stats.median(A), MfArray([5.0], mftype: .Double))
        _assertClose(Matft.stats.median(A, axis: 0), MfArray([5.0, 2.0, 6.0, 5.0, 5.0], mftype: .Double))
        _assertClose(Matft.stats.median(A, axis: 1), MfArray([3.0, 5.0, 8.0], mftype: .Double))
        _assertClose(Matft.stats.median(A, axis: -1, keepDims: true), MfArray([[3.0], [5.0], [8.0]], mftype: .Double))
        XCTAssertEqual(Matft.stats.median(A, keepDims: true).shape, [1, 1])

        // Int input returns Float, non-contiguous input
        let b = Matft.stats.median(B, axis: 1)
        XCTAssertEqual(b.mftype, .Float)
        _assertClose(b, MfArray([[5.0, 4.0, 2.0, 1.0], [3.0, 1.0, 5.0, 4.0]], mftype: .Float))
        _assertClose(Matft.stats.median(B.transpose(axes: [2, 0, 1]), axis: 0), MfArray([[2.0, 3.0, 4.0], [3.0, 3.5, 2.5]], mftype: .Float))
        _assertClose(Matft.stats.median(MfArray([4.0, 1.0, 3.0, 2.0], mftype: .Double)), MfArray([2.5], mftype: .Double))

        // Float input keeps Float
        let e = MfArray([[1.5, 2.5], [3.25, -1.0]], mftype: .Float)
        XCTAssertEqual(Matft.stats.median(e, axis: 0).mftype, .Float)
        _assertClose(Matft.stats.median(e, axis: 0), MfArray([2.375, 0.75], mftype: .Float))

        // NaN propagates
        _assertClose(Matft.stats.median(C, axis: 1), MfArray([nan, nan, nan], mftype: .Double))
        _assertClose(Matft.stats.median(C), MfArray([nan], mftype: .Double))
    }

    func test_percentile_quantile() {
        let expected: [(MfQuantileMethod, Double, [Double], [Double])] = [
            (.linear, 3.2, [4.2, 1.6, 5.2, 3.4, 4.2], [1.4, 3.4, 7.2]),
            (.lower, 3.0, [3.0, 1.0, 4.0, 1.0, 3.0], [1.0, 3.0, 7.0]),
            (.higher, 4.0, [5.0, 2.0, 6.0, 5.0, 5.0], [3.0, 5.0, 8.0]),
            (.nearest, 3.0, [5.0, 2.0, 6.0, 5.0, 5.0], [1.0, 3.0, 7.0]),
            (.midpoint, 3.5, [4.0, 1.5, 5.0, 3.0, 4.0], [2.0, 4.0, 7.5]),
        ]
        for (method, none, axis0, axis1) in expected {
            _assertClose(Matft.stats.percentile(A, q: 30, method: method), MfArray([none], mftype: .Double))
            _assertClose(Matft.stats.percentile(A, q: 30, axis: 0, method: method), MfArray(axis0, mftype: .Double))
            _assertClose(Matft.stats.percentile(A, q: 30, axis: 1, method: method), MfArray(axis1, mftype: .Double))
        }
        // nearest rounds half to even: virtual index 1.5 -> 2, 0.5 -> 0, 2.5 -> 2
        _assertClose(Matft.stats.percentile(MfArray([1.0, 2.0, 3.0, 4.0], mftype: .Double), q: [50, 100.0 / 6, 500.0 / 6], method: .nearest),
                     MfArray([3.0, 1.0, 3.0], mftype: .Double))

        // multiple q: shape = (len(q),) + reduced shape
        let multi = Matft.stats.percentile(A, q: [25, 50, 90], axis: 1)
        XCTAssertEqual(multi.shape, [3, 3])
        _assertClose(multi, MfArray([[1.0, 3.0, 7.0], [3.0, 5.0, 8.0], [4.6, 7.8, 9.0]], mftype: .Double))
        _assertClose(Matft.stats.percentile(A, q: [0, 100]), MfArray([1.0, 9.0], mftype: .Double))
        XCTAssertEqual(Matft.stats.percentile(A, q: [25, 50], axis: 1, keepDims: true).shape, [2, 3, 1])

        _assertClose(Matft.stats.quantile(A, q: 0.3, axis: 1), MfArray([1.4, 3.4, 7.2], mftype: .Double))
        _assertClose(Matft.stats.quantile(A, q: [0.1, 0.5], axis: 0), MfArray([[3.4, 1.2, 4.4, 1.8, 3.4], [5.0, 2.0, 6.0, 5.0, 5.0]], mftype: .Double))

        // NaN propagates
        _assertClose(Matft.stats.percentile(C, q: 50, axis: 1), MfArray([nan, nan, nan], mftype: .Double))
    }

    func test_nansum_nanmean() {
        _assertClose(Matft.stats.nansum(C), MfArray([16.0], mftype: .Double))
        _assertClose(Matft.stats.nansum(C, axis: 1), MfArray([8.0, 0.0, 8.0], mftype: .Double))
        _assertClose(Matft.stats.nansum(C, axis: 0), MfArray([3.0, 5.0, 3.0, 5.0], mftype: .Double))

        _assertClose(Matft.stats.nanmean(C), MfArray([2.6666666667], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.nanmean(C, axis: 1), MfArray([2.6666666667, nan, 2.6666666667], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.nanmean(C, axis: 0, keepDims: true), MfArray([[1.5, 5.0, 3.0, 2.5]], mftype: .Double))

        // Float keeps Float
        let f = C.astype(.Float)
        XCTAssertEqual(Matft.stats.nanmean(f, axis: 1).mftype, .Float)
        _assertClose(Matft.stats.nansum(f, axis: 1), MfArray([8.0, 0.0, 8.0], mftype: .Float))
    }

    func test_nanmax_nanmin_nanarg() {
        _assertClose(Matft.stats.nanmax(C, axis: 1), MfArray([4.0, nan, 5.0], mftype: .Double))
        _assertClose(Matft.stats.nanmin(C, axis: 1), MfArray([1.0, nan, 1.0], mftype: .Double))
        _assertClose(Matft.stats.nanmax(C), MfArray([5.0], mftype: .Double))

        let argmax0 = Matft.stats.nanargmax(D, axis: 0)
        XCTAssertEqual(argmax0.mftype, .Int)
        XCTAssertEqual(argmax0, MfArray([2, 1, 0]))
        XCTAssertEqual(Matft.stats.nanargmax(D, axis: 1), MfArray([2, 1, 1]))
        XCTAssertEqual(Matft.stats.nanargmax(D), MfArray([4]))
        XCTAssertEqual(Matft.stats.nanargmin(D, axis: 0), MfArray([0, 2, 1]))
        XCTAssertEqual(Matft.stats.nanargmin(D, axis: 1), MfArray([0, 2, 0]))
        XCTAssertEqual(Matft.stats.nanargmin(D), MfArray([0]))
    }

    func test_nanvar_nanstd() {
        _assertClose(Matft.stats.nanvar(C, axis: 1), MfArray([1.5555555556, nan, 2.8888888889], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.nanvar(C, axis: 1, ddof: 1), MfArray([2.3333333333, nan, 4.3333333333], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.nanvar(C), MfArray([2.2222222222], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.nanstd(C, axis: 1), MfArray([1.2472191289, nan, 1.6996731712], mftype: .Double), atol: 1e-9)
        // the degrees of freedom <= 0 returns NaN
        _assertClose(Matft.stats.nanstd(C, axis: 0, ddof: 1), MfArray([0.7071067812, nan, nan, 2.1213203436], mftype: .Double), atol: 1e-9)
    }

    func test_nanmedian_nanpercentile() {
        _assertClose(Matft.stats.nanmedian(C, axis: 1), MfArray([3.0, nan, 2.0], mftype: .Double))
        _assertClose(Matft.stats.nanmedian(C), MfArray([2.5], mftype: .Double))
        _assertClose(Matft.stats.nanmedian(C, axis: 0), MfArray([1.5, 5.0, 3.0, 2.5], mftype: .Double))
        _assertClose(Matft.stats.nanpercentile(C, q: 40, axis: 1), MfArray([2.6, nan, 1.8], mftype: .Double))
        _assertClose(Matft.stats.nanquantile(C, q: 0.4, axis: 1), MfArray([2.6, nan, 1.8], mftype: .Double))
        _assertClose(Matft.stats.nanpercentile(C, q: [10, 90], axis: 0), MfArray([[1.1, 5.0, 3.0, 1.3], [1.9, 5.0, 3.0, 3.7]], mftype: .Double))
    }
}

/// |actual - expected| <= atol + rtol * |expected|, and NaN must be at the same positions
fileprivate func _assertClose(_ actual: MfArray, _ expected: MfArray, rtol: Double = 1e-7, atol: Double = 1e-10, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertClose(actual, expected, rtol: rtol, atol: atol, checkType: true, file: file, line: line)
}
