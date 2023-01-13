import XCTest
//@testable import Matft
import Matft

final class SubscriptTests: XCTestCase {
    
    func testScalar() {
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            XCTAssertEqual(a[2,1,0] as! Int, 21)
            XCTAssertEqual(a[0,0,0] as! Int, 0)
            XCTAssertEqual(a[2,0,2] as! Int, 20)
            XCTAssertEqual(a[1,1,0] as! Int, 12)
            XCTAssertEqual(a[1,0,2] as! Int, 11)
        }
        
        do{
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mftype: .Double, mforder: .Column)

            XCTAssertEqual(a[1,2] as! Double, 4.0)
            XCTAssertEqual(a[0,3] as! Double, 0.0)
            XCTAssertEqual(a[1,1] as! Double, 1.0)
        }
        
        do{
            let a = Matft.arange(start: 0, to: 4*4*4, by: 1, shape: [4,4,4], mftype: .UInt).T
            
            XCTAssertEqual(a[3,2,0] as! UInt, UInt(11))
            XCTAssertEqual(a[0,0,2] as! UInt, UInt(32))
            XCTAssertEqual(a[1,0,2] as! UInt, UInt(33))
            XCTAssertEqual(a[1,3,1] as! UInt, UInt(29))
            XCTAssertEqual(a[0,2,0] as! UInt, UInt(8))
        }
    }
    

    func testSlicing(){
        
        do{
            let a = Matft.arange(start: 0, to: 27*2, by: 2, shape: [3,3,3], mftype: .Double, mforder: .Column)
            XCTAssertEqual(a[~<1], MfArray([[[ 0, 18, 36],
                                            [ 6, 24, 42],
                                            [12, 30, 48]]], mftype: .Double))
            XCTAssertEqual(a[1~<2], MfArray([[[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            XCTAssertEqual(a[~<-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            XCTAssertNotEqual(a[~<-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 2, 44],
                                             [14, 32, 50]]], mftype: .Double))
            
            XCTAssertEqual(a[0~<,0~<,~<-1], MfArray([[[ 0, 18],
                                                   [ 6, 24],
                                                   [12, 30]],

                                                  [[ 2, 20],
                                                   [ 8, 26],
                                                   [14, 32]],

                                                  [[ 4, 22],
                                                   [10, 28],
                                                   [16, 34]]], mftype: .Double))
            XCTAssertEqual(a[0~<,-1~<-3~<-1,-2], MfArray([[30, 24],
                                                       [32, 26],
                                                       [34, 28]], mftype: .Double))
        }
        
        do{
            let a = Matft.broadcast_to(MfArray([[2, 5, -1],
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
            
            XCTAssertEqual(a, MfArray([[[[ 2,  5, -1],
                                        [ 3,  1,  0]],

                                       [[ 2,  5, -1],
                                        [ 3,  1,  0]]],


                                       [[[ 2,  5, -1],
                                         [ 3,  1,  0]],

                                        [[ 2,  5, -1],
                                         [ 3,  1,  0]]]]))
            
            XCTAssertEqual(a[-1~<<-1, (-2)~<], MfArray([[[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]],


                                                    [[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]]]))
            
            XCTAssertEqual(a[0~<,0~<,1~<<-1,~<<3], MfArray([[[[3],
                                                                [2]],

                                                               [[3],
                                                                [2]]],


                                                              [[[3],
                                                                [2]],

                                                               [[3],
                                                                [2]]]]))
            XCTAssertNotEqual(a[0~<,0~<,~<1~<-1,~<<3], MfArray([[[2],

                                                            [2]],


                                                           [[2],

                                                            [2]]]))
            XCTAssertEqual(a[~<1, ~<<-2], MfArray([[[[ 2,  5, -1],
                                                   [ 3,  1,  0]]]]))
            
            //check alias
            XCTAssertEqual(a[-1~<~<-1, (-2)~<], MfArray([[[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]],


                                                    [[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]]]))
            
            XCTAssertEqual(a[0~<,0~<,1~<~<-1,~<<3], MfArray([[[[3],
                                                                [2]],

                                                               [[3],
                                                                [2]]],


                                                              [[[3],
                                                                [2]],

                                                               [[3],
                                                                [2]]]]))
            XCTAssertNotEqual(a[0~<,0~<,~<1~<-1,~<~<3], MfArray([[[2],

                                                            [2]],


                                                           [[2],

                                                            [2]]]))
            XCTAssertEqual(a[~<1, ~<~<-2], MfArray([[[[ 2,  5, -1],
                                                   [ 3,  1,  0]]]]))
            
        }
    }
    
    func testSubscrpt_Subscript(){
        do{
            let a = Matft.arange(start: 0, to: 27*2, by: 2, shape: [3,3,3], mftype: .Double, mforder: .Column)

            XCTAssertEqual(a[~<-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            let b = a[~<-1]
            

            XCTAssertEqual(b[~<1, ~<2], MfArray([[[ 0, 18, 36],
                                                [ 6, 24, 42]]], mftype: .Double))

            XCTAssertEqual(b[0], MfArray([[ 0, 18, 36],
                                          [ 6, 24, 42],
                                          [12, 30, 48]], mftype: .Double))
            XCTAssertEqual(b[0~<, ~<<-1], MfArray([[[12, 30, 48],
                                                  [ 6, 24, 42],
                                                  [ 0, 18, 36]],

                                                 [[14, 32, 50],
                                                  [ 8, 26, 44],
                                                  [ 2, 20, 38]]], mftype: .Double))
            XCTAssertEqual(b[0~<, ~<~<-1], MfArray([[[12, 30, 48],
                                                     [ 6, 24, 42],
                                                     [ 0, 18, 36]],

                                                    [[14, 32, 50],
                                                     [ 8, 26, 44],
                                                     [ 2, 20, 38]]], mftype: .Double))
        }
        
        do{
            let a = Matft.broadcast_to(MfArray([[2, 5, -1],
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
            
            
            XCTAssertEqual(a, MfArray([[[[ 2,  5, -1],
                                        [ 3,  1,  0]],

                                       [[ 2,  5, -1],
                                        [ 3,  1,  0]]],


                                       [[[ 2,  5, -1],
                                         [ 3,  1,  0]],

                                        [[ 2,  5, -1],
                                         [ 3,  1,  0]]]]))
            
            XCTAssertEqual(a[0~<, ~<1, ~<<2], MfArray([[[[ 2,  5, -1]]],


                                                    [[[ 2,  5, -1]]]]))
            
            XCTAssertEqual(a[0~<, ~<1, ~<~<2], MfArray([[[[ 2,  5, -1]]],


                                                       [[[ 2,  5, -1]]]]))
            
            XCTAssertEqual(a[~<<-1], MfArray([[[[ 2,  5, -1],
                                               [ 3,  1,  0]],

                                              [[ 2,  5, -1],
                                               [ 3,  1,  0]]],


                                             [[[ 2,  5, -1],
                                               [ 3,  1,  0]],

                                              [[ 2,  5, -1],
                                               [ 3,  1,  0]]]]))
            
            XCTAssertEqual(a[Matft.reverse], MfArray([[[[ 2,  5, -1],
                                               [ 3,  1,  0]],

                                              [[ 2,  5, -1],
                                               [ 3,  1,  0]]],


                                             [[[ 2,  5, -1],
                                               [ 3,  1,  0]],

                                              [[ 2,  5, -1],
                                               [ 3,  1,  0]]]]))
            
            let b = a[0~<, ~<1, ~<<2]
            XCTAssertEqual(b[0, ~<1], MfArray([[[ 2,  5, -1]]]))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
            
            let b = a[0~<, 1]
            XCTAssertEqual(b[~<<-1], MfArray([[26, 27],
                                             [18, 19],
                                             [10, 11],
                                             [ 2,  3]]))
            
            XCTAssertEqual(b[0~<,1], MfArray([ 3, 11, 19, 27]))
            
            XCTAssertEqual(b[-1,1~<<-1], MfArray([27, 26]))
            
            XCTAssertEqual(b.T[0~<,1], MfArray([10, 11]))
        }
    }
    
    func testAssign(){
        do{
            let a = Matft.arange(start: 0, to: 27*2, by: 2, shape: [3,3,3], mftype: .Double, mforder: .Column)

            XCTAssertEqual(a[~<-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            let b = a[~<-1]
            
            b[~<1, ~<2] = MfArray([3333])
            XCTAssertEqual(a, MfArray([[[3333, 3333, 3333],
                                        [3333, 3333, 3333],
                                        [  12,   30,   48]],

                                       [[   2,   20,   38],
                                        [   8,   26,   44],
                                        [  14,   32,   50]],

                                       [[   4,   22,   40],
                                        [  10,   28,   46],
                                        [  16,   34,   52]]], mftype: .Double))
            
            b[0] = Matft.arange(start: 0, to: 9, by: 1).reshape([3,3])
            XCTAssertEqual(a, MfArray([[[ 0,  1,  2],
                                        [ 3,  4,  5],
                                        [ 6,  7,  8]],

                                       [[ 2, 20, 38],
                                        [ 8, 26, 44],
                                        [14, 32, 50]],

                                       [[ 4, 22, 40],
                                        [10, 28, 46],
                                        [16, 34, 52]]], mftype: .Double))
            
            b[0~<, ~<<-1] = MfArray([0])
            XCTAssertEqual(a, MfArray([[[ 0,  0,  0],
                                        [ 0,  0,  0],
                                        [ 0,  0,  0]],

                                       [[ 0,  0,  0],
                                        [ 0,  0,  0],
                                        [ 0,  0,  0]],

                                       [[ 4, 22, 40],
                                        [10, 28, 46],
                                        [16, 34, 52]]], mftype: .Double))
        }
        
        do{
            let a = Matft.broadcast_to(MfArray([[2, 5, -1],
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
            
            
            XCTAssertEqual(a, MfArray([[[[ 2,  5, -1],
                                        [ 3,  1,  0]],

                                       [[ 2,  5, -1],
                                        [ 3,  1,  0]]],


                                       [[[ 2,  5, -1],
                                         [ 3,  1,  0]],

                                        [[ 2,  5, -1],
                                         [ 3,  1,  0]]]]))
            
            a[0~<, ~<1, ~<<2] = MfArray([888, 777, 333])
            
            XCTAssertEqual(a, MfArray([[[[888, 777, 333],
                                         [  3,   1,   0]],

                                        [[888, 777, 333],
                                         [  3,   1,   0]]],


                                       [[[888, 777, 333],
                                         [  3,   1,   0]],

                                        [[888, 777, 333],
                                         [  3,   1,   0]]]]))
            

            
            let b = a[0~<, ~<1, ~<<2]
            
            b[0, 0~<1] = MfArray([222])
            //b[0, ~<1] = MfArray([222]) //>>> passed as Int of Array... It's strange
            XCTAssertEqual(a, MfArray([[[[222, 222, 222],
                                         [  3,   1,   0]],

                                        [[222, 222, 222],
                                         [  3,   1,   0]]],


                                       [[[222, 222, 222],
                                         [  3,   1,   0]],

                                        [[222, 222, 222],
                                         [  3,   1,   0]]]]))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
            
            let b = a[0~<, 1]
            b[~<<-1] = MfArray([9999])
            XCTAssertEqual(a, MfArray([[[   0,    1],
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
                                        [  30,   31]]]))
            
            b[-1,1~<<-1] = MfArray([-9999])
            XCTAssertEqual(a, MfArray([[[    0,     1],
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
                                        [   30,    31]]]))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1).reshape([2,4,2])
            a[Matft.all, 2, Matft.all] = MfArray([3])
            
            XCTAssertEqual(a, MfArray([[[ 0,  1],
                                        [ 2,  3],
                                        [ 3,  3],
                                        [ 6,  7]],

                                       [[ 8,  9],
                                        [10, 11],
                                        [ 3,  3],
                                        [14, 15]]]))
            
            a[Matft.reverse, Matft.all, 1] = Matft.arange(start: 0, to: 8, by: 1, shape: [2,4])
            
            XCTAssertEqual(a, MfArray([[[ 0,  4],
                                        [ 2,  5],
                                        [ 3,  6],
                                        [ 6,  7]],

                                       [[ 8,  0],
                                        [10,  1],
                                        [ 3,  2],
                                        [14,  3]]]))
        }
    }
    
    func testBooleanIndexingGet(){
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
            let b = MfArray([true, false, true]).broadcast_to(shape: [3, 3, 3])
            
            XCTAssertEqual(a[b], MfArray([ 0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 15, 17, 18, 20, 21, 23, 24, 26]))
            
            let c = MfArray([false, false, true]).broadcast_to(shape: [3, 3, 3])
            XCTAssertEqual(a[c], MfArray([ 2,  5,  8, 11, 14, 17, 20, 23, 26]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3]).astype(.Double)
            let b = MfArray([true, false, true]).broadcast_to(shape: [3, 3, 3])
            
            XCTAssertEqual(a[b], MfArray([ 0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 15, 17, 18, 20, 21, 23, 24, 26], mftype: .Double))
            
            let c = MfArray([false, false, true]).broadcast_to(shape: [3, 3, 3])
            XCTAssertEqual(a[c], MfArray([ 2,  5,  8, 11, 14, 17, 20, 23, 26], mftype: .Double))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            let b = MfArray([true, false, true])

            XCTAssertEqual(a[b], MfArray([[[ 0,  1,  2],
                                           [ 3,  4,  5],
                                           [ 6,  7,  8]],

                                          [[18, 19, 20],
                                           [21, 22, 23],
                                           [24, 25, 26]]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 18, by: 1, shape: [2, 3, 3])
            let b = MfArray([[true, false, true],
                             [false, true, true]])
            
            XCTAssertEqual(a[b], MfArray([[ 0,  1,  2],
                                          [ 6,  7,  8],
                                          [12, 13, 14],
                                          [15, 16, 17]]))
        }
    }
    
    func testBooleanIndexingSet(){
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
            let b = MfArray([true, false, true]).broadcast_to(shape: [3, 3, 3])
            
            a[b] = MfArray([555])
            XCTAssertEqual(a, MfArray([[[555,   1, 555],
                                        [555,   4, 555],
                                        [555,   7, 555]],

                                       [[555,  10, 555],
                                        [555,  13, 555],
                                        [555,  16, 555]],

                                       [[555,  19, 555],
                                        [555,  22, 555],
                                        [555,  25, 555]]]))
            
            let c = MfArray([false, false, true]).broadcast_to(shape: [3, 3, 3])
            
            a[c] = MfArray([333])
            XCTAssertEqual(a, MfArray([[[555,   1, 333],
                                        [555,   4, 333],
                                        [555,   7, 333]],

                                       [[555,  10, 333],
                                        [555,  13, 333],
                                        [555,  16, 333]],

                                       [[555,  19, 333],
                                        [555,  22, 333],
                                        [555,  25, 333]]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 160000, by: 1, shape: [400, 400])
            let c = MfArray([true]).broadcast_to(shape: [400, 400])
            /*
            self.measure {
                a[c] = MfArray([555])
                // time in release mode
                // average: 0.005, relative standard deviation: 8.334%, values: [0.006032, 0.004685, 0.004630, 0.005293, 0.004738, 0.004789, 0.004905, 0.005056, 0.004624, 0.004729],
            }*/
            a[c] = MfArray([555])
            XCTAssertEqual(a, MfArray([555]).broadcast_to(shape: [400, 400]))
        }
        
        
        do{
            let a = Matft.arange(start: 0, to: 18, by: 1, shape: [2, 3, 3])
            let b = MfArray([[true, false, true],
                             [false, true, true]])
            
            a[b] = MfArray([[-1,  0,  2],
                            [ 3,  7,  4],
                            [ 2,  3, 14],
                            [ 8,  4,  4]])
            XCTAssertEqual(a, MfArray([[[-1,  0,  2],
                                        [ 3,  4,  5],
                                        [ 3,  7,  4]],

                                       [[ 9, 10, 11],
                                        [ 2,  3, 14],
                                        [ 8,  4,  4]]]))
        }
    }
    
    func testFancyIndexingGet(){
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1)
            let b = MfArray([3, 7, 2])
            
            XCTAssertEqual(a[b], MfArray([3, 7, 2]))
            
            let c = MfArray([[2, 1],
                             [-2, 1]])
            XCTAssertEqual(a[c], MfArray([[ 2,  1],
                                          [25,  1]]))
            
            let d = MfArray([[2,1,0,-2],
                             [-2,1,-1,1]])
            XCTAssertEqual(a[d], MfArray([[ 2,  1,  0, 25],
                                          [25,  1, 26,  1]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
            let b = MfArray([[2,1],
                             [-2,1]])
            
            XCTAssertEqual(a[b], MfArray([[[[18, 19, 20],
                                            [21, 22, 23],
                                            [24, 25, 26]],

                                           [[ 9, 10, 11],
                                            [12, 13, 14],
                                            [15, 16, 17]]],


                                          [[[ 9, 10, 11],
                                            [12, 13, 14],
                                            [15, 16, 17]],

                                           [[ 9, 10, 11],
                                            [12, 13, 14],
                                            [15, 16, 17]]]]))
            
            let c = MfArray([[1,-1,2,2],[2,-2,-1,0]])
            
            XCTAssertEqual(a[c], MfArray([[[[ 9, 10, 11],
                                              [12, 13, 14],
                                              [15, 16, 17]],

                                             [[18, 19, 20],
                                              [21, 22, 23],
                                              [24, 25, 26]],

                                             [[18, 19, 20],
                                              [21, 22, 23],
                                              [24, 25, 26]],

                                             [[18, 19, 20],
                                              [21, 22, 23],
                                              [24, 25, 26]]],


                                            [[[18, 19, 20],
                                              [21, 22, 23],
                                              [24, 25, 26]],

                                             [[ 9, 10, 11],
                                              [12, 13, 14],
                                              [15, 16, 17]],

                                             [[18, 19, 20],
                                              [21, 22, 23],
                                              [24, 25, 26]],

                                             [[ 0,  1,  2],
                                              [ 3,  4,  5],
                                              [ 6,  7,  8]]]]))
            
            XCTAssertEqual(a.T[c], MfArray([[[[ 1, 10, 19],
                                              [ 4, 13, 22],
                                              [ 7, 16, 25]],

                                             [[ 2, 11, 20],
                                              [ 5, 14, 23],
                                              [ 8, 17, 26]],

                                             [[ 2, 11, 20],
                                              [ 5, 14, 23],
                                              [ 8, 17, 26]],

                                             [[ 2, 11, 20],
                                              [ 5, 14, 23],
                                              [ 8, 17, 26]]],


                                            [[[ 2, 11, 20],
                                              [ 5, 14, 23],
                                              [ 8, 17, 26]],

                                             [[ 1, 10, 19],
                                              [ 4, 13, 22],
                                              [ 7, 16, 25]],

                                             [[ 2, 11, 20],
                                              [ 5, 14, 23],
                                              [ 8, 17, 26]],

                                             [[ 0,  9, 18],
                                              [ 3, 12, 21],
                                              [ 6, 15, 24]]]]))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])

            XCTAssertEqual(a[MfArray([-2,1,0]), MfArray([0,1,0])], MfArray([[ 9, 10, 11],
                                                                            [12, 13, 14],
                                                                            [ 0,  1,  2]]))
            
            XCTAssertEqual(a[MfArray([-2,1,0]), MfArray([0,1,0]), MfArray([2,2,2])], MfArray([11, 14,  2]))
        }
        
        do{
            let a = MfArray([[1, 2], [3, 4], [5, 6]])
            
            XCTAssertEqual(a[MfArray([0, 1, 2]), MfArray([0, 1, 0])], MfArray([1, 4, 5]))
            XCTAssertEqual(a.T[MfArray([0, 1, -1]), MfArray([0, 1, 0])], MfArray([1, 4, 2]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1, shape: [4,2,2])
            let b = Matft.nums(0, shape: [6,4,2])
            XCTAssertEqual(a[Matft.arange(start: 0, to: 4, by: 1), b[0, Matft.all, 0], 0], MfArray([ 0,  4,  8, 12]) )
        }
        
    }
    
    func testFancyIndexGet2(){
        
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,2,2])
            
            XCTAssertEqual(a[MfArray([0, 1, -1])],
                        MfArray([[[[ 0,  1],
                                   [ 2,  3]],

                                  [[ 4,  5],
                                   [ 6,  7]]],


                                 [[[ 8,  9],
                                   [10, 11]],

                                  [[12, 13],
                                   [14, 15]]],


                                 [[[ 8,  9],
                                   [10, 11]],

                                  [[12, 13],
                                   [14, 15]]]]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,2,2])
            
            XCTAssertEqual(a[0~<, Matft.all, MfArray([0, 1, 0]), 0~<],
                           MfArray([[[[ 0,  1],
                                      [ 2,  3],
                                      [ 0,  1]],

                                     [[ 4,  5],
                                      [ 6,  7],
                                      [ 4,  5]]],


                                    [[[ 8,  9],
                                      [10, 11],
                                      [ 8,  9]],

                                     [[12, 13],
                                      [14, 15],
                                      [12, 13]]]]))
            
            
            XCTAssertEqual(a[Matft.reverse, MfArray([0, 1, -1])],
                           MfArray([[[[ 8,  9],
                                      [10, 11]],

                                     [[12, 13],
                                      [14, 15]],

                                     [[12, 13],
                                      [14, 15]]],


                                    [[[ 0,  1],
                                      [ 2,  3]],

                                     [[ 4,  5],
                                      [ 6,  7]],

                                     [[ 4,  5],
                                      [ 6,  7]]]]))
        }
    }
    
    func testFancyIndexingSet(){
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1)
            let b = MfArray([3, 7, 2])
            a[b] = MfArray([10])
            XCTAssertEqual(a, MfArray([ 0,  1, 10, 10,  4,  5,  6, 10,  8,  9, 10, 11, 12, 13, 14, 15, 16,
                                        17, 18, 19, 20, 21, 22, 23, 24, 25, 26]))
            
            let c = MfArray([[2, 1],
                             [-2, 1]])
            a[c] = MfArray([999, -999])
            XCTAssertEqual(a, MfArray([   0, -999,  999,   10,    4,    5,    6,   10,    8,    9,   10,
                                             11,   12,   13,   14,   15,   16,   17,   18,   19,   20,   21,
                                             22,   23,   24,  999,   26]))
            

        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
            let b = MfArray([[2,1],
                             [-2,1]])
            
            a[b] = Matft.arange(start: -36, to: 0, by: 1, shape: [2,2,3,3])
            XCTAssertEqual(a, MfArray([[[  0,   1,   2],
                                       [  3,   4,   5],
                                       [  6,   7,   8]],

                                      [[ -9,  -8,  -7],
                                       [ -6,  -5,  -4],
                                       [ -3,  -2,  -1]],

                                      [[-36, -35, -34],
                                       [-33, -32, -31],
                                       [-30, -29, -28]]]))
            
            let c = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
            
            c.T[MfArray([[1,-1],[2,-2]])] = MfArray([-999])
            XCTAssertEqual(c, MfArray([[[   0, -999, -999],
                                        [   3, -999, -999],
                                        [   6, -999, -999]],

                                       [[   9, -999, -999],
                                        [  12, -999, -999],
                                        [  15, -999, -999]],

                                       [[  18, -999, -999],
                                        [  21, -999, -999],
                                        [  24, -999, -999]]]))
            
            c[MfArray([[1,-1],[2,-2]])] = Matft.arange(start: 80, to: 116, by: 1, shape: [2,2,3,3])
            XCTAssertEqual(c, MfArray([[[   0, -999, -999],
                                           [   3, -999, -999],
                                           [   6, -999, -999]],

                                          [[ 107,  108,  109],
                                           [ 110,  111,  112],
                                           [ 113,  114,  115]],

                                          [[  98,   99,  100],
                                           [ 101,  102,  103],
                                           [ 104,  105,  106]]]))
            
        }
        
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            a[MfArray([-2,1,0]), MfArray([0,1,0])] = MfArray([999])
            XCTAssertEqual(a, MfArray([[[999, 999, 999],
                                        [  3,   4,   5],
                                        [  6,   7,   8]],

                                       [[999, 999, 999],
                                        [999, 999, 999],
                                        [ 15,  16,  17]],

                                       [[ 18,  19,  20],
                                        [ 21,  22,  23],
                                        [ 24,  25,  26]]]))
            
            a.T[MfArray([-2,1,0]), MfArray([0,1,0])] = MfArray([-999])
            XCTAssertEqual(a, MfArray([[[-999, -999,  999],
                                       [   3, -999,    5],
                                       [   6,    7,    8]],

                                      [[-999, -999,  999],
                                       [ 999, -999,  999],
                                       [  15,   16,   17]],

                                      [[-999, -999,   20],
                                       [  21, -999,   23],
                                       [  24,   25,   26]]]))
        }
        
        do{
            let a = MfArray([[1, 2], [3, 4], [5, 6]])
            
            a[MfArray([0, 1, 2]), MfArray([0, -1, 0])] = MfArray([999,888,777])
            XCTAssertEqual(a, MfArray(([[999,   2],
                                        [  3, 888],
                                        [777,   6]])))
            
            a.T[MfArray([0, 1, -1]), MfArray([0, 1, 0])] = MfArray([-999,-888,-777])
            XCTAssertEqual(a, MfArray([[-999, -777],
                                       [   3, -888],
                                       [ 777,    6]]))
        }
    }
    
    func testFancyIndexingSet2(){
        do{
            let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
            let b = Matft.arange(start: -27, to: 0, by: 1, shape: [3,3,3])
            a[Matft.all, Matft.all, 0] = b[Matft.all, Matft.all, 0]

            XCTAssertEqual(a, MfArray([[[-27,   1,   2],
                                       [-24,   4,   5],
                                       [-21,   7,   8]],

                                      [[-18,  10,  11],
                                       [-15,  13,  14],
                                       [-12,  16,  17]],

                                      [[ -9,  19,  20],
                                       [ -6,  22,  23],
                                       [ -3,  25,  26]]]))
            
            a[Matft.all, 1, Matft.all] = b[Matft.all, 1, Matft.all]
            XCTAssertEqual(a, MfArray([[[-27,   1,   2],
                                        [-24, -23, -22],
                                        [-21,   7,   8]],

                                       [[-18,  10,  11],
                                        [-15, -14, -13],
                                        [-12,  16,  17]],

                                       [[ -9,  19,  20],
                                        [ -6,  -5,  -4],
                                        [ -3,  25,  26]]]))
            
            a[Matft.all, 1, Matft.all] = b.T[Matft.all, 1, Matft.all]
            XCTAssertEqual(a, MfArray([[[-27,   1,   2],
                                        [-24, -15,  -6],
                                        [-21,   7,   8]],

                                       [[-18,  10,  11],
                                        [-23, -14,  -5],
                                        [-12,  16,  17]],

                                       [[ -9,  19,  20],
                                        [-22, -13,  -4],
                                        [ -3,  25,  26]]]))

        }
        
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1, shape: [2,2,2,2])
            let b = a[Matft.reverse, Matft.all, Matft.reverse, Matft.all]
            a[~<1] = b[~<1]

            XCTAssertEqual(a, MfArray([[[[10, 11],
                                         [ 8,  9]],

                                        [[14, 15],
                                         [12, 13]]],


                                       [[[ 8,  9],
                                         [10, 11]],

                                        [[12, 13],
                                         [14, 15]]]]))
            
            
        }
    }
}
