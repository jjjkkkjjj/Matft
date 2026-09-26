import XCTest

import Matft

final class ArithmeticPefTests: XCTestCase {
    
    func testPeformanceAdd1() {
        let a = PerfFixtures.a
        let aneg = PerfFixtures.aneg
        
        self.measureWithWarmup {
            let _ = a+aneg
        }
    }
    
    func testPeformanceAdd2(){
        let a = PerfFixtures.a
        let aT = a.T
        let b = a.transpose(axes: [0,3,4,2,1,5])
        
        self.measureWithWarmup {
            let _ = b+aT
        }
    }

    func testPeformanceAdd3(){
        let a = PerfFixtures.a
        let aT = a.T
        let c = a.transpose(axes: [1,2,3,4,5,0])
        
        self.measureWithWarmup {
            let _ = c+aT
        }
    }
    
    func testPeformanceAddScalar1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a + Float(0.5)
        }
    }
}
