//
//  ConversionTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/12.
//

import XCTest
import Matft

final class ConversionTest: XCTestCase {
    func testAsType(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                [1, 5, -2]])
            
            XCTAssertEqual(a.astype(newtype: Float.self),
                           MfArray<Float>([[2.0, -7.0, 0.0],
                                            [1.0, 5.0, -2.0]] as [[Float]]))
            
            XCTAssertEqual(a.astype(newtype: Double.self),
                           MfArray<Double>([[2.0, -7.0, 0.0],
                                            [1.0, 5.0, -2.0]] as [[Double]]))
            
            XCTAssertEqual(a.astype(newtype: UInt8.self),
                           MfArray<UInt8>([[2, 249, 0],
                                            [1, 5, 254]] as [[UInt8]]))
        }
    }
}
