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
             average: 0.003, relative standard deviation: 14.938%, values: [0.004529, 0.003927, 0.003320, 0.003287, 0.003101, 0.002959, 0.003091, 0.002964, 0.002963, 0.002959]
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
             average: 0.011, relative standard deviation: 14.907%, values: [0.015954, 0.010788, 0.010796, 0.010536, 0.010265, 0.010362, 0.010551, 0.010372, 0.010643, 0.010206]
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
             average: 0.005, relative standard deviation: 9.034%, values: [0.006524, 0.005876, 0.005703, 0.004927, 0.005378, 0.005505, 0.004791, 0.005208, 0.005357, 0.004975]
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
             average: 0.013, relative standard deviation: 12.651%, values: [0.015696, 0.014966, 0.015348, 0.014442, 0.012155, 0.011975, 0.011820, 0.012067, 0.011779, 0.011114]
             */
        }
    }
}
