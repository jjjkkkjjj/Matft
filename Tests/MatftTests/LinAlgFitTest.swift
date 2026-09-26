import XCTest
//@testable import Matft
import Matft

/// lstsq, matrix_rank, polyfit, polyval, cov and corrcoef. Expected values are the outputs of numpy 2.x
final class LinAlgFitTests: XCTestCase {

    // SVD is not supported on WASI
    #if !os(WASI)
    func test_lstsq() throws {
        let A = MfArray([[1.0, 1.0], [1.0, 2.0], [1.0, 3.0], [1.0, 4.0]], mftype: .Double)
        let b = MfArray([6.0, 5.0, 7.0, 10.0], mftype: .Double)
        do {
            let (x, residuals, rank, s) = try Matft.linalg.lstsq(A, b)
            XCTAssertEqual(x.mftype, .Double)
            _assertClose(x, MfArray([3.5, 1.4], mftype: .Double))
            _assertClose(residuals, MfArray([4.2], mftype: .Double))
            XCTAssertEqual(rank, 2)
            _assertClose(s, MfArray([5.7793788132, 0.7738091064], mftype: .Double), atol: 1e-9)
        }
        do {
            // multiple right hand sides
            let B = Matft.hstack([b.expand_dims(axis: 1), (b * 2.0 - 1.0).expand_dims(axis: 1)])
            let (x, residuals, rank, _) = try Matft.linalg.lstsq(A, B)
            _assertClose(x, MfArray([[3.5, 6.0], [1.4, 2.8]], mftype: .Double))
            _assertClose(residuals, MfArray([4.2, 16.8], mftype: .Double))
            XCTAssertEqual(rank, 2)
        }
        do {
            // rank deficient: minimum norm solution and empty residuals
            let R = MfArray([[1.0, 2.0, 3.0], [2.0, 4.0, 6.0], [1.0, 0.0, 1.0]], mftype: .Double)
            let (x, residuals, rank, s) = try Matft.linalg.lstsq(R, MfArray([1.0, 2.0, 3.0], mftype: .Double))
            _assertClose(x, MfArray([2.3333333333, -1.6666666667, 0.6666666667], mftype: .Double), atol: 1e-9)
            XCTAssertEqual(residuals.shape, [0])
            XCTAssertEqual(rank, 2)
            _assertClose(s, MfArray([8.4354485158, 0.9182637625, 0.0], mftype: .Double), atol: 1e-9)
        }
        do {
            // wide
            let W = MfArray([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]], mftype: .Double)
            let (x, residuals, rank, _) = try Matft.linalg.lstsq(W, MfArray([1.0, 2.0], mftype: .Double))
            _assertClose(x, MfArray([-0.0555555556, 0.1111111111, 0.2777777778], mftype: .Double), atol: 1e-9)
            XCTAssertEqual(residuals.shape, [0])
            XCTAssertEqual(rank, 2)
        }
        do {
            // Float keeps Float
            let (x, _, _, _) = try Matft.linalg.lstsq(A.astype(.Float), b.astype(.Float))
            XCTAssertEqual(x.mftype, .Float)
            _assertClose(x, MfArray([3.5, 1.4], mftype: .Float), rtol: 1e-5)
        }
    }

    func test_matrix_rank() throws {
        let R = MfArray([[1.0, 2.0, 3.0], [2.0, 4.0, 6.0], [1.0, 0.0, 1.0]], mftype: .Double)
        XCTAssertEqual(try Matft.linalg.matrix_rank(R), 2)
        XCTAssertEqual(try Matft.linalg.matrix_rank(Matft.eye(dim: 4)), 4)
        XCTAssertEqual(try Matft.linalg.matrix_rank(Matft.nums(0.0, shape: [3, 3])), 0)
        XCTAssertEqual(try Matft.linalg.matrix_rank(MfArray([1.0, 0.0, 2.0], mftype: .Double)), 1)
        XCTAssertEqual(try Matft.linalg.matrix_rank(R, tol: 0.5), 2)
    }

    func test_polyfit() throws {
        let x = MfArray([0.0, 1.0, 2.0, 3.0, 4.0, 5.0], mftype: .Double)
        let y = MfArray([1.0, 1.8, 3.2, 4.9, 7.1, 9.8], mftype: .Double)
        _assertClose(try Matft.polyfit(x, y, deg: 1), MfArray([1.76, 0.2333333333], mftype: .Double), atol: 1e-9)
        _assertClose(try Matft.polyfit(x, y, deg: 2), MfArray([0.2267857143, 0.6260714286, 0.9892857143], mftype: .Double), atol: 1e-9)
        // interpolation (deg = len - 1)
        _assertClose(try Matft.polyfit(x, y, deg: 5), MfArray([-0.0058333333, 0.0791666667, -0.3791666667, 0.9708333333, 0.135, 1.0], mftype: .Double), atol: 1e-8)
    }
    #endif

    func test_polyval() {
        _assertClose(Matft.polyval(MfArray([3.0, 0.0, 1.0], mftype: .Double), MfArray([0.0, 1.0, 2.5], mftype: .Double)),
                     MfArray([1.0, 4.0, 19.75], mftype: .Double))
        _assertClose(Matft.polyval(MfArray([1.0, -2.0], mftype: .Double), MfArray([[1.0, 2.0], [3.0, 4.0]], mftype: .Double)),
                     MfArray([[-1.0, 0.0], [1.0, 2.0]], mftype: .Double))
    }

    func test_cov_corrcoef() {
        let m = MfArray([[0.0, 1.0, 2.0], [2.0, 1.0, 0.0], [1.0, 3.0, 2.5]], mftype: .Double)
        _assertClose(Matft.stats.cov(m), MfArray([[1.0, -1.0, 0.75], [-1.0, 1.0, -0.75], [0.75, -0.75, 1.0833333333]], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.cov(m, rowvar: false), MfArray([[1.0, 0.0, -1.0], [0.0, 1.3333333333, 1.0], [-1.0, 1.0, 1.75]], mftype: .Double), atol: 1e-9)
        let biased = MfArray([[0.6666666667, -0.6666666667, 0.5], [-0.6666666667, 0.6666666667, -0.5], [0.5, -0.5, 0.7222222222]], mftype: .Double)
        _assertClose(Matft.stats.cov(m, bias: true), biased, atol: 1e-9)
        _assertClose(Matft.stats.cov(m, ddof: 0), biased, atol: 1e-9)
        // 1d: a single variable
        _assertClose(Matft.stats.cov(MfArray([1.0, 2.0, 4.0], mftype: .Double)), MfArray([2.3333333333], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.cov(MfArray([1.0, 2.0, 4.0], mftype: .Double), y: MfArray([2.0, 1.0, 0.0], mftype: .Double)),
                     MfArray([[2.3333333333, -1.5], [-1.5, 1.0]], mftype: .Double), atol: 1e-9)

        _assertClose(Matft.stats.corrcoef(m), MfArray([[1.0, -1.0, 0.7205766921], [-1.0, 1.0, -0.7205766921], [0.7205766921, -0.7205766921, 1.0]], mftype: .Double), atol: 1e-9)
        _assertClose(Matft.stats.corrcoef(MfArray([1.0, 2.0, 4.0], mftype: .Double), y: MfArray([2.0, 1.0, 0.0], mftype: .Double)),
                     MfArray([[1.0, -0.9819805061], [-0.9819805061, 1.0]], mftype: .Double), atol: 1e-9)
        // Int returns Float
        XCTAssertEqual(Matft.stats.cov(MfArray([[1, 2], [3, 5]])).mftype, .Float)
    }
}

/// |actual - expected| <= atol + rtol * |expected|
fileprivate func _assertClose(_ actual: MfArray, _ expected: MfArray, rtol: Double = 1e-7, atol: Double = 1e-10, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertClose(actual, expected, rtol: rtol, atol: atol, checkType: true, file: file, line: line)
}
