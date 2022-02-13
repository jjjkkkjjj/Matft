//
//  PreopTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import XCTest
//@testable import Matft
import Matft

final class PreOpTests: XCTestCase {
    
    
    func testNormal() {
        do{

            let a = MfArray<Int>([[3, -19],
                                  [-22, 4]] as [[Int]])
            let b = MfArray<Int>([[2, 1177],
                                  [5, -43]] as [[Int]])
            
            XCTAssertEqual(-a, MfArray<Int>([[-3, 19],
                                        [22, -4]] as [[Int]]))
            
            XCTAssertEqual(-b, MfArray<Int>([[-2, -1177],
                                        [-5, 43]] as [[Int]]))
        }

        do{
            
            let a = MfArray<Int>([[2, 1, -3, 0],
                                  [3, 1, 4, -5]] as [[Int]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                                     [-0.0002, 2, 3.4, -5]] as [[Double]], mforder: .Column)

            XCTAssertEqual(-a, MfArray<Int>([[-2, -1, 3, 0],
                                             [-3, -1, -4, 5]] as [[Int]]))
            XCTAssertEqual(-b,
                            MfArray<Double>([[0.87, -1.2, -5.5134, 8.78],
                                                [0.0002, -2, -3.4, 5]] as [[Double]]))

        }
        
        do{
            let a = Matft.arange(start: UInt8(0), to: 4*4, by: 1, shape: [4,4]).T
            let b = MfArray<UInt8>([[251, 3, 2, 4],
                                    [247, 3, 1, 1],
                                    [22, 17, 0, 254],
                                    [1, 249, 3, 3]] as [[UInt8]], mforder: .Column)
            XCTAssertEqual(-a, MfArray<UInt8>([[  0, 252, 248, 244],
                                               [255, 251, 247, 243],
                                               [254, 250, 246, 242],
                                               [253, 249, 245, 241]] as [[UInt8]]))
            XCTAssertEqual(-b, MfArray<UInt8>([[  5, 253, 254, 252],
                                               [  9, 253, 255, 255],
                                               [234, 239,   0,   2],
                                               [255,   7, 253, 253]] as [[UInt8]]))
        }
    }
    

    func testBroadcast(){
        do{
            let a = MfArray<Int>([[1, 3, 5],
                                  [2, -4, -1]] as [[Int]], mforder: .Column)
            let b = a.broadcast_to(shape: [3,2,3])
            XCTAssertEqual(-b, MfArray<Int>([[[ -1,  -3,  -5],
                                              [-2, 4, 1]],

                                             [[ -1,  -3,  -5],
                                              [-2, 4, 1]],

                                             [[ -1,  -3,  -5],
                                              [-2, 4, 1]]] as [[[Int]]]))
            let c = MfArray<Int>([[1, 2]] as [[Int]])
            let d = c.broadcast_to(shape: [2,2])
            XCTAssertEqual(-d, MfArray<Int>([[-1,-2],
                                             [-1,-2]] as [[Int]]))
        }
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                  [1, 5, -2]] as [[Int]]).reshape([2,1,1,3])
            let b = a.broadcast_to(shape: [2,2,2,3])
            XCTAssertEqual(-b, MfArray<Int>([[[[ -2, 7,  0],
                                               [ -2, 7,  0]],

                                              [[ -2, 7,  0],
                                               [ -2, 7,  0]]],
                                                                          

                                             [[[ -1,  -5, 2],
                                               [ -1,  -5, 2]],

                                              [[ -1,  -5, 2],
                                               [ -1,  -5, 2]]]] as [[[[Int]]]]))
        }
    }
    
    func testNegativeIndexing(){
        
        do{
            let a = Matft.arange(start: 0, to: 3*3*3*2, by: 2, shape: [3, 3, 3])
            let b = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
            let c = a[~<~<-1]
            let d = b[2, 1, ~<~<-1]
            
            XCTAssertEqual(-c, MfArray<Int>([[[-36, -38, -40],
                                              [-42, -44, -46],
                                              [-48, -50, -52]],

                                             [[-18, -20, -22],
                                              [-24, -26, -28],
                                              [-30, -32, -34]],

                                             [[  0,  -2,  -4],
                                              [ -6,  -8, -10],
                                              [-12, -14, -16]]] as [[[Int]]]))
            
            XCTAssertEqual(-d, MfArray<Int>([-23, -22, -21] as [Int]))

        }
        
        do{
            let a = MfArray<Double>([[1.28, -3.2],[1.579, -0.82]] as [[Double]])
            let b = MfArray<Double>([2,1] as [Double])
            let c = a[-1~<-2~<-1]
            let d = b[~<~<-1]

            XCTAssertEqual(-c, MfArray<Double>([[-1.579,  0.82 ]] as [[Double]]))
            XCTAssertEqual(-d, MfArray<Double>([ -1, -2 ] as [Double]))
        }
    }
}
