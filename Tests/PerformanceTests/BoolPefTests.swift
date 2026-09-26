//
//  BoolPefTests.swift
//  
//
//  Created by Junnosuke Kado on 2021/05/05.
//

// Performance tests for boolean operations disabled for WASM temporally
import XCTest

import Matft

final class BoolPefTests: XCTestCase {
    
    func testPeformanceGreater1() {
        let a = PerfFixtures.a
        
        self.measureWithWarmup {
            let _ = a > 0
        }
    }
    
    func testPeformanceGreaterDouble1() {
        let ad = PerfFixtures.ad
        self.measureWithWarmup {
            let _ = ad > 0
        }
    }
    
    func testPeformanceGreater2() {
        let a = PerfFixtures.a
        let b = a.transpose(axes: [0,3,4,2,1,5])
        
        self.measureWithWarmup {
            let _ = a > b
        }
    }
    
    func testPeformanceEqual1() {
        let a = PerfFixtures.a
        
        self.measureWithWarmup {
            let _ = a === 0
        }
    }
    
    func testPeformanceEqual2() {
        let a = PerfFixtures.a
        let b = a.transpose(axes: [0,3,4,2,1,5])
        
        self.measureWithWarmup {
            let _ = a === b
        }
    }
    
    func testPeformanceEqual3() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a === 5
        }
    }
    
    func testPeformanceNotEqual1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a !== 0
        }
    }
    
    func testPeformanceLogicalNot1() {
        let posb = PerfFixtures.a > 0
        self.measureWithWarmup {
            let _ = Matft.logical_not(posb)
        }
    }
    
    func testPeformanceAllEqual1() {
        let a = PerfFixtures.a
        self.measureWithWarmup {
            let _ = a == a
        }
    }
}
