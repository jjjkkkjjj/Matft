//
//  StatsTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//



import XCTest
import Matft

final class StatsTests: XCTestCase {
    func testMean(){
        
        do{
            let a = MfArray<Double>([[3, -19],
                                     [-22, 4]] as [[Double]])
            
            XCTAssertEqual(Matft.stats.mean(a), MfArray<Double>([-8.5]))
            
            XCTAssertEqual(Matft.stats.mean(a, axis: 0), MfArray<Double>([-9.5, -7.5]))
            XCTAssertEqual(Matft.stats.mean(a, axis: -1), MfArray<Double>([-8.0, -9.0]))

            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.mean(b), MfArray<Float>([285.25]  as [Float]))

            XCTAssertEqual(Matft.stats.mean(b, axis: 0), MfArray<Float>([  3.5, 567.0 ] as [Float]))
            XCTAssertEqual(Matft.stats.mean(b, axis: -1), MfArray<Float>([589.5, -19.0 ] as [Float]))
        }

        do{
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.mean(a), MfArray<Double>([0.02894999999999981]))
            
            XCTAssertEqual(Matft.stats.mean(a, axis: 0), MfArray<Double>([ 2.5   ,  1.0    ,  0.5   , -2.5   , -0.4351,  1.6   ,  4.4567,
            -6.89  ]))
            XCTAssertEqual(Matft.stats.mean(a, axis: -1), MfArray<Double>([-0.367075,  0.424975]))
        }
        
        do{
            let a = MfArray<UInt8>([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]] as [[UInt8]]).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.stats.mean(a), MfArray<Float>([26.333333333333332] as [Float]))
            
            XCTAssertEqual(Matft.stats.mean(a, axis: 0), MfArray<Float>([[[  1.0 ,   5.0 ],
                               [  9.0 ,  13.0 ]],

                              [[126.5, 124.0 ],
                               [  2.0 ,   6.0 ]],

                              [[ 10.0 ,  14.0 ],
                               [  3.5,   2.0 ]]] as [[[Float]]]))
            XCTAssertEqual(Matft.stats.mean(a, axis: -1), MfArray<Float>([[[  2.0 ,  10.0 ],
                                [249.0 ,   3.0 ],
                                [ 11.0 ,   3.0 ]],

                               [[  4.0 ,  12.0 ],
                                [  1.5,   5.0 ],
                                [ 13.0 ,   2.5]]] as [[[Float]]]))
            XCTAssertEqual(Matft.stats.mean(a, axis: 1, keepDims: true), MfArray<Float>([[[[86.66666667, 88.0        ],
                                [ 4.0        ,  6.66666667]]],


                              [[[ 5.0       ,  7.33333333],
                                [ 5.66666667,  7.33333333]]]] as [[[[Float]]]]))
        }

        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.mean(a[0]), MfArray<Float>([-8.0] as [Float]))
            XCTAssertEqual(Matft.stats.mean(a[0~<,1]), MfArray<Float>([-7.5] as [Float]))
            
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.mean(b[0]), MfArray<Float>([589.5] as [Float]))
            XCTAssertEqual(Matft.stats.mean(b[0~<,1]), MfArray<Float>([567] as [Float]))
        }

        do{
            let a = MfArray<Float>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]] as [[Float]], mforder: .Column)

            XCTAssertEqual(Matft.stats.mean(a[0~<, 1~<5]), MfArray<Float>([-0.35877500000000007] as [Float]))
        }
    }

}
