import XCTest
//@testable import Matft
import Matft

/// Functions whose output shape depends on the data. Expected values are the outputs of numpy 2.x
final class SearchTests: XCTestCase {
    let nan = Double.nan

    func test_nonzero_argwhere() {
        let a = MfArray([[0, 3, 0], [1, 0, -2]])
        let nz = Matft.nonzero(a)
        XCTAssertEqual(nz.count, 2)
        XCTAssertEqual(nz[0].mftype, .Int)
        XCTAssertEqual(nz[0], MfArray([0, 1, 1]))
        XCTAssertEqual(nz[1], MfArray([1, 0, 2]))
        XCTAssertEqual(Matft.argwhere(a), MfArray([[0, 1], [1, 0], [1, 2]]))
        XCTAssertEqual(Matft.argwhere(a).mftype, .Int)

        XCTAssertEqual(Matft.nonzero(MfArray([true, false, true]))[0], MfArray([0, 2]))
        // non-contiguous input
        let t = Matft.nonzero(a.T)
        XCTAssertEqual(t[0], MfArray([0, 1, 2]))
        XCTAssertEqual(t[1], MfArray([1, 0, 1]))

        // np.arange(24).reshape(2,3,4)%5==0
        let b = MfArray((0..<24).map{ $0 % 5 == 0 }, mftype: .Bool, shape: [2, 3, 4])
        let nz3 = Matft.nonzero(b)
        XCTAssertEqual(nz3[0], MfArray([0, 0, 0, 1, 1]))
        XCTAssertEqual(nz3[1], MfArray([0, 1, 2, 0, 2]))
        XCTAssertEqual(nz3[2], MfArray([0, 1, 2, 3, 0]))

        // no nonzero element
        XCTAssertEqual(Matft.nonzero(MfArray([0, 0]))[0].shape, [0])
        XCTAssertEqual(Matft.argwhere(MfArray([[0, 0]])).shape, [0, 2])
    }

    func test_where() {
        // one argument is the same as nonzero
        let a = MfArray([[0, 3, 0], [1, 0, -2]])
        XCTAssertEqual(Matft.where(a)[1], MfArray([1, 0, 2]))

        // three arguments with broadcast
        let c = MfArray([[true, false], [false, true]])
        let ret = Matft.where(c, MfArray([[1, 2], [3, 4]]), MfArray([10.5, 20.5], mftype: .Double))
        XCTAssertEqual(ret.mftype, .Double)
        XCTAssertEqual(ret, MfArray([[1.0, 20.5], [10.5, 4.0]], mftype: .Double))

        // scalar
        XCTAssertEqual(Matft.where(a > 0, a, -1), MfArray([[-1, 3, -1], [1, -1, -1]]))
        XCTAssertEqual(Matft.where(MfArray([1.0, nan, 3.0], mftype: .Double) > 2, 1.0, 0.0), MfArray([0.0, 0.0, 1.0], mftype: .Double))
    }

    func test_searchsorted_digitize() {
        let s = MfArray([1, 2, 2, 3, 5])
        let left = Matft.searchsorted(s, MfArray([0, 2, 3, 4, 6]))
        XCTAssertEqual(left.mftype, .Int)
        XCTAssertEqual(left, MfArray([0, 1, 3, 4, 5]))
        XCTAssertEqual(Matft.searchsorted(s, MfArray([0, 2, 3, 4, 6]), side: .right), MfArray([0, 3, 4, 4, 5]))
        XCTAssertEqual(Matft.searchsorted(s, MfArray([[2, 5], [1, 9]])), MfArray([[1, 4], [0, 5]]))
        // NaN is the largest
        XCTAssertEqual(Matft.searchsorted(MfArray([1.0, 2.0, nan], mftype: .Double), MfArray([nan, 2.0, 3.0], mftype: .Double)), MfArray([2, 1, 2]))

        let bins = MfArray([0.0, 1.0, 2.5, 4.0, 10.0], mftype: .Double)
        let x = MfArray([-1.0, 0.0, 1.0, 2.0, 2.5, 3.0, 4.0, 10.0, 11.0], mftype: .Double)
        XCTAssertEqual(Matft.digitize(x, bins: bins), MfArray([0, 1, 2, 2, 3, 3, 4, 5, 5]))
        XCTAssertEqual(Matft.digitize(x, bins: bins, right: true), MfArray([0, 0, 1, 2, 2, 3, 3, 4, 5]))
        // decreasing bins
        let rbins = bins[Matft.reverse]
        XCTAssertEqual(Matft.digitize(x, bins: rbins), MfArray([5, 4, 3, 3, 2, 2, 1, 0, 0]))
        XCTAssertEqual(Matft.digitize(x, bins: rbins, right: true), MfArray([5, 5, 4, 3, 3, 2, 2, 1, 0]))
    }

    func test_bincount() {
        let ret = Matft.bincount(MfArray([0, 1, 1, 3, 2, 1, 7]))
        XCTAssertEqual(ret.mftype, .Int)
        XCTAssertEqual(ret, MfArray([1, 3, 1, 1, 0, 0, 0, 1]))
        let w = Matft.bincount(MfArray([0, 1, 1, 2]), weights: MfArray([0.5, 1.0, 0.25, 2.0], mftype: .Double))
        XCTAssertEqual(w.mftype, .Double)
        XCTAssertEqual(w, MfArray([0.5, 1.25, 2.0], mftype: .Double))
        XCTAssertEqual(Matft.bincount(MfArray([1, 1]), minlength: 4), MfArray([0, 2, 0, 0]))
    }

    func test_histogram() {
        let a = MfArray([1.0, 2.0, 1.0, 3.0, 4.0, 2.5, 2.0, 6.0, 0.5, 5.5], mftype: .Double)
        do {
            let (hist, edges) = Matft.histogram(a, bins: 4)
            XCTAssertEqual(hist.mftype, .Int)
            XCTAssertEqual(hist, MfArray([3, 4, 1, 2]))
            XCTAssertEqual(edges, MfArray([0.5, 1.875, 3.25, 4.625, 6.0], mftype: .Double))
        }
        do {
            let (hist, edges) = Matft.histogram(a, bins: 3, range: (1, 4))
            XCTAssertEqual(hist, MfArray([2, 3, 2]))
            XCTAssertEqual(edges, MfArray([1.0, 2.0, 3.0, 4.0], mftype: .Double))
        }
        do {
            let (hist, edges) = Matft.histogram(a, bins: MfArray([0.0, 1.0, 2.5, 6.0], mftype: .Double))
            XCTAssertEqual(hist, MfArray([1, 4, 5]))
            XCTAssertEqual(edges, MfArray([0.0, 1.0, 2.5, 6.0], mftype: .Double))
        }
        do {
            let (hist, _) = Matft.histogram(a, bins: 4, density: true)
            XCTAssertEqual(hist.mftype, .Double)
            XCTAssertEqual(hist, MfArray([0.21818181818181817, 0.2909090909090909, 0.07272727272727272, 0.14545454545454545], mftype: .Double))
        }
        do {
            let (hist, _) = Matft.histogram(a, bins: 2, weights: Matft.arange(start: 0, to: 10, by: 1, mftype: .Double))
            XCTAssertEqual(hist, MfArray([25.0, 20.0], mftype: .Double))
        }
        do {
            // the bin edges of linspace(0, 1, 11) are not exact, so numpy corrects the bin indices
            let b = MfArray([0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], mftype: .Double)
            XCTAssertEqual(Matft.histogram(b, bins: 10).hist, MfArray([1, 1, 2, 0, 1, 2, 1, 0, 1, 2]))
        }
    }
}
