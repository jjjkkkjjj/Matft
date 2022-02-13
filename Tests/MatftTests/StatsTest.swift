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

    func testSum(){
        
        do{
            let a = MfArray<Double>([[3, -19],
                                     [-22, 4]] as [[Double]])
            
            XCTAssertEqual(Matft.stats.sum(a), MfArray<Double>([-34.0]))
            
            XCTAssertEqual(Matft.stats.sum(a, axis: 0), MfArray<Double>([-19.0, -15.0]))
            XCTAssertEqual(Matft.stats.sum(a, axis: -1), MfArray<Double>([-16.0, -18.0]))

            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.sum(b), MfArray<Int>([1141]))
                       
            XCTAssertEqual(Matft.stats.sum(b, axis: 0),
                           MfArray<Int>([   7, 1134]))
            XCTAssertEqual(Matft.stats.sum(b, axis: -1),                            MfArray<Int>([1179,  -38]))
        }

        do{
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.sum(a), MfArray<Double>([0.46319999999999695]))
            
            XCTAssertEqual(Matft.stats.sum(a, axis: 0), MfArray<Double>([  5.0    ,   2.0    ,   1.0   ,  -5.0    ,  -0.8702,   3.2   ,
                        8.9134, -13.78  ]))
            XCTAssertEqual(Matft.stats.sum(a, axis: -1), MfArray<Double>([-2.9366,  3.3998]))
        }
        
        do{
            let a = MfArray<UInt8>([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]] as [[UInt8]]).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.stats.sum(a), MfArray<UInt8>([120] as [UInt8]))
            
            XCTAssertEqual(Matft.stats.sum(a, axis: 0), MfArray<UInt8>([[[  2,  10],
                              [ 18,  26]],

                             [[253, 248],
                              [  4,  12]],

                             [[ 20,  28],
                              [  7,   4]]] as [[[UInt8]]]))
            XCTAssertEqual(Matft.stats.sum(a, axis: -1), MfArray<UInt8>([[[  4,  20],
                               [242,   6],
                               [ 22,   6]],

                              [[  8,  24],
                               [  3,  10],
                               [ 26,   5]]] as [[[UInt8]]]))
            XCTAssertEqual(Matft.stats.sum(a, axis: 1, keepDims: true), MfArray<UInt8>([[[[4, 8],
                               [ 12,  20]]],

                             
                             [[[ 15,  22],
                               [ 17,  22]]]] as [[[[UInt8]]]]))
        }

        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.sum(a[0]), MfArray<Int>([-16]))
            XCTAssertEqual(Matft.stats.sum(a[0~<,1]), MfArray<Int>([-15]))
            
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.sum(b[0]), MfArray<Int>([1179]))
            XCTAssertEqual(Matft.stats.sum(b[0~<,1]), MfArray<Int>([1134]))
        }

        do{
            let a = MfArray<Float>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]] as [[Float]], mforder: .Column)

            XCTAssertEqual(Matft.stats.sum(a[0~<, 1~<5]), MfArray<Float>([-2.8702000000000005] as [Float]))
        }
    }
    
    func testSquareSum(){
        
        do{
            let a = MfArray<Double>([[3, -19],
                                     [-22, 4]] as [[Double]])
            
            XCTAssertEqual(Matft.stats.squaresum(a), MfArray<Double>([870.0]))
            
            XCTAssertEqual(Matft.stats.squaresum(a, axis: 0), MfArray<Double>([493.0, 377.0]))
            XCTAssertEqual(Matft.stats.squaresum(a, axis: -1), MfArray<Double>([370.0, 500.0]))

            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.squaresum(b), MfArray<Int>([1387207]))
                       
            XCTAssertEqual(Matft.stats.squaresum(b, axis: 0),
                           MfArray<Int>([ 29, 1387178]))
            XCTAssertEqual(Matft.stats.squaresum(b, axis: -1),             MfArray<Int>([1385333, 1874]))
        }
    }
}
