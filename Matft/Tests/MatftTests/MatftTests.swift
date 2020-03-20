import XCTest
@testable import Matft

final class MatftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let a = Matft.mfarray.arange(start: 0, stop: 27, step: 1)
        
        //XCTAssertEqual(Matft().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
