//
//  MathPefTests.swift
//  
//
//  Created by Junnosuke Kado on 2021/05/05.
//

import XCTest

import Matft

final class MathPefTests: XCTestCase {
    
    func testPeformanceSin1() {
        let a = PerfFixtures.a
        
        self.measure {
            let _ = Matft.math.sin(a)
        }
    }
    
    func testPeformanceSin2() {
        let a = PerfFixtures.a
        let b = a.transpose(axes: [0,3,4,2,1,5])
        
        self.measure {
            let _ = Matft.math.sin(b)
        }
    }
    
    func testPeformanceSign1() {
        let a = PerfFixtures.a
        
        self.measure {
            let _ = Matft.math.sign(a)
        }
    }
    
    func testPeformanceSign2() {
        let a = PerfFixtures.a
        let b = a.transpose(axes: [0,3,4,2,1,5])
        
        self.measure {
            let _ = Matft.math.sign(b)
        }
    }
}
