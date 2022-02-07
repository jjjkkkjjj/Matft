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
             average: 0.003, relative standard deviation: 24.007%, values: [0.005204, 0.003871, 0.003393, 0.003030, 0.003063, 0.002735, 0.002716, 0.002659, 0.002650, 0.002658]
            3.20ms
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
             average: 0.003, relative standard deviation: 20.959%, values: [0.004195, 0.003275, 0.003214, 0.002595, 0.002604, 0.002686, 0.002267, 0.002244, 0.002492, 0.002268]
            2.78ms
             */
        }
    }
}


