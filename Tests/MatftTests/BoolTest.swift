import XCTest
//@testable import Matft
import Matft

final class BoolTests: XCTestCase {
    
    func testAllEqual() {
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertTrue(a == MfArray<Bool>([true, false]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertFalse(a == b)
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertTrue(a == c)
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                  [[4,5],
                                   [6,7]]])
            XCTAssertTrue(a == b)
            XCTAssertFalse(a[0~<,0~<,~<~<-1] == Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]))
            
        }
    }
    
    //element-wise
    func testEqual(){
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertEqual(a === MfArray<Bool>([true, false]), MfArray<Bool>([true, true]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray<Bool>([true, false, true, true]))
            XCTAssertEqual(-3 === b, MfArray<Bool>([false, false, true, false]))
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a === c, MfArray<Bool>([true, true, true, true]))
            XCTAssertEqual(a === 1, MfArray<Bool>([false, true, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                  [[4,5],
                                   [6,7]]])
            XCTAssertEqual(a === b, MfArray<Bool>([[[true,true],
                                                    [true,true]],
            
                                                   [[true,true],
                                                    [true,true]]]))
            
            XCTAssertEqual(a[0~<,0~<,~<~<-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray<Bool>([[[false,false],
                                                    [false,false]],
            
                                                   [[false,false],
                                                    [false,false]]]))
        }
    }
    
    
    func testLogicalNot(){
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertEqual(!a, MfArray<Bool>([false, true]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray<Bool>([true, false, true, true]))
            XCTAssertEqual(!(a === b), MfArray<Bool>([false, true, false, false]))
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(!(a === c), MfArray<Bool>([false, false, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                    [[4,5],
                              [6,7]]])
            XCTAssertEqual(!(a === b), MfArray<Bool>([[[false,false],
                                                       [false,false]],
            
                                                      [[false,false],
                                                       [false,false]]]))
            
            XCTAssertEqual(!(a[0~<,0~<,~<~<-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2])),
                                    MfArray<Bool>([[[true,true],
                                                    [true,true]],
                                    
                                                   [[true,true],
                                                    [true,true]]]))
        }
    }
    
    func testNotEqual(){
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertEqual(a !== a, MfArray<Bool>([false, false]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray<Bool>([true, false, true, true]))
            XCTAssertEqual(a !== b, MfArray<Bool>([false, true, false, false]))
            XCTAssertEqual(2.0 !== b, MfArray<Bool>([false, true, true, true]))
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a !== c, MfArray<Bool>([false, false, false, false]))
            XCTAssertEqual(a !== 1.0, MfArray<Bool>([true, false, true, true]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                  [[4,5],
                                   [6,7]]])
            XCTAssertEqual(a !== b, MfArray<Bool>([[[false,false],
                                                    [false,false]],
            
                                                   [[false,false],
                                                    [false,false]]]))
            
            XCTAssertEqual(a[0~<,0~<,~<~<-1] !== Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray<Bool>([[[true,true],
                                                    [true,true]],
                                    
                                                   [[true,true],
                                                    [true,true]]]))
        }
    }
    
    func testLess(){
        do{
            let a = MfArray<Int>([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray<Int>([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])

            XCTAssertEqual(a < b, MfArray<Bool>([[ true,  true,  true,  true, false],
                                           [ true,  true, false, false, false]]))
        }

        do{
            let a = MfArray<Float>([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray<Float>([[0.31286134, 0.69967412]])

            XCTAssertEqual(a < b, MfArray<Bool>([[false,  true],
                                           [false,  true],
                                           [ true,  true]]))
        }

        do{
            let a = MfArray<Float>([[[0.51448786, 0.25203844],
                              [0.85263964, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray<Float>([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])

            XCTAssertEqual(a < b, MfArray<Bool>([[[false, false],
                                            [false, false]],

                                           [[false, false],
                                            [ true,  true]]]))

            XCTAssertEqual(a.transpose(axes: [2,0,1]) < b, MfArray<Bool>([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }
    }

    func testGreater(){
        do{
            let a = MfArray<Int>([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray<Int>([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])

            XCTAssertEqual(b > a, MfArray<Bool>([[ true,  true,  true,  true, false],
                                           [ true,  true, false, false, false]]))
        }

        do{
            let a = MfArray<Float>([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray<Float>([[0.31286134, 0.69967412]])

            XCTAssertEqual(b > a, MfArray<Bool>([[false,  true],
                                           [false,  true],
                                           [ true,  true]]))
        }

        do{
            let a = MfArray<Float>([[[0.51448786, 0.25203844],
                              [0.85263964, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray<Float>([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])

            XCTAssertEqual(b > a, MfArray<Bool>([[[false, false],
                                            [false, false]],

                                           [[false, false],
                                            [ true,  true]]]))

            XCTAssertEqual(b > a.transpose(axes: [2,0,1]), MfArray<Bool>([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }

        do{
            let img = MfArray<UInt8>([[1, 2, 3],
                               [4, 5, 6],
                               [7, 8, 9]])
            img[img > 3] = MfArray<UInt8>([10])
            XCTAssertEqual(img, MfArray<UInt8>([[ 1,  2,  3],
                                         [10, 10, 10],
                                         [10, 10, 10]]))
            //print(img)
        }
    }

    func testLessEqual(){
        do{
            let a = MfArray<Int>([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray<Int>([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])

            XCTAssertEqual(a <= b, MfArray<Bool>([[ true,  true,  true,  true, false],
                                           [ true,  true, true, false, false]]))
        }

        do{
            let a = MfArray<Float>([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray<Float>([[0.60871936, 0.69967412]])

            XCTAssertEqual(a <= b, MfArray<Bool>([[false,  true],
                                           [ true,  true],
                                           [ true,  true]]))
        }

        do{
            let a = MfArray<Float>([[[0.51448786, 0.25203844],
                              [0.70294935, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray<Float>([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])

            XCTAssertEqual(a <= b, MfArray<Bool>([[[false, false],
                                            [ true, false]],

                                           [[false, false],
                                            [ true,  true]]]))

            XCTAssertEqual(a.transpose(axes: [2,0,1]) <= b, MfArray<Bool>([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }
    }

    func testGreaterEqual(){
        do{
            let a = MfArray<Int>([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray<Int>([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])

            XCTAssertEqual(b >= a, MfArray<Bool>([[ true,  true,  true,  true, false],
                                           [ true,  true, true, false, false]]))
        }

        do{
            let a = MfArray<Float>([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray<Float>([[0.60871936, 0.69967412]])

            XCTAssertEqual(b >= a, MfArray<Bool>([[false,  true],
                                           [ true,  true],
                                           [ true,  true]]))
        }

        do{
            let a = MfArray<Float>([[[0.51448786, 0.25203844],
                              [0.70294935, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray<Float>([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])

            XCTAssertEqual(b >= a, MfArray<Bool>([[[false, false],
                                            [ true, false]],

                                           [[false, false],
                                            [ true,  true]]]))

            XCTAssertEqual(b >= a.transpose(axes: [2,0,1]), MfArray<Bool>([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }
    }
}
