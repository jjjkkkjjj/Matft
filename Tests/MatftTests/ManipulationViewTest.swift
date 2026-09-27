import XCTest

import Matft

/// View vs copy semantics of the conversion / manipulation functions, like numpy:
/// writing into a view changes the input, writing into a copy doesn't, and non-in-place calls leave the input unchanged.
final class ManipulationViewTests: XCTestCase {
    /// [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]]
    private func base() -> MfArray {
        Matft.arange(start: 0, to: 12, by: 1, shape: [3, 4], mftype: .Double)
    }

    func testViewsShareMemory() {
        // numpy: the result of these functions is a view, so a write into it is visible in the input.
        // (position written in the result, flatten index in the row-major input)
        let cases: [(String, (MfArray) -> MfArray, (MfArray) -> Void, Int)] = [
            ("transpose", { Matft.transpose($0) }, { $0[2, 1] = MfArray([-1] as [Double]) }, 6),              // np.transpose(a)[2, 1] is a[1, 2]
            ("T", { $0.T }, { $0[0, 2] = MfArray([-1] as [Double]) }, 8),
            ("swapaxes", { Matft.swapaxes($0, axis1: 0, axis2: 1) }, { $0[3, 0] = MfArray([-1] as [Double]) }, 3),
            ("moveaxis", { Matft.moveaxis($0, src: 0, dst: -1) }, { $0[1, 2] = MfArray([-1] as [Double]) }, 9),
            ("expand_dims", { Matft.expand_dims($0, axis: 1) }, { $0[2, 0, 3] = MfArray([-1] as [Double]) }, 11),
            ("squeeze", { Matft.squeeze(Matft.expand_dims($0, axis: 0)) }, { $0[1, 1] = MfArray([-1] as [Double]) }, 5),
            ("flip", { Matft.flip($0) }, { $0[0, 0] = MfArray([-1] as [Double]) }, 11),                      // np.flip(a)[0, 0] is a[2, 3]
            ("flip axis", { Matft.flip($0, axis: 1) }, { $0[1, 0] = MfArray([-1] as [Double]) }, 7),
            ("slice", { $0[1~<3, 1~<4~<2] }, { $0[1, 1] = MfArray([-1] as [Double]) }, 11),
        ]
        for (name, f, write, flat) in cases {
            let a = base()
            let v = f(a)
            XCTAssertTrue(v.isView, name)
            write(v)
            var expected = (0..<12).map { Double($0) }
            expected[flat] = -1
            XCTAssertEqual(rowValues(a), expected, name)
        }
    }

    func testViewOfViewShareMemory() {
        // numpy: views of views still write into the original buffer
        let a = base()
        let v = Matft.flip(Matft.transpose(a[1~<3]), axis: 0) // shape [4, 2], v[0, 1] is a[2, 3]
        v[0, 1] = MfArray([-1] as [Double])
        XCTAssertEqual(rowValues(a)[11], -1)
        XCTAssertEqual(rowValues(a).filter { $0 == -1 }.count, 1)
    }

    func testCopiesDoNotShareMemory() {
        // numpy returns copies for these (reshape is a view in numpy when possible, but Matft always copies: documented)
        let cases: [(String, (MfArray) -> MfArray)] = [
            ("reshape", { $0.reshape([4, 3]) }),
            ("flatten", { $0.flatten() }),
            ("flatten column", { $0.flatten(.Column) }),
            ("astype same", { $0.astype(.Double) }),
            ("astype", { $0.astype(.Float) }),
            ("to_contiguous", { $0.to_contiguous(mforder: .Column) }),
            ("deepcopy", { $0.deepcopy() }),
            ("clip", { Matft.clip($0, min: 1, max: 10) }),
            ("sort", { Matft.sort($0, order: .Descending) }),
            ("roll", { Matft.roll($0, shift: 1, axis: 0) }),
            ("concatenate", { Matft.concatenate([$0, $0], axis: 1) }),
            ("concatenate single", { Matft.concatenate([$0]) }),
            ("vstack", { Matft.vstack([$0]) }),
            ("hstack", { Matft.hstack([$0]) }),
            ("append", { Matft.append($0, values: $0, axis: 0) }),
            ("insert", { Matft.insert($0, indices: [1], value: 0.0, axis: 0) }),
            ("take", { Matft.take($0, indices: MfArray([0, 1]), axis: 0) }),
        ]
        for (name, f) in cases {
            let a = base()
            let c = f(a)
            let before = rowValues(c)
            c[Matft.all] = MfArray([-1] as [Double])
            XCTAssertEqual(rowValues(a), (0..<12).map { Double($0) }, name)
            XCTAssertNotEqual(rowValues(c), before, name)
        }
    }

    func testInputUnchanged() {
        // non-in-place calls on a view of a shared base must not change the base or the view
        let calls: [(String, (MfArray) -> MfArray)] = [
            ("sort", { Matft.sort($0, axis: 0, order: .Descending) }),
            ("argsort", { Matft.argsort($0, axis: nil) }),
            ("roll", { Matft.roll($0, shift: -1) }),
            ("clip", { Matft.clip($0, min: 2, max: 5) }),
            ("astype", { $0.astype(.Int) }),
            ("insert", { Matft.insert($0, indices: [0], value: 100.0) }),
            ("orderedUnique", { Matft.orderedUnique($0) }),
        ]
        for (name, f) in calls {
            let a = base()
            let view = Matft.flip(a[1~<3], axis: 1)
            let viewBefore = rowValues(view)
            _ = f(view)
            XCTAssertEqual(rowValues(a), (0..<12).map { Double($0) }, name)
            XCTAssertEqual(rowValues(view), viewBefore, name)
        }
    }

    func testBroadcastViewStridesAreZero() {
        // numpy: np.broadcast_to returns a read-only view with stride 0 on the broadcast axes
        let a = MfArray([1, 2, 3] as [Double])
        let b = Matft.broadcast_to(a, shape: [2, 3])
        XCTAssertTrue(b.isView)
        XCTAssertEqual(b.strides, [0, 1])
        // a copy made from it is independent and contiguous
        let c = b.to_contiguous(mforder: .Row)
        XCTAssertEqual(c.strides, [3, 1])
        c[0, 0] = MfArray([-1] as [Double])
        XCTAssertEqual(rowValues(a), [1, 2, 3])
        XCTAssertEqual(rowValues(c), [-1, 2, 3, 1, 2, 3])
    }
}
