//
//  MatftTests.swift
//  MatftTests
//
//  Created by AM19A0 on 2019/12/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import XCTest
@testable import Matft

class MatftTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let arr22 = try! MfArray([[[ 0,  8],
                                   [ 4, 12]],
            
                                  [[ 1,  9],
                                   [ 5, 13]],
            
                                  [[ 2, 10],
                                   [ 6, 14]],
          
                                  [[ 3, 11],
                                   [ 7, 15]]])
        print(arr22.data)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
