//
//  BoolPefTests.swift
//
//
//  Created by Junnosuke Kado on 2021/05/05.
//

import XCTest
//@testable import Matft
import Matft

final class BoolPefTests: XCTestCase {
    /*
    func testPeformanceGreater1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a > 0
            }
            /*
             average: 0.005, relative standard deviation: 29.541%, values: [0.010153, 0.005457, 0.004667, 0.004294, 0.004840, 0.004900, 0.004404, 0.004938, 0.005424, 0.005643]
            5.47ms
             */
        }
    }
    
    func testPeformanceGreater2() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            let b = a.T
            self.measure {
                let _ = a > b
            }
            /*
             average: 0.013, relative standard deviation: 16.887%, values: [0.018914, 0.014113, 0.014571, 0.013467, 0.011153, 0.011144, 0.012473, 0.012131, 0.011092, 0.013995]
             13.3ms
             */
        }
    }
    */
    func testPeformanceEqual1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a === 0
            }
            /*
             average: 0.007, relative standard deviation: 34.558%, values: [0.012823, 0.006521, 0.006329, 0.004909, 0.005088, 0.004256, 0.005424, 0.006592, 0.007469, 0.006347]
            6.57ms
             */
        }
    }
    
    func testPeformanceEqual2() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            let b = a.T
            self.measure {
                let _ = a === b
            }
            /*
             average: 0.022, relative standard deviation: 13.122%, values: [0.030443, 0.023247, 0.023287, 0.020883, 0.021200, 0.020453, 0.019885, 0.020128, 0.022114, 0.021631]
            22.3ms
             */
        }
    }
}
