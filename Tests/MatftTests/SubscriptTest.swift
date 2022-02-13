//
//  SubscriptTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import XCTest
import Matft

final class SubscriptTests: XCTestCase {
    
    func testScalar() {
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            XCTAssertEqual(a[2,1,0].scalar!, 21)
            XCTAssertEqual(a[0,0,0].scalar!, 0)
            XCTAssertEqual(a[2,0,2].scalar!, 20)
            XCTAssertEqual(a[1,1,0].scalar!, 12)
            XCTAssertEqual(a[1,0,2].scalar!, 11)
        }
        
        do{
            let a = MfArray<Double>([[2, 1, -3, 0],
                                     [3, 1, 4, -5]] as [[Double]], mforder: .Column)

            XCTAssertEqual(a[1,2].scalar!, 4.0)
            XCTAssertEqual(a[0,3].scalar!, 0.0)
            XCTAssertEqual(a[1,1].scalar!, 1.0)
        }
        
        do{
            let a = Matft.arange(start: UInt(0), to: UInt(4*4*4), by: 1, shape: [4,4,4]).T
            
            XCTAssertEqual(a[3,2,0].scalar!, UInt(11))
            XCTAssertEqual(a[0,0,2].scalar!, UInt(32))
            XCTAssertEqual(a[1,0,2].scalar!, UInt(33))
            XCTAssertEqual(a[1,3,1].scalar!, UInt(29))
            XCTAssertEqual(a[0,2,0].scalar!, UInt(8))
        }
    }
    

    func testSlicing(){
        
        do{
            let a = Matft.arange(start: 0.0, to: 27*2, by: 2, shape: [3,3,3], mforder: .Column)
            XCTAssertEqual(a[~<1], MfArray<Double>([[[ 0, 18, 36],
                                                    [ 6, 24, 42],
                                                    [12, 30, 48]]] as [[[Double]]]))
            XCTAssertEqual(a[1~<2], MfArray<Double>([[[ 2, 20, 38],
                                                     [ 8, 26, 44],
                                                     [14, 32, 50]]] as [[[Double]]]))
            XCTAssertEqual(a[~<-1], MfArray<Double>([[[ 0, 18, 36],
                                                     [ 6, 24, 42],
                                                     [12, 30, 48]],

                                                    [[ 2, 20, 38],
                                                     [ 8, 26, 44],
                                                     [14, 32, 50]]] as [[[Double]]]))
            XCTAssertNotEqual(a[~<-1], MfArray<Double>([[[ 0, 18, 36],
                                                        [ 6, 24, 42],
                                                        [12, 30, 48]],

                                                       [[ 2, 20, 38],
                                                        [ 8, 2, 44],
                                                        [14, 32, 50]]] as [[[Double]]]))
            
            XCTAssertEqual(a[0~<,0~<,~<-1], MfArray<Double>([[[ 0, 18],
                                                           [ 6, 24],
                                                           [12, 30]],

                                                          [[ 2, 20],
                                                           [ 8, 26],
                                                           [14, 32]],

                                                          [[ 4, 22],
                                                           [10, 28],
                                                           [16, 34]]] as [[[Double]]]))
            XCTAssertEqual(a[0~<,-1~<-3~<-1,-2],
                           MfArray<Double>([[30, 24],
                                           [32, 26],
                                           [34, 28]] as [[Double]]))
        }
        
        do{
            let a = Matft.broadcast_to(MfArray<Int>([[2, 5, -1],
                                                     [3, 1, 0]]), shape: [2,2,2,3])
            //print(a) ok
            /*
            let c = MfArray([[[[ 2,  5, -1],
             [ 3,  1,  0]],

            [[ 2,  5, -1],
             [ 3,  1,  0]]],


            [[[ 2,  5, -1],
              [ 3,  1,  0]],

             [[ 2,  5, -1],
              [ 3,  1,  0]]]])
            print(a - c)*/
            
            XCTAssertEqual(a, MfArray<Int>([[[[ 2,  5, -1],
                                              [ 3,  1,  0]],

                                             [[ 2,  5, -1],
                                              [ 3,  1,  0]]],


                                            [[[ 2,  5, -1],
                                              [ 3,  1,  0]],

                                             [[ 2,  5, -1],
                                              [ 3,  1,  0]]]] as [[[[Int]]]]))
            
            XCTAssertEqual(a[-1~<<-1, (-2)~<],
                           MfArray<Int>([[[[ 2,  5, -1],
                                         [ 3,  1,  0]],
                                        
                                        [[ 2,  5, -1],
                                         [ 3,  1,  0]]],


                                       [[[ 2,  5, -1],
                                         [ 3,  1,  0]],

                                        [[ 2,  5, -1],
                                         [ 3,  1,  0]]]] as [[[[Int]]]]))
            
            XCTAssertEqual(a[0~<,0~<,1~<<-1,~<<3],
                           MfArray<Int>([[[[3],
                                         [2]],

                                        [[3],
                                         [2]]],


                                       [[[3],
                                         [2]],

                                        [[3],
                                         [2]]]] as [[[[Int]]]]))
            XCTAssertEqual(a[0~<,0~<, 1~<<-1,~<<3],
                           MfArray<Int>([[[[3],
                               [2]],

                              [[3],
                               [2]]],


                             [[[3],
                               [2]],

                              [[3],
                               [2]]]] as [[[[Int]]]]))
            XCTAssertEqual(a[~<1, ~<<-2], MfArray<Int>([[[[ 2,  5, -1],
                                                        [ 3,  1,  0]]]] as [[[[Int]]]]))
            
            //check alias
            XCTAssertEqual(a[-1~<~<-1, (-2)~<],
                           MfArray([[[[ 2,  5, -1],
                                      [ 3,  1,  0]],

                                     [[ 2,  5, -1],
                                      [ 3,  1,  0]]],


                                    [[[ 2,  5, -1],
                                      [ 3,  1,  0]],

                                     [[ 2,  5, -1],
                                      [ 3,  1,  0]]]] as [[[[Int]]]]))
            
            XCTAssertEqual(a[0~<,0~<,1~<~<-1,~<<3], MfArray([[[[3],
                                                                [2]],

                                                               [[3],
                                                                [2]]],


                                                              [[[3],
                                                                [2]],

                                                               [[3],
                                                                [2]]]] as [[[[Int]]]]))
            XCTAssertEqual(a[0~<,1~<<-1,0~<,~<<3],
                              MfArray([[[[2],
                                         [3]],

                                        [[2],
                                         [3]]],


                                       [[[2],
                                         [3]],

                                        [[2],
                                         [3]]]] as [[[[Int]]]]))
            XCTAssertEqual(a[~<1, ~<~<-2], MfArray([[[[ 2,  5, -1],
                                                   [ 3,  1,  0]]]] as [[[[Int]]]]))
        }
    }
    
    func testNormalIndexingGet(){
        
        do{
            let a = Matft.arange(start: 0.0, to: 27*2, by: 2, shape: [3,3,3], mforder: .Column)

            XCTAssertEqual(a[~<-1], MfArray<Double>([[[ 0, 18, 36],
                                                     [ 6, 24, 42],
                                                     [12, 30, 48]],

                                                    [[ 2, 20, 38],
                                                     [ 8, 26, 44],
                                                     [14, 32, 50]]] as [[[Double]]]))
            let b = a[~<-1]
            

            XCTAssertEqual(b[~<1, ~<2], MfArray<Double>([[[ 0, 18, 36],
                                                        [ 6, 24, 42]]] as [[[Double]]]))

            XCTAssertEqual(b[0], MfArray<Double>([[ 0, 18, 36],
                                                  [ 6, 24, 42],
                                                  [12, 30, 48]] as [[Double]]))
            XCTAssertEqual(b[0~<, ~<<-1],
                           MfArray<Double>([[[12, 30, 48],
                                          [ 6, 24, 42],
                                          [ 0, 18, 36]],

                                         [[14, 32, 50],
                                          [ 8, 26, 44],
                                          [ 2, 20, 38]]] as [[[Double]]]))
            XCTAssertEqual(b[0~<, ~<~<-1],
                           MfArray<Double>([[[12, 30, 48],
                                            [ 6, 24, 42],
                                            [ 0, 18, 36]],

                                           [[14, 32, 50],
                                            [ 8, 26, 44],
                                            [ 2, 20, 38]]] as [[[Double]]]))
        }
        
        do{
            let a = Matft.broadcast_to(MfArray<Int>([[2, 5, -1],
                                                     [3, 1, 0]] as [[Int]]), shape: [2,2,2,3])
            //print(a) ok
            /*
            let c = MfArray([[[[ 2,  5, -1],
             [ 3,  1,  0]],

            [[ 2,  5, -1],
             [ 3,  1,  0]]],


            [[[ 2,  5, -1],
              [ 3,  1,  0]],

             [[ 2,  5, -1],
              [ 3,  1,  0]]]])
            print(a - c)*/
            
            
            XCTAssertEqual(a, MfArray<Int>([[[[ 2,  5, -1],
                                              [ 3,  1,  0]],

                                             [[ 2,  5, -1],
                                              [ 3,  1,  0]]],


                                            [[[ 2,  5, -1],
                                              [ 3,  1,  0]],

                                             [[ 2,  5, -1],
                                              [ 3,  1,  0]]]] as [[[[Int]]]]))
            
            XCTAssertEqual(a[0~<, ~<1, ~<<2],
                           MfArray<Int>([[[[ 2,  5, -1]]],


                                         [[[ 2,  5, -1]]]] as [[[[Int]]]]))
            
            XCTAssertEqual(a[0~<, ~<1, ~<~<2],
                           MfArray([[[[ 2,  5, -1]]],


                                    [[[ 2,  5, -1]]]] as [[[[Int]]]]))
            
            XCTAssertEqual(a[~<<-1], MfArray<Int>([[[[ 2,  5, -1],
                                                    [ 3,  1,  0]],

                                                   [[ 2,  5, -1],
                                                    [ 3,  1,  0]]],


                                                  [[[ 2,  5, -1],
                                                    [ 3,  1,  0]],

                                                   [[ 2,  5, -1],
                                                    [ 3,  1,  0]]]] as [[[[Int]]]]))
            
            //let b = a[0~<, ~<1, ~<<2]
            //XCTAssertEqual(b[0, ~<1], MfArray<Int>([[[ 2,  5, -1]]]))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
            
            let b = a[0~<, 1]
            
            XCTAssertEqual(b[~<<-1], MfArray<Int>([[26, 27],
                                                  [18, 19],
                                                  [10, 11],
                                                  [ 2,  3]] as [[Int]]))
            
            XCTAssertEqual(b[0~<,1], MfArray<Int>([ 3, 11, 19, 27] as [Int]))
            
            XCTAssertEqual(b[-1,1~<<-1], MfArray<Int>([27, 26] as [Int]))
            
            XCTAssertEqual(b.T[0~<,1], MfArray<Int>([10, 11] as [Int]))
        }
    }
    
    func testNormalIndexingSet(){
        do{
            let a = Matft.arange(start: 0.0, to: 27*2, by: 2, shape: [3,3,3], mforder: .Column)

            XCTAssertEqual(a[~<-1], MfArray<Double>([[[ 0, 18, 36],
                                                     [ 6, 24, 42],
                                                     [12, 30, 48]],

                                                    [[ 2, 20, 38],
                                                     [ 8, 26, 44],
                                                     [14, 32, 50]]] as [[[Double]]]))
            let b = a[~<-1]
            
            b[~<1, ~<2] = MfArray<Double>([3333] as [Double])
            XCTAssertEqual(a, MfArray<Double>([[[3333, 3333, 3333],
                                                [3333, 3333, 3333],
                                                [  12,   30,   48]],

                                               [[   2,   20,   38],
                                                [   8,   26,   44],
                                                [  14,   32,   50]],

                                               [[   4,   22,   40],
                                                [  10,   28,   46],
                                                [  16,   34,   52]]] as [[[Double]]]))
            
            b[0] = Matft.arange(start: 0.0, to: 9, by: 1).reshape([3,3])
            XCTAssertEqual(a, MfArray<Double>([[[ 0,  1,  2],
                                                [ 3,  4,  5],
                                                [ 6,  7,  8]],

                                               [[ 2, 20, 38],
                                                [ 8, 26, 44],
                                                [14, 32, 50]],

                                               [[ 4, 22, 40],
                                                [10, 28, 46],
                                                [16, 34, 52]]] as [[[Double]]]))
            
            b[0~<, ~<<-1] = MfArray<Double>([0] as [Double])
            XCTAssertEqual(a, MfArray<Double>([[[ 0,  0,  0],
                                                [ 0,  0,  0],
                                                [ 0,  0,  0]],

                                               [[ 0,  0,  0],
                                                [ 0,  0,  0],
                                                [ 0,  0,  0]],

                                               [[ 4, 22, 40],
                                                [10, 28, 46],
                                                [16, 34, 52]]] as [[[Double]]]))
        }
        
        do{
            let a = Matft.broadcast_to(MfArray<Int>([[2, 5, -1],
                                                     [3, 1, 0]] as [[Int]]), shape: [2,2,2,3])
            //print(a) ok
            /*
            let c = MfArray([[[[ 2,  5, -1],
             [ 3,  1,  0]],

            [[ 2,  5, -1],
             [ 3,  1,  0]]],


            [[[ 2,  5, -1],
              [ 3,  1,  0]],

             [[ 2,  5, -1],
              [ 3,  1,  0]]]])
            print(a - c)*/
            
            
            XCTAssertEqual(a, MfArray<Int>([[[[ 2,  5, -1],
                                              [ 3,  1,  0]],

                                             [[ 2,  5, -1],
                                              [ 3,  1,  0]]],


                                            [[[ 2,  5, -1],
                                              [ 3,  1,  0]],

                                             [[ 2,  5, -1],
                                              [ 3,  1,  0]]]] as [[[[Int]]]]))
            
            a[0~<, ~<1, ~<<2] = MfArray<Int>([888, 777, 333] as [Int])
            
            XCTAssertEqual(a, MfArray<Int>([[[[888, 777, 333],
                                              [  3,   1,   0]],

                                             [[888, 777, 333],
                                              [  3,   1,   0]]],


                                       [[[888, 777, 333],
                                         [  3,   1,   0]],

                                        [[888, 777, 333],
                                         [  3,   1,   0]]]] as [[[[Int]]]]))
            

            
            let b = a[0~<, ~<1, ~<<2]
            
            b[0, 0~<1] = MfArray<Int>([222] as [Int])
            //b[0, ~<1] = MfArray([222]) //>>> passed as Int of Array... It's strange
            XCTAssertEqual(a, MfArray<Int>([[[[222, 222, 222],
                                              [  3,   1,   0]],

                                             [[222, 222, 222],
                                              [  3,   1,   0]]],


                                            [[[222, 222, 222],
                                              [  3,   1,   0]],

                                             [[222, 222, 222],
                                              [  3,   1,   0]]]] as [[[[Int]]]]))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
            
            let b = a[0~<, 1]
            b[~<<-1] = MfArray([9999])
            XCTAssertEqual(a, MfArray<Int>([[[   0,    1],
                                             [9999, 9999],
                                             [   4,    5],
                                             [   6,    7]],

                                            [[   8,    9],
                                             [9999, 9999],
                                             [  12,   13],
                                             [  14,   15]],

                                            [[  16,   17],
                                             [9999, 9999],
                                             [  20,   21],
                                             [  22,   23]],

                                            [[  24,   25],
                                             [9999, 9999],
                                             [  28,   29],
                                             [  30,   31]]] as [[[Int]]]))
            
            b[-1,1~<<-1] = MfArray<Int>([-9999] as [Int])
            XCTAssertEqual(a, MfArray<Int>([[[    0,     1],
                                             [ 9999,  9999],
                                             [    4,     5],
                                             [    6,     7]],

                                            [[    8,     9],
                                             [ 9999,  9999],
                                             [   12,    13],
                                             [   14,    15]],

                                            [[   16,    17],
                                             [ 9999,  9999],
                                             [   20,    21],
                                             [   22,    23]],

                                            [[   24,    25],
                                             [-9999, -9999],
                                             [   28,    29],
                                             [   30,    31]]] as [[[Int]]]))
            
        }
    }
    
    func testBooleanIndexingGet(){
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
            let b = MfArray<Bool>([true, false, true]).broadcast_to(shape: [3, 3, 3])
            
            XCTAssertEqual(a[b], MfArray<Int>([ 0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 15, 17, 18, 20, 21, 23, 24, 26] as [Int]))
            
            let c = MfArray<Bool>([false, false, true]).broadcast_to(shape: [3, 3, 3])
            XCTAssertEqual(a[c], MfArray<Int>([ 2,  5,  8, 11, 14, 17, 20, 23, 26] as [Int]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3]).astype(newtype: Double.self)
            let b = MfArray<Bool>([true, false, true]).broadcast_to(shape: [3, 3, 3])
            
            XCTAssertEqual(a[b], MfArray<Double>([ 0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 15, 17, 18, 20, 21, 23, 24, 26] as [Double]))
            
            let c = MfArray<Bool>([false, false, true]).broadcast_to(shape: [3, 3, 3])
            XCTAssertEqual(a[c], MfArray<Double>([ 2,  5,  8, 11, 14, 17, 20, 23, 26] as [Double]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            let b = MfArray<Bool>([true, false, true])

            XCTAssertEqual(a[b], MfArray<Int>([[[ 0,  1,  2],
                                           [ 3,  4,  5],
                                           [ 6,  7,  8]],

                                          [[18, 19, 20],
                                           [21, 22, 23],
                                           [24, 25, 26]]] as [[[Int]]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 18, by: 1, shape: [2, 3, 3])
            let b = MfArray<Bool>([[true, false, true],
                             [false, true, true]])
            
            XCTAssertEqual(a[b], MfArray<Int>([[ 0,  1,  2],
                                          [ 6,  7,  8],
                                          [12, 13, 14],
                                          [15, 16, 17]] as [[Int]]))
        }
    }
    
    func testBooleanIndexingSet(){
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
            let b = MfArray<Bool>([true, false, true]).broadcast_to(shape: [3, 3, 3])
            
            a[b] = MfArray<Int>([555] as [Int])
            XCTAssertEqual(a, MfArray<Int>([[[555,   1, 555],
                                        [555,   4, 555],
                                        [555,   7, 555]],

                                       [[555,  10, 555],
                                        [555,  13, 555],
                                        [555,  16, 555]],

                                       [[555,  19, 555],
                                        [555,  22, 555],
                                        [555,  25, 555]]] as [[[Int]]]))
            
            let c = MfArray<Bool>([false, false, true]).broadcast_to(shape: [3, 3, 3])
            
            a[c] = MfArray<Int>([333] as [Int])
            XCTAssertEqual(a, MfArray<Int>([[[555,   1, 333],
                                        [555,   4, 333],
                                        [555,   7, 333]],

                                       [[555,  10, 333],
                                        [555,  13, 333],
                                        [555,  16, 333]],

                                       [[555,  19, 333],
                                        [555,  22, 333],
                                        [555,  25, 333]]] as [[[Int]]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 160000, by: 1, shape: [400, 400])
            let c = MfArray<Bool>([true]).broadcast_to(shape: [400, 400])
            
            //self.measure {
                //a[c] = MfArray([555])
                // time in release mode
                // average: 0.009, relative standard deviation: 15.930%, values: [0.012394, 0.009048, 0.008606, 0.007531, 0.007859, 0.007862, 0.008099, 0.007935, 0.008400, 0.007617]
            //}
            a[c] = MfArray<Int>([555] as [Int])
            XCTAssertEqual(a, MfArray<Int>([555] as [Int]).broadcast_to(shape: [400, 400]))
        }
        
        
        do{
            let a = Matft.arange(start: 0, to: 18, by: 1, shape: [2, 3, 3])
            let b = MfArray<Bool>([[true, false, true],
                             [false, true, true]])
            
            a[b] = MfArray<Int>([[-1,  0,  2],
                            [ 3,  7,  4],
                            [ 2,  3, 14],
                            [ 8,  4,  4]] as [[Int]])
            XCTAssertEqual(a, MfArray<Int>([[[-1,  0,  2],
                                        [ 3,  4,  5],
                                        [ 3,  7,  4]],

                                       [[ 9, 10, 11],
                                        [ 2,  3, 14],
                                        [ 8,  4,  4]]] as [[[Int]]]))
        }
    }
}
