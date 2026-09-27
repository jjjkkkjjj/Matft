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

    /// Printing, `data` and the scalar accessors of empty arrays, including views of a non-empty base
    /// (numpy: `repr` gives `array([], shape=(3, 0), dtype=float64)` and `.item()` raises; Matft returns nil)
    func testDescriptionDataScalar(){
        for shape in [[0]] + shapes{
            for mftype in [MfType.Double, .Float, .Int, .UInt8, .Bool]{
                // a zero-length slice of a non-empty array, whose storedSize and offset are not 0
                let axis = shape.firstIndex(of: 0)!
                var baseShape = shape
                baseShape[axis] = 3
                let view = Matft.nums(Double(1), shape: baseShape, mftype: mftype).swapaxes(axis1: 0, axis2: axis)[2~<2].swapaxes(axis1: 0, axis2: axis)
                let arrays = [
                    ("row", MfArray([] as [Double], mftype: mftype, shape: shape)),
                    ("column", MfArray([] as [Double], mftype: mftype, shape: shape, mforder: .Column)),
                    ("slice view", view),
                ]
                for (layout, x) in arrays{
                    let name = "\(shape) \(mftype) \(layout)"
                    XCTAssertEqual(x.shape, shape, name)
                    XCTAssertEqual(x.size, 0, name)
                    XCTAssertEqual(x.description, "mfarray = \n\t[], type=\(mftype), shape=\(shape)", name)
                    // `data` is the whole stored buffer, which is the base's for a view
                    if layout != "slice view"{
                        XCTAssertEqual(x.data.count, 0, name)
                    }
                    XCTAssertNil(x.scalarFirst, name)
                    XCTAssertNil(x.scalar, name)
                    XCTAssertEqual(x.T.description, "mfarray = \n\t[], type=\(mftype), shape=\(Array(shape.reversed()))", name)
                }
            }
        }
        XCTAssertNil(MfArray([] as [Double], shape: [3, 0]).scalar(Double.self))
        XCTAssertNil(MfArray([] as [Int], shape: [0]).scalar(Int.self))
    }

    /// Complex arrays with a zero-length dimension through creation, printing and elementwise operations
    func testComplex(){
        for shape in [[0]] + shapes{
            for mftype in [MfType.Double, .Float]{
                let e = MfArray([] as [Double], mftype: mftype, shape: shape)
                let z = MfArray(real: e, imag: e)
                // the mftype of a complex array is the type of its parts
                let name = "\(shape) complex \(mftype)"
                XCTAssertTrue(z.isComplex, name)
                XCTAssertEqual(z.mftype, mftype, name)
                XCTAssertEqual(z.shape, shape, name)
                XCTAssertEqual(z.description, "mfarray = \n\t[], type=\(mftype), shape=\(shape)", name)
                XCTAssertEqual(z.data.count, 0, name)
                XCTAssertEqual(z.data_imag?.count, 0, name)
                XCTAssertNil(z.scalarFirst, name)
                // numpy: every elementwise result keeps the (broadcast) shape
                for (op, r) in [("z + z", z + z), ("z - e", z - e), ("z * 2", z * 2), ("z / z", z / z), ("-z", -z),
                                ("z.T.T", z.T.T), ("deepcopy", Matft.deepcopy(z)), ("column", z.to_contiguous(mforder: .Column))]{
                    XCTAssertEqual(r.shape, shape, "\(op) \(name)")
                    XCTAssertTrue(r.isComplex, "\(op) \(name)")
                    XCTAssertEqual(r.mftype, mftype, "\(op) \(name)")
                    XCTAssertEqual(r.data.count, 0, "\(op) \(name)")
                }
                XCTAssertEqual(Matft.math.abs(z).shape, shape, name)
                XCTAssertTrue(Matft.math.abs(z).isReal, name)
                XCTAssertEqual(Matft.complex.conjugate(z).shape, shape, name)
                XCTAssertEqual(z.real.shape, shape, name)
                XCTAssertEqual(z.imag!.shape, shape, name)
                XCTAssertEqual((z === z).shape, shape, name)
            }
        }
    }
}
