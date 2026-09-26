import XCTest

import Matft

final class StatsPefTests: XCTestCase {
    
    func testPeformanceMean1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a.mean()
        }
    }
}
