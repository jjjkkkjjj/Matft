import XCTest
//@testable import Matft
import Matft

final class PadTests: XCTestCase {

    func test_pad_1d() {
        let a = MfArray([1, 2, 3])

        // np.pad(a, (5, 5), mode)
        XCTAssertEqual(Matft.pad(a, pad_width: [(5, 5)], mode: .reflect), MfArray([2, 1, 2, 3, 2, 1, 2, 3, 2, 1, 2, 3, 2]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(5, 5)], mode: .symmetric), MfArray([2, 3, 3, 2, 1, 1, 2, 3, 3, 2, 1, 1, 2]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(5, 5)], mode: .wrap), MfArray([2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(5, 5)], mode: .edge), MfArray([1, 1, 1, 1, 1, 1, 2, 3, 3, 3, 3, 3, 3]))

        // np.pad(a, (2, 1), mode)
        XCTAssertEqual(Matft.pad(a, pad_width: [(2, 1)], mode: .reflect), MfArray([3, 2, 1, 2, 3, 2]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(2, 1)], mode: .symmetric), MfArray([2, 1, 1, 2, 3, 3]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(2, 1)], mode: .wrap), MfArray([2, 3, 1, 2, 3, 1]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(2, 1)], mode: .edge), MfArray([1, 1, 1, 2, 3, 3]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(2, 1)]), MfArray([0, 0, 1, 2, 3, 0]))

        // size 1
        let b = MfArray([7])
        XCTAssertEqual(Matft.pad(b, pad_width: [(2, 2)], mode: .reflect), MfArray([7, 7, 7, 7, 7]))
        XCTAssertEqual(Matft.pad(b, pad_width: [(2, 2)], mode: .symmetric), MfArray([7, 7, 7, 7, 7]))
    }

    func test_pad_2d() {
        let a = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])

        // np.pad(a, ((1,0),(2,1)), 'constant', constant_values=9)
        XCTAssertEqual(Matft.pad(a, pad_width: [(1, 0), (2, 1)], mode: .constant, constant_values: 9),
                       MfArray([[9, 9, 9, 9, 9, 9],
                                [9, 9, 0, 1, 2, 9],
                                [9, 9, 3, 4, 5, 9]]))
        // np.pad(a, 1)
        XCTAssertEqual(Matft.pad(a, pad_width: 1),
                       MfArray([[0, 0, 0, 0, 0],
                                [0, 0, 1, 2, 0],
                                [0, 3, 4, 5, 0],
                                [0, 0, 0, 0, 0]]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(1, 1), (2, 2)], mode: .reflect),
                       MfArray([[5, 4, 3, 4, 5, 4, 3],
                                [2, 1, 0, 1, 2, 1, 0],
                                [5, 4, 3, 4, 5, 4, 3],
                                [2, 1, 0, 1, 2, 1, 0]]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(0, 2), (1, 0)], mode: .symmetric),
                       MfArray([[0, 0, 1, 2],
                                [3, 3, 4, 5],
                                [3, 3, 4, 5],
                                [0, 0, 1, 2]]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(1, 1), (1, 1)], mode: .edge),
                       MfArray([[0, 0, 1, 2, 2],
                                [0, 0, 1, 2, 2],
                                [3, 3, 4, 5, 5],
                                [3, 3, 4, 5, 5]]))
        XCTAssertEqual(Matft.pad(a, pad_width: [(2, 1), (4, 0)], mode: .wrap),
                       MfArray([[2, 0, 1, 2, 0, 1, 2],
                                [5, 3, 4, 5, 3, 4, 5],
                                [2, 0, 1, 2, 0, 1, 2],
                                [5, 3, 4, 5, 3, 4, 5],
                                [2, 0, 1, 2, 0, 1, 2]]))

        // non-contiguous input: np.pad(a.T, ((1,0),(0,1)), 'reflect')
        XCTAssertEqual(Matft.pad(a.T, pad_width: [(1, 0), (0, 1)], mode: .reflect),
                       MfArray([[1, 4, 1],
                                [0, 3, 0],
                                [1, 4, 1],
                                [2, 5, 2]]))
    }

    func test_pad_type() {
        let a = MfArray([1.5, 2.5], mftype: .Double)
        let ret = Matft.pad(a, pad_width: [(1, 1)], mode: .constant, constant_values: -1)
        XCTAssertEqual(ret.mftype, .Double)
        XCTAssertEqual(ret, MfArray([-1.0, 1.5, 2.5, -1.0], mftype: .Double))

        let b = MfArray([1, 2], mftype: .UInt8)
        let retb = Matft.pad(b, pad_width: [(1, 0)], mode: .edge)
        XCTAssertEqual(retb.mftype, .UInt8)
        XCTAssertEqual(retb, MfArray([1, 1, 2], mftype: .UInt8))

        // method
        XCTAssertEqual(b.pad(pad_width: [(0, 1)], mode: .wrap), MfArray([1, 2, 1], mftype: .UInt8))
    }
}
