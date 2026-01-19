#if !OS(WASI)
import XCTest

@testable import Matft

final class ArithmeticPefTests: XCTestCase {
    
    func testPeformanceAdd1() {
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let aneg = Matft.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a+aneg
            }
            /*
             average: 0.001, relative standard deviation: 29.440%, values: [0.001123, 0.000550, 0.000536, 0.000530, 0.000527, 0.000536, 0.000531, 0.000529, 0.000570, 0.000537]
            596μs
             */
        }
    }
    
    func testPeformanceAdd2(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let aT = a.T
            let b = a.transpose(axes: [0,3,4,2,1,5])
            
            self.measure {
                let _ = b+aT
            }
            /*
             'average: 0.004, relative standard deviation: 15.791%, values: [0.004821, 0.003964, 0.003851, 0.004885, 0.003652, 0.003740, 0.003728, 0.005234, 0.005280, 0.005492]
            4.46ms
             */
        }
    }

    func testPeformanceAdd3(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let aT = a.T
            let c = a.transpose(axes: [1,2,3,4,5,0])
            
            self.measure {
                let _ = c+aT
            }
            /*
             average: 0.005, relative standard deviation: 21.654%, values: [0.008364, 0.005223, 0.004903, 0.005531, 0.004377, 0.004365, 0.005575, 0.005891, 0.004486, 0.004401]
            5.31ms
             */
        }
    }
}
