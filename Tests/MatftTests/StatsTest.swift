import XCTest
//@testable import Matft
import Matft

final class StatsTests: XCTestCase {
    
    func test_minmax() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.min(a), MfArray<Int>([-22]))
            XCTAssertEqual(Matft.stats.max(a), MfArray<Int>([4]))
            
            XCTAssertEqual(Matft.stats.min(a, axis: 0), MfArray<Int>([-22, -19]))
            XCTAssertEqual(Matft.stats.min(a, axis: -1), MfArray<Int>([-19, -22]))
            XCTAssertEqual(Matft.stats.max(a, axis: 0), MfArray<Int>([3, 4]))
            XCTAssertEqual(Matft.stats.max(a, axis: -1), MfArray<Int>([3, 4]))
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.min(b), MfArray<Int>([-43]))
            XCTAssertEqual(Matft.stats.max(b), MfArray<Int>([1177]))
            
            XCTAssertEqual(Matft.stats.min(b, axis: 0), MfArray<Int>([2, -43]))
            XCTAssertEqual(Matft.stats.min(b, axis: -1), MfArray<Int>([2, -43]))
            XCTAssertEqual(Matft.stats.max(b, axis: 0), MfArray<Int>([5, 1177]))
            XCTAssertEqual(Matft.stats.max(b, axis: -1), MfArray<Int>([1177, 5]))
        }

        do{
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.min(a), MfArray<Double>([-8.78]))
            XCTAssertEqual(Matft.stats.max(a), MfArray<Double>([5.5134]))
            
            XCTAssertEqual(Matft.stats.min(a, axis: 0), MfArray<Double>([ 2.0  ,  1.0  , -3.0  , -5.0  , -0.87,  1.2 ,  3.4 , -8.78]))
            XCTAssertEqual(Matft.stats.min(a, axis: -1), MfArray<Double>([-8.78, -5.0  ]))
            XCTAssertEqual(Matft.stats.max(a, axis: 0), MfArray<Double>([ 3.0000e+00,  1.0000e+00,  4.0000e+00,  0.0000e+00, -2.0000e-04,
            2.0000e+00,  5.5134e+00, -5.0000e+00]))
            XCTAssertEqual(Matft.stats.max(a, axis: -1), MfArray<Double>([5.5134, 4.0    ]))
        }
        
        do{
            let a = MfArray<UInt8>([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]]).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.stats.min(a), MfArray<UInt8>([0]))
            XCTAssertEqual(Matft.stats.max(a), MfArray<UInt8>([251]))
            
            XCTAssertEqual(Matft.stats.min(a, axis: 0), MfArray<UInt8>([[[ 0,  4],
                                                                          [ 8, 12]],

                                                                         [[ 2,  1],
                                                                          [ 1,  5]],

                                                                         [[ 9, 13],
                                                                          [ 3,  1]]]))
            XCTAssertEqual(Matft.stats.min(a, axis: -1), MfArray<UInt8>([[[  0,   8],
                                                                           [247,   1],
                                                                           [  9,   3]],

                                                                          [[  2,  10],
                                                                           [  1,   3],
                                                                           [ 11,   1]]]))
            XCTAssertEqual(Matft.stats.min(a, axis: 1, keepDims: true), MfArray<UInt8>([[[[0, 4],
                                                                                           [1, 3]]],


                                                                                         [[[2, 1],
                                                                                           [3, 1]]]]))
            XCTAssertEqual(Matft.stats.max(a, axis: 0), MfArray<UInt8>([[[  2,   6],
                                                                          [ 10,  14]],

                                                                         [[251, 247],
                                                                          [  3,   7]],

                                                                         [[ 11,  15],
                                                                          [  4,   3]]]))
            XCTAssertEqual(Matft.stats.max(a, axis: -1), MfArray<UInt8>([[[  4,  12],
                                                                           [251,   5],
                                                                           [ 13,   3]],
                                                                          
                                                                          [[  6,  14],
                                                                           [  2,   7],
                                                                           [ 15,   4]]]))
            XCTAssertEqual(Matft.stats.max(a, axis: 1, keepDims: true), MfArray<UInt8>([[[[251, 247],
                                                                                           [  8,  12]]],


                                                                                         [[[ 11,  15],
                                                                                           [ 10,  14]]]]))
                
        }
    }
    
    func test_argminmax(){
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.argmin(a), MfArray<Int>([2]))
            XCTAssertEqual(Matft.stats.argmax(a), MfArray<Int>([3]))
            
            XCTAssertEqual(Matft.stats.argmin(a, axis: 0), MfArray<Int>([1, 0]))
            XCTAssertEqual(Matft.stats.argmin(a, axis: -1), MfArray<Int>([1, 0]))
            XCTAssertEqual(Matft.stats.argmax(a, axis: 0), MfArray<Int>([0, 1]))
            XCTAssertEqual(Matft.stats.argmax(a, axis: -1), MfArray<Int>([0, 1]))
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.argmin(b), MfArray<Int>([3]))
            XCTAssertEqual(Matft.stats.argmax(b), MfArray<Int>([1]))
            
            XCTAssertEqual(Matft.stats.argmin(b, axis: 0), MfArray<Int>([0, 1]))
            XCTAssertEqual(Matft.stats.argmin(b, axis: -1), MfArray<Int>([0, 1]))
            XCTAssertEqual(Matft.stats.argmax(b, axis: 0), MfArray<Int>([1, 0]))
            XCTAssertEqual(Matft.stats.argmax(b, axis: -1), MfArray<Int>([1, 0]))
        }

        do{
            
            let a = MfArray<UInt8>([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]]).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.stats.argmin(a), MfArray<Int>([0]))
            XCTAssertEqual(Matft.stats.argmax(a), MfArray<Int>([4]))
            
            XCTAssertEqual(Matft.stats.argmin(a, axis: 0), MfArray<Int>([[[0, 0],
                                                                             [0, 0]],

                                                                            [[1, 1],
                                                                             [0, 0]],

                                                                            [[0, 0],
                                                                             [0, 1]]]))
            XCTAssertEqual(Matft.stats.argmin(a, axis: -1), MfArray<Int>([[[0, 0],
                                                                              [1, 0],
                                                                              [0, 0]],

                                                                             [[0, 0],
                                                                              [1, 0],
                                                                              [0, 1]]]))
            XCTAssertEqual(Matft.stats.argmin(a, axis: 1), MfArray<Int>([[[0, 0],
                                                                             [1, 2]],

                                                                            [[0, 1],
                                                                             [1, 2]]]))
            XCTAssertEqual(Matft.stats.argmax(a, axis: 0), MfArray<Int>([[[1, 1],
                                                                             [1, 1]],

                                                                            [[0, 0],
                                                                             [1, 1]],
                                                                            
                                                                            [[1, 1],
                                                                             [1, 0]]]))
            XCTAssertEqual(Matft.stats.argmax(a, axis: -1), MfArray<Int>([[[1, 1],
                                                                              [0, 1],
                                                                              [1, 0]],

                                                                             [[1, 1],
                                                                              [0, 1],
                                                                              [1, 0]]]))
            XCTAssertEqual(Matft.stats.argmax(a, axis: 1), MfArray<Int>([[[1, 1],
                                                                             [0, 0]],

                                                                            [[2, 2],
                                                                             [0, 0]]]))

        }
        
        do{
            let a = MfArray<Float>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.argmin(a), MfArray<Int>([7]))
            XCTAssertEqual(Matft.stats.argmax(a), MfArray<Int>([6]))
            
            XCTAssertEqual(Matft.stats.argmin(a, axis: 0), MfArray<Int>([0, 0, 0, 1, 0, 0, 1, 0]))
            XCTAssertEqual(Matft.stats.argmin(a, axis: -1), MfArray<Int>([7, 3]))
            XCTAssertEqual(Matft.stats.argmax(a, axis: 0), MfArray<Int>([1, 0, 1, 0, 1, 1, 0, 1]))
            XCTAssertEqual(Matft.stats.argmax(a, axis: -1), MfArray<Int>([6, 2]))
        }
        
    }
    
    func test_minimummaximum() {
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.maximum(a, b), MfArray<Int>([[3,1177],[5,4]]))
            XCTAssertEqual(Matft.stats.maximum(b, a), MfArray<Int>([[3,1177],[5,4]]))

            XCTAssertEqual(Matft.stats.minimum(a, b), MfArray<Int>([[2,-19],[-22,-43]]))
            XCTAssertEqual(Matft.stats.minimum(b, a), MfArray<Int>([[2,-19],[-22,-43]]))

        }
        
        do{
            
            let a = MfArray<Double>([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mforder: .Column)

            XCTAssertEqual(Matft.stats.maximum(a, b), MfArray<Double>([[2,1.2,5.5134,0],[3,2,4,-5]]))
            XCTAssertEqual(Matft.stats.maximum(b, a), MfArray<Double>([[2,1.2,5.5134,0],[3,2,4,-5]]))

            XCTAssertEqual(Matft.stats.minimum(a, b), MfArray<Double>([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]]))
            XCTAssertEqual(Matft.stats.minimum(b, a), MfArray<Double>([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]]))
        }

    }
    
    func test_statsval(){
        do{
            let a = MfArray<Double>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.mean(a), MfArray<Double>([-8.5]))
            XCTAssertEqual(Matft.stats.sum(a), MfArray<Double>([-34]))
            
            XCTAssertEqual(Matft.stats.mean(a, axis: 0), MfArray<Double>([-9.5, -7.5]))
            XCTAssertEqual(Matft.stats.mean(a, axis: -1), MfArray<Double>([-8.0, -9.0]))
            XCTAssertEqual(Matft.stats.sum(a, axis: 0), MfArray<Double>([-19, -15]))
            XCTAssertEqual(Matft.stats.sum(a, axis: -1), MfArray<Double>([-16, -18]))
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.mean(b), MfArray<Float>([285.25]))
            XCTAssertEqual(Matft.stats.sum(b), MfArray<Int>([1141]))
            
            XCTAssertEqual(Matft.stats.mean(b, axis: 0), MfArray<Float>([  3.5, 567.0 ]))
            XCTAssertEqual(Matft.stats.mean(b, axis: -1), MfArray<Float>([589.5, -19.0 ]))
            XCTAssertEqual(Matft.stats.sum(b, axis: 0), MfArray<Int>([   7, 1134]))
            XCTAssertEqual(Matft.stats.sum(b, axis: -1), MfArray<Int>([1179,  -38]))
        }

        do{
            let a = MfArray<Double>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.mean(a), MfArray<Double>([0.02894999999999981]))
            XCTAssertEqual(Matft.stats.sum(a), MfArray<Double>([0.46319999999999695]))
            
            XCTAssertEqual(Matft.stats.mean(a, axis: 0), MfArray<Double>([ 2.5   ,  1.0    ,  0.5   , -2.5   , -0.4351,  1.6   ,  4.4567,
            -6.89  ]))
            XCTAssertEqual(Matft.stats.mean(a, axis: -1), MfArray<Double>([-0.367075,  0.424975]))
            XCTAssertEqual(Matft.stats.sum(a, axis: 0), MfArray<Double>([  5.0    ,   2.0    ,   1.0   ,  -5.0    ,  -0.8702,   3.2   ,
            8.9134, -13.78  ]))
            XCTAssertEqual(Matft.stats.sum(a, axis: -1), MfArray<Double>([-2.9366,  3.3998]))
        }
        
        do{
            let a = MfArray<UInt8>([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]]).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.stats.mean(a), MfArray<Float>([26.333333333333332]))
            XCTAssertEqual(Matft.stats.sum(a), MfArray<UInt8>([120]))
            
            XCTAssertEqual(Matft.stats.mean(a, axis: 0), MfArray<Float>([[[  1.0 ,   5.0 ],
                                                                           [  9.0 ,  13.0 ]],

                                                                          [[126.5, 124.0 ],
                                                                           [  2.0 ,   6.0 ]],

                                                                          [[ 10.0 ,  14.0 ],
                                                                           [  3.5,   2.0 ]]]))
            XCTAssertEqual(Matft.stats.mean(a, axis: -1), MfArray<Float>([[[  2.0 ,  10.0 ],
                                                                            [249.0 ,   3.0 ],
                                                                            [ 11.0 ,   3.0 ]],

                                                                           [[  4.0 ,  12.0 ],
                                                                            [  1.5,   5.0 ],
                                                                            [ 13.0 ,   2.5]]]))
            XCTAssertEqual(Matft.stats.mean(a, axis: 1, keepDims: true), MfArray<Float>([[[[86.66666667, 88.0        ],
                                                                                            [ 4.0        ,  6.66666667]]],


                                                                                          [[[ 5.0       ,  7.33333333],
                                                                                            [ 5.66666667,  7.33333333]]]]))
            XCTAssertEqual(Matft.stats.sum(a, axis: 0), MfArray<UInt8>([[[  2,  10],
                                                                          [ 18,  26]],

                                                                         [[253, 248],
                                                                          [  4,  12]],

                                                                         [[ 20,  28],
                                                                          [  7,   4]]]))
            XCTAssertEqual(Matft.stats.sum(a, axis: -1), MfArray<UInt8>([[[  4,  20],
                                                                           [242,   6],
                                                                           [ 22,   6]],

                                                                          [[  8,  24],
                                                                           [  3,  10],
                                                                           [ 26,   5]]]))
            XCTAssertEqual(Matft.stats.sum(a, axis: 1, keepDims: true), MfArray<UInt8>([[[[4, 8],
                                                                                           [ 12,  20]]],

                                                                                         
                                                                                         [[[ 15,  22],
                                                                                           [ 17,  22]]]]))
        }
    }
    
    func test_subscripted(){
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.stats.mean(a[0]), MfArray<Float>([-8]))
            XCTAssertEqual(Matft.stats.mean(a[0~,1]), MfArray<Float>([-7.5]))
            XCTAssertEqual(Matft.stats.sum(a[0]), MfArray<Int>([-16]))
            XCTAssertEqual(Matft.stats.sum(a[0~,1]), MfArray<Int>([-15]))
            
            
            let b = MfArray<Int>([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.stats.mean(b[0]), MfArray<Float>([589.5]))
            XCTAssertEqual(Matft.stats.mean(b[0~,1]), MfArray<Float>([567]))
            XCTAssertEqual(Matft.stats.sum(b[0]), MfArray<Int>([1179]))
            XCTAssertEqual(Matft.stats.sum(b[0~,1]), MfArray<Int>([1134]))
        }

        do{
            let a = MfArray<Float>([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mforder: .Column)

            XCTAssertEqual(Matft.stats.mean(a[0~, 1~5]), MfArray<Float>([-0.35877500000000007]))
            XCTAssertEqual(Matft.stats.sum(a[0~, 1~5]), MfArray<Float>([-2.8702000000000005]))
        }
    }
}

