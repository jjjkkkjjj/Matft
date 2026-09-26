import XCTest

import Matft

final class ConversionPefTests: XCTestCase {
    
    func testPeformanceAstype1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a.astype(.Double)
        }
    }
    
    func testPeformanceDeepcopy1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = Matft.deepcopy(a)
        }
    }
    
    func testPeformanceReshape1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a.reshape([1000, 1000])
        }
    }
}
