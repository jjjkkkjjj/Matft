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
             '-[PerformanceTests.IndexingPefTests testPeformanceBooleanIndexing1]' measured [Time, seconds] average: 0.007, relative standard deviation: 17.050%, values: [0.010224, 0.007128, 0.006454, 0.007535, 0.006929, 0.006481, 0.006221, 0.006312, 0.006142, 0.006018]
            7ms
             */
        }
    }
}

