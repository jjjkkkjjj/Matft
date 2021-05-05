import XCTest
//@testable import Matft
import Matft

final class ArithmeticPefTests: XCTestCase {
    
    func testPeformanceAdd1() {
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let aneg = Matft.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a+aneg
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd1]' measured [Time, seconds] average: 0.001, relative standard deviation: 28.260%, values: [0.001494, 0.000943, 0.000886, 0.000997, 0.000728, 0.000799, 0.000710, 0.000830, 0.000708, 0.000543]
            863μs
             */
        }
    }
    
    func testPeformanceAdd2(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let aT = a.T
            let b = a.transpose(axes: [0,3,4,2,1,5])
            
            self.measure {
                let _ = b+aT
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd2]' measured [Time, seconds] average: 0.004, relative standard deviation: 16.601%, values: [0.005048, 0.004253, 0.004364, 0.004945, 0.003621, 0.003685, 0.003902, 0.005843, 0.005326, 0.003692],
            4.47ms
             */
        }
    }

    func testPeformanceAdd3(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let aT = a.T
            let c = a.transpose(axes: [1,2,3,4,5,0])
            
            self.measure {
                let _ = c+aT
            }
            /*
             average: 0.005, relative standard deviation: 17.583%, values: [0.007990, 0.005514, 0.004973, 0.004960, 0.004900, 0.004848, 0.005003, 0.005239, 0.005113, 0.004468]
            5.30ms
             */
        }
    }
}

