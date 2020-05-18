//
//  File.swift
//  
//
//  Created by β α on 2020/05/18.
//

import XCTest
//@testable import Matft
import Matft

final class NewFunctionTests: XCTestCase {

    func testMinMaximum() {
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            
            
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.mfarray.maximum(a, b), MfArray([[3,1177],[5,4]]))
            XCTAssertEqual(Matft.mfarray.maximum(b, a), MfArray([[3,1177],[5,4]]))

            XCTAssertEqual(Matft.mfarray.minimum(a, b), MfArray([[2,-19],[-22,-43]]))
            XCTAssertEqual(Matft.mfarray.minimum(b, a), MfArray([[2,-19],[-22,-43]]))

        }
        
        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
            let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.mfarray.maximum(a, b), MfArray([[2,1.2,5.5134,0],[3,2,4,-5]]))
            XCTAssertEqual(Matft.mfarray.maximum(b, a), MfArray([[2,1.2,5.5134,0],[3,2,4,-5]]))

            XCTAssertEqual(Matft.mfarray.minimum(a, b), MfArray([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]]))
            XCTAssertEqual(Matft.mfarray.minimum(b, a), MfArray([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]]))
        }

    }

}
