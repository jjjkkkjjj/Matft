//
//  MathTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import XCTest
import Matft

final class MathTests: XCTestCase {
    
    func testSinCos() {
        do{
            let a = Matft.arange(start: Float.zero, to: 15, by: 1, shape: [3, 5], mforder: .Column)
            
            XCTAssertEqual(Matft.math.sin(a),
                           MfArray<Float>([[ 0.0        ,  0.14112001, -0.2794155 ,  0.41211849, -0.53657292],
                                    [ 0.84147098, -0.7568025 ,  0.6569866 , -0.54402111,  0.42016704],
                                    [ 0.90929743, -0.95892427,  0.98935825, -0.99999021,  0.99060736]] as [[Float]]))
            
            XCTAssertEqual(Matft.math.cos(a),
                           MfArray<Float>([[ 1.0        , -0.9899925 ,  0.96017029, -0.91113026,  0.84385396],
                                    [ 0.54030231, -0.65364362,  0.75390225, -0.83907153,  0.90744678],
                                    [-0.41614684,  0.28366219, -0.14550003,  0.0044257 ,  0.13673722]] as [[Float]]))
            
            XCTAssertEqual(Matft.math.sin(a.T),
                           MfArray<Float>([[ 0.0        ,  0.84147098,  0.90929743],
                                    [ 0.14112001, -0.7568025 , -0.95892427],
                                    [-0.2794155 ,  0.6569866 ,  0.98935825],
                                    [ 0.41211849, -0.54402111, -0.99999021],
                                    [-0.53657292,  0.42016704,  0.99060736]] as [[Float]]))
            
            XCTAssertEqual(Matft.math.cos(a.T),
                           MfArray<Float>([[ 1.0        ,  0.54030231, -0.41614684],
                                    [-0.9899925 , -0.65364362,  0.28366219],
                                    [ 0.96017029,  0.75390225, -0.14550003],
                                    [-0.91113026, -0.83907153,  0.0044257 ],
                                    [ 0.84385396,  0.90744678,  0.13673722]] as [[Float]]))
            
        }
        
        do{
            let a = Matft.arange(start: Float.zero, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(Matft.math.sin(a.transpose(axes: [0, 2, 3, 1])),
                           MfArray<Float>([[[[ 0.0        , -0.7568025 ],
                                      [ 0.84147098, -0.95892427]],

                                     [[ 0.90929743, -0.2794155 ],
                                      [ 0.14112001,  0.6569866 ]]],


                                    [[[ 0.98935825, -0.53657292],
                                      [ 0.41211849,  0.42016704]],

                                     [[-0.54402111,  0.99060736],
                                      [-0.99999021,  0.65028784]]]] as [[[[Float]]]]))
            
            XCTAssertEqual(Matft.math.cos(a.transpose(axes: [0, 2, 3, 1])),
                           MfArray<Float>([[[[ 1.0        , -0.65364362],
                                      [ 0.54030231,  0.28366219]],

                                     [[-0.41614684,  0.96017029],
                                      [-0.9899925 ,  0.75390225]]],


                                    [[[-0.14550003,  0.84385396],
                                      [-0.91113026,  0.90744678]],
                                     
                                     [[-0.83907153,  0.13673722],
                                      [ 0.0044257 , -0.75968791]]]] as [[[[Float]]]]))
        }
            
    }
        
    func testRound(){
        do {
            let a = Matft.arange(start: Float.zero, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            
            XCTAssertEqual(Matft.math.sin(a.transpose(axes: [3,0,2,1])*3.1415926535).round(decimals: 7),
                           MfArray<Float>([[[[ 0, 0],
                                      [0, 0]],

                                     [[0, 0],
                                      [0, 0]]],


                                    [[[ 0,  0],
                                      [ 0,  0]],

                                     [[ 0, 0],
                                      [ 0,  0]]]] as [[[[Float]]]]))
            
            XCTAssertEqual(Matft.math.cos(a.transpose(axes: [3,0,2,1])*3.1415926535),
                           MfArray<Float>([[[[ 1.0,  1.0],
                                      [ 1.0,  1.0]],

                                     [[ 1.0,  1.0],
                                      [ 1.0,  1.0]]],


                                    [[[-1.0, -1.0],
                                      [-1.0, -1.0]],

                                     [[-1.0, -1.0],
                                      [-1.0, -1.0]]]] as [[[[Float]]]]))
        }
    }
    
    func testAbs(){
        do{
            let a = MfArray<Float>([[[[ 1.0        , -0.65364362],
                               [ 0.54030231,  0.28366219]],

                              [[-0.41614684,  0.96017029],
                               [-0.9899925 ,  0.75390225]]],


                             [[[-0.14550003,  0.84385396],
                               [-0.91113026,  0.90744678]],
             
                              [[-0.83907153,  0.13673722],
                               [ 0.0044257 , -0.75968791]]]] as [[[[Float]]]])
            XCTAssertEqual(Matft.math.abs(a),
                   MfArray<Float>([[[[ 1.0        ,  0.65364362],
                                      [ 0.54030231,  0.28366219]],

                                     [[ 0.41614684,  0.96017029],
                                      [ 0.9899925 ,  0.75390225]]],


                                    [[[ 0.14550003,  0.84385396],
                                      [ 0.91113026,  0.90744678]],
                    
                                     [[ 0.83907153,  0.13673722],
                                      [ 0.0044257 ,  0.75968791]]]] as [[[[Float]]]]))
        }
    }
    
    func testReciprocal(){
        do{
            let a = MfArray<Float>([[[[ 1.0        , -0.65364362],
                               [ 0.54030231,  0.28366219]],

                              [[-0.41614684,  0.96017029],
                               [-0.9899925 ,  0.75390225]]],


                             [[[-0.14550003,  0.84385396],
                               [-0.91113026,  0.90744678]],
             
                              [[-0.83907153,  0.13673722],
                               [ 0.0044257 , -0.75968791]]]] as [[[[Float]]]])
            XCTAssertEqual(Matft.math.reciprocal(a),
               MfArray<Float>([[[[    1.0,        -1.5298856],
                                 [    1.8508157,        3.5253198]],

                                 [[    -2.402998,        1.041482],
                                 [    -1.0101087,        1.3264319]]],


                                 [[[    -6.8728504,        1.1850392],
                                 [    -1.0975379,        1.101993]],

                                 [[    -1.1917936,        7.3132973],
                                 [    225.95297,        -1.3163301]]]] as [[[[Float]]]]))
        }
    }
    
    func testSign(){
        do{
            let a = MfArray<Float>([[[[ 1.0        , -0.65364362],
                               [ 0.54030231,  0.28366219]],

                              [[-0.41614684,  0.96017029],
                               [-0.9899925 ,  0.75390225]]],


                             [[[-0.14550003,  0.84385396],
                               [-0.91113026,  0.90744678]],
             
                              [[-0.83907153,  0.13673722],
                               [ 0.0044257 , -0.75968791]]]] as [[[[Float]]]])
            
            XCTAssertEqual(a.sign(), MfArray<Float>([[[[ 1.0, -1.0],
                                                [ 1.0,  1.0]],

                                              [[-1.0,  1.0],
                                               [-1.0,  1.0]]],


                                              [[[-1.0,  1.0],
                                                [-1.0,  1.0]],

                                               [[-1.0,  1.0],
                                                [ 1.0, -1.0]]]] as [[[[Float]]]]))
        }
        
        do{
            let a = MfArray<Float>([[ 1.0        ,  0.54030231, -0.41614684],
                             [-0.9899925 , -0.65364362,  0.28366219],
                             [ 0.96017029,  0.75390225, -0.14550003],
                             [-0.91113026, -0.83907153,  0.0044257 ],
                             [ 0.84385396,  0.90744678,  0.13673722]] as [[Float]])
            
            XCTAssertEqual(a.T.sign(), MfArray<Float>([[ 1.0, -1.0,  1.0, -1.0,  1.0],
                                                [ 1.0, -1.0,  1.0, -1.0,  1.0],
                                                [-1.0,  1.0, -1.0,  1.0,  1.0]] as [[Float]]))
        }
        do{
            let a = MfArray<Double>([0.2, -0.02, 0.0, 3.2])
            XCTAssertEqual(a.sign(), MfArray<Double>([1.0, -1.0, 0.0, 1.0]))
        }
        
        do{
            let a = MfArray<Int>([[ 2,  0],
                             [ 1,  2],
                             [-2,  1],
                             [ 2,  2],
                             [ 0,  2]] as [[Int]])
            XCTAssertEqual(a.sign(), MfArray<Int>([[ 1,  0],
                                              [ 1,  1],
                                              [-1,  1],
                                              [ 1,  1],
                                              [ 0,  1]] as [[Int]]))
        }
    }
}
