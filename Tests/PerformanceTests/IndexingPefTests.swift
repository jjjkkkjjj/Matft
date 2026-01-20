// Performance tests for boolean operations disabled for WASM temporally
#if !os(WASI)
import XCTest

@testable import Matft

final class IndexingPefTests: XCTestCase {
    
    func testPeformanceBooleanIndexing1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            let posb = a > 0
            self.measure {
                let _ = a[posb]
            }
            /*
             average: 0.001, relative standard deviation: 15.909%, values: [0.001687, 0.001327, 0.001296, 0.001292, 0.001237, 0.001028, 0.001093, 0.001108, 0.001045, 0.001029]
            1.21ms
             */
        }
    }
}
#endif
