import XCTest
//@testable import Matft
import Matft

final class ArithmeticTests: XCTestCase {
    
    static var allTests = [
        ("testSameShape", testSameShape),
        ("testBroadcast", testBroadcast),
        ("testNegativeIndexing", testNegativeIndexing),
    ]
    
    func testSameShape() {
        do{
            /*
            let a = MfArray([[3, -19],
                             [-22, 4]], mftype: .Float)
            let b = MfArray([[0.2, 1.177],
                             [5, -4.3]], mftype: .Float)
            
            XCTAssertEqual(a + b, MfArray([[  3.2  , -17.823],
                                           [-17.0   ,  -0.3  ]], mftype: .Float))*/
            let a = MfArray([[3, -19],
                             [-22, 4]])
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(a + b, MfArray([[   5, 1158],
                                           [ -17,  -39]]))
            
            XCTAssertEqual(a - b, MfArray([[    1, -1196],
                                           [  -27,    47]]))
            XCTAssertEqual(a * b, MfArray([[     6, -22363],
                                           [  -110,   -172]]))
            XCTAssertEqual(a / b, MfArray([[ 1.5       , -0.01614274],
                                           [-4.4       , -0.09302326]], mftype: .Int))
        }

        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
            let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(a+b, MfArray([[  1.13  ,   2.2   ,   2.5134,  -8.78  ],
                                       [  2.9998,   3.0    ,   7.4   , -10.0    ]]))
            XCTAssertEqual(a-b, MfArray([[ 2.87  , -0.2   , -8.5134,  8.78  ],
                                       [ 3.0002, -1.0    ,  0.6   ,  0.0    ]]))


            XCTAssertEqual(a*b, MfArray([[-1.74000e+00,  1.20000e+00, -1.65402e+01, -0.00000e+00],
                                         [-6.00000e-04,  2.00000e+00,  1.36000e+01,  2.50000e+01]]))
            /*
            //rounding error will be occurred
            XCTAssertEqual(a/b, MfArray([[-2.29885057e+00,  8.33333333e-01, -5.44128850e-01,
                                          -0.00000000e+00],
                                         [-1.50000000e+04,  5.00000000e-01,  1.17647059e+00,
                                          1.00000000e+00]]))*/
        }
        
        do{
            let a = Matft.mfarray.arange(start: 0, stop: 4*4, step: 1, shape: [4,4], mftype: .UInt8).T
            let b = MfArray([[-5, 3, 2, 4],
                             [-9, 3, 1, 1],
                             [22, 17, 0, -2],
                             [1, -7, 3, 3]], mftype: .UInt8, mforder: .Column)
            XCTAssertEqual(a+b, MfArray([[251,   7,  10,  16],
                                         [248,   8,  10,  14],
                                         [ 24,  23,  10,  12],
                                         [  4,   0,  14,  18]], mftype: .UInt8))
            XCTAssertEqual(a-b, MfArray([[  5,   1,   6,   8],
                                         [ 10,   2,   8,  12],
                                         [236, 245,  10,  16],
                                         [  2,  14,   8,  12]], mftype: .UInt8))
            XCTAssertEqual(a*b, MfArray([[  0,  12,  16,  48],
                                         [247,  15,   9,  13],
                                         [ 44, 102,   0, 228],
                                         [  3, 207,  33,  45]], mftype: .UInt8))
        }
    }
    

    func testBroadcast(){
        do{
            let a = MfArray([[1, 3, 5],
                            [2, -4, -1]])
            let b = Matft.mfarray.arange(start: 0, stop: 2*3*3, step: 1, shape: [3, 2, 3])
            
            XCTAssertEqual(a+b, MfArray([[[ 1,  4,  7],
                                          [ 5,  0,  4]],

                                         [[ 7, 10, 13],
                                          [11,  6, 10]],

                                         [[13, 16, 19],
                                          [17, 12, 16]]]))
            XCTAssertEqual(a-b, MfArray([[[  1,   2,   3],
                                          [ -1,  -8,  -6]],

                                         [[ -5,  -4,  -3],
                                          [ -7, -14, -12]],

                                         [[-11, -10,  -9],
                                          [-13, -20, -18]]]))
            XCTAssertEqual(a*b, MfArray([[[  0,   3,  10],
                                          [  6, -16,  -5]],

                                         [[  6,  21,  40],
                                          [ 18, -40, -11]],

                                         [[ 12,  39,  70],
                                          [ 30, -64, -17]]]))
        }
        do{
            
        }
    }
    
    func testNegativeIndexing(){
        
    }
}
