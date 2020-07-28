import XCTest
//@testable import Matft
import Matft

final class ArithmeticTests: XCTestCase {
    
    func test_ms_sm() {
        do{

            let a = MfArray<Int>([[3, -19],
                                  [-22, 4]])
            let b = MfArray<Int>([[2, 1177],
                                  [5, -43]])
            
            XCTAssertEqual(a + 5, MfArray<Int>([[  8, -14],
                                                [-17,   9]]))
            
            XCTAssertEqual(a - 6, MfArray<Int>([[ -3, -25],
                                                [-28,  -2]]))
            XCTAssertEqual(a * 2, MfArray<Int>([[  6, -38],
                                                [-44,   8]]))
            XCTAssertEqual((a / 3).round(decimals: 6), MfArray<Float>([[ 1.0        , -6.33333333],
                                                                       [-7.33333333,  1.33333333]]).round(decimals: 6))
            
            XCTAssertEqual(5 + b, MfArray<Int>([[   7, 1182],
                                                [  10,  -38]]))
            
            XCTAssertEqual(6 + b, MfArray<Int>([[   8, 1183],
                                                [  11,  -37]]))
            XCTAssertEqual(2 * b, MfArray<Int>([[   4, 2354],
                                                [  10,  -86]]))
            XCTAssertEqual((3 / b).round(decimals: 6), MfArray<Float>([[ 1.5       ,  0.00254885],
                                                                       [ 0.6       , -0.06976744]]).round(decimals: 6))
        }

        do{
            
            let a = MfArray<Float>([[2.0, 1, -3, 0],
                                    [3, 1, 4, -5]], mforder: .Column)


            XCTAssertEqual(a+2.0, MfArray<Float>([[ 4.0,  3.0, -1.0,  2.0],
                                                  [ 5.0,  3.0,  6.0, -3.0]]))
            XCTAssertEqual(a-3.2, MfArray<Float>([[-1.2, -2.2, -6.2, -3.2],
                                                  [-0.2, -2.2,  0.8, -8.2]]))


            
            
            XCTAssertEqual((a/1.3).round(decimals: 6), MfArray<Float>([[ 1.53846154,  0.76923077, -2.30769231,  0.0        ],
                                                                       [ 2.30769231,  0.76923077,  3.07692308, -3.84615385]]).round(decimals: 6))
            
        }
        
    }
    
