import XCTest
//@testable import Matft
import Matft

#if canImport(CoreML)
import CoreML
#endif

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
        
        do{
            let a = Matft.nums(Float(0), shape: [3, 4, 5])
            XCTAssertEqual(Matft.expand_dims(a, axis: -1).shape, [3, 4, 5, 1])
        }
        
        do{
            let a = Matft.nums(Float(0), shape: [3, 4, 5])
            XCTAssertEqual(Matft.expand_dims(a, axes: [-1, 2]).shape, [3, 4, 1, 5, 1])
            
            XCTAssertEqual(Matft.expand_dims(a, axes: [2, -1]).shape, [3, 4, 1, 5, 1])
        }
    }
    
    func testReshape(){
        do{
            let a = MfArray([2.0, 1.1, 3.2, 2.5])

            XCTAssertEqual(a.reshape([2, 2]), MfArray([[2.0, 1.1],
                                                       [3.2, 2.5]]))
        }

        do{
            // keeps the type, the imaginary part and returns a copy
            let a = MfArray(real: MfArray([1.0, 2.0, 3.0, 4.0], mftype: .Double), imag: MfArray([5.0, 6.0, 7.0, 8.0], mftype: .Double))
            let b = a.reshape([2, 2])
            XCTAssertEqual(b.mftype, .Double)
            XCTAssertTrue(b.isComplex)
            XCTAssertEqual(b.real, MfArray([[1.0, 2.0], [3.0, 4.0]], mftype: .Double))
            XCTAssertEqual(b.imag!, MfArray([[5.0, 6.0], [7.0, 8.0]], mftype: .Double))

            let c = MfArray([1, 2, 3, 4, 5, 6], mftype: .UInt8)
            let d = c.reshape([3, 2])
            XCTAssertEqual(d.mftype, .UInt8)
            d[0, 0] = MfArray([100], mftype: .UInt8)
            XCTAssertEqual(c, MfArray([1, 2, 3, 4, 5, 6], mftype: .UInt8))

            // non-contiguous input and column order
            let e = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3]).T
            XCTAssertEqual(e.reshape([6]), MfArray([0, 3, 1, 4, 2, 5]))
            XCTAssertEqual(Matft.reshape(e, newshape: [3, 2], order: .Column), MfArray([[0, 3], [1, 4], [2, 5]]))
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
            
            let b = Matft.expand_dims(a, axis: 0).toArray() as! [[[Int]]]
            XCTAssertEqual(b, [[[ 2, -7,  0],
                                [ 1,  5, -2]]])
            XCTAssertNotEqual(b, [[[ 2, -3,  0],
                                   [ 1,  5, -2]]])

            let c = Matft.expand_dims(a, axis: 2).toArray() as! [[[Int]]]
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
            
            XCTAssertEqual(a.toArray() as! [[Int]], [[1, 3, 5],
                                                       [2, -4, -1]])

            XCTAssertEqual(a.reshape([3, 1, 2]).toArray() as! [[[Int]]], [[[ 1,  3]],

                                                                            [[ 5,  2]],

                                                                            [[-4, -1]]])
            
            XCTAssertEqual(a.T.toArray() as! [[Int]], [[ 1,  2],
                                                         [ 3, -4],
                                                         [ 5, -1]])
        }
        
        do {
            let a = Matft.arange(start: 0, to: 11, by: 1)
            XCTAssertEqual(a.ufuncReduce(Matft.add).toArray() as! [Int], [55])
        }
        
        do{
            let a = MfArray([[1, 3, 5],
                             [2, -4, -1]])
            
            XCTAssertEqual(a.astype(.Float).toArray() as! [[Float]], [[Float(1), 3, 5],
                                                                      [2, -4, -1]])
            
            XCTAssertEqual(a.astype(.Int16).toArray() as! [[Int16]], [[Int16(1), 3, 5],
                                                                      [2, -4, -1]])
            
            XCTAssertEqual(a.astype(.Double).toArray() as! [[Double]], [[Double(1), 3, 5],
                                                                        [2, -4, -1]])
            
            XCTAssertEqual(a.astype(.Int).toArray() as! [[Int]], [[1, 3, 5],
                                                                  [2, -4, -1]])
        }
        
        do {
            let a = MfArray([
               [1,2,3],
               [4,5,6]
           ], mftype: .Float)
           XCTAssertEqual(a[1], MfArray([4,5,6], mftype: .Float))
           XCTAssertEqual(a[1].toArray() as! [Float], [4.0,5,6])
        }
    }
    
    func testOrderedUnique(){
        do{
            let a = MfArray([0, 0, 30, 10, 10, 20])
            XCTAssertEqual(a.orderedUnique(), MfArray([0, 30, 10, 20]))
        }
        
        do{
            let a = MfArray([[20, 20, 10, 10],
                             [0, 0, 10, 30],
                             [20, 20, 10, 10]])
            
            XCTAssertEqual(a.orderedUnique(), MfArray([20, 10, 0, 30]))
            XCTAssertEqual(a.orderedUnique(axis: 0), MfArray([[20, 20, 10, 10],
                        [ 0, 0, 10, 30]]))
            XCTAssertEqual(a.orderedUnique(axis: 1), MfArray([[20, 10, 10],
                                                              [0, 10, 30],
                                                              [20, 10, 10]]))
        }
        do{
            let a = MfArray([[20, 20, 10, 10],
                             [0, 0, 10, 30],
                             [20, 20, 10, 10]])
            
            XCTAssertEqual(a.T.orderedUnique(axis: 0), MfArray([[20,  0, 20],
                                                                [10, 10, 10],
                                                                [10, 30, 10]]))
            XCTAssertEqual(a.T.orderedUnique(axis: -1), MfArray([[20,  0],
                                                                 [20,  0],
                                                                 [10, 10],
                                                                 [10, 30]]))
        }
        
        do{
            let a = MfArray([[1.0, 0.0, 0.0],
                             [1.0, 0.0, 0.0],
                             [2.0, 3.0, 4.0],
                             [5.2, 0.1, 3.3]])
            
            XCTAssertEqual(a.orderedUnique(), MfArray([1.0, 0.0, 2.0, 3.0, 4.0, 5.2, 0.1, 3.3]))
            XCTAssertEqual(a.orderedUnique(axis: 0), MfArray([[1.0, 0.0, 0.0],
                                                              [2.0, 3.0, 4.0],
                                                              [5.2, 0.1, 3.3]]))
        }
    }
    
    func testFlip(){
        let a = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4])
        // np.flip(a, axis=1)
        let axis1 = MfArray([[[8, 9, 10, 11], [4, 5, 6, 7], [0, 1, 2, 3]], [[20, 21, 22, 23], [16, 17, 18, 19], [12, 13, 14, 15]]])
        XCTAssertEqual(Matft.flip(a, axis: 1), axis1)
        XCTAssertEqual(a.flip(axis: 1), axis1)
        // np.flip(a, axis=-1)
        XCTAssertEqual(Matft.flip(a, axis: -1), MfArray([[[3, 2, 1, 0], [7, 6, 5, 4], [11, 10, 9, 8]], [[15, 14, 13, 12], [19, 18, 17, 16], [23, 22, 21, 20]]]))
        // np.flip(a)
        let all = MfArray([[[23, 22, 21, 20], [19, 18, 17, 16], [15, 14, 13, 12]], [[11, 10, 9, 8], [7, 6, 5, 4], [3, 2, 1, 0]]])
        XCTAssertEqual(Matft.flip(a), all)
        XCTAssertEqual(a.flip(), all)
        // np.flip(a, axis=(0, 2))
        let axes02 = MfArray([[[15, 14, 13, 12], [19, 18, 17, 16], [23, 22, 21, 20]], [[3, 2, 1, 0], [7, 6, 5, 4], [11, 10, 9, 8]]])
        XCTAssertEqual(Matft.flip(a, axes: [0, 2]), axes02)
        XCTAssertEqual(a.flip(axes: [0, 2]), axes02)
        // column major
        XCTAssertEqual(Matft.flip(a.to_contiguous(mforder: .Column), axis: 1), axis1)
    }

    func testRoll(){
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            
            XCTAssertEqual(a.roll(shift: 1), MfArray([[[26,  0,  1],
                                                       [ 2,  3,  4],
                                                       [ 5,  6,  7]],

                                                      [[ 8,  9, 10],
                                                       [11, 12, 13],
                                                       [14, 15, 16]],

                                                      [[17, 18, 19],
                                                       [20, 21, 22],
                                                       [23, 24, 25]]]))
            
            
            let b = a[1~<2]
            XCTAssertEqual(b.roll(shift: 1), MfArray([[[17,  9, 10],
                                                       [11, 12, 13],
                                                       [14, 15, 16]]]))
            
            XCTAssertEqual(a.roll(shift: -1), MfArray([[[ 1,  2,  3],
                                                        [ 4,  5,  6],
                                                        [ 7,  8,  9]],

                                                       [[10, 11, 12],
                                                        [13, 14, 15],
                                                        [16, 17, 18]],

                                                       [[19, 20, 21],
                                                        [22, 23, 24],
                                                        [25, 26,  0]]]))
            
            XCTAssertEqual(a.roll(shift: 100), MfArray([[[ 8,  9, 10],
                                                         [11, 12, 13],
                                                         [14, 15, 16]],

                                                        [[17, 18, 19],
                                                         [20, 21, 22],
                                                         [23, 24, 25]],

                                                        [[26,  0,  1],
                                                         [ 2,  3,  4],
                                                         [ 5,  6,  7]]]))
            
            XCTAssertEqual(a.roll(shift: -100), MfArray([[[19, 20, 21],
                                                          [22, 23, 24],
                                                          [25, 26,  0]],

                                                         [[ 1,  2,  3],
                                                          [ 4,  5,  6],
                                                          [ 7,  8,  9]],

                                                         [[10, 11, 12],
                                                          [13, 14, 15],
                                                          [16, 17, 18]]]))
        }
        
        do {
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            
            XCTAssertEqual(a.roll(shift: -1, axis: 1), MfArray([[[ 3,  4,  5],
                                                                 [ 6,  7,  8],
                                                                 [ 0,  1,  2]],

                                                                [[12, 13, 14],
                                                                 [15, 16, 17],
                                                                 [ 9, 10, 11]],

                                                                [[21, 22, 23],
                                                                 [24, 25, 26],
                                                                 [18, 19, 20]]]))
            
            XCTAssertEqual(a.roll(shift: -100, axis: 1), MfArray([[[ 3,  4,  5],
                                                                   [ 6,  7,  8],
                                                                   [ 0,  1,  2]],

                                                                  [[12, 13, 14],
                                                                   [15, 16, 17],
                                                                   [ 9, 10, 11]],

                                                                  [[21, 22, 23],
                                                                   [24, 25, 26],
                                                                   [18, 19, 20]]]))
        }
    }

    #if canImport(CoreML)
    @available(macOS 12.0, *)
    @available(iOS 14.0, *)
    func testToMlMultiArray() throws{
        do {
            let arr = [1.0, 2, 3, 4.0, 5, 6]
            let mlmularr = try MLMultiArray(shape: [2, 3], dataType: .double)
            for i in 0..<arr.count {
                mlmularr[i] = NSNumber(value: arr[i])
            }
            let a = MfArray(arr, shape: [2, 3])
            XCTAssertEqual(try a.toMLMultiArray(), mlmularr)
        }

        do {
            let arr = [1.0, 2, 3, 4.0, 5, 6]
            let arrT = [1.0, 4, 2, 5, 3, 6]
            let mlmularr = try MLMultiArray(shape: [3, 2], dataType: .double)
            for i in 0..<arr.count {
                mlmularr[i] = NSNumber(value: arrT[i])
            }
            let a = MfArray(arr, shape: [2, 3])
            XCTAssertEqual(try a.T.toMLMultiArray(), mlmularr)
        }
    }

    func testToMLMultiArrayLayouts() throws {
        /// Values in row major order read by the logical indices
        func values(_ m: MLMultiArray) -> [Double] {
            let shape = m.shape.map{ $0.intValue }
            return (0..<shape.reduce(1, *)).map{ i in
                var idx = [Int](repeating: 0, count: shape.count)
                var r = i
                for k in (0..<shape.count).reversed(){ idx[k] = r % shape[k]; r /= shape[k] }
                return m[idx.map{ NSNumber(value: $0) }].doubleValue
            }
        }
        let base = MfArray([[1, -2, 3], [4, 5, -6]] as [[Float]])
        for dtype in [MfType.Float, .Double, .Int]{
            for (name, x) in layoutVariants(base.astype(dtype)){
                let m = try x.toMLMultiArray()
                XCTAssertEqual(m.shape.map{ $0.intValue }, [2, 3], "\(dtype) \(name)")
                XCTAssertEqual(m.dataType, dtype == .Double ? .double : .float32, "\(dtype) \(name)")
                XCTAssertEqual(values(m), [1, -2, 3, 4, 5, -6], "\(dtype) \(name)")
            }
        }
    }
    #endif
}
