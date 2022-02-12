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
    
    func testReshape(){
        do{
            let a = MfArray<Float>([2.0, 1.1, 3.2, 2.5] as [Float])

            XCTAssertEqual(a.reshape([2, 2]), MfArray<Float>([[2.0, 1.1],
                                                       [3.2, 2.5]] as [[Float]]))
        }

        do{
            let a = Matft.arange(start: 0, to: 36, by: 1)

            XCTAssertEqual(a.reshape([2, 3, 3, 2]),
                           MfArray<Int>([[[[ 0,  1],
                                           [ 2,  3],
                                           [ 4,  5]],

                                          [[ 6,  7],
                                           [ 8,  9],
                                           [10, 11]],

                                          [[12, 13],
                                           [14, 15],
                                           [16, 17]]],


                                         [[[18, 19],
                                           [20, 21],
                                           [22, 23]],

                                          [[24, 25],
                                           [26, 27],
                                           [28, 29]],

                                          [[30, 31],
                                           [32, 33],
                                           [34, 35]]]]))
        }

        do{
            let a = MfArray<Int>([[1, 3, 5],
                             [2, -4, -1]], mforder: .Column)


            XCTAssertEqual(a.reshape([3, 1, 2]),
                           MfArray<Int>([[[ 1,  3]],

                                          [[ 5,  2]],

                                          [[-4, -1]]]))
        }
    }
    
    func testFlatten(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                [1, 5, -2]])
            
            XCTAssertEqual(a.flatten(),
                           MfArray<Int>([2, -7, 0, 1, 5, -2]))
            XCTAssertEqual(a.T.flatten(),
                           MfArray<Int>([ 2,  1, -7,  5,  0, -2]))
            XCTAssertEqual(a[~<<-1].flatten(),
                           MfArray<Int>([ 1,  5, -2,  2, -7,  0]))
        }
    }
}