    func testSameShape() {
        do{
            
            let a = MfArray<Float>([[3, -19],
                             [-22, 4]])
            let b = MfArray<Float>([[0.2, 1.177],
                             [5, -4.3]])
            
            XCTAssertEqual(a + b, MfArray<Float>([[  3.2  , -17.823],
                                           [-17.0   ,  -0.3  ]]))
            let c = MfArray<Int>([[3, -19],
                                  [-22, 4]])
            let d = MfArray<Int>([[2, 1177],
                                  [5, -43]])
            
            XCTAssertEqual(c + d, MfArray<Int>([[   5, 1158],
                                                [ -17,  -39]]))
            
            XCTAssertEqual(c - d, MfArray<Int>([[    1, -1196],
                                                [  -27,    47]]))
            XCTAssertEqual(c * d, MfArray<Int>([[     6, -22363],
                                                [  -110,   -172]]))

            XCTAssertEqual((c / d).round(decimals: 6), MfArray<Float>([[ 1.5       , -0.01614274],
                                                                       [-4.4       , -0.09302326]]).round(decimals: 6))
        }

        do{
            
            let a = MfArray<Double>([[2, 1, -3, 0],
                                     [3, 1, 4, -5]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                                     [-0.0002, 2, 3.4, -5]], mforder: .Column)

            XCTAssertEqual(a+b, MfArray<Double>([[  1.13  ,   2.2   ,   2.5134,  -8.78  ],
                                                 [  2.9998,   3.0    ,   7.4   , -10.0    ]]))
            XCTAssertEqual(a-b, MfArray<Double>([[ 2.87  , -0.2   , -8.5134,  8.78  ],
                                                 [ 3.0002, -1.0    ,  0.6   ,  0.0    ]]))
            

            XCTAssertEqual(a*b, MfArray<Double>([[-1.74000e+00,  1.20000e+00, -1.65402e+01, -0.00000e+00],
                                                 [-6.00000e-04,  2.00000e+00,  1.36000e+01,  2.50000e+01]]))
            
            XCTAssertEqual((a/b).round(decimals: 10), MfArray<Double>([[-2.2988505747126435,  8.33333333333333e-01, -0.5441288497116117,
                                          -0.00000000e+00],
                                         [-1.50000000e+04,  5.00000000e-01,  1.1764705882352942,
                1.00000000e+00]]).round(decimals: 10))
        }
        
        do{
            let a = Matft.arange(start: UInt8(0), to: 4*4, by: 1, shape: [4,4]).T
            let b = MfArray<UInt8>([[251, 3, 2, 4],
                                    [247, 3, 1, 1],
                                    [22, 17, 0, 254],
                                    [1, 249, 3, 3]], mforder: .Column)
            XCTAssertEqual(a+b, MfArray<UInt8>([[251,   7,  10,  16],
                                                [248,   8,  10,  14],
                                                [ 24,  23,  10,  12],
                                                [  4,   0,  14,  18]]))
            XCTAssertEqual(a-b, MfArray<UInt8>([[  5,   1,   6,   8],
                                                [ 10,   2,   8,  12],
                                                [236, 245,  10,  16],
                                                [  2,  14,   8,  12]]))
            XCTAssertEqual(a*b, MfArray<UInt8>([[  0,  12,  16,  48],
                                                [247,  15,   9,  13],
                                                [ 44, 102,   0, 228],
                                                [  3, 207,  33,  45]]))

            XCTAssertEqual(a/b, MfArray<UInt8>([[    0,        1,        3,        2],
                                                [    0,        1,        8,        12],
                                                [    0,        0,        0,        0],
                                                [    2,        0,        3,        4]]))
        }
    }
    

    func testBroadcast(){
        do{
            let a = MfArray<Int64>([[1, 3, 5],
                                    [2, -4, -1]])
            let b = Matft.arange(start: Int64.zero, to: 2*3*3, by: 1, shape: [3, 2, 3])
            
            XCTAssertEqual(a+b, MfArray<Int64>([[[ 1,  4,  7],
                                          [ 5,  0,  4]],

                                         [[ 7, 10, 13],
                                          [11,  6, 10]],

                                         [[13, 16, 19],
                                          [17, 12, 16]]]))
            XCTAssertEqual(a-b, MfArray<Int64>([[[  1,   2,   3],
                                          [ -1,  -8,  -6]],

                                         [[ -5,  -4,  -3],
                                          [ -7, -14, -12]],

                                         [[-11, -10,  -9],
                                          [-13, -20, -18]]]))
            XCTAssertEqual(a*b, MfArray<Int64>([[[  0,   3,  10],
                                          [  6, -16,  -5]],

                                         [[  6,  21,  40],
                                          [ 18, -40, -11]],

                                         [[ 12,  39,  70],
                                          [ 30, -64, -17]]]))
            /*
            XCTAssertEqual(b/a, MfArray([[[  0.0        ,   0.33333333,   0.4       ],
                                          [  1.5       ,  -1.0        ,  -5.0        ]],

                                         [[  6.0        ,   2.33333333,   1.6       ],
                                          [  4.5       ,  -2.5       , -11.0        ]],

                                         [[ 12.0        ,   4.33333333,   2.8       ],
                                          [  7.5       ,  -4.0        , -17.0        ]]], mftype: .Float))*/
        }
        do{
            let a = Matft.arange(start: 1, to: 7, by: 1, shape: [3, 2])
                let b = Matft.arange(start: 1, to: 5, by: 1, shape: [2, 1, 2])

                XCTAssertEqual(a-b, MfArray([[[ 0,  0],
                                              [ 2,  2],
                                              [ 4,  4]],

                                             [[-2, -2],
                                              [ 0,  0],
                                              [ 2,  2]]]))

                XCTAssertEqual(a+b, MfArray([[[ 2,  4],
                                              [ 4,  6],
                                              [ 6,  8]],

                                             [[ 4,  6],
                                              [ 6,  8],
                                              [ 8, 10]]]))
            }

            do{
                let a = Matft.arange(start: 0, to: 18, by: 1, shape: [3, 1, 3, 2])
                let b = Matft.arange(start: 0, to: 24, by: 1, shape: [4, 3, 2])

                XCTAssertEqual(a+b, MfArray([[[[ 0,  2],
                                               [ 4,  6],
                                               [ 8, 10]],

                                              [[ 6,  8],
                                               [10, 12],
                                               [14, 16]],

                                              [[12, 14],
                                               [16, 18],
                                               [20, 22]],

                                              [[18, 20],
                                               [22, 24],
                                               [26, 28]]],


                                             [[[ 6,  8],
                                               [10, 12],
                                               [14, 16]],

                                              [[12, 14],
                                               [16, 18],
                                               [20, 22]],

                                              [[18, 20],
                                               [22, 24],
                                               [26, 28]],

                                              [[24, 26],
                                               [28, 30],
                                               [32, 34]]],


                                             [[[12, 14],
                                               [16, 18],
                                               [20, 22]],

                                              [[18, 20],
                                               [22, 24],
                                               [26, 28]],

                                              [[24, 26],
                                               [28, 30],
                                               [32, 34]],

                                              [[30, 32],
                                               [34, 36],
                                               [38, 40]]]]))
        }
    }
    
    func testNegativeIndexing(){
        
        do{
            let a = Matft.arange(start: 0, to: 3*3*3*2, by: 2, shape: [3, 3, 3])
            let b = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
            let c = a[~<~<-1]
            let d = b[2, 1, ~<~<-1]
            
            XCTAssertEqual(c+d, MfArray<Int>([[[59, 60, 61],
                                               [65, 66, 67],
                                               [71, 72, 73]],

                                              [[41, 42, 43],
                                               [47, 48, 49],
                                               [53, 54, 55]],

                                              [[23, 24, 25],
                                               [29, 30, 31],
                                               [35, 36, 37]]]))
            XCTAssertEqual(c-d, MfArray<Int>([[[ 13,  16,  19],
                                               [ 19,  22,  25],
                                               [ 25,  28,  31]],

                                              [[ -5,  -2,   1],
                                               [  1,   4,   7],
                                               [  7,  10,  13]],

                                              [[-23, -20, -17],
                                               [-17, -14, -11],
                                               [-11,  -8,  -5]]]))
            XCTAssertEqual(c*d, MfArray<Int>([[[ 828,  836,  840],
                                               [ 966,  968,  966],
                                               [1104, 1100, 1092]],

                                              [[ 414,  440,  462],
                                               [ 552,  572,  588],
                                               [ 690,  704,  714]],

                                              [[   0,   44,   84],
                                               [ 138,  176,  210],
                                               [ 276,  308,  336]]]))
            //print(c)
            //print(d)
            //print(36/23) = c[0,0,0] / d[0]
            //Note that 36 / 23 > 1.5, but got 1
            XCTAssertEqual(c/d, MfArray<Int>([[[    1,        1,        1],
                                               [    1,        2,        2],
                                               [    2,        2,        2]],

                                              [[    0,        0,        1],
                                               [    1,        1,        1],
                                               [    1,        1,        1]],

                                              [[    0,        0,        0],
                                               [    0,        0,        0],
                                               [    0,        0,        0]]]))
        }
        
        do{
            let a = MfArray<Double>([[1.28, -3.2],[1.579, -0.82]])
            let b = MfArray<Double>([2,1])
            let c = a[-1~<-2~<-1]
            let d = b[~<~<-1]

            XCTAssertEqual(c+d, MfArray<Double>([[2.579, 1.18 ]]))
            XCTAssertEqual(c-d, MfArray<Double>([[ 0.579, -2.82 ]]))
            XCTAssertEqual(c*d, MfArray<Double>([[ 1.579, -1.64 ]]))
            XCTAssertEqual(c/d, MfArray<Double>([[ 1.579, -0.41 ]]))
        }
    }
}
