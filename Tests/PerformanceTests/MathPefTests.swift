// Performance tests for boolean operations disabled for WASM temporally
#if !os(WASI)
//
//  MathPefTests.swift
//  
//
//  Created by Junnosuke Kado on 2021/05/05.
//

import XCTest

@testable import Matft

final class MathPefTests: XCTestCase {
    
    func testPeformanceSin1() {
        do{
            let a = Matft.arange(start: -10*10*10*10*10*5, to: 10*10*10*10*10*5, by: 1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = Matft.math.sin(a)
            }
            /*
             average: 0.002, relative standard deviation: 19.882%, values: [0.003021, 0.002398, 0.002378, 0.002091, 0.002353, 0.002307, 0.002038, 0.001660, 0.001598, 0.001587],
            2.14ms
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
             average: 0.007, relative standard deviation: 15.104%, values: [0.009838, 0.007075, 0.006724, 0.006179, 0.006817, 0.006001, 0.006269, 0.007070, 0.006485, 0.007783]
            7.02ms
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
             average: 0.003, relative standard deviation: 23.996%, values: [0.004978, 0.003791, 0.003449, 0.002882, 0.002869, 0.002630, 0.002463, 0.002636, 0.002756, 0.002520]
            3.09ms
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
             average: 0.008, relative standard deviation: 13.671%, values: [0.010916, 0.007980, 0.007547, 0.007210, 0.007323, 0.007931, 0.007168, 0.009037, 0.009036, 0.009219]
            8.33ms
             */
        }
    }
}
#endif

