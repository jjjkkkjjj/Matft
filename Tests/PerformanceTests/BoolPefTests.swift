//
//  BoolPefTests.swift
//  
//
//  Created by Junnosuke Kado on 2021/05/05.
//

// Performance tests for boolean operations disabled for WASM temporally
#if !os(WASI)
import XCTest

@testable import Matft

final class BoolPefTests: XCTestCase {
    
    func testPeformanceGreater1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a > 0
            }
            /*
             average: 0.005, relative standard deviation: 13.105%, values: [0.005919, 0.004773, 0.004801, 0.004345, 0.004045, 0.004657, 0.004171, 0.004112, 0.004063, 0.005502]
            4.63ms
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
             average: 0.018, relative standard deviation: 3.369%, values: [0.019256, 0.017742, 0.018757, 0.017547, 0.017825, 0.017720, 0.017430, 0.017445, 0.017328, 0.017551]
             17.8ms
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
             average: 0.005, relative standard deviation: 28.273%, values: [0.008474, 0.004336, 0.004922, 0.004191, 0.003911, 0.004051, 0.004746, 0.004058, 0.003964, 0.003893]
            4.65ms
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
             average: 0.020, relative standard deviation: 5.911%, values: [0.022530, 0.019385, 0.019731, 0.018503, 0.021188, 0.019174, 0.019055, 0.019295, 0.019675, 0.018707]
            19.7ms
             */
        }
    }
}

#endif