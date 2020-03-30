import XCTest
//@testable import Matft
import Matft

//Note that when performance test is conducted with other tests simultaneously, that will be caused to crash...
final class ArithmeticPefTests: XCTestCase {
    
    static var allTests = [
        ("testPefAdd1", testPefAdd1),
        ("testPefAdd2", testPefAdd2),
        ("testPefAdd3", testPefAdd3),
    ]
    
    func testPefAdd1() {
        do{
            let a = Matft.mfarray.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = Matft.mfarray.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a+b
            }
        }
    }
    
    func testPefAdd2(){
        do{
            let a = Matft.mfarray.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [0,3,4,2,1,5])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
        }
    }

    func testPefAdd3(){
        do{
            let a = Matft.mfarray.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [1,2,3,4,5,0])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
        }
    }
}
