import XCTest

import Matft

final class StatsPefTests: XCTestCase {
    
    func testPeformanceMean1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a.mean()
        }
    }
    
    func testPeformanceCumsum1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = Matft.stats.cumsum(a, axis: 0)
        }
    }
    
    func testPeformanceCumsum2() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = Matft.stats.cumsum(a, axis: 5)
        }
    }
    
    func testPeformanceCumsum3() {
        let v = PerfFixtures.v
        self.measureWithWarmup {
            let _ = Matft.stats.cumsum(v)
        }
    }
    
    func testPeformanceArgmax1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a.argmax(axis: 5)
        }
    }
    
    func testPeformanceArgmax2() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a.argmax(axis: 0)
        }
    }
}
