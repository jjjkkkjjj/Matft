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
             '-[PerformanceTests.IndexingPefTests testPeformanceBooleanIndexing1]' measured [Time, seconds] average: 0.008, relative standard deviation: 38.855%, values: [0.017263, 0.007442, 0.007837, 0.006746, 0.006820, 0.007230, 0.006740, 0.006502, 0.006838, 0.006634]
            8.00ms
             */
        }
    }
}
