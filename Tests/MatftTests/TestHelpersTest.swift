import XCTest

import Matft

final class TestHelpersTests: XCTestCase {

    func testLayoutVariants(){
        let a = MfArray([[1, -2, 3], [4, 5, -6]] as [[Int]])
        for (name, x) in layoutVariants(a){
            XCTAssertEqual(x.shape, [2, 3], name)
            XCTAssertEqual(x.mftype, .Int, name)
            XCTAssertEqual(rowValues(x), [1, -2, 3, 4, 5, -6], name)
        }
        let names = layoutVariants(a).map{ $0.name }
        XCTAssertEqual(names.count, 7)
        // views keep the data of their bases
        let variants = Dictionary(uniqueKeysWithValues: layoutVariants(a))
        XCTAssertEqual(variants["offset view"]!.offsetIndex, 3)
        XCTAssertEqual(variants["prefix view"]!.storedSize, 9)
        XCTAssertEqual(variants["reversed view"]!.strides[0], -3)

        let b = MfArray([1.5, 2.5, 3.5] as [Float])
        for (name, x) in layoutVariants(b){
            XCTAssertEqual(rowValues(x), [1.5, 2.5, 3.5], name)
        }
    }

    #if !os(WASI) // XCTExpectFailure is not available
    func testAssertClose(){
        XCTAssertClose(MfArray([1.0, Double.nan, Double.infinity]), MfArray([1.0 + 1e-9, Double.nan, Double.infinity]), rtol: 1e-8)
        XCTExpectFailure("not close"){
            XCTAssertClose(MfArray([1.0, 2.0]), MfArray([1.0, 2.1]))
        }
        XCTExpectFailure("NaN mismatch"){
            XCTAssertClose(MfArray([1.0, 2.0]), MfArray([1.0, Double.nan]))
        }
        XCTExpectFailure("type mismatch"){
            XCTAssertClose(MfArray([1, 2]), MfArray([1.0, 2.0]), checkType: true)
        }
    }
    #endif
}
