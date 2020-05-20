import XCTest
//@testable import Matft
import Matft

final class SubscriptTests: XCTestCase {
    
    func testScalar() {
        do{
            let a = Matft.mfarray.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
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
            let a = Matft.mfarray.arange(start: 0, to: 4*4*4, by: 1, shape: [4,4,4], mftype: .UInt).T
            
            XCTAssertEqual(a[3,2,0] as! UInt, UInt(11))
            XCTAssertEqual(a[0,0,2] as! UInt, UInt(32))
            XCTAssertEqual(a[1,0,2] as! UInt, UInt(33))
            XCTAssertEqual(a[1,3,1] as! UInt, UInt(29))
            XCTAssertEqual(a[0,2,0] as! UInt, UInt(8))
        }
    }
    

    func testSlicing(){
        
        do{
            let a = Matft.mfarray.arange(start: 0, to: 27*2, by: 2, shape: [3,3,3], mftype: .Double, mforder: .Column)
            XCTAssertEqual(a[~1], MfArray([[[ 0, 18, 36],
                                            [ 6, 24, 42],
                                            [12, 30, 48]]], mftype: .Double))
            XCTAssertEqual(a[1~2], MfArray([[[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            XCTAssertEqual(a[~-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            XCTAssertNotEqual(a[~-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 2, 44],
                                             [14, 32, 50]]], mftype: .Double))
            
            XCTAssertEqual(a[0~,0~,~-1], MfArray([[[ 0, 18],
                                                   [ 6, 24],
                                                   [12, 30]],

                                                  [[ 2, 20],
                                                   [ 8, 26],
                                                   [14, 32]],

                                                  [[ 4, 22],
                                                   [10, 28],
                                                   [16, 34]]], mftype: .Double))
            XCTAssertEqual(a[0~,-1~-3~-1,-2], MfArray([[30, 24],
                                                       [32, 26],
                                                       [34, 28]], mftype: .Double))
        }
        
        do{
            let a = Matft.mfarray.broadcast_to(MfArray([[2, 5, -1],
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
            
            XCTAssertEqual(a[-1~~-1, (-2)~], MfArray([[[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]],


                                                    [[[ 2,  5, -1],
                                                      [ 3,  1,  0]],

                                                     [[ 2,  5, -1],
                                                      [ 3,  1,  0]]]]))
            
            XCTAssertEqual(a[0~,0~,~1~-1,~~3], MfArray([[[[2]],

                                                         [[2]]],


                                                        [[[2]],

                                                         [[2]]]]))
            XCTAssertNotEqual(a[0~,0~,~1~-1,~~3], MfArray([[[2],

                                                            [2]],


                                                           [[2],

                                                            [2]]]))
            XCTAssertEqual(a[~1, ~~-2], MfArray([[[[ 2,  5, -1],
                                                   [ 3,  1,  0]]]]))
        }
    }
    
    func testSubscrpt_Subscript(){
        do{
            let a = Matft.mfarray.arange(start: 0, to: 27*2, by: 2, shape: [3,3,3], mftype: .Double, mforder: .Column)

            XCTAssertEqual(a[~-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            let b = a[~-1]
            

            XCTAssertEqual(b[~1, ~2], MfArray([[[ 0, 18, 36],
                                                [ 6, 24, 42]]], mftype: .Double))

            XCTAssertEqual(b[0], MfArray([[ 0, 18, 36],
                                          [ 6, 24, 42],
                                          [12, 30, 48]], mftype: .Double))
            XCTAssertEqual(b[0~, ~~-1], MfArray([[[12, 30, 48],
                                                  [ 6, 24, 42],
                                                  [ 0, 18, 36]],

                                                 [[14, 32, 50],
                                                  [ 8, 26, 44],
                                                  [ 2, 20, 38]]], mftype: .Double))
        }
        
        do{
            let a = Matft.mfarray.broadcast_to(MfArray([[2, 5, -1],
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
            
            XCTAssertEqual(a[0~, ~1, ~~2], MfArray([[[[ 2,  5, -1]]],


                                                    [[[ 2,  5, -1]]]]))
            
            XCTAssertEqual(a[~~-1], MfArray([[[[ 2,  5, -1],
                                               [ 3,  1,  0]],

                                              [[ 2,  5, -1],
                                               [ 3,  1,  0]]],


                                             [[[ 2,  5, -1],
                                               [ 3,  1,  0]],

                                              [[ 2,  5, -1],
                                               [ 3,  1,  0]]]]))
            
            let b = a[0~, ~1, ~~2]
            XCTAssertEqual(b[0, ~1], MfArray([[[ 2,  5, -1]]]))
            
        }
        
        do{
            let a = Matft.mfarray.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
            
            let b = a[0~, 1]
            XCTAssertEqual(b[~~-1], MfArray([[26, 27],
                                             [18, 19],
                                             [10, 11],
                                             [ 2,  3]]))
            
            XCTAssertEqual(b[0~,1], MfArray([ 3, 11, 19, 27]))
            
            XCTAssertEqual(b[-1,1~~-1], MfArray([27, 26]))
            
            XCTAssertEqual(b.T[0~,1], MfArray([10, 11]))
        }
    }
    
    func testAssign(){
        do{
            let a = Matft.mfarray.arange(start: 0, to: 27*2, by: 2, shape: [3,3,3], mftype: .Double, mforder: .Column)

            XCTAssertEqual(a[~-1], MfArray([[[ 0, 18, 36],
                                             [ 6, 24, 42],
                                             [12, 30, 48]],

                                            [[ 2, 20, 38],
                                             [ 8, 26, 44],
                                             [14, 32, 50]]], mftype: .Double))
            let b = a[~-1]
            
            b[~1, ~2] = MfArray([3333])
            XCTAssertEqual(a, MfArray([[[3333, 3333, 3333],
                                        [3333, 3333, 3333],
                                        [  12,   30,   48]],

                                       [[   2,   20,   38],
                                        [   8,   26,   44],
                                        [  14,   32,   50]],

                                       [[   4,   22,   40],
                                        [  10,   28,   46],
                                        [  16,   34,   52]]], mftype: .Double))
            
            b[0] = Matft.mfarray.arange(start: 0, to: 9, by: 1).reshape([3,3])
            XCTAssertEqual(a, MfArray([[[ 0,  1,  2],
                                        [ 3,  4,  5],
                                        [ 6,  7,  8]],

                                       [[ 2, 20, 38],
                                        [ 8, 26, 44],
                                        [14, 32, 50]],

                                       [[ 4, 22, 40],
                                        [10, 28, 46],
                                        [16, 34, 52]]], mftype: .Double))
            
            b[0~, ~~-1] = MfArray([0])
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
            let a = Matft.mfarray.broadcast_to(MfArray([[2, 5, -1],
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
            
            a[0~, ~1, ~~2] = MfArray([888, 777, 333])
            
            XCTAssertEqual(a, MfArray([[[[888, 777, 333],
                                         [  3,   1,   0]],

                                        [[888, 777, 333],
                                         [  3,   1,   0]]],


                                       [[[888, 777, 333],
                                         [  3,   1,   0]],

                                        [[888, 777, 333],
                                         [  3,   1,   0]]]]))
            

            
            let b = a[0~, ~1, ~~2]
            
            b[0, 0~1] = MfArray([222])
            //b[0, ~1] = MfArray([222]) //>>> passed as Int of Array... It's strange
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
            let a = Matft.mfarray.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
            
            let b = a[0~, 1]
            b[~~-1] = MfArray([9999])
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
            
            b[-1,1~~-1] = MfArray([-9999])
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
    }
}
