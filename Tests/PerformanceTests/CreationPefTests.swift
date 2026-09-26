import XCTest

import Matft

final class CreationPefTests: XCTestCase {
    
    func testPeformanceNested1() {
        let nested = PerfFixtures.nested
        self.measureWithWarmup {
            let _ = MfArray(nested)
        }
    }
    
    func testPeformanceNums1() {
        self.measureWithWarmup {
            let _ = Matft.nums(Float(1), shape: [1000, 1000])
        }
    }
}
