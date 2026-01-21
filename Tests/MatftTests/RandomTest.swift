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
        // Use smaller array size on WASM to avoid memory pressure
        // 100x100x100 = 1M elements = 4MB per array, too much for WASM
        // Smaller sample size requires wider tolerance for mean (higher variance)
        #if os(WASI)
        let shape = [10, 10, 10]  // 1K elements
        let tolerance: Float = 0.10  // Wider bounds for smaller sample
        #else
        let shape = [100, 100, 100]  // 1M elements
        let tolerance: Float = 0.02  // Tight bounds for large sample
        #endif

        let a = Matft.random.rand(shape: shape)
        let mean_a = a.mean().scalar as! Float
        let cond_a = (Float(0.5 - tolerance) < mean_a) && (mean_a < Float(0.5 + tolerance))

        let b = Matft.random.rand(shape: shape)
        let mean_b = b.mean().scalar as! Float
        let cond_b = (Float(0.5 - tolerance) < mean_b) && (mean_b < Float(0.5 + tolerance))

        XCTAssertTrue(cond_a, "The result may be failure due to random generation")
        XCTAssertTrue(cond_b, "The result may be failure due to random generation")

        XCTAssertNotEqual(a, b,"The result may be failure due to random generation")
    }

    func testRandint() {
        // Use smaller array size on WASM to avoid memory pressure
        // Smaller sample size requires wider tolerance for mean (higher variance)
        #if os(WASI)
        let shape = [10, 10, 10]  // 1K elements
        let tolerance: Float = 0.50  // Wider bounds for smaller sample
        #else
        let shape = [100, 100, 100]  // 1M elements
        let tolerance: Float = 0.02  // Tight bounds for large sample
        #endif

        let a = Matft.random.randint(low: 0, high: 10, shape: shape)
        let mean_a = a.mean().scalar as! Float
        let cond_a = (Float(4.5 - tolerance) < mean_a) && (mean_a < Float(4.5 + tolerance))

        let b = Matft.random.randint(low: 0, high: 10, shape: shape)
        let mean_b = b.mean().scalar as! Float
        let cond_b = (Float(4.5 - tolerance) < mean_b) && (mean_b < Float(4.5 + tolerance))

        XCTAssertTrue(cond_a, "The result may be failure due to random generation")
        XCTAssertTrue(cond_b, "The result may be failure due to random generation")

        XCTAssertNotEqual(a, b,"The result may be failure due to random generation")
    }
}
