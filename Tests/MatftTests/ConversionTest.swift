import XCTest
//@testable import Matft
import Matft

final class ConversionTests: XCTestCase {
    
    
    func testTranspose() {
        do{

            let a = MfArray([[3, -19],
                             [-22, 4]])
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(a.T, MfArray([[3, -22],
                                        [-19, 4]]))
            
            XCTAssertEqual(b.T, MfArray([[2, 5],
                                        [1177, -43]]))
        }

        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
            let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(a.T, MfArray([[2, 3],
                                         [1, 1],
                                         [-3, 4],
                                         [0, -5]], mftype: .Double))
            XCTAssertEqual(b.transpose(), MfArray([[-0.87, -0.0002],
                                                   [1.2, 2],
                                                   [5.5134, 3.4],
                                                   [-8.78, -5]], mftype: .Double))

        }
        
        do{
            let a = Matft.mfarray.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(a.transpose(axes: [0, 2, 3, 1]), MfArray([[[[ 0,  4],
                                                                       [ 1,  5]],

                                                                      [[ 2,  6],
                                                                       [ 3,  7]]],


                                                                     [[[ 8, 12],
                                                                       [ 9, 13]],

                                                                      [[10, 14],
                                                                       [11, 15]]]]))
            XCTAssertEqual(a.transpose(axes: [3,0,2,1]), MfArray([[[[ 0,  4],
                                                                    [ 2,  6]],

                                                                   [[ 8, 12],
                                                                    [10, 14]]],


                                                                  [[[ 1,  5],
                                                                    [ 3,  7]],

                                                                   [[ 9, 13],
                                                                    [11, 15]]]]))
        }
    }
    
    func testSwapaxes() {
        do{

            let a = MfArray([[3, -19],
                             [-22, 4]])
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(a.swapaxes(axis1: 0, axis2: 1), MfArray([[3, -22],
                                                                    [-19, 4]]))
            XCTAssertEqual(a.swapaxes(axis1: -1, axis2: -2), MfArray([[3, -22],
                                                                      [-19, 4]]))
            
            XCTAssertEqual(b.swapaxes(axis1: 0, axis2: 1), MfArray([[2, 5],
                                                                    [1177, -43]]))
            XCTAssertEqual(b.swapaxes(axis1: -1, axis2: -2), MfArray([[2, 5],
                                                                      [1177, -43]]))
        }

        
        do{
            let a = Matft.mfarray.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(a.swapaxes(axis1: 0, axis2: 2), MfArray([[[[ 0,  1],
                                                                      [ 8,  9]],

                                                                     [[ 4,  5],
                                                                      [12, 13]]],


                                                                    [[[ 2,  3],
                                                                      [10, 11]],

                                                                     [[ 6,  7],
                                                                      [14, 15]]]]))
            XCTAssertEqual(a.swapaxes(axis1: 0, axis2: -2), MfArray([[[[ 0,  1],
                                                                       [ 8,  9]],

                                                                      [[ 4,  5],
                                                                       [12, 13]]],

                                                                     
                                                                     [[[ 2,  3],
                                                                       [10, 11]],

                                                                      [[ 6,  7],
                                                                       [14, 15]]]]))
            
            XCTAssertEqual(a.swapaxes(axis1: -1, axis2: 0), MfArray([[[[ 0,  8],
                                                                       [ 2, 10]],

                                                                      [[ 4, 12],
                                                                       [ 6, 14]]],

                                                                     
                                                                     [[[ 1,  9],
                                                                       [ 3, 11]],

                                                                      [[ 5, 13],
                                                                       [ 7, 15]]]]))
        }
    }
    
    func testMoveaxis() {
        do{

            let a = MfArray([[3, -19],
                             [-22, 4]])
            let b = MfArray([[2, 1177],
                             [5, -43]])
            
            XCTAssertEqual(a.moveaxis(src: 0, dst: 1), MfArray([[3, -22],
                                                                [-19, 4]]))
            XCTAssertEqual(a.moveaxis(src: -1, dst: -2), MfArray([[3, -22],
                                                                  [-19, 4]]))
            
            XCTAssertEqual(b.moveaxis(src: 0, dst: 1), MfArray([[2, 5],
                                                                [1177, -43]]))
            XCTAssertEqual(b.moveaxis(src: -1, dst: -2), MfArray([[2, 5],
                                                                  [1177, -43]]))
        }

        
        do{
            let a = Matft.mfarray.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(a.moveaxis(src: 0, dst: 2), MfArray([[[[ 0,  1],
                                                                  [ 8,  9]],

                                                                 [[ 2,  3],
                                                                  [10, 11]]],


                                                                [[[ 4,  5],
                                                                  [12, 13]],

                                                                 [[ 6,  7],
                                                                  [14, 15]]]]))
            XCTAssertEqual(a.moveaxis(src: 0, dst: -2), MfArray([[[[ 0,  1],
                                                                   [ 8,  9]],

                                                                  [[ 2,  3],
                                                                   [10, 11]]],


                                                                 [[[ 4,  5],
                                                                   [12, 13]],

                                                                  [[ 6,  7],
                                                                   [14, 15]]]]))
            
            XCTAssertEqual(a.moveaxis(src: -1, dst: 0), MfArray([[[[ 0,  2],
                                                                   [ 4,  6]],

                                                                  [[ 8, 10],
                                                                   [12, 14]]],


                                                                 [[[ 1,  3],
                                                                   [ 5,  7]],

                                                                  [[ 9, 11],
                                                                   [13, 15]]]]))
        }
    }
    

    func testBroadcast(){
        do{
            let a = MfArray([[1, 3, 5],
                             [2, -4, -1]], mforder: .Column)
            
            XCTAssertEqual(try a.broadcast_to(shape: [3,2,3]), MfArray([[[ 1,  3,  5],
                                                                     [ 2, -4, -1]],

                                                                    [[ 1,  3,  5],
                                                                     [ 2, -4, -1]],

                                                                    [[ 1,  3,  5],
                                                                     [ 2, -4, -1]]]))
            let b = MfArray([[1, 2]])
            XCTAssertEqual(try b.broadcast_to(shape: [2,2]), MfArray([[1,2],
                                                                      [1,2]]))
        }
        do{
            let a = MfArray([[2, -7, 0],
                             [1, 5, -2]]).reshape([2,1,1,3])
            
            XCTAssertEqual(try a.broadcast_to(shape: [2,2,2,3]), MfArray([[[[ 2, -7,  0],
                                                                            [ 2, -7,  0]],

                                                                           [[ 2, -7,  0],
                                                                            [ 2, -7,  0]]],
                                                                          

                                                                          [[[ 1,  5, -2],
                                                                            [ 1,  5, -2]],

                                                                           [[ 1,  5, -2],
                                                                            [ 1,  5, -2]]]]))
        }
    }
    
    func testSort(){
        let a = MfArray([[2, -7, 0],
                         [1, 5, -2]])
        XCTAssertEqual(a.sort(), MfArray([-7, -2,  0,  1,  2,  5]))
        XCTAssertEqual(a.sort(axis: -1), MfArray([[-7,  0,  2],
                                                  [-2,  1,  5]]))
        XCTAssertEqual(a.sort(axis: 0), MfArray([[ 1, -7, -2],
                                                 [ 2,  5,  0]]))
    }
    
    func testArgSort(){
        
    }
    
    func testAsType(){
        
    }
}
