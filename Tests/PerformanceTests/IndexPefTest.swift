import XCTest
//@testable import Matft
import Matft

final class IndexingPefTests: XCTestCase {
    
    func testPeformanceBooleanIndexing1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            let posb = a > 0
            self.measure {
                let _ = a[posb]
            }
            /*
             average: 0.001, relative standard deviation: 15.756%, values: [0.001506, 0.000995, 0.000926, 0.000909, 0.001114, 0.001096, 0.001230, 0.000987, 0.000973, 0.001032]
            1.07ms
             */
        }
    }
}
