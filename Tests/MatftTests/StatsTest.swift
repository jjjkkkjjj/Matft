import XCTest
//@testable import Matft
import Matft

final class StatsTests: XCTestCase {
    
    func test_minmax() {
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.mfarray.stats.min(a), MfArray([-22]))
            XCTAssertEqual(Matft.mfarray.stats.max(a), MfArray([4]))
            
            XCTAssertEqual(Matft.mfarray.stats.min(a, axis: 0), MfArray([-22, -19]))
            XCTAssertEqual(Matft.mfarray.stats.min(a, axis: -1), MfArray([-19, -22]))
            XCTAssertEqual(Matft.mfarray.stats.max(a, axis: 0), MfArray([3, 4]))
            XCTAssertEqual(Matft.mfarray.stats.max(a, axis: -1), MfArray([3, 4]))
            
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.mfarray.stats.min(b), MfArray([-43]))
            XCTAssertEqual(Matft.mfarray.stats.max(b), MfArray([1177]))
            
            XCTAssertEqual(Matft.mfarray.stats.min(b, axis: 0), MfArray([2, -43]))
            XCTAssertEqual(Matft.mfarray.stats.min(b, axis: -1), MfArray([2, -43]))
            XCTAssertEqual(Matft.mfarray.stats.max(b, axis: 0), MfArray([5, 1177]))
            XCTAssertEqual(Matft.mfarray.stats.max(b, axis: -1), MfArray([1177, 5]))
        }

        do{
            let a = MfArray([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.mfarray.stats.min(a), MfArray([-8.78]))
            XCTAssertEqual(Matft.mfarray.stats.max(a), MfArray([5.5134]))
            
            XCTAssertEqual(Matft.mfarray.stats.min(a, axis: 0), MfArray([ 2.0  ,  1.0  , -3.0  , -5.0  , -0.87,  1.2 ,  3.4 , -8.78]))
            XCTAssertEqual(Matft.mfarray.stats.min(a, axis: -1), MfArray([-8.78, -5.0  ]))
            XCTAssertEqual(Matft.mfarray.stats.max(a, axis: 0), MfArray([ 3.0000e+00,  1.0000e+00,  4.0000e+00,  0.0000e+00, -2.0000e-04,
            2.0000e+00,  5.5134e+00, -5.0000e+00]))
            XCTAssertEqual(Matft.mfarray.stats.max(a, axis: -1), MfArray([5.5134, 4.0    ]))
        }
        
        do{
            let a = MfArray([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]], mftype: .UInt8).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.mfarray.stats.min(a), MfArray([0], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.max(a), MfArray([251], mftype: .UInt8))
            
            XCTAssertEqual(Matft.mfarray.stats.min(a, axis: 0), MfArray([[[ 0,  4],
                                                                          [ 8, 12]],

                                                                         [[ 2,  1],
                                                                          [ 1,  5]],

                                                                         [[ 9, 13],
                                                                          [ 3,  1]]], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.min(a, axis: -1), MfArray([[[  0,   8],
                                                                           [247,   1],
                                                                           [  9,   3]],

                                                                          [[  2,  10],
                                                                           [  1,   3],
                                                                           [ 11,   1]]], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.min(a, axis: 1, keepDims: true), MfArray([[[[0, 4],
                                                                                           [1, 3]]],


                                                                                         [[[2, 1],
                                                                                           [3, 1]]]], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.max(a, axis: 0), MfArray([[[  2,   6],
                                                                          [ 10,  14]],

                                                                         [[251, 247],
                                                                          [  3,   7]],

                                                                         [[ 11,  15],
                                                                          [  4,   3]]], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.max(a, axis: -1), MfArray([[[  4,  12],
                                                                           [251,   5],
                                                                           [ 13,   3]],
                                                                          
                                                                          [[  6,  14],
                                                                           [  2,   7],
                                                                           [ 15,   4]]], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.max(a, axis: 1, keepDims: true), MfArray([[[[251, 247],
                                                                                           [  8,  12]]],


                                                                                         [[[ 11,  15],
                                                                                           [ 10,  14]]]], mftype: .UInt8))
                
        }
    }
    
    func test_argminmax(){
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.mfarray.stats.argmin(a), MfArray([2]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a), MfArray([3]))
            
            XCTAssertEqual(Matft.mfarray.stats.argmin(a, axis: 0), MfArray([1, 0]))
            XCTAssertEqual(Matft.mfarray.stats.argmin(a, axis: -1), MfArray([1, 0]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a, axis: 0), MfArray([0, 1]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a, axis: -1), MfArray([0, 1]))
            
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.mfarray.stats.argmin(b), MfArray([3]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(b), MfArray([1]))
            
            XCTAssertEqual(Matft.mfarray.stats.argmin(b, axis: 0), MfArray([0, 1]))
            XCTAssertEqual(Matft.mfarray.stats.argmin(b, axis: -1), MfArray([0, 1]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(b, axis: 0), MfArray([1, 0]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(b, axis: -1), MfArray([1, 0]))
        }

        do{
            
            let a = MfArray([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]], mftype: .UInt8).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.mfarray.stats.argmin(a), MfArray([0]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a), MfArray([4]))
            
            XCTAssertEqual(Matft.mfarray.stats.argmin(a, axis: 0), MfArray([[[0, 0],
                                                                             [0, 0]],

                                                                            [[1, 1],
                                                                             [0, 0]],

                                                                            [[0, 0],
                                                                             [0, 1]]]))
            XCTAssertEqual(Matft.mfarray.stats.argmin(a, axis: -1), MfArray([[[0, 0],
                                                                              [1, 0],
                                                                              [0, 0]],

                                                                             [[0, 0],
                                                                              [1, 0],
                                                                              [0, 1]]]))
            XCTAssertEqual(Matft.mfarray.stats.argmin(a, axis: 1), MfArray([[[0, 0],
                                                                             [1, 2]],

                                                                            [[0, 1],
                                                                             [1, 2]]]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a, axis: 0), MfArray([[[1, 1],
                                                                             [1, 1]],

                                                                            [[0, 0],
                                                                             [1, 1]],
                                                                            
                                                                            [[1, 1],
                                                                             [1, 0]]]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a, axis: -1), MfArray([[[1, 1],
                                                                              [0, 1],
                                                                              [1, 0]],

                                                                             [[1, 1],
                                                                              [0, 1],
                                                                              [1, 0]]]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a, axis: 1), MfArray([[[1, 1],
                                                                             [0, 0]],

                                                                            [[2, 2],
                                                                             [0, 0]]]))

        }
        
        do{
            let a = MfArray([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.mfarray.stats.argmin(a), MfArray([7]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a), MfArray([6]))
            
            XCTAssertEqual(Matft.mfarray.stats.argmin(a, axis: 0), MfArray([0, 0, 0, 1, 0, 0, 1, 0]))
            XCTAssertEqual(Matft.mfarray.stats.argmin(a, axis: -1), MfArray([7, 3]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a, axis: 0), MfArray([1, 0, 1, 0, 1, 1, 0, 1]))
            XCTAssertEqual(Matft.mfarray.stats.argmax(a, axis: -1), MfArray([6, 2]))
        }
        
    }
    
    func test_minimummaximum() {
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            
            
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.mfarray.stats.maximum(a, b), MfArray([[3,1177],[5,4]]))
            XCTAssertEqual(Matft.mfarray.stats.maximum(b, a), MfArray([[3,1177],[5,4]]))

            XCTAssertEqual(Matft.mfarray.stats.minimum(a, b), MfArray([[2,-19],[-22,-43]]))
            XCTAssertEqual(Matft.mfarray.stats.minimum(b, a), MfArray([[2,-19],[-22,-43]]))

        }
        
        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
            let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.mfarray.stats.maximum(a, b), MfArray([[2,1.2,5.5134,0],[3,2,4,-5]]))
            XCTAssertEqual(Matft.mfarray.stats.maximum(b, a), MfArray([[2,1.2,5.5134,0],[3,2,4,-5]]))

            XCTAssertEqual(Matft.mfarray.stats.minimum(a, b), MfArray([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]]))
            XCTAssertEqual(Matft.mfarray.stats.minimum(b, a), MfArray([[-0.87,1,-3,-8.78],[-0.0002,1,3.4,-5]]))
        }

    }
    
    func test_statsval(){
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.mfarray.stats.mean(a), MfArray([-8.5], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(a), MfArray([-34]))
            
            XCTAssertEqual(Matft.mfarray.stats.mean(a, axis: 0), MfArray([-9.5, -7.5], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.mean(a, axis: -1), MfArray([-8.0, -9.0], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(a, axis: 0), MfArray([-19, -15]))
            XCTAssertEqual(Matft.mfarray.stats.sum(a, axis: -1), MfArray([-16, -18]))
            
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.mfarray.stats.mean(b), MfArray([285.25], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(b), MfArray([1141]))
            
            XCTAssertEqual(Matft.mfarray.stats.mean(b, axis: 0), MfArray([  3.5, 567.0 ], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.mean(b, axis: -1), MfArray([589.5, -19.0 ], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(b, axis: 0), MfArray([   7, 1134]))
            XCTAssertEqual(Matft.mfarray.stats.sum(b, axis: -1), MfArray([1179,  -38]))
        }

        do{
            let a = MfArray([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.mfarray.stats.mean(a), MfArray([0.02894999999999981]))
            XCTAssertEqual(Matft.mfarray.stats.sum(a), MfArray([0.46319999999999695]))
            
            XCTAssertEqual(Matft.mfarray.stats.mean(a, axis: 0), MfArray([ 2.5   ,  1.0    ,  0.5   , -2.5   , -0.4351,  1.6   ,  4.4567,
            -6.89  ]))
            XCTAssertEqual(Matft.mfarray.stats.mean(a, axis: -1), MfArray([-0.367075,  0.424975]))
            XCTAssertEqual(Matft.mfarray.stats.sum(a, axis: 0), MfArray([  5.0    ,   2.0    ,   1.0   ,  -5.0    ,  -0.8702,   3.2   ,
            8.9134, -13.78  ]))
            XCTAssertEqual(Matft.mfarray.stats.sum(a, axis: -1), MfArray([-2.9366,  3.3998]))
        }
        
        do{
            let a = MfArray([[  0,   4,   8,  12, 251, 247],
                             [  1,   5,   9,  13,   3,   3],
                             [  2,   6,  10,  14,   2,   1],
                             [  3,   7,  11,  15,   4,   1]], mftype: .UInt8).reshape([2,3,2,2])
            
            XCTAssertEqual(Matft.mfarray.stats.mean(a), MfArray([26.333333333333332], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(a), MfArray([632], mftype: .UInt8))
            
            XCTAssertEqual(Matft.mfarray.stats.mean(a, axis: 0), MfArray([[[  1.0 ,   5.0 ],
                                                                           [  9.0 ,  13.0 ]],

                                                                          [[126.5, 124.0 ],
                                                                           [  2.0 ,   6.0 ]],

                                                                          [[ 10.0 ,  14.0 ],
                                                                           [  3.5,   2.0 ]]], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.mean(a, axis: -1), MfArray([[[  2.0 ,  10.0 ],
                                                                            [249.0 ,   3.0 ],
                                                                            [ 11.0 ,   3.0 ]],

                                                                           [[  4.0 ,  12.0 ],
                                                                            [  1.5,   5.0 ],
                                                                            [ 13.0 ,   2.5]]], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.mean(a, axis: 1, keepDims: true), MfArray([[[[86.66666667, 88.0        ],
                                                                                            [ 4.0        ,  6.66666667]]],


                                                                                          [[[ 5.0       ,  7.33333333],
                                                                                            [ 5.66666667,  7.33333333]]]], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(a, axis: 0), MfArray([[[  2,  10],
                                                                          [ 18,  26]],

                                                                         [[253, 248],
                                                                          [  4,  12]],

                                                                         [[ 20,  28],
                                                                          [  7,   4]]], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.sum(a, axis: -1), MfArray([[[  4,  20],
                                                                           [498,   6],
                                                                           [ 22,   6]],

                                                                          [[  8,  24],
                                                                           [  3,  10],
                                                                           [ 26,   5]]], mftype: .UInt8))
            XCTAssertEqual(Matft.mfarray.stats.sum(a, axis: 1, keepDims: true), MfArray([[[[260, 264],
                                                                                           [ 12,  20]]],

                                                                                         
                                                                                         [[[ 15,  22],
                                                                                           [ 17,  22]]]], mftype: .UInt8))
        }
    }
    
    func test_subscripted(){
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            
            XCTAssertEqual(Matft.mfarray.stats.mean(a[0]), MfArray([-8], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.mean(a[0~,1]), MfArray([-7.5], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(a[0]), MfArray([-16]))
            XCTAssertEqual(Matft.mfarray.stats.sum(a[0~,1]), MfArray([-15]))
            
            
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.mfarray.stats.mean(b[0]), MfArray([589.5], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.mean(b[0~,1]), MfArray([567], mftype: .Float))
            XCTAssertEqual(Matft.mfarray.stats.sum(b[0]), MfArray([1179]))
            XCTAssertEqual(Matft.mfarray.stats.sum(b[0~,1]), MfArray([1134]))
        }

        do{
            let a = MfArray([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                             [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.mfarray.stats.mean(a[0~, 1~5]), MfArray([-0.35877500000000007]))
            XCTAssertEqual(Matft.mfarray.stats.sum(a[0~, 1~5]), MfArray([-2.8702000000000005]))
        }
    }
}
