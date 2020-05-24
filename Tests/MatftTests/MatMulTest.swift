import XCTest
//@testable import Matft
import Matft

final class MatMulTests: XCTestCase {
    
    func testSameShape() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(a *& a, MfArray<Int>([[ 427, -133],
                                            [-154,  434]]))
            XCTAssertEqual(b *& b, MfArray<Int>([[  5889, -48257],
                                            [  -205,   7734]]))
            XCTAssertEqual(a *& b, MfArray<Int>([[   -89,   4348],
                                            [   -24, -26066]]))
            XCTAssertEqual(a *& b.T, MfArray<Int>([[-22357,    832],
                                              [  4664,   -282]]))
        }
        
        do{
            let a = MfArray<Double>([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                [-0.0002, 2, 3.4, -5]], mforder: .Column)
            
            XCTAssertEqual(a *& b.T, MfArray<Double>([[-17.0802,  -8.2004],
                                              [ 64.5436,  40.5994]]))
            XCTAssertEqual(a.T *& b, MfArray<Double>([[-1.74060e+00,  8.40000e+00,  2.12268e+01, -3.25600e+01],
                                              [-8.70200e-01,  3.20000e+00,  8.91340e+00, -1.37800e+01],
                                              [ 2.60920e+00,  4.40000e+00, -2.94020e+00,  6.34000e+00],
                                              [ 1.00000e-03, -1.00000e+01, -1.70000e+01,  2.50000e+01]]))
        }
        /*
        do{
            let a = Matft.arange(start: 0, to: 4*4, by: 1, shape: [4,4], mftype: .UInt8).T
            let b = MfArray([[-5, 3, 2, 4],
                             [-9, 3, 1, 1],
                             [22, 17, 0, -2],
                             [1, -7, 3, 3]], mftype: .UInt8, mforder: .Column)
            
            XCTAssertEqual(a*&b, MfArray([[152,  64,  40,  24],
                                          [161,  80,  46,  30],
                                          [170,  96,  52,  36],
                                          [179, 112,  58,  42]], mftype: .UInt8))
            XCTAssertEqual(b*&a, MfArray([[ 19,  35,  51,  67],
                                          [  8, 248, 232, 216],
                                          [ 11, 159,  51, 199],
                                          [  8,   8,   8,   8]], mftype: .UInt8))
        }*/
    }
    
    //element-wise
    func testBroadCast(){
        do{
            let a =  Matft.arange(start: 0, to: 2*2*4, by: 1, shape: [2, 2, 4])
            let b = Matft.arange(start: 0, to: 2*2*4, by: 1, shape: [2, 4, 2])
            
            XCTAssertEqual(a*&b, MfArray<Int>([[[ 28,  34],
                                           [ 76,  98]],

                                          [[428, 466],
                                           [604, 658]]]))
            XCTAssertEqual(b*&a, MfArray<Int>([[[  4,   5,   6,   7],
                                           [ 12,  17,  22,  27],
                                           [ 20,  29,  38,  47],
                                           [ 28,  41,  54,  67]],

                                          [[172, 189, 206, 223],
                                           [212, 233, 254, 275],
                                           [252, 277, 302, 327],
                                           [292, 321, 350, 379]]]))
        }
        
        do{
            
        }

    }
    
    func testNegativeIndexing(){
        let a = Matft.arange(start: 0, to: 3*3*3*2, by: 2, shape: [3, 3, 3])
        let b = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
        let c = a[~~-1]
        let d = b[2, 0~, ~~-1]

        XCTAssertEqual(c*&d, MfArray<Int>([[[2634, 2520, 2406],
                                       [3048, 2916, 2784],
                                       [3462, 3312, 3162]],

                                      [[1392, 1332, 1272],
                                       [1806, 1728, 1650],
                                       [2220, 2124, 2028]],

                                      [[ 150,  144,  138],
                                       [ 564,  540,  516],
                                       [ 978,  936,  894]]]))
        
        XCTAssertEqual(b[~~-1]*&a[2,0~,~~-1], MfArray<Int>([[[2634, 2520, 2406],
                                                        [3048, 2916, 2784],
                                                        [3462, 3312, 3162]],

                                                       [[1392, 1332, 1272],
                                                        [1806, 1728, 1650],
                                                        [2220, 2124, 2028]],

                                                       [[ 150,  144,  138],
                                                        [ 564,  540,  516],
                                                        [ 978,  936,  894]]]))
        
    }
}

