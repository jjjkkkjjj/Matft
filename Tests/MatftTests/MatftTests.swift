import XCTest
import Matft

final class MatftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        //addTest()
        let c = Matft.mfarray.arange(start: 0, stop: 10*10*10*10*10*10, step: 1, shape: [10,10,10,10,10,10])
        let d = c.transpose()
        let e = c.transpose(axes: [1,2,3,4,5,0])
        
        self.measure {
            let e = d+e
        }
        //XCTAssertEqual(Matft().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}


func addTest(){
    let a = MfArray([1,2,3])
    let b = MfArray([[1,2,3],[4,5,6]])
    
    let c = Matft.mfarray.arange(start: 0, stop: 10*10*10*10*10*10, step: 1, shape: [10,10,10,10,10,10])
    let d = c.transpose()
    let e = c.transpose(axes: [1,2,3,4,5,0])
    
    let _ = d+e
}
