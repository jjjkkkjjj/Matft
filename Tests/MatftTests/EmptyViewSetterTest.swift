import XCTest

import Matft

/// Empty views and setters, like numpy: an empty slice is still a view of its base, writing through it changes nothing,
/// and results built from an empty view hold no elements (a kernel copying `storedSize` elements of the base would).
/// The values over dtypes and layouts are in EmptyManipulationCoverageTest.swift
final class EmptyViewSetterTests: XCTestCase {
    /// [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]]
    private func base(_ mforder: MfOrder = .Row) -> MfArray {
        Matft.arange(start: 0, to: 12, by: 1, shape: [3, 4], mftype: .Double).to_contiguous(mforder: mforder)
    }

    func testEmptySlicesAreViews() {
        // numpy: a[1:1] and a[:, 2:2] are views (np.shares_memory(a, a[1:1]) is False only because they hold nothing)
        for mforder in [MfOrder.Row, .Column] {
            let a = base(mforder)
            let views: [(String, MfArray)] = [
                ("a[1~<1]", a[1~<1]),
                ("a[Matft.all, 2~<2]", a[Matft.all, 2~<2]),
                ("a[1~<1].T", a[1~<1].T),
                ("a.T[Matft.all, 3~<3]", a.T[Matft.all, 3~<3]),
                ("a[2~<2][Matft.reverse]", a[2~<2][Matft.reverse]),
            ]
            for (name, v) in views {
                XCTAssertTrue(v.isView, "\(name) \(mforder)")
                XCTAssertEqual(v.size, 0, "\(name) \(mforder)")
            }
        }
    }

    func testWritingThroughEmptyViewsChangesNothing() {
        // numpy: v = a[1:1]; v[...] = 7 leaves a unchanged
        let expected = (0..<12).map { Double($0) }
        let writes: [(String, (MfArray) -> Void)] = [
            ("a[1~<1] = 7", { $0[1~<1] = MfArray([7.0]) }),
            ("a[Matft.all, 2~<2] = 7", { $0[Matft.all, 2~<2] = MfArray([7.0]) }),
            ("v = a[1~<1]; v[0~<] = 7", { let v = $0[1~<1]; v[0~<] = MfArray([7.0]) }),
            ("v = a[Matft.all, 2~<2]; v[Matft.all, 0~<] = 7", { let v = $0[Matft.all, 2~<2]; v[Matft.all, 0~<] = MfArray([7.0]) }),
            ("v = a[1~<1].T; v[v > 0] = 7", { let v = $0[1~<1].T; v[v > 0] = MfArray([7.0]) }),
            ("v = a.T[Matft.all, 3~<3]; v[MfArray([0, 3])] = 7", { let v = $0.T[Matft.all, 3~<3]; v[MfArray([0, 3])] = MfArray([7.0]) }),
            ("a[a > 100] = 7", { $0[$0 > 100] = MfArray([7.0]) }),
            ("a[empty indices] = 7", { $0[MfArray([] as [Int], mftype: .Int, shape: [0])] = MfArray([7.0]) }),
            ("a[2~<2] = empty [0, 4]", { $0[2~<2] = MfArray([] as [Double], mftype: .Double, shape: [0, 4]) }),
        ]
        for mforder in [MfOrder.Row, .Column] {
            for (name, write) in writes {
                let a = base(mforder)
                write(a)
                XCTAssertEqual(rowValues(a), expected, "\(name) \(mforder)")
                XCTAssertEqual(a.mftype, .Double, "\(name) \(mforder)")
            }
        }
    }

    func testWritesNextToEmptyViewsOnlyTouchTheSelection() {
        // numpy: a[1:1] is empty, a[1:2] is the second row
        for mforder in [MfOrder.Row, .Column] {
            let a = base(mforder)
            let empty = a[1~<1]
            a[1~<2] = MfArray([-1.0])
            XCTAssertEqual(empty.shape, [0, 4])
            XCTAssertEqual(rowValues(a), [0, 1, 2, 3, -1, -1, -1, -1, 8, 9, 10, 11], "\(mforder)")
        }
    }

