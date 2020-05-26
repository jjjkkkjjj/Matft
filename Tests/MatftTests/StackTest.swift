import XCTest
//@testable import Matft
import Matft
/*
final class StackTests: XCTestCase {

    func test_hstack() {
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.hstack([a, b]), MfArray([[3, -19, 2, 1177],
                                                                   [-22, 4, 5, -43]]))
        }

        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
            let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.hstack([a, b]), MfArray([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2, 5.5134, -8.78],
                                                                  [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]]))

        }
        
        do{
            let a = Matft.arange(start: 0, to: 4*4, by: 1, shape: [4,4], mftype: .UInt8).T
            let b = MfArray([[-5, 3, 2, 4],
                             [-9, 3, 1, 1]], mftype: .UInt8, mforder: .Column)
            XCTAssertEqual(Matft.hstack([a, b.T]), MfArray([[  0,   4,   8,  12, 251, 247],
                                                                    [  1,   5,   9,  13,   3,   3],
                                                                    [  2,   6,  10,  14,   2,   1],
                                                                    [  3,   7,  11,  15,   4,   1]], mftype: .UInt8))
        }
    }
    
    func test_vstack(){
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.vstack([a, b]), MfArray([[3, -19],
                                                                   [-22, 4],
                                                                   [2, 1177],
                                                                   [5, -43]]))
        }

        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
            let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.vstack([a, b]), MfArray([[2, 1, -3, 0],
                                                                  [3, 1, 4, -5],
                                                                  [-0.87, 1.2, 5.5134, -8.78],
                                                                  [-0.0002, 2, 3.4, -5]]))

        }
        
        do{
            let a = Matft.arange(start: 0, to: 4*4, by: 1, shape: [4,4], mftype: .UInt8).T
            let b = MfArray([[-5, 3, 2, 4],
                             [-9, 3, 1, 1]], mftype: .UInt8, mforder: .Column)
            XCTAssertEqual(Matft.vstack([a, b]), MfArray([[  0,   4,   8,  12],
                                                                  [  1,   5,   9,  13],
                                                                  [  2,   6,  10,  14],
                                                                  [  3,   7,  11,  15],
                                                                  [251,   3,   2,   4],
                                                                  [247,   3,   1,   1]], mftype: .UInt8))
        }
    }
    
    func test_concatenate(){
        do{
            let a = MfArray([[3, -19],
                             [-22, 4]])
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(Matft.concatenate([a, b], axis: -1), MfArray([[3, -19, 2, 1177],
                                                                                 [-22, 4, 5, -43]]))
            XCTAssertEqual(Matft.concatenate([a, b], axis: 0), MfArray([[3, -19],
                                                                                [-22, 4],
                                                                                [2, 1177],
                                                                                [5, -43]]))
            
            let c = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
            let d = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(Matft.concatenate([c, d], axis: -1), MfArray([[2.0, 1.0, -3.0, 0.0, -0.87, 1.2,                                                                   5.5134, -8.78],
                                                                  [3.0, 1.0, 4.0, -5.0, -0.0002, 2.0, 3.4, -5.0]]))
            
            XCTAssertEqual(Matft.concatenate([c, d], axis: 0), MfArray([[2, 1, -3, 0],
                                                                                [3, 1, 4, -5],
                                                                                [-0.87, 1.2, 5.5134, -8.78],
                                                                                [-0.0002, 2, 3.4, -5]]))
            
            let e = Matft.arange(start: 0, to: 4*4, by: 1, shape: [4,4], mftype: .UInt8).T
            let f = MfArray([[-5, 3, 2, 4],
                             [-9, 3, 1, 1]], mftype: .UInt8, mforder: .Column)
            XCTAssertEqual(Matft.concatenate([e, f.T], axis: -1), MfArray([[  0,   4,   8,  12, 251, 247],
                                                                                   [  1,   5,   9,  13,   3,   3],
                                                                                   [  2,   6,  10,  14,   2,   1],
                                                                                   [  3,   7,  11,  15,   4,   1]], mftype: .UInt8))
            
            XCTAssertEqual(Matft.concatenate([e, f], axis: 0), MfArray([[  0,   4,   8,  12],
                                                                                [  1,   5,   9,  13],
                                                                                [  2,   6,  10,  14],
                                                                                [  3,   7,  11,  15],
                                                                                [251,   3,   2,   4],
                                                                                [247,   3,   1,   1]], mftype: .UInt8))
        }

        do{
            let a = Matft.arange(start: 0, to: 6, by: 0.2, shape: [2,5,3])
            let b = Matft.arange(start: 1, to: 13, by: 1, shape: [2,2,3], mforder: .Column)
            
            XCTAssertEqual(Matft.concatenate([a, b], axis: 1), MfArray([[[ 0.0 ,  0.2,  0.4],
                                                                                 [ 0.6,  0.8,  1.0 ],
                                                                                 [ 1.2,  1.4,  1.6],
                                                                                 [ 1.8,  2.0 ,  2.2],
                                                                                 [ 2.4,  2.6,  2.8],
                                                                                 [ 1.0 ,  5.0 ,  9.0 ],
                                                                                 [ 3.0 ,  7.0 , 11.0 ]],

                                                                                [[ 3.0 ,  3.2,  3.4],
                                                                                 [ 3.6,  3.8,  4.0 ],
                                                                                 [ 4.2,  4.4,  4.6],
                                                                                 [ 4.8,  5.0 ,  5.2],
                                                                                 [ 5.4,  5.6,  5.8],
                                                                                 [ 2.0 ,  6.0 , 10.0 ],
                                                                                 [ 4.0 ,  8.0 , 12.0 ]]]))
            XCTAssertEqual(Matft.concatenate([a, b.transpose(axes: [1,0,2])], axis: 1), MfArray([[[ 0.0 ,  0.2,  0.4],
                                                                                                          [ 0.6,  0.8,  1.0 ],
                                                                                                          [ 1.2,  1.4,  1.6],
                                                                                                          [ 1.8,  2.0 ,  2.2],
                                                                                                          [ 2.4,  2.6,  2.8],
                                                                                                          [ 1.0 ,  5.0 ,  9.0 ],
                                                                                                          [ 2.0 ,  6.0 , 10.0 ]],

                                                                                                         [[ 3.0 ,  3.2,  3.4],
                                                                                                          [ 3.6,  3.8,  4.0 ],
                                                                                                          [ 4.2,  4.4,  4.6],
                                                                                                          [ 4.8,  5.0 ,  5.2],
                                                                                                          [ 5.4,  5.6,  5.8],
                                                                                                          [ 3.0 ,  7.0 , 11.0 ],
                                                                                                          [ 4.0 ,  8.0 , 12.0 ]]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 45, by: 1, shape: [15,3])
            let b = Matft.arange(start: 0, to: 45, by: 1, shape: [15,3])
            
            let P = Matft.concatenate([a[0~<-1], b[1~<]], axis: 0).T
            
            XCTAssertEqual(P, MfArray([[ 0,  3,  6,  9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39,  3,  6,
                                         9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42],
                                       [ 1,  4,  7, 10, 13, 16, 19, 22, 25, 28, 31, 34, 37, 40,  4,  7,
                                         10, 13, 16, 19, 22, 25, 28, 31, 34, 37, 40, 43],
                                       [ 2,  5,  8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41,  5,  8,
                                         11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44]]))
        }
    }
}
*/
