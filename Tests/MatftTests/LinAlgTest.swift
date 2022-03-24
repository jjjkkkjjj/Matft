//
//  LinAlgTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/03/24.
//

import XCTest
//@testable import Matft
import Matft

final class LinAlgTests: XCTestCase {
    
    func testSolve() {
        do{
            let coef = MfArray<Int>([[3,2],[1,2]])
            let b = MfArray<Int>([7,1])
            
            XCTAssertEqual(try Matft.linalg.solve(coef, b: b), MfArray<Float>([ 3.0, -1.0] as [Float]))
        }

        do{
            let coef = MfArray<Double>([[3,1],[1,2]] as [[Double]])
            let b = MfArray<Double>([9,8] as [Double])
            
            XCTAssertEqual(try Matft.linalg.solve(coef, b: b), MfArray<Double>([ 2.0, 3.0] as [Double]))
        }
        
        do{
            let coef = MfArray<Int>([[1,2],[2,4]])
            let b = MfArray<Int>([-1,-2])
            
            XCTAssertThrowsError(try Matft.linalg.solve(coef, b: b))
        }
        
        do{
            let coef = MfArray<Int>([[1,2],[2,4]])
            let b = MfArray<Int>([-1,-3])
            
            XCTAssertThrowsError(try Matft.linalg.solve(coef, b: b))
        }
    }
    
    func testInv(){
        do{
            let a = MfArray<Int>([[1, 2], [3, 4]])
            XCTAssertEqual(try Matft.linalg.inv(a), MfArray([[-2.0 ,  1.0 ],
                                                                     [ 1.5, -0.5]] as [[Float]]))
        }
        do{
            let a = MfArray<Double>([[[1.0, 2.0],
                              [3.0, 4.0]],
                             
                             [[1.0, 3.0],
                              [3.0, 5.0]]] as [[[Double]]])
            XCTAssertEqual(try Matft.linalg.inv(a), MfArray<Double>([[[-2.0  ,  1.0  ],
                        [ 1.5 , -0.5 ]],
                                                             
                         [[-1.25,  0.75],
                          [ 0.75, -0.25]]] as [[[Double]]]))
        }
    }
}
