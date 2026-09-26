import XCTest

import Matft

/// Arrays with a zero-length dimension (e.g. `np.diff(a, n=len)`). numpy returns empty arrays of the broadcast shape.
/// Out of bounds writes on these arrays corrupt the heap silently, so run with Guard Malloc (`DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`) when they are suspected
final class EmptyArrayTests: XCTestCase {

    private let shapes: [[Int]] = [[3, 0], [0, 4], [2, 0, 3]]

    func testElementwise(){
        for shape in shapes{
            for mforder in [MfOrder.Row, .Column]{
                let e = Matft.nums(1.5, shape: shape, mforder: mforder)
                let name = "\(shape) \(mforder)"
                XCTAssertEqual((e + e).shape, shape, name)
                XCTAssertEqual((e - 1).shape, shape, name)
                XCTAssertEqual((2 * e).shape, shape, name)
                XCTAssertEqual((e / e).shape, shape, name)
                XCTAssertEqual((-e).shape, shape, name)
                XCTAssertEqual((e > 0).shape, shape, name)
                XCTAssertEqual((e === e).shape, shape, name)
                XCTAssertEqual(Matft.math.sin(e).shape, shape, name)
                XCTAssertEqual(Matft.math.abs(e).shape, shape, name)
                XCTAssertEqual(e.astype(.Int).shape, shape, name)
                XCTAssertEqual(e.to_contiguous(mforder: .Row).shape, shape, name)
                XCTAssertEqual(e.to_contiguous(mforder: .Column).shape, shape, name)
                XCTAssertEqual(e.T.shape, shape.reversed(), name)
                XCTAssertEqual((e.T + e.T).shape, shape.reversed(), name)
                XCTAssertEqual(e.clip(min: 0, max: 1).shape, shape, name)
                XCTAssertEqual(e.data.count, 0, name)
            }
        }
        // broadcasting with an empty dimension: np.ones((3, 0)) + np.ones((3, 1)) -> (3, 0)
        XCTAssertEqual((Matft.nums(1.0, shape: [3, 0]) + Matft.nums(1.0, shape: [3, 1])).shape, [3, 0])
        XCTAssertEqual((Matft.nums(1.0, shape: [1, 4]) * Matft.nums(1.0, shape: [0, 4])).shape, [0, 4])
    }

    func testDiffToEmpty(){
        let a = MfArray([[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]] as [[Double]])
        for (name, x) in layoutVariants(a){
            // numpy: np.diff(a, n=4, axis=1).shape -> (3, 0), np.diff(a, n=3, axis=0).shape -> (0, 4)
            XCTAssertEqual(Matft.diff(x, n: 4, axis: 1).shape, [3, 0], name)
            XCTAssertEqual(Matft.diff(x, n: 5, axis: 1).shape, [3, 0], name)
            XCTAssertEqual(Matft.diff(x, n: 3, axis: 0).shape, [0, 4], name)
        }
    }
}
