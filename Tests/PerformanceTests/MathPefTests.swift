//
//  MathPefTests.swift
//  
//
//  Created by Junnosuke Kado on 2021/05/05.
//

import XCTest
//@testable import Matft
import Matft

final class MathPefTests: XCTestCase {
    
    func testPeformanceSin1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = Matft.math.sin(a)
            }
            /*
             average: 0.002, relative standard deviation: 16.693%, values: [0.002076, 0.002134, 0.002175, 0.001475, 0.001616, 0.002272, 0.001525, 0.001551, 0.001567, 0.001645],
            1.80ms
             */
        }
    }
    
    func testPeformanceSin2() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [0,3,4,2,1,5])
            self.measure {
                let _ = Matft.math.sin(b)
            }
            /*
             0.008, relative standard deviation: 12.702%, values: [0.010386, 0.006988, 0.008064, 0.007728, 0.007327, 0.008012, 0.008144, 0.009945, 0.008369, 0.007425]
            8.24ms
             */
        }
    }
    
    func testPeformanceSign1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = Matft.math.sign(a)
            }
            /*
             average: 0.030, relative standard deviation: 7.006%, values: [0.030391, 0.028586, 0.026669, 0.027902, 0.031177, 0.029743, 0.032523, 0.034133, 0.031864, 0.030903]
            30.4ms
             */
        }
    }
    
    func testPeformanceSign2() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [0,3,4,2,1,5])
            self.measure {
                let _ = Matft.math.sign(b)
            }
            /*
             average: 0.036, relative standard deviation: 12.528%, values: [0.035343, 0.033219, 0.037924, 0.044944, 0.042078, 0.032277, 0.032339, 0.034491, 0.032207, 0.030740]
            35.6ms
             */
        }
    }
}


