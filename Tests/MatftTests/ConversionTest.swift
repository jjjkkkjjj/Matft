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
            let a = Matft.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
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
            let a = Matft.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
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
            let a = Matft.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
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
            
            XCTAssertEqual(a.broadcast_to(shape: [3,2,3]), MfArray([[[ 1,  3,  5],
                                                                     [ 2, -4, -1]],

                                                                    [[ 1,  3,  5],
                                                                     [ 2, -4, -1]],

                                                                    [[ 1,  3,  5],
                                                                     [ 2, -4, -1]]]))
            let b = MfArray([[1, 2]])
            XCTAssertEqual(b.broadcast_to(shape: [2,2]), MfArray([[1,2],
                                                                      [1,2]]))
        }
        do{
            let a = MfArray([[2, -7, 0],
                             [1, 5, -2]]).reshape([2,1,1,3])
            
            XCTAssertEqual(a.broadcast_to(shape: [2,2,2,3]), MfArray([[[[ 2, -7,  0],
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
        do{
            let a = MfArray([[2, -7, 0],
                             [1, 5, -2]])
            XCTAssertEqual(a.sort(axis: nil), MfArray([-7, -2,  0,  1,  2,  5]))
            XCTAssertEqual(a.sort(axis: -1), MfArray([[-7,  0,  2],
                                                      [-2,  1,  5]]))
            XCTAssertEqual(a.sort(axis: 0), MfArray([[ 1, -7, -2],
                                                     [ 2,  5,  0]]))
        }
        
        do{
            let a = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)
            XCTAssertEqual(a.sort(axis: nil, order: .Descending), MfArray([ 5.5134e+00,  3.4000e+00,  2.0000e+00,  1.2000e+00, -2.0000e-04,
            -8.7000e-01, -5.0000e+00, -8.7800e+00], mftype: .Double))
            XCTAssertEqual(a.sort(axis: -1, order: .Descending), MfArray([[ 5.5134e+00,  1.2000e+00, -8.7000e-01, -8.7800e+00],
                                                                          [ 3.4000e+00,  2.0000e+00, -2.0000e-04, -5.0000e+00]], mftype: .Double))
            XCTAssertEqual(a.sort(), MfArray([[-8.7800e+00, -8.7000e-01,  1.2000e+00,  5.5134e+00],
                                              [-5.0000e+00, -2.0000e-04,  2.0000e+00,  3.4000e+00]], mftype: .Double))
        }
    }
    
    func testArgSort(){
        do{
            let a = MfArray([[2, -7, 0],
                             [1, 5, -2]])
            XCTAssertEqual(a.argsort(axis: nil), MfArray([1, 5, 2, 3, 0, 4]))
            XCTAssertEqual(a.argsort(axis: -1), MfArray([[1, 2, 0],
                                                         [2, 0, 1]]))
            XCTAssertEqual(a.argsort(axis: 0), MfArray([[1, 0, 1],
                                                        [0, 1, 0]]))
        }
        
        do{
            let a = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)
            XCTAssertEqual(a.argsort(axis: nil, order: .Descending), MfArray([2, 6, 5, 1, 4, 0, 7, 3]))
            XCTAssertEqual(a.argsort(axis: -1, order: .Descending), MfArray([[2, 1, 0, 3],
                                                                             [2, 1, 0, 3]]))
            XCTAssertEqual(a.argsort(), MfArray([[3, 0, 1, 2],
                                                 [3, 0, 1, 2]]))
        }
    }
    
    func testClip(){
        do{
            let a = MfArray([[2, -7, 0],
                             [1, 5, -2]])
            XCTAssertEqual(a.clip(min: -3, max: 3), MfArray([[2, -3, 0],
                                                             [1, 3, -2]]))
            XCTAssertEqual(a.clip(min: -1), MfArray([[2, -1, 0],
                                                     [1, 5, -1]]))
            XCTAssertEqual(a.clip(max: 0), MfArray([[0, -7, 0],
                                                    [0, 0, -2]]))
        }
        
        do{
            let a = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                             [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)
            XCTAssertEqual(a.clip(min: -0.2, max: 1.2), MfArray([[-0.2, 1.2, 1.2, -0.2],
                                                                 [-0.0002, 1.2, 1.2, -0.2]]))
            XCTAssertEqual(a.clip(max: 1.2), MfArray([[-0.87, 1.2, 1.2, -8.78],
                                                      [-0.0002, 1.2, 1.2, -5]]))
            XCTAssertEqual(a.clip(min: -0.2), MfArray([[-0.2, 1.2, 5.5134, -0.2],
                                                       [-0.0002, 2, 3.4, -0.2]]))
        }
    }
    
    func testExpandDims(){
        do{
            let a = MfArray([[2, -7, 0],
                             [1, 5, -2]])
            XCTAssertEqual(Matft.expand_dims(a, axis: 0), MfArray([[[ 2, -7,  0],
                                                                          [ 1,  5, -2]]]))
            XCTAssertEqual(Matft.expand_dims(a, axis: 2), MfArray([[[ 2],
                                                                          [-7],
                                                                          [ 0]],

                                                                         [[ 1],
                                                                          [ 5],
                                                                          [-2]]]))
        }
        
        do{
            let a = MfArray([1,2])
            XCTAssertEqual(Matft.expand_dims(a, axes: [0, 1]), MfArray([[[1, 2]]]))
            XCTAssertEqual(Matft.expand_dims(a, axes: [2, 0]), MfArray([[[1],
                                                                         [2]]]))
        }
    }
    
    func testReshape(){
        do{
            let a = MfArray([2.0, 1.1, 3.2, 2.5])
            
            XCTAssertEqual(a.reshape([2, 2]), MfArray([[2.0, 1.1],
                                                       [3.2, 2.5]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 36, by: 1)
            
            XCTAssertEqual(a.reshape([2, 3, 3, 2]), MfArray([[[[ 0,  1],
                                                               [ 2,  3],
                                                               [ 4,  5]],

                                                              [[ 6,  7],
                                                               [ 8,  9],
                                                               [10, 11]],

                                                              [[12, 13],
                                                               [14, 15],
                                                               [16, 17]]],


                                                             [[[18, 19],
                                                               [20, 21],
                                                               [22, 23]],

                                                              [[24, 25],
                                                               [26, 27],
                                                               [28, 29]],

                                                              [[30, 31],
                                                               [32, 33],
                                                               [34, 35]]]]))
        }
        
        do{
            let a = MfArray([[1, 3, 5],
                             [2, -4, -1]], mforder: .Column)
            

            XCTAssertEqual(a.reshape([3, 1, 2]), MfArray([[[ 1,  3]],

                                                          [[ 5,  2]],

                                                          [[-4, -1]]]))
        }
    }
    
    func testAsType(){
        
    }
    
    func testToArray(){
        do{
            let a = MfArray([[2, -7, 0],
                             [1, 5, -2]])
            
            let b = Matft.expand_dims(a, axis: 0).toArray() as! [[[Int32]]]
            XCTAssertEqual(b, [[[ 2, -7,  0],
                                [ 1,  5, -2]]])
            XCTAssertNotEqual(b, [[[ 2, -3,  0],
                                   [ 1,  5, -2]]])

            let c = Matft.expand_dims(a, axis: 2).toArray() as! [[[Int32]]]
            XCTAssertEqual(c, [[[ 2],
                                [-7],
                                [ 0]],

                               [[ 1],
                                [ 5],
                                [-2]]])
        }
        
        do{
            let a = MfArray([[1, 3, 5],
                             [2, -4, -1]], mforder: .Column)
            
            XCTAssertEqual(a.toArray() as! [[Int32]], [[1, 3, 5],
                                                       [2, -4, -1]])

            XCTAssertEqual(a.reshape([3, 1, 2]).toArray() as! [[[Int32]]], [[[ 1,  3]],

                                                                            [[ 5,  2]],

                                                                            [[-4, -1]]])
            
            XCTAssertEqual(a.T.toArray() as! [[Int32]], [[ 1,  2],
                                                         [ 3, -4],
                                                         [ 5, -1]])
        }
    }
}
