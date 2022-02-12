//
//  CreationTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/12.
//

import XCTest
import Matft

final class CreationTest: XCTestCase {
    
    func testDiag() {
        do{
            XCTAssertEqual(Matft.diag(v: [3, -19, -22, 4]), MfArray<Int>([[  3,   0,   0,   0],
                              [  0, -19,   0,   0],
                              [  0,   0, -22,   0],
                              [  0,   0,   0,   4]]))
            let a = MfArray<Int>([3, -19, -22, 4])
            XCTAssertEqual(Matft.diag(v: a),
                           MfArray<Int>([[  3,   0,   0,   0],
                                       [  0, -19,   0,   0],
                                       [  0,   0, -22,   0],
                                       [  0,   0,   0,   4]]))
        }

        do{

            XCTAssertEqual(Matft.diag(v: [-0.87, 1.2, 5.5134, -8.78]), MfArray<Double>([[-0.87  ,  0.0    ,  0.0    ,  0.0    ],
                                [ 0.0    ,  1.2   ,  0.0    ,  0.0    ],
                                [ 0.0    ,  0.0    ,  5.5134,  0.0    ],
                                [ 0.0    ,  0.0    ,  0.0    , -8.78 ]] as [[Double]]))
            let a = MfArray<Double>([-0.87, 1.2, 5.5134, -8.78], mforder: .Column)
            XCTAssertEqual(Matft.diag(v: a), MfArray<Double>([[-0.87  ,  0.0    , 0.0   , 0.0],
                              [ 0.0    ,  1.2   ,  0.0    ,  0.0    ],
                              [ 0.0    ,  0.0    ,  5.5134,  0.0    ],
                              [ 0.0    ,  0.0    ,  0.0    , -8.78  ]] as [[Double]]))

        }
        
        
    }
    

    func testEye(){
        do{
            XCTAssertEqual(Matft.eye(dim: 3),
                           MfArray<Int>([[ 1,  0,  0],
                                        [ 0,  1,  0],
                                        [ 0,  0,  1]]))
        }
        do{
            let eye: MfArray<Float> = Matft.eye(dim: 3)
            XCTAssertEqual(eye,
                           MfArray<Float>([[ 1,  0,  0],
                                          [ 0,  1,  0],
                                          [ 0,  0,  1]] as [[Float]]))
        }
    }
    
}
