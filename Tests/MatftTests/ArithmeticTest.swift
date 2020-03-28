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
            /*rounding error will be occurred
            XCTAssertEqual(a/b, MfArray([[-2.29885057e+00,  8.33333333e-01, -5.44128850e-01,
                                          -0.00000000e+00],
                                         [-1.50000000e+04,  5.00000000e-01,  1.17647059e+00,
                                          1.00000000e+00]]))*/
        }
        
        do{
            let a = Matft.mfarray.arange(start: 0, stop: 4*4*4, step: 1, shape: [4,4,4], mftype: .UInt).T
            
            XCTAssertEqual(a[3,2,0] as! UInt, UInt(11))
            XCTAssertEqual(a[0,0,2] as! UInt, UInt(32))
            XCTAssertEqual(a[1,0,2] as! UInt, UInt(33))
            XCTAssertEqual(a[1,3,1] as! UInt, UInt(29))
            XCTAssertEqual(a[0,2,0] as! UInt, UInt(8))
        }
    }
    

    func testBroadcast(){
        do{
            let a = Matft.mfarray.arange(start: 0, stop: 27*2, step: 2, shape: [3,3,3], mftype: .Double, mforder: .Column)
            XCTAssertEqual(a[~1], MfArray([[[ 0, 18, 36],
                                            [ 6, 24, 42],
                                            [12, 30, 48]]], mftype: .Double))
            XCTAssertEqual(a[1~2], MfArray([[[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            XCTAssertEqual(a[~-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            XCTAssertNotEqual(a[~-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 2, 44],
                                             [14, 32, 50]]], mftype: .Double))
            
            XCTAssertEqual(a[0~,0~,~-1], MfArray([[[ 0, 18],
                                                   [ 6, 24],
                                                   [12, 30]],

                                                  [[ 2, 20],
                                                   [ 8, 26],
                                                   [14, 32]],

                                                  [[ 4, 22],
                                                   [10, 28],
                                                   [16, 34]]], mftype: .Double))
            XCTAssertEqual(a[0~,-1~-3~-1,-2], MfArray([[30, 24],
                                                       [32, 26],
                                                       [34, 28]], mftype: .Double))
        }
        
        do{
            let a = try! Matft.mfarray.broadcast_to(MfArray([[2, 5, -1],
                                                        [3, 1, 0]]), shape: [2,2,2,3])

            XCTAssertEqual(a[-1~~-1, (-2)~], MfArray([[[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]],


                                                    [[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]]]))
            
            XCTAssertEqual(a[0~,0~,~1~-1,~~3], MfArray([[[[2]],

                                                         [[2]]],


                                                        [[[2]],

                                                         [[2]]]]))
            XCTAssertNotEqual(a[0~,0~,~1~-1,~~3], MfArray([[[2],

                                                            [2]],


                                                           [[2],

                                                            [2]]]))
            XCTAssertEqual(a[~1, ~~-2], MfArray([[[[ 2,  5, -1],
                                                   [ 3,  1,  0]]]]))
        }
    }
    
    func testNegativeIndexing(){
        
    }
}
