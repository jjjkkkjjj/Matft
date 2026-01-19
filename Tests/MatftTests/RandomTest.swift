//
//  RandomTest.swift
//  
//
//  Created by Junnosuke Kado on 2021/07/31.
//

import XCTest

@testable import Matft

final class RandomTests: XCTestCase {
    func testRand() {
        let a = Matft.random.rand(shape: [100, 100, 100])
        let mean_a = a.mean().scalar as! Float
        let cond_a = (Float(0.48) < mean_a) && (mean_a < Float(0.52))
        
        let b = Matft.random.rand(shape: [100, 100, 100])
        let mean_b = b.mean().scalar as! Float
        let cond_b = (Float(0.48) < mean_b) && (mean_b < Float(0.52))
        
        XCTAssertTrue(cond_a, "The result may be failure due to random generation")
        XCTAssertTrue(cond_b, "The result may be failure due to random generation")
        
        XCTAssertNotEqual(a, b,"The result may be failure due to random generation")
    }
    
    func testRandint() {
        let a = Matft.random.randint(low: 0, high: 10, shape: [100, 100, 100])
        let mean_a = a.mean().scalar as! Float
        let cond_a = (Float(4.48) < mean_a) && (mean_a < Float(4.52))
        
        let b = Matft.random.randint(low: 0, high: 10, shape: [100, 100, 100])
        let mean_b = b.mean().scalar as! Float
        let cond_b = (Float(4.48) < mean_b) && (mean_b < Float(4.52))
        
        XCTAssertTrue(cond_a, "The result may be failure due to random generation")
        XCTAssertTrue(cond_b, "The result may be failure due to random generation")
        
        XCTAssertNotEqual(a, b,"The result may be failure due to random generation")
    }
}
