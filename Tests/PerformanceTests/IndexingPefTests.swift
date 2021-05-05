import XCTest
//@testable import Matft
import Matft

final class IndexingPefTests: XCTestCase {
    
    func testPeformanceBooleanIndexing1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a[a>0]
            }
            /*
             '-[PerformanceTests.IndexingPefTests testPeformanceBooleanIndexing1]' measured [Time, seconds] average: 0.003, relative standard deviation: 36.534%, values: [0.006049, 0.003468, 0.002757, 0.002517, 0.002827, 0.002821, 0.002513, 0.002312, 0.002275, 0.002172]
            2.97ms
             */
        }
    }
}

