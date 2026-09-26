// Performance tests for boolean operations disabled for WASM temporally
import XCTest

import Matft

final class IndexingPefTests: XCTestCase {
    
    func testPeformanceBooleanIndexing1() {
        let a = PerfFixtures.a
        let posb = a > 0
        
        self.measure {
            let _ = a[posb]
        }
    }
    
    func testPeformanceBooleanIndexing2() {
        let a = PerfFixtures.a
        self.measure {
            let _ = a[a > 0]
        }
    }
}
