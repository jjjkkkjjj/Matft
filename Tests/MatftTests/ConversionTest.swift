//
//  ConversionTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/12.
//

import XCTest
import Matft

final class ConversionTest: XCTestCase {
    func testAsType(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                [1, 5, -2]])
            
            XCTAssertEqual(a.astype(newtype: Float.self),
                           MfArray<Float>([[2.0, -7.0, 0.0],
                                            [1.0, 5.0, -2.0]] as [[Float]]))
            
            XCTAssertEqual(a.astype(newtype: Double.self),
                           MfArray<Double>([[2.0, -7.0, 0.0],
                                            [1.0, 5.0, -2.0]] as [[Double]]))
            
            XCTAssertEqual(a.astype(newtype: UInt8.self),
                           MfArray<UInt8>([[2, 249, 0],
                                            [1, 5, 254]] as [[UInt8]]))
        }
    }
    
    func testReshape(){
        do{
            let a = MfArray<Float>([2.0, 1.1, 3.2, 2.5] as [Float])

            XCTAssertEqual(a.reshape([2, 2]), MfArray<Float>([[2.0, 1.1],
                                                       [3.2, 2.5]] as [[Float]]))
        }

        do{
            let a = Matft.arange(start: 0, to: 36, by: 1)

            XCTAssertEqual(a.reshape([2, 3, 3, 2]),
                           MfArray<Int>([[[[ 0,  1],
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
            let a = MfArray<Int>([[1, 3, 5],
                             [2, -4, -1]], mforder: .Column)


            XCTAssertEqual(a.reshape([3, 1, 2]),
                           MfArray<Int>([[[ 1,  3]],

                                          [[ 5,  2]],

                                          [[-4, -1]]]))
        }
    }
    
    func testExpandDims(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                  [1, 5, -2]])
            XCTAssertEqual(Matft.expand_dims(a, axis: 0), MfArray<Int>([[[ 2, -7,  0],
                             [ 1,  5, -2]]]))
            XCTAssertEqual(Matft.expand_dims(a, axis: 2), MfArray<Int>([[[ 2],
                             [-7],
                             [ 0]],

                            [[ 1],
                             [ 5],
                             [-2]]]))
        }
        
        do{
            let a = MfArray<Int>([1,2])
            XCTAssertEqual(Matft.expand_dims(a, axes: [0, 1]), MfArray<Int>([[[1, 2]]]))
            XCTAssertEqual(Matft.expand_dims(a, axes: [2, 0]), MfArray<Int>([[[1],
                              [2]]]))
        }
    }
    
    func testSqueeze(){
        let a = MfArray<Int>([[[ 1,  3]],
                              
                              [[ 5,  2]],

                              [[-4, -1]]])
        XCTAssertEqual(a.squeeze(), MfArray<Int>([[ 1,  3],
                                                  [ 5,  2],
                                                  [-4, -1]]))
    }
    
    func testToArray(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
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
            let a = MfArray<Int>([[1, 3, 5],
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
        
        do{
            let a = MfArray<Int>([[1, 3, 5],
                             [2, -4, -1]])

            XCTAssertEqual(a.astype(newtype: Float.self).toArray() as! [[Float]], [[Float(1), 3, 5],
                              [2, -4, -1]])

            XCTAssertEqual(a.astype(newtype: Int16.self).toArray() as! [[Int16]], [[Int16(1), 3, 5],
                              [2, -4, -1]])

            XCTAssertEqual(a.astype(newtype: Double.self).toArray() as! [[Double]], [[1.0, 3, 5],
                            [2, -4, -1]])

            XCTAssertEqual(a.astype(newtype: Int.self).toArray() as! [[Int]], [[1, 3, 5],
                          [2, -4, -1]])
        }
    }
    
    func testBroadcast(){
        do{
            let a = MfArray<Int>([[1, 3, 5],
                                  [2, -4, -1]], mforder: .Column)
            
            XCTAssertEqual(a.broadcast_to(shape: [3,2,3]), MfArray<Int>([[[ 1,  3,  5],
                              [ 2, -4, -1]],

                             [[ 1,  3,  5],
                              [ 2, -4, -1]],

                             [[ 1,  3,  5],
                              [ 2, -4, -1]]]))
            let b = MfArray<Int>([[1, 2]])
            XCTAssertEqual(b.broadcast_to(shape: [2,2]), MfArray<Int>([[1,2],
                               [1,2]]))
        }
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                  [1, 5, -2]]).reshape([2,1,1,3])
            
            XCTAssertEqual(a.broadcast_to(shape: [2,2,2,3]), MfArray<Int>([[[[ 2, -7,  0],
                             [ 2, -7,  0]],

                            [[ 2, -7,  0],
                             [ 2, -7,  0]]],
                          

                           [[[ 1,  5, -2],
                             [ 1,  5, -2]],

                            [[ 1,  5, -2],
                             [ 1,  5, -2]]]]))
        }
    }
    
    
    func testFlatten(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                [1, 5, -2]])
            
            XCTAssertEqual(a.flatten(),
                           MfArray<Int>([2, -7, 0, 1, 5, -2]))
            XCTAssertEqual(a.T.flatten(),
                           MfArray<Int>([ 2,  1, -7,  5,  0, -2]))
            XCTAssertEqual(a[~<<-1].flatten(),
                           MfArray<Int>([ 1,  5, -2,  2, -7,  0]))
        }
    }
    
    func testFlip(){
        let a = MfArray<Int>([[[ 1,  3]],
                              
                              [[ 5,  2]],

                              [[-4, -1]]])

        XCTAssertEqual(a.flip(), MfArray<Int>(([[[-1, -4]],
                                                
                                                [[ 2,  5]],

                                                [[ 3,  1]]])))
        XCTAssertEqual(a.flip(axis: 1), MfArray<Int>(([[[ 1,  3]],
                                                      
                                                      [[ 5,  2]],

                                                      [[-4, -1]]])))
    }
    
    func testClip(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                  [1, 5, -2]])
            XCTAssertEqual(a.clip(minval: -3, maxval: 3), MfArray<Int>([[2, -3, 0],
                              [1, 3, -2]]))
            XCTAssertEqual(a.clip(minval: -1),
                           MfArray<Int>([[2, -1, 0],
                                      [1, 5, -1]]))
            XCTAssertEqual(a.clip(maxval: 0),
                           MfArray<Int>([[0, -7, 0],
                                         [0, 0, -2]]))
        }
        
        do{
            let a = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                                     [-0.0002, 2, 3.4, -5]], mforder: .Column)
            XCTAssertEqual(a.clip(minval: -0.2, maxval: 1.2), MfArray<Double>([[-0.2, 1.2, 1.2, -0.2],
                                 [-0.0002, 1.2, 1.2, -0.2]]))
            XCTAssertEqual(a.clip(maxval: 1.2),
                           MfArray<Double>([[-0.87, 1.2, 1.2, -8.78],
                                          [-0.0002, 1.2, 1.2, -5]]))
            XCTAssertEqual(a.clip(minval: -0.2), MfArray<Double>([[-0.2, 1.2, 5.5134, -0.2],
                               [-0.0002, 2, 3.4, -0.2]]))
        }
    }
    
    func testSwapaxes() {
        do{

            let a = MfArray<Int>([[3, -19],
                                  [-22, 4]])
            let b = MfArray<Int>([[2, 1177],
                                  [5, -43]])
            
            XCTAssertEqual(a.swapaxes(axis1: 0, axis2: 1), MfArray<Int>([[3, -22],
                             [-19, 4]]))
            XCTAssertEqual(a.swapaxes(axis1: -1, axis2: -2), MfArray<Int>([[3, -22],
                           [-19, 4]]))
            
            XCTAssertEqual(b.swapaxes(axis1: 0, axis2: 1), MfArray<Int>([[2, 5],
                             [1177, -43]]))
            XCTAssertEqual(b.swapaxes(axis1: -1, axis2: -2), MfArray<Int>([[2, 5],
                               [1177, -43]]))
        }

        
        do{
            let a = Matft.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(a.swapaxes(axis1: 0, axis2: 2), MfArray<Int>([[[[ 0,  1],
                               [ 8,  9]],

                              [[ 4,  5],
                               [12, 13]]],


                             [[[ 2,  3],
                               [10, 11]],

                              [[ 6,  7],
                               [14, 15]]]]))
            XCTAssertEqual(a.swapaxes(axis1: 0, axis2: -2), MfArray<Int>([[[[ 0,  1],
                                [ 8,  9]],

                               [[ 4,  5],
                                [12, 13]]],

                         
                              [[[ 2,  3],
                                [10, 11]],

                               [[ 6,  7],
                                [14, 15]]]]))
            
            XCTAssertEqual(a.swapaxes(axis1: -1, axis2: 0), MfArray<Int>([[[[ 0,  8],
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

            let a = MfArray<Int>([[3, -19],
                                  [-22, 4]])
            let b = MfArray<Int>([[2, 1177],
                                  [5, -43]])
            
            XCTAssertEqual(a.moveaxis(src: 0, dst: 1),
                           MfArray<Int>([[3, -22],
                                         [-19, 4]]))
            XCTAssertEqual(a.moveaxis(src: -1, dst: -2), MfArray<Int>([[3, -22],
                               [-19, 4]]))
            
            XCTAssertEqual(b.moveaxis(src: 0, dst: 1),
                           MfArray<Int>([[2, 5],
                                         [1177, -43]]))
            XCTAssertEqual(b.moveaxis(src: -1, dst: -2), MfArray<Int>([[2, 5],
                           [1177, -43]]))
        }

        
        do{
            let a = Matft.arange(start: 0, to: 2*2*2*2, by: 1, shape: [2,2,2,2])
            XCTAssertEqual(a.moveaxis(src: 0, dst: 2),
                           MfArray<Int>([[[[ 0,  1],
                                           [ 8,  9]],

                                          [[ 2,  3],
                                           [10, 11]]],


                                         [[[ 4,  5],
                                           [12, 13]],

                                          [[ 6,  7],
                                           [14, 15]]]]))
            XCTAssertEqual(a.moveaxis(src: 0, dst: -2), MfArray<Int>([[[[ 0,  1],
                                [ 8,  9]],

                               [[ 2,  3],
                                [10, 11]]],


                              [[[ 4,  5],
                                [12, 13]],

                               [[ 6,  7],
                                [14, 15]]]]))
            
            XCTAssertEqual(a.moveaxis(src: -1, dst: 0), MfArray<Int>([[[[ 0,  2],
                                [ 4,  6]],

                               [[ 8, 10],
                                [12, 14]]],


                           [[[ 1,  3],
                             [ 5,  7]],

                            [[ 9, 11],
                             [13, 15]]]]))
        }
    }
    
    
    func testSort(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                  [1, 5, -2]])
            XCTAssertEqual(a.sort(axis: nil),
                           MfArray<Int>([-7, -2,  0,  1,  2,  5]))
            XCTAssertEqual(a.sort(axis: -1),
                           MfArray<Int>([[-7,  0,  2],
                                       [-2,  1,  5]]))
            XCTAssertEqual(a.sort(axis: 0), MfArray<Int>([[ 1, -7, -2],
                                                          [ 2,  5,  0]]))
        }
        
        do{
            let a = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                                     [-0.0002, 2, 3.4, -5]], mforder: .Column)
            XCTAssertEqual(a.sort(axis: nil, order: .Descending), MfArray<Double>([ 5.5134e+00,  3.4000e+00,  2.0000e+00,  1.2000e+00, -2.0000e-04,
            -8.7000e-01, -5.0000e+00, -8.7800e+00]))
            XCTAssertEqual(a.sort(axis: -1, order: .Descending), MfArray<Double>([[ 5.5134e+00,  1.2000e+00, -8.7000e-01, -8.7800e+00],
                              [ 3.4000e+00,  2.0000e+00, -2.0000e-04, -5.0000e+00]]))
            XCTAssertEqual(a.sort(),
                MfArray<Double>([[-8.7800e+00, -8.7000e-01,  1.2000e+00,  5.5134e+00],
                              [-5.0000e+00, -2.0000e-04,  2.0000e+00,  3.4000e+00]]))
        }
    }
    
    func testArgSort(){
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                  [1, 5, -2]])
            XCTAssertEqual(a.argsort(axis: nil),
                           MfArray<UInt>([1, 5, 2, 3, 0, 4] as [UInt]))
            XCTAssertEqual(a.argsort(axis: -1),
                           MfArray<UInt>([[1, 2, 0],
                                          [2, 0, 1]] as [[UInt]]))
            XCTAssertEqual(a.argsort(axis: 0),
                           MfArray<UInt>([[1, 0, 1],
                                         [0, 1, 0]] as [[UInt]]))
        }
        
        do{
            let a = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                                     [-0.0002, 2, 3.4, -5]], mforder: .Column)
            XCTAssertEqual(a.argsort(axis: nil, order: .Descending),
                           MfArray<UInt>([2, 6, 5, 1, 4, 0, 7, 3] as [UInt]))
            XCTAssertEqual(a.argsort(axis: -1, order: .Descending),
                           MfArray<UInt>([[2, 1, 0, 3],
                                         [2, 1, 0, 3]] as [[UInt]]))
            XCTAssertEqual(a.argsort(),
                           MfArray<UInt>([[3, 0, 1, 2],
                                         [3, 0, 1, 2]] as [[UInt]]))
        }
    }

    func testOrderedUnique(){
        do{
            let a = MfArray<Int>([0, 0, 30, 10, 10, 20])
            XCTAssertEqual(a.orderedUnique(), MfArray<Int>([0, 30, 10, 20]))
        }
        
        do{
            let a = MfArray<Int>([[20, 20, 10, 10],
                             [0, 0, 10, 30],
                             [20, 20, 10, 10]])
            
            XCTAssertEqual(a.orderedUnique(),
                           MfArray<Int>([20, 10, 0, 30]))
            XCTAssertEqual(a.orderedUnique(axis: 0),
                           MfArray<Int>([[20, 20, 10, 10],
                                         [ 0, 0, 10, 30]]))
            XCTAssertEqual(a.orderedUnique(axis: 1),
                           MfArray<Int>([[20, 10, 10],
                                          [0, 10, 30],
                                          [20, 10, 10]]))
        }
        do{
            let a = MfArray<Int>([[20, 20, 10, 10],
                             [0, 0, 10, 30],
                             [20, 20, 10, 10]])
            
            XCTAssertEqual(a.T.orderedUnique(axis: 0), MfArray<Int>([[20,  0, 20],
                            [10, 10, 10],
                            [10, 30, 10]]))
            XCTAssertEqual(a.T.orderedUnique(axis: -1), MfArray<Int>([[20,  0],
                             [20,  0],
                             [10, 10],
                             [10, 30]]))
        }
        
        do{
            let a = MfArray<Double>([[1.0, 0.0, 0.0],
                             [1.0, 0.0, 0.0],
                             [2.0, 3.0, 4.0],
                             [5.2, 0.1, 3.3]])
            
            XCTAssertEqual(a.orderedUnique(),
                MfArray<Double>([1.0, 0.0, 2.0, 3.0, 4.0, 5.2, 0.1, 3.3]))
            XCTAssertEqual(a.orderedUnique(axis: 0), MfArray<Double>([[1.0, 0.0, 0.0],
                              [2.0, 3.0, 4.0],
                              [5.2, 0.1, 3.3]]))
        }
    }
}