    func testResultsOfEmptyViewsHoldNothing() {
        // the empty views start inside a non-empty buffer, so a kernel that copies `storedSize` elements from the start pointer
        // returns the base's elements instead of an empty array
        for mforder in [MfOrder.Row, .Column] {
            let a = base(mforder)
            for (vname, v) in [("a[1~<1]", a[1~<1]), ("a[Matft.all, 2~<2]", a[Matft.all, 2~<2]), ("a[1~<1].T", a[1~<1].T)] {
                let results: [(String, MfArray)] = [
                    ("deepcopy", Matft.deepcopy(v)),
                    ("to_contiguous row", v.to_contiguous(mforder: .Row)),
                    ("to_contiguous column", v.to_contiguous(mforder: .Column)),
                    ("astype Float", v.astype(.Float)),
                    ("astype Int", v.astype(.Int)),
                    ("flatten", v.flatten()),
                    ("reshape", v.reshape([-1])),
                    ("roll", Matft.roll(v, shift: 1)),
                    ("clip", v.clip(min: 0.0, max: 1.0)),
                    ("negative", -v),
                    ("add", v + v),
                    ("compare", v > v),
                ]
                for (name, r) in results {
                    XCTAssertEqual(r.size, 0, "\(name) of \(vname) \(mforder)")
                    XCTAssertEqual(r.data.count, 0, "\(name) of \(vname) \(mforder)")
                    XCTAssertEqual(r.shape.reduce(1, *), 0, "\(name) of \(vname) \(mforder)")
                }
            }
            // the base is unchanged
            XCTAssertEqual(rowValues(a), (0..<12).map { Double($0) }, "\(mforder)")
        }
    }

    func testEmptyResultsCanBeUsedFurther() {
        // chaining ops after an empty result must keep working: numpy np.concatenate([a[1:1], a]) etc.
        let a = base()
        let e = a[1~<1]
        XCTAssertClose(Matft.concatenate([e, a, e], axis: 0), a, rtol: 0, atol: 0, checkType: true)
        XCTAssertClose(Matft.vstack([e.to_contiguous(mforder: .Column), a]), a, rtol: 0, atol: 0, checkType: true)
        XCTAssertClose(Matft.hstack([a[Matft.all, 2~<2], a]), a, rtol: 0, atol: 0, checkType: true)
        XCTAssertEqual(Matft.expand_dims(e, axis: 0).T.shape, [4, 0, 1])
        XCTAssertEqual((e.T + MfArray([[1.0]])).shape, [4, 0])
        XCTAssertEqual(Matft.broadcast_to(e[Matft.all, 0~<1], shape: [2, 0, 1]).shape, [2, 0, 1])
    }

    func testToArrayOfEmpty() {
        // numpy: np.zeros(0).tolist() -> [], np.zeros((3, 0)).tolist() -> [[], [], []], np.zeros((0, 4)).tolist() -> []
        XCTAssertEqual(MfArray([] as [Double], mftype: .Double, shape: [0]).toArray().count, 0)
        let rows = MfArray([] as [Double], mftype: .Double, shape: [3, 0]).toArray()
        XCTAssertEqual(rows.count, 3)
        for row in rows {
            XCTAssertEqual((row as! [Any]).count, 0)
        }
        XCTAssertEqual(MfArray([] as [Double], mftype: .Double, shape: [0, 4]).toArray().count, 0)
        let nested = MfArray([] as [Int], mftype: .Int, shape: [2, 0, 3]).toArray()
        XCTAssertEqual(nested.count, 2)
        XCTAssertEqual((nested[0] as! [Any]).count, 0)
        XCTAssertEqual(base()[Matft.all, 2~<2].toArray().count, 3)
    }
}
