import XCTest
//@testable import Matft
import Matft

final class ArithmeticPefTests: XCTestCase {
    
    static var allTests = [
        ("testSameShape", testAdd),
    ]
    
    func testAdd() {
        do{
            let a = Matft.mfarray.arange(start: 0, stop: 10*10*10*10*10*10, step: 1, shape: [10,10,10,10,10,10])
            let b = Matft.mfarray.arange(start: -1, stop: -10*10*10*10*10*10, step: -1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a+b
            }
        }

        do{
            let a = Matft.mfarray.arange(start: 0, stop: 10*10*10*10*10*10, step: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [0,3,4,2,1,5])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
        }
        
        do{
            let a = Matft.mfarray.arange(start: 0, stop: 10*10*10*10*10*10, step: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [1,2,3,4,5,0])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
        }
    }
    

    
}
