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
    
    func testPeformanceFancyIndexing1() {
        let a = PerfFixtures.a
        let idx = PerfFixtures.idx
        self.measureWithWarmup {
            let _ = a[idx]
        }
    }
    
    func testPeformanceBoolSetter1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let x = Matft.deepcopy(a)
            x[x > 0] = MfArray([0])
        }
    }
    
    func testPeformanceBoolSetter2() {
        let a = PerfFixtures.a
        let posb = a > 0
        let values = a[posb]
        self.measureWithWarmup {
            let x = Matft.deepcopy(a)
            x[posb] = values
        }
    }
    
    // not row contiguous target
    func testPeformanceBoolSetter3() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let x = Matft.deepcopy(a).T
            x[x > 0] = MfArray([0])
        }
    }
}
