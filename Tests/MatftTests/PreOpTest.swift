import XCTest
//@testable import Matft
import Matft

final class PreOpTests: XCTestCase {
    
    
    func testNormal() {
        do{

            let a = MfArray<Int>([[3, -19],
                                  [-22, 4]])
            let b = MfArray<Int>([[2, 1177],
                                  [5, -43]])
            
            XCTAssertEqual(-a, MfArray([[-3, 19],
                                        [22, -4]]))
            
            XCTAssertEqual(-b, MfArray([[-2, -1177],
                                        [-5, 43]]))
        }

        do{
            
            let a = MfArray<Int>([[2, 1, -3, 0],
                                  [3, 1, 4, -5]], mforder: .Column)
            let b = MfArray<Double>([[-0.87, 1.2, 5.5134, -8.78],
                                     [-0.0002, 2, 3.4, -5]], mforder: .Column)

            XCTAssertEqual(-a, MfArray<Int>([[-2, -1, 3, 0],
                                             [-3, -1, -4, 5]]))
            XCTAssertEqual(-b, MfArray<Double>([[0.87, -1.2, -5.5134, 8.78],
                                                [0.0002, -2, -3.4, 5]]))

        }
        
        do{
            let a = Matft.arange(start: UInt8(0), to: 4*4, by: 1, shape: [4,4]).T
            let b = MfArray<UInt8>([[251, 3, 2, 4],
                                    [247, 3, 1, 1],
                                    [22, 17, 0, 254],
                                    [1, 249, 3, 3]], mforder: .Column)
            XCTAssertEqual(-a, MfArray<UInt8>([[  0, 252, 248, 244],
                                               [255, 251, 247, 243],
                                               [254, 250, 246, 242],
                                               [253, 249, 245, 241]]))
            XCTAssertEqual(-b, MfArray<UInt8>([[  5, 253, 254, 252],
                                               [  9, 253, 255, 255],
                                               [234, 239,   0,   2],
                                               [255,   7, 253, 253]]))
        }
    }
    

    func testBroadcast(){
        do{
            let a = MfArray<Int>([[1, 3, 5],
                                  [2, -4, -1]], mforder: .Column)
            let b = a.broadcast_to(shape: [3,2,3])
            XCTAssertEqual(-b, MfArray<Int>([[[ -1,  -3,  -5],
                                              [-2, 4, 1]],

                                             [[ -1,  -3,  -5],
                                              [-2, 4, 1]],

                                             [[ -1,  -3,  -5],
                                              [-2, 4, 1]]]))
            let c = MfArray<Int>([[1, 2]])
            let d = c.broadcast_to(shape: [2,2])
            XCTAssertEqual(-d, MfArray<Int>([[-1,-2],
                                             [-1,-2]]))
        }
        do{
            let a = MfArray<Int>([[2, -7, 0],
                                  [1, 5, -2]]).reshape([2,1,1,3])
            let b = a.broadcast_to(shape: [2,2,2,3])
            XCTAssertEqual(-b, MfArray<Int>([[[[ -2, 7,  0],
                                               [ -2, 7,  0]],

                                              [[ -2, 7,  0],
                                               [ -2, 7,  0]]],
                                                                          

                                             [[[ -1,  -5, 2],
                                               [ -1,  -5, 2]],

                                              [[ -1,  -5, 2],
                                               [ -1,  -5, 2]]]]))
        }
    }
    
    func testNegativeIndexing(){
        
        do{
            let a = Matft.arange(start: 0, to: 3*3*3*2, by: 2, shape: [3, 3, 3])
            let b = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
            let c = a[~~-1]
            let d = b[2, 1, ~~-1]
            
            XCTAssertEqual(-c, MfArray<Int>([[[-36, -38, -40],
                                              [-42, -44, -46],
                                              [-48, -50, -52]],

                                             [[-18, -20, -22],
                                              [-24, -26, -28],
                                              [-30, -32, -34]],

                                             [[  0,  -2,  -4],
                                              [ -6,  -8, -10],
                                              [-12, -14, -16]]]))
            
            XCTAssertEqual(-d, MfArray<Int>([-23, -22, -21]))

        }
        
        do{
            let a = MfArray<Double>([[1.28, -3.2],[1.579, -0.82]])
            let b = MfArray<Double>([2,1])
            let c = a[-1~-2~-1]
            let d = b[~~-1]

            XCTAssertEqual(-c, MfArray<Double>([[-1.579,  0.82 ]]))
            XCTAssertEqual(-d, MfArray<Double>([ -1, -2 ]))
        }
    }
}
