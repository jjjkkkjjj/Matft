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
             '-[PerformanceTests.IndexingPefTests testPeformanceBooleanIndexing1]' measured [Time, seconds] average: 0.005, relative standard deviation: 37.720%, values: [0.010294, 0.004666, 0.004402, 0.004150, 0.004102, 0.004048, 0.004186, 0.004013, 0.004319, 0.004240]
            4.84ms
             */
        }
    }
}

