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
    
    func testPeformanceGreater1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a > 0
            }
            /*
             average: 0.005, relative standard deviation: 21.157%, values: [0.008025, 0.005333, 0.004917, 0.005099, 0.004411, 0.004362, 0.004531, 0.004916, 0.004222, 0.004360]
            5.01ms
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
    
    func testPeformanceEqual1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a === 0
            }
            /*
             'average: 0.010, relative standard deviation: 28.372%, values: [0.018112, 0.008027, 0.009588, 0.008938, 0.009636, 0.008126, 0.009601, 0.008486, 0.010103, 0.008544]
            9.91ms
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
             average: 0.018, relative standard deviation: 4.942%, values: [0.019387, 0.017090, 0.019169, 0.017611, 0.017275, 0.018815, 0.016749, 0.017909, 0.018322, 0.017130]
            22.3ms
             */
        }
    }
}

