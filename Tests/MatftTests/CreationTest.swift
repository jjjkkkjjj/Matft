import XCTest
//@testable import Matft
import Matft

final class CreationTests: XCTestCase {
    
    func testAppend() {
        do {
            let x = MfArray([1,2,3])
            let y = MfArray([[4,5,6],[7,8,9]])
            XCTAssertEqual(Matft.append(x, values: y), MfArray([1,2,3,4,5,6,7,8,9]))
        }
        
        do {
            let x = MfArray([[1,2,3],[4,5,6]])
            let y = MfArray([[7,8,9]])
            XCTAssertEqual(Matft.append(x, values: y, axis: 0), MfArray([[1, 2, 3],
                                                                        [4, 5, 6],
                                                                        [7, 8, 9]]))
        }
    }
    
    func testTake() {
        do {
            let a = Matft.arange(start: 0, to: 20, by: 1, shape: [2,2,5])
            let b = MfArray([1,0])
            
            XCTAssertEqual(Matft.take(a, indices: b), MfArray([[[10, 11, 12, 13, 14],
                                                         [15, 16, 17, 18, 19]],

                                                        [[ 0,  1,  2,  3,  4],
                                                         [ 5,  6,  7,  8,  9]]]))
            
            XCTAssertEqual(Matft.take(a, indices: b, axis: 1), MfArray([[[ 5,  6,  7,  8,  9],
                                                                 [ 0,  1,  2,  3,  4]],

                                                                [[15, 16, 17, 18, 19],
                                                                 [10, 11, 12, 13, 14]]]))
            
            XCTAssertEqual(Matft.take(a, indices: b, axis: -1), MfArray([[[ 1,  0],
                                                                     [ 6,  5]],

                                                                    [[11, 10],
                                                                     [16, 15]]]))
        }
        
        do {
            let a = MfArray([4, 3, 5, 7, 6, 8])
            let b = MfArray([0,1,4])
            XCTAssertEqual(Matft.take(a, indices: b), MfArray([4,3,6]))
            
            XCTAssertEqual(Matft.take(a, indices: MfArray([[0,1],[2,3]])), MfArray([[4, 3],
                                                                                    [5, 7]]))
        }
    }
    
    func testDiag() {
        do{
            XCTAssertEqual(Matft.diag(v: [3, -19, -22, 4]), MfArray([[  3,   0,   0,   0],
                                                                             [  0, -19,   0,   0],
                                                                             [  0,   0, -22,   0],
                                                                             [  0,   0,   0,   4]]))
            let a = MfArray([3, -19, -22, 4])
            XCTAssertEqual(Matft.diag(v: a), MfArray([[  3,   0,   0,   0],
                                                              [  0, -19,   0,   0],
                                                              [  0,   0, -22,   0],
                                                              [  0,   0,   0,   4]]))
        }
        
        do{
            XCTAssertEqual(Matft.diag(v: [3, -19, -22, 4], k: 1), MfArray([[  0,   3,   0,   0,   0],
                                                                            [  0,   0, -19,   0,   0],
                                                                            [  0,   0,   0, -22,   0],
                                                                            [  0,   0,   0,   0,   4],
                                                                            [  0,   0,   0,   0,   0]]))
            let a = MfArray([3, -19, -22, 4])
            XCTAssertEqual(Matft.diag(v: a, k: 1), MfArray([[  0,   3,   0,   0,   0],
                                                            [  0,   0, -19,   0,   0],
                                                            [  0,   0,   0, -22,   0],
                                                            [  0,   0,   0,   0,   4],
                                                            [  0,   0,   0,   0,   0]]))
            
            XCTAssertEqual(Matft.diag(v: [3, -19, -22, 4], k: -1), MfArray([[  0,   0,   0,   0,   0],
                                                                            [  3,   0,   0,   0,   0],
                                                                            [  0, -19,   0,   0,   0],
                                                                            [  0,   0, -22,   0,   0],
                                                                            [  0,   0,   0,   4,   0]]))
            
            XCTAssertEqual(Matft.diag(v: a, k: -1), MfArray([[  0,   0,   0,   0,   0],
                                                                [  3,   0,   0,   0,   0],
                                                                [  0, -19,   0,   0,   0],
                                                                [  0,   0, -22,   0,   0],
                                                                [  0,   0,   0,   4,   0]]))
        }

        do{

            XCTAssertEqual(Matft.diag(v: [-0.87, 1.2, 5.5134, -8.78]), MfArray([[-0.87  ,  0.0    ,  0.0    ,  0.0    ],
                                                                                        [ 0.0    ,  1.2   ,  0.0    ,  0.0    ],
                                                                                        [ 0.0    ,  0.0    ,  5.5134,  0.0    ],
                                                                                        [ 0.0    ,  0.0    ,  0.0    , -8.78  ]], mftype: .Double))
            let a = MfArray([-0.87, 1.2, 5.5134, -8.78], mftype: .Double, mforder: .Column)
            XCTAssertEqual(Matft.diag(v: a), MfArray([[-0.87  ,  0.0    ,  0.0    ,  0.0    ],
                                                              [ 0.0    ,  1.2   ,  0.0    ,  0.0    ],
                                                              [ 0.0    ,  0.0    ,  5.5134,  0.0    ],
                                                              [ 0.0    ,  0.0    ,  0.0    , -8.78  ]], mftype: .Double))

        }
        
        
    }
    

    func testEye(){
        do{
            XCTAssertEqual(Matft.eye(dim: 3), MfArray([[ 1,  0,  0],
                                                               [ 0,  1,  0],
                                                               [ 0,  0,  1]]))
        }
        do{
            XCTAssertEqual(Matft.eye(dim: 3, mftype: .Float), MfArray([[ 1,  0,  0],
                                                                               [ 0,  1,  0],
                                                                               [ 0,  0,  1]], mftype: .Float))
        }
    }
    

}
