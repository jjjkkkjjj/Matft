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
    

    func testMin() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.min(a), MfArray<Int>([-22]))

            XCTAssertEqual(Matft.stats.min(a, axis: 0), MfArray<Int>([-22, -19]))
            XCTAssertEqual(Matft.stats.min(a, axis: -1), MfArray<Int>([-19, -22]))
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.min(b), MfArray<Int>([-43]))

            XCTAssertEqual(Matft.stats.min(b, axis: 0),
                           MfArray<Int>([2, -43]))
            XCTAssertEqual(Matft.stats.min(b, axis: -1), MfArray<Int>([2, -43]))
        }

        do{
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.min(a), MfArray<Double>([-8.78]))

            XCTAssertEqual(Matft.stats.min(a, axis: 0), MfArray<Double>([ 2.0  ,  1.0  , -3.0  , -5.0  , -0.87,  1.2 ,  3.4 , -8.78]))
            XCTAssertEqual(Matft.stats.min(a, axis: -1), MfArray<Double>([-8.78, -5.0  ]))
        }
        
        do{
            let a = MfArray<UInt8>([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]] as [[UInt8]]).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.stats.min(a), MfArray<UInt8>([0] as [UInt8]))
            
            XCTAssertEqual(Matft.stats.min(a, axis: 0), MfArray<UInt8>([[[ 0,  4],
                                  [ 8, 12]],

                                 [[ 2,  1],
                                  [ 1,  5]],

                                 [[ 9, 13],
                                  [ 3,  1]]] as [[[UInt8]]]))
            XCTAssertEqual(Matft.stats.min(a, axis: -1), MfArray<UInt8>([[[  0,   8],
                               [247,   1],
                               [  9,   3]],

                              [[  2,  10],
                               [  1,   3],
                               [ 11,   1]]] as [[[UInt8]]]))
            XCTAssertEqual(Matft.stats.min(a, axis: 1, keepDims: true), MfArray<UInt8>([[[[0, 4],
                               [1, 3]]],


                             [[[2, 1],
                               [3, 1]]]] as [[[[UInt8]]]]))
                
        }
    }

    func testMax() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.max(a), MfArray<Int>([4]))
            
            XCTAssertEqual(Matft.stats.max(a, axis: 0),
                           MfArray<Int>([3, 4]))
            XCTAssertEqual(Matft.stats.max(a, axis: -1), MfArray<Int>([3, 4]))
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.max(b), MfArray<Int>([1177]))
            
            XCTAssertEqual(Matft.stats.max(b, axis: 0),
                MfArray<Int>([5, 1177]))
            XCTAssertEqual(Matft.stats.max(b, axis: -1), MfArray<Int>([1177, 5]))
        }

        do{
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.max(a), MfArray<Double>([5.5134]))

            XCTAssertEqual(Matft.stats.max(a, axis: 0), MfArray<Double>([ 3.0000e+00,  1.0000e+00,  4.0000e+00,  0.0000e+00, -2.0000e-04,
            2.0000e+00,  5.5134e+00, -5.0000e+00]))
            XCTAssertEqual(Matft.stats.max(a, axis: -1), MfArray<Double>([5.5134, 4.0    ]))
        }
        
        do{
            let a = MfArray<UInt8>([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]] as [[UInt8]]).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.stats.max(a), MfArray<UInt8>([251] as [UInt8]))
            
            XCTAssertEqual(Matft.stats.max(a, axis: 0), MfArray<UInt8>([[[  2,   6],
                                  [ 10,  14]],

                                 [[251, 247],
                                  [  3,   7]],

                                 [[ 11,  15],
                                  [  4,   3]]] as [[[UInt8]]]))
            XCTAssertEqual(Matft.stats.max(a, axis: -1), MfArray<UInt8>([[[  4,  12],
                               [251,   5],
                               [ 13,   3]],
                              
                              [[  6,  14],
                               [  2,   7],
                               [ 15,   4]]] as [[[UInt8]]]))
            XCTAssertEqual(Matft.stats.max(a, axis: 1, keepDims: true), MfArray<UInt8>([[[[251, 247],
                               [  8,  12]]],


                             [[[ 11,  15],
                               [ 10,  14]]]] as [[[[UInt8]]]]))
                
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
    
    func testMinimum() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            

            XCTAssertEqual(Matft.stats.minimum(a, b), MfArray<Int>([[2,-19],[-22,-43]]))
            XCTAssertEqual(Matft.stats.minimum(b, a), MfArray<Int>([[2,-19],[-22,-43]]))

        }
        
        do{
            
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0],
                                     [3.0, 1.0, 4.0, -5.0]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mforder: .Column)


            XCTAssertEqual(Matft.stats.minimum(a, b), MfArray<Double>([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]] as [[Double]]))
            XCTAssertEqual(Matft.stats.minimum(b, a), MfArray<Double>([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]] as [[Double]]))
        }
        
        do{

            let a = MfArray<Int>([[[[33, 74],
                                    [62, 33],
                                    [79, 78]]],


                                  [[[74, 19],
                                    [83, 58],
                                    [89,  3]]],


                                  [[[26, 11],
                                    [77, 27],
                                    [93, 86]]]])
            let b = MfArray<Int>([[[22, 36],
                                   [66, 63],
                                   [48, 27]],

                                  [[ 1, 47],
                                   [36, 91],
                                   [ 7, 63]],

                                  [[61, 92],
                                   [72, 21],
                                   [24, 21]],

                                  [[38, 66],
                                   [64, 81],
                                   [35, 53]]])

            XCTAssertEqual(Matft.stats.minimum(a, b), MfArray<Int>([[[[22, 36],
                              [62, 33],
                              [48, 27]],

                             [[ 1, 47],
                              [36, 33],
                              [ 7, 63]],

                             [[33, 74],
                              [62, 21],
                              [24, 21]],

                             [[33, 66],
                              [62, 33],
                              [35, 53]]],


                            [[[22, 19],
                              [66, 58],
                              [48,  3]],

                             [[ 1, 19],
                              [36, 58],
                              [ 7,  3]],

                             [[61, 19],
                              [72, 21],
                              [24,  3]],

                             [[38, 19],
                              [64, 58],
                              [35,  3]]],


                            [[[22, 11],
                              [66, 27],
                              [48, 27]],

                             [[ 1, 11],
                              [36, 27],
                              [ 7, 63]],

                             [[26, 11],
                              [72, 21],
                              [24, 21]],

                             [[26, 11],
                              [64, 27],
                              [35, 53]]]]))
        }
    }
    
    func testMaximum() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.maximum(a, b), MfArray<Int>([[3,1177],[5,4]]))
            XCTAssertEqual(Matft.stats.maximum(b, a), MfArray<Int>([[3,1177],[5,4]]))

        }
        
        do{
            
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0],
                                     [3.0, 1.0, 4.0, -5.0]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mforder: .Column)

            XCTAssertEqual(Matft.stats.maximum(a, b), MfArray<Double>([[2,1.2,5.5134,0],[3,2,4,-5]] as [[Double]]))
            XCTAssertEqual(Matft.stats.maximum(b, a), MfArray<Double>([[2,1.2,5.5134,0],[3,2,4,-5]] as [[Double]]))
        }
        
        do{

            let a = MfArray<Int>([[[[33, 74],
                                    [62, 33],
                                    [79, 78]]],


                                  [[[74, 19],
                                    [83, 58],
                                    [89,  3]]],


                                  [[[26, 11],
                                    [77, 27],
                                    [93, 86]]]])
            let b = MfArray<Int>([[[22, 36],
                                   [66, 63],
                                   [48, 27]],

                                  [[ 1, 47],
                                   [36, 91],
                                   [ 7, 63]],

                                  [[61, 92],
                                   [72, 21],
                                   [24, 21]],

                                  [[38, 66],
                                   [64, 81],
                                   [35, 53]]])

            XCTAssertEqual(Matft.stats.maximum(a, b), MfArray<Int>([[[[33, 74],
                              [66, 63],
                              [79, 78]],

                             [[33, 74],
                              [62, 91],
                              [79, 78]],

                             [[61, 92],
                              [72, 33],
                              [79, 78]],

                             [[38, 74],
                              [64, 81],
                              [79, 78]]],


                            [[[74, 36],
                              [83, 63],
                              [89, 27]],

                             [[74, 47],
                              [83, 91],
                              [89, 63]],
                             
                             [[74, 92],
                              [83, 58],
                              [89, 21]],

                             [[74, 66],
                              [83, 81],
                              [89, 53]]],



                            [[[26, 36],
                              [77, 63],
                              [93, 86]],

                             [[26, 47],
                              [77, 91],
                              [93, 86]],

                             [[61, 92],
                              [77, 27],
                              [93, 86]],

                             [[38, 66],
                              [77, 81],
                              [93, 86]]]]))
        }
    }

    func testCumsum(){
        do{
            let a = MfArray<Int>([[1,2,3],
                             [4,5,6]])

            XCTAssertEqual(a.cumsum(),
                           MfArray<Int>([ 1,  3,  6, 10, 15, 21]))
            XCTAssertEqual(a.cumsum(axis: 0),
                           MfArray<Int>([[1, 2, 3],
                                       [5, 7, 9]]))
            XCTAssertEqual(a.cumsum(axis: 1),
                           MfArray<Int>([[ 1,  3,  6],
                                       [ 4,  9, 15]]))
        }

        do{
            let a = MfArray<Int>([[1, 2],
                             [3, 4],
                             [5, 6]])

            XCTAssertEqual(a.cumsum(),
                           MfArray<Int>([1, 3, 6, 10, 15, 21]))
            XCTAssertEqual(a.cumsum(axis: 0),
                           MfArray<Int>([[ 1,  2],
                                       [ 4,  6],
                                       [ 9, 12]]))
            XCTAssertEqual(a.cumsum(axis: 1),
                           MfArray<Int>([[ 1,  3],
                                       [ 3,  7],
                                       [ 5, 11]]))

            XCTAssertEqual(a.T.cumsum(),
                           MfArray<Int>([ 1,  4,  9, 11, 15, 21]))
            XCTAssertEqual(a[1~<].cumsum(),
                           MfArray<Int>([ 3,  7, 12, 18]))
            XCTAssertEqual(a[~<<2].cumsum(axis: 1),
                           MfArray<Int>([[ 1,  3],
                                         [ 5, 11]]))
        }
    }
}
