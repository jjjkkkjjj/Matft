import XCTest
//@testable import Matft
import Matft

final class ArithmeticPefTests: XCTestCase {
    
    func testPeformanceAdd1() {
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = Matft.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a+b
            }
            /*
             '-[PerformanceTests.ArithmeticPefTests testPeformanceAdd1]' measured [Time, seconds] average: 0.001, relative standard deviation: 20.535%, values: [0.001553, 0.001149, 0.000915, 0.000818, 0.000968, 0.001011, 0.000988, 0.000873, 0.000793, 0.001095]
            1.01ms
             */
        }
    }
    
    func testPeformanceAdd2(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [0,3,4,2,1,5])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
            /*
             '-[PerformanceTests.ArithmeticPefTests testPeformanceAdd2]' measured [Time, seconds] average: 0.005, relative standard deviation: 10.173%, values: [0.006353, 0.006614, 0.005028, 0.005030, 0.005173, 0.005078, 0.005270, 0.005182, 0.005163, 0.005109]
            5.40ms
             */
        }
    }

    func testPeformanceAdd3(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [1,2,3,4,5,0])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
            /*
             '-[PerformanceTests.ArithmeticPefTests testPeformanceAdd3]' measured [Time, seconds] average: 0.005, relative standard deviation: 13.939%, values: [0.007165, 0.005703, 0.005128, 0.004764, 0.004865, 0.006081, 0.005096, 0.004979, 0.004849, 0.004653],
            5.32ms
             */
        }
    }
}

