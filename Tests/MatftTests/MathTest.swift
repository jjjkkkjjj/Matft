import XCTest
//@testable import Matft
import Matft
/*
final class MathTests: XCTestCase {
    
    
    func testSqrt() {
        do{
            let a = Matft.arange(start: 0, to: 15, by: 1, shape: [3, 5], mftype: .Float, mforder: .Column)
            
            XCTAssertEqual(Matft.math.sqrt(a), MfArray([[0.0        , 1.73205081, 2.44948974, 3.0        , 3.46410162],
                                                                [1.0        , 2.0        , 2.64575131, 3.16227766, 3.60555128],
                                                                [1.41421356, 2.23606798, 2.82842712, 3.31662479, 3.74165739]], mftype: .Float))
            XCTAssertEqual(Matft.math.sqrt(a.T), MfArray([[0.0        , 1.0        , 1.41421356],
                                                                  [1.73205081, 2.0        , 2.23606798],
                                                                  [2.44948974, 2.64575131, 2.82842712],
                                                                  [3.0        , 3.16227766, 3.31662479],
                                                                  [3.46410162, 3.60555128, 3.74165739]], mftype: .Float))
            
        }

        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Float)

            let aret = MfArray([[1.4142135, 1.0        ,    -Float.nan, 0.0        ],
                                [1.732050, 1.0        , 2.0        ,     -Float.nan]], mftype: .Float)
            let aTret = MfArray([[1.4142135, 1.732050],
                                 [1.0        , 1.0        ],
                                 [   -Float.nan, 2.0        ],
                                 [0.0        ,    -Float.nan]], mftype: .Float)
            
            XCTAssertEqual(Matft.math.sqrt(a) === aret, MfArray([[true, true, false, true],
                                                                         [true, true, true, false]]))
            
            
            XCTAssertEqual(Matft.math.sqrt(a.T) === aTret, MfArray([[true, true],
                                                                            [true, true],
                                                                            [false, true],
                                                                            [true, false]], mftype: .Float))

        }
        
        do{
            let a = Matft.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(Matft.math.sqrt(a.transpose(axes: [0, 2, 3, 1])),
                           MfArray([[[[0.0        , 2.0        ],
                                      [1.0        , 2.23606798]],

                                     [[1.41421356, 2.44948974],
                                      [1.73205081, 2.64575131]]],


                                    [[[2.82842712, 3.46410162],
                                      [3.0        , 3.60555128]],

                                     [[3.16227766, 3.74165739],
                                      [3.31662479, 3.87298335]]]], mftype: .Float))
            XCTAssertEqual(Matft.math.sqrt(a.transpose(axes: [3,0,2,1])),
                           MfArray([[[[0.0        , 2.0        ],
                                      [1.41421356, 2.44948974]],
                                     
                                     [[2.82842712, 3.46410162],
                                      [3.16227766, 3.74165739]]],


                                    [[[1.0        , 2.23606798],
                                      [1.73205081, 2.64575131]],

                                     [[3.0        , 3.60555128],
                                      [3.31662479, 3.87298335]]]], mftype: .Float))
        }
    }
    
    func testSinCos() {
        do{
            let a = Matft.arange(start: 0, to: 15, by: 1, shape: [3, 5], mftype: .Float, mforder: .Column)
            
            XCTAssertEqual(Matft.math.sin(a),
                           MfArray([[ 0.0        ,  0.14112001, -0.2794155 ,  0.41211849, -0.53657292],
                                    [ 0.84147098, -0.7568025 ,  0.6569866 , -0.54402111,  0.42016704],
                                    [ 0.90929743, -0.95892427,  0.98935825, -0.99999021,  0.99060736]], mftype: .Float))
            
            XCTAssertEqual(Matft.math.cos(a),
                           MfArray([[ 1.0        , -0.9899925 ,  0.96017029, -0.91113026,  0.84385396],
                                    [ 0.54030231, -0.65364362,  0.75390225, -0.83907153,  0.90744678],
                                    [-0.41614684,  0.28366219, -0.14550003,  0.0044257 ,  0.13673722]], mftype: .Float))
            
            XCTAssertEqual(Matft.math.sin(a.T),
                           MfArray([[ 0.0        ,  0.84147098,  0.90929743],
                                    [ 0.14112001, -0.7568025 , -0.95892427],
                                    [-0.2794155 ,  0.6569866 ,  0.98935825],
                                    [ 0.41211849, -0.54402111, -0.99999021],
                                    [-0.53657292,  0.42016704,  0.99060736]], mftype: .Float))
            
            XCTAssertEqual(Matft.math.cos(a.T),
                           MfArray([[ 1.0        ,  0.54030231, -0.41614684],
                                    [-0.9899925 , -0.65364362,  0.28366219],
                                    [ 0.96017029,  0.75390225, -0.14550003],
                                    [-0.91113026, -0.83907153,  0.0044257 ],
                                    [ 0.84385396,  0.90744678,  0.13673722]], mftype: .Float))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(Matft.math.sin(a.transpose(axes: [0, 2, 3, 1])),
                           MfArray([[[[ 0.0        , -0.7568025 ],
                                      [ 0.84147098, -0.95892427]],

                                     [[ 0.90929743, -0.2794155 ],
                                      [ 0.14112001,  0.6569866 ]]],


                                    [[[ 0.98935825, -0.53657292],
                                      [ 0.41211849,  0.42016704]],

                                     [[-0.54402111,  0.99060736],
                                      [-0.99999021,  0.65028784]]]], mftype: .Float))
            
            XCTAssertEqual(Matft.math.cos(a.transpose(axes: [0, 2, 3, 1])),
                           MfArray([[[[ 1.0        , -0.65364362],
                                      [ 0.54030231,  0.28366219]],

                                     [[-0.41614684,  0.96017029],
                                      [-0.9899925 ,  0.75390225]]],


                                    [[[-0.14550003,  0.84385396],
                                      [-0.91113026,  0.90744678]],
                                     
                                     [[-0.83907153,  0.13673722],
                                      [ 0.0044257 , -0.75968791]]]], mftype: .Float))
            
            XCTAssertEqual(Matft.math.sin(a.transpose(axes: [3,0,2,1])*3.1415926535).round(decimals: 7),
                           MfArray([[[[ 0, 0],
                                      [0, 0]],

                                     [[0, 0],
                                      [0, 0]]],


                                    [[[ 0,  0],
                                      [ 0,  0]],

                                     [[ 0, 0],
                                      [ 0,  0]]]], mftype: .Float))
            
            XCTAssertEqual(Matft.math.cos(a.transpose(axes: [3,0,2,1])*3.1415926535),
                           MfArray([[[[ 1.0,  1.0],
                                      [ 1.0,  1.0]],

                                     [[ 1.0,  1.0],
                                      [ 1.0,  1.0]]],


                                    [[[-1.0, -1.0],
                                      [-1.0, -1.0]],

                                     [[-1.0, -1.0],
                                      [-1.0, -1.0]]]], mftype: .Float))
        }
    }
    
    func testSign(){
        do{
            let a = MfArray([[[[ 1.0        , -0.65364362],
                               [ 0.54030231,  0.28366219]],

                              [[-0.41614684,  0.96017029],
                               [-0.9899925 ,  0.75390225]]],


                             [[[-0.14550003,  0.84385396],
                               [-0.91113026,  0.90744678]],
             
                              [[-0.83907153,  0.13673722],
                               [ 0.0044257 , -0.75968791]]]], mftype: .Float)
            
            XCTAssertEqual(a.sign(), MfArray([[[[ 1.0, -1.0],
                                                [ 1.0,  1.0]],

                                              [[-1.0,  1.0],
                                               [-1.0,  1.0]]],


                                              [[[-1.0,  1.0],
                                                [-1.0,  1.0]],

                                               [[-1.0,  1.0],
                                                [ 1.0, -1.0]]]], mftype: .Float))
        }
        
        do{
            let a = MfArray([[ 1.0        ,  0.54030231, -0.41614684],
                             [-0.9899925 , -0.65364362,  0.28366219],
                             [ 0.96017029,  0.75390225, -0.14550003],
                             [-0.91113026, -0.83907153,  0.0044257 ],
                             [ 0.84385396,  0.90744678,  0.13673722]])
            
            XCTAssertEqual(a.T.sign(), MfArray([[ 1.0, -1.0,  1.0, -1.0,  1.0],
                                                [ 1.0, -1.0,  1.0, -1.0,  1.0],
                                                [-1.0,  1.0, -1.0,  1.0,  1.0]]))
        }
    }
    
    func testPower(){
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(Matft.math.power(base: 2, exponents: a), MfArray([[[[    1.0,        2.0],
                                                                               [    4.0,        8.0]],

                                                                              [[    16.0,        32.0],
                                                                               [    64.0,        128.0]]],


                                                                             [[[    256.0,        512.0],
                                                                               [    1024.0,        2048.0]],

                                                                              [[    4096.0,        8192.0],
                                                                               [    16384.0,        32768.0]]]]))
            let b = Matft.nums(2, shape: [1])
            XCTAssertEqual(Matft.math.power(bases: b, exponents: a), MfArray([[[[    1.0,        2.0],
                                                                               [    4.0,        8.0]],

                                                                              [[    16.0,        32.0],
                                                                               [    64.0,        128.0]]],


                                                                             [[[    256.0,        512.0],
                                                                               [    1024.0,        2048.0]],

                                                                              [[    4096.0,        8192.0],
                                                                               [    16384.0,        32768.0]]]]))
            XCTAssertEqual(Matft.math.power(bases: a, exponent: 2).round(decimals: 4),
                           MfArray([[[[  0,   1],
                                      [  4,   9]],

                                     [[ 16,  25],
                                      [ 36,  49]]],


                                    [[[ 64,  81],
                                      [100, 121]],

                                     [[144, 169],
                                      [196, 225]]]], mftype: .Float))
        }
    }
}
*/
