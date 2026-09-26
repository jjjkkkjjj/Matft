import XCTest

import Matft

final class LinAlgPefTests: XCTestCase {
    
    func testPeformanceInv1() {
        let m = PerfFixtures.m
        self.measureWithWarmup {
            let _ = try! Matft.linalg.inv(m)
        }
    }
}
