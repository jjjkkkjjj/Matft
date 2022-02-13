//
//  BiopVectorTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import XCTest
//@testable import Matft
import Matft

final class BiopVectorTests: XCTestCase {
    
    func testMatmul_sameShape() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]] as [[Int]])
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]] as [[Int]])
            
            XCTAssertEqual(a *& a, MfArray<Int>([[ 427, -133],
                                            [-154,  434]] as [[Int]]))
            XCTAssertEqual(b *& b, MfArray<Int>([[  5889, -48257],
                                            [  -205,   7734]] as [[Int]]))
            XCTAssertEqual(a *& b, MfArray<Int>([[   -89,   4348],
                                            [   -24, -26066]] as [[Int]]))
            XCTAssertEqual(a *& b.T, MfArray<Int>([[-22357,    832],
                                              [  4664,   -282]] as [[Int]]))
        }
        
        do{
            let a = MfArray<Double>([[2, 1, -3, 0],
                             [3, 1, 4, -5]] as [[Double]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                [-0.0002, 2, 3.4, -5]] as [[Double]], mforder: .Column)
            
            XCTAssertEqual(a *& b.T,
                           MfArray<Double>([[-17.0802,  -8.2004],
                                              [ 64.5436,  40.5994]] as [[Double]]))
            XCTAssertEqual(a.T *& b,
                        MfArray<Double>([[-1.74060e+00,  8.40000e+00,  2.12268e+01, -3.25600e+01],
                                  [-8.70200e-01,  3.20000e+00,  8.91340e+00, -1.37800e+01],
                                  [ 2.60920e+00,  4.40000e+00, -2.94020e+00,  6.34000e+00],
                                  [ 1.00000e-03, -1.00000e+01, -1.70000e+01,  2.50000e+01]] as [[Double]]))
        }
        
        do{
            let a = Matft.arange(start: UInt8.zero, to: 4*4, by: 1, shape: [4,4]).T
            let b = MfArray<UInt8>([[251, 3, 2, 4],
                             [247, 3, 1, 1],
                             [22, 17, 0, 254],
                             [1, 249, 3, 3]] as [[UInt8]], mforder: .Column)
            
            XCTAssertEqual(a*&b, MfArray<UInt8>([[152,  64,  40,  24],
                                          [161,  80,  46,  30],
                                          [170,  96,  52,  36],
                                          [179, 112,  58,  42]] as [[UInt8]]))
            XCTAssertEqual(b*&a, MfArray<UInt8>([[ 19,  35,  51,  67],
                                          [  8, 248, 232, 216],
                                          [ 11, 159,  51, 199],
                                          [  8,   8,   8,   8]] as [[UInt8]]))
        }
    }
    
    //element-wise
    func testMatmul_broadCast(){
        do{
            let a =  Matft.arange(start: 0, to: 2*2*4, by: 1, shape: [2, 2, 4])
            let b = Matft.arange(start: 0, to: 2*2*4, by: 1, shape: [2, 4, 2])
            
            XCTAssertEqual(a*&b, MfArray<Int>([[[ 28,  34],
                                           [ 76,  98]],

                                          [[428, 466],
                                           [604, 658]]] as [[[Int]]]))
            XCTAssertEqual(b*&a, MfArray<Int>([[[  4,   5,   6,   7],
                                           [ 12,  17,  22,  27],
                                           [ 20,  29,  38,  47],
                                           [ 28,  41,  54,  67]],

                                          [[172, 189, 206, 223],
                                           [212, 233, 254, 275],
                                           [252, 277, 302, 327],
                                           [292, 321, 350, 379]]] as [[[Int]]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 18, by: 1, shape: [3, 1, 2, 3])
            let b = Matft.arange(start: 0, to: 24, by: 1, shape: [4, 3, 2])
            XCTAssertEqual(a*&b, MfArray<Int>([[[[  10,   13],
                                                 [  28,   40]],

                                                [[  28,   31],
                                                 [ 100,  112]],

                                                [[  46,   49],
                                                 [ 172,  184]],

                                                [[  64,   67],
                                                 [ 244,  256]]],


                                               [[[  46,   67],
                                                 [  64,   94]],

                                                [[ 172,  193],
                                                 [ 244,  274]],

                                                [[ 298,  319],
                                                 [ 424,  454]],
                                                
                                                [[ 424,  445],
                                                 [ 604,  634]]],


                                               [[[  82,  121],
                                                 [ 100,  148]],

                                                [[ 316,  355],
                                                 [ 388,  436]],

                                                [[ 550,  589],
                                                 [ 676,  724]],

                                                [[ 784,  823],
                                                 [ 964, 1012]]]] as [[[[Int]]]]))
        }

    }
    
    func testMatmul_negativeIndexing(){
        let a = Matft.arange(start: 0, to: 3*3*3*2, by: 2, shape: [3, 3, 3])
        let b = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
        let c = a[~<~<-1]
        let d = b[2, 0~<, ~<~<-1]

        XCTAssertEqual(c*&d, MfArray<Int>([[[2634, 2520, 2406],
                                       [3048, 2916, 2784],
                                       [3462, 3312, 3162]],

                                      [[1392, 1332, 1272],
                                       [1806, 1728, 1650],
                                       [2220, 2124, 2028]],

                                      [[ 150,  144,  138],
                                       [ 564,  540,  516],
                                       [ 978,  936,  894]]] as [[[Int]]]))
        
        XCTAssertEqual(b[~<~<-1]*&a[2,0~<,~<~<-1],
                       MfArray<Int>([[[2634, 2520, 2406],
                                    [3048, 2916, 2784],
                                    [3462, 3312, 3162]],

                                   [[1392, 1332, 1272],
                                    [1806, 1728, 1650],
                                    [2220, 2124, 2028]],

                                   [[ 150,  144,  138],
                                    [ 564,  540,  516],
                                    [ 978,  936,  894]]] as [[[Int]]]))
        
    }
}
