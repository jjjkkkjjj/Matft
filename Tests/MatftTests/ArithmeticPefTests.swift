import XCTest
//@testable import Matft
import Matft


//Note that sometimes when performance test is conducted with other tests simultaneously, that will be caused to crash...
final class ArithmeticPefTests: XCTestCase {
    
    static var allTests = [
        ("testPeformanceAdd1", testPeformanceAdd1),
        ("testPeformanceAdd2", testPeformanceAdd2),
        ("testPeformanceAdd3", testPeformanceAdd3),
    ]
    
    func testPeformanceAdd1() {
        do{
            let a = Matft.mfarray.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = Matft.mfarray.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a+b
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd1]' measured [Time, seconds] average: 0.001, relative standard deviation: 23.418%, values: [0.001707, 0.001141, 0.000999, 0.000969, 0.001029, 0.000979, 0.001031, 0.000986, 0.000963, 0.001631]
            1.14ms
             */
        }
    }
    
    func testPeformanceAdd2(){
        do{
            let a = Matft.mfarray.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [0,3,4,2,1,5])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd2]' measured [Time, seconds] average: 0.004, relative standard deviation: 5.842%, values: [0.004680, 0.003993, 0.004159, 0.004564, 0.003955, 0.004200, 0.003998, 0.004317, 0.003919, 0.004248]
            4.20ms
             */
        }
    }

    func testPeformanceAdd3(){
        do{
            let a = Matft.mfarray.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [1,2,3,4,5,0])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd3]' measured [Time, seconds] average: 0.004, relative standard deviation: 16.815%, values: [0.004906, 0.003785, 0.003702, 0.005981, 0.004261, 0.003665, 0.004083, 0.003654, 0.003836, 0.003874]
            4.17ms
             */
        }
    }
}


