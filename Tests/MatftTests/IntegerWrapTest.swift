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
}
