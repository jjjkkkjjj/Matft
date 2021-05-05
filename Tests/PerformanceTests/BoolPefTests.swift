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
             average: 0.007, relative standard deviation: 42.315%, values: [0.015937, 0.005105, 0.005490, 0.006968, 0.006461, 0.005805, 0.006472, 0.005748, 0.009101, 0.005661]
            7.27ms
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
             average: 0.022, relative standard deviation: 13.122%, values: [0.030443, 0.023247, 0.023287, 0.020883, 0.021200, 0.020453, 0.019885, 0.020128, 0.022114, 0.021631]
            22.3ms
             */
        }
    }
}

