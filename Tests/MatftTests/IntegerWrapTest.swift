import XCTest

import Matft

/// Integer values are stored as Float, so results out of the type's range are wrapped around
/// when they are read (`data`, `==`) like numpy's fixed width integers
final class IntegerWrapTests: XCTestCase {

    func testUInt8(){
        let a = MfArray([0, 1, 200], mftype: .UInt8)
        let b = MfArray([5, 1, 100], mftype: .UInt8)
        // numpy: [251, 0, 100], [10, 3, 144], [5, 3, 244]
        XCTAssertEqual((a - b).data as! [UInt8], [251, 0, 100])
        XCTAssertEqual((a + b + b).data as! [UInt8], [10, 3, 144])
        XCTAssertEqual((a + a + b).data as! [UInt8], [5, 3, 244])

        // different values are never equal
        XCTAssertFalse(MfArray([0], mftype: .UInt8) == MfArray([5], mftype: .UInt8))
        XCTAssertFalse(MfArray([5], mftype: .UInt8) == MfArray([0], mftype: .UInt8))
        XCTAssertTrue(a - b == MfArray([251, 0, 100], mftype: .UInt8))
        XCTAssertFalse(a - b == MfArray([250, 0, 100], mftype: .UInt8))
    }

    func testUInt16(){
        let a = MfArray([0, 60000], mftype: .UInt16)
        let b = MfArray([5, 10000], mftype: .UInt16)
        // numpy: [65531, 50000], [5, 4464]
        XCTAssertEqual((a - b).data as! [UInt16], [65531, 50000])
        XCTAssertEqual((a + b).data as! [UInt16], [5, 4464])
        XCTAssertFalse(MfArray([0], mftype: .UInt16) == MfArray([5], mftype: .UInt16))
    }

    func testUInt32(){
        let a = MfArray([0], mftype: .UInt32)
        let b = MfArray([5], mftype: .UInt32)
        // numpy: [4294967291]
        XCTAssertEqual((a - b).data as! [UInt32], [4294967291])
    }

    func testSigned(){
        let a = MfArray([100, -100], mftype: .Int8)
        // numpy: [-56, 56]
        XCTAssertEqual((a + a).data as! [Int8], [-56, 56])
        let b = MfArray([30000], mftype: .Int16)
        // numpy: [-25536]
        XCTAssertEqual((b + MfArray([10000], mftype: .Int16)).data as! [Int16], [-25536])
        XCTAssertFalse(MfArray([1], mftype: .Int8) == MfArray([2], mftype: .Int8))
    }

    func testCompareAfterWrap(){
        let a = MfArray([0, 1, 200], mftype: .UInt8)
        let b = MfArray([5, 1, 100], mftype: .UInt8)
        let d = a - b // [251, 0, 100]
        // numpy: d > 250 -> [True, False, False], d == 251 -> [True, False, False], d < 5 -> [False, True, False]
        XCTAssertEqual((d > 250).data as! [Bool], [true, false, false])
        XCTAssertEqual((d === 251).data as! [Bool], [true, false, false])
        XCTAssertEqual((d < 5).data as! [Bool], [false, true, false])
        // numpy: d > b -> [True, False, False]
        XCTAssertEqual((d > b).data as! [Bool], [true, false, false])

        let i = MfArray([100, -100], mftype: .Int8)
        // numpy: (i + i) < 0 -> [True, False]
        XCTAssertEqual(((i + i) < 0).data as! [Bool], [true, false])
    }

    func testReduceAfterWrap(){
        let a = MfArray([0, 1, 200], mftype: .UInt8)
        let b = MfArray([5, 1, 100], mftype: .UInt8)
        let d = a - b // [251, 0, 100]
        // numpy: d.max() -> 251, d.min() -> 0, d.argmax() -> 0, np.sort(d) -> [0, 100, 251]
        XCTAssertEqual(d.max().scalar as! UInt8, 251)
        XCTAssertEqual(d.min().scalar as! UInt8, 0)
        XCTAssertEqual(d.argmax().scalar as! Int, 0)
        XCTAssertEqual(d.sort().data as! [UInt8], [0, 100, 251])
        // numpy: d.mean() -> 117.0
        XCTAssertEqual(d.mean().scalar as! Float, 117, accuracy: 1e-5)
        // numpy: d.astype(np.float32) -> [251, 0, 100]
        XCTAssertEqual(d.astype(.Float).data as! [Float], [251, 0, 100])

        let i = MfArray([100, -100], mftype: .Int8)
        // numpy: (i + i).max() -> 56
        XCTAssertEqual((i + i).max().scalar as! Int8, 56)
    }

    func testMultiplyWrap(){
        let a = MfArray([0, 1, 200], mftype: .UInt8)
        let b = MfArray([5, 1, 100], mftype: .UInt8)
        // numpy: a * b -> [0, 1, 32]
        XCTAssertEqual((a * b).data as! [UInt8], [0, 1, 32])
        XCTAssertEqual(((a * b) > 30).data as! [Bool], [false, false, true])
    }
}
