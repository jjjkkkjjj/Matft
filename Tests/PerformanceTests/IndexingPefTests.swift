// Performance tests for boolean operations disabled for WASM temporally
import XCTest

import Matft

final class IndexingPefTests: XCTestCase {
    
    func testPeformanceBooleanIndexing1() {
        let a = PerfFixtures.a
        let posb = a > 0
        
        self.measureWithWarmup {
            let _ = a[posb]
        }
    }
    
    func testPeformanceBooleanIndexing2() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a[a > 0]
        }
    }
    
    // not row contiguous source
    func testPeformanceBooleanIndexing3() {
        let aT = PerfFixtures.a.T
        self.measureWithWarmup {
            let _ = aT[aT > 0]
        }
    }
}
