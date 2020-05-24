import XCTest
//@testable import Matft
import Matft

final class CreationTests: XCTestCase {
    
    
    func testDiag() {
        do{
            XCTAssertEqual(Matft.diag(v: [3, -19, -22, 4]), MfArray<Int>([[  3,   0,   0,   0],
                                                                          [  0, -19,   0,   0],
                                                                          [  0,   0, -22,   0],
                                                                          [  0,   0,   0,   4]]))
            let a = MfArray<Int>([3, -19, -22, 4])
            XCTAssertEqual(Matft.diag(v: a), MfArray<Int>([[  3,   0,   0,   0],
                                                           [  0, -19,   0,   0],
                                                           [  0,   0, -22,   0],
                                                           [  0,   0,   0,   4]]))
        }

        do{

            XCTAssertEqual(Matft.diag(v: [-0.87, 1.2, 5.5134, -8.78]), MfArray<Double>([[-0.87  ,  0.0    ,  0.0    ,  0.0    ],
                                                                                        [ 0.0    ,  1.2   ,  0.0    ,  0.0    ],
                                                                                        [ 0.0    ,  0.0    ,  5.5134,  0.0    ],
                                                                                        [ 0.0    ,  0.0    ,  0.0    , -8.78  ]]))
            let a = MfArray<Double>([-0.87, 1.2, 5.5134, -8.78], mforder: .Column)
            XCTAssertEqual(Matft.diag(v: a), MfArray<Double>([[-0.87  ,  0.0    ,  0.0    ,  0.0    ],
                                                              [ 0.0    ,  1.2   ,  0.0    ,  0.0    ],
                                                              [ 0.0    ,  0.0    ,  5.5134,  0.0    ],
                                                              [ 0.0    ,  0.0    ,  0.0    , -8.78  ]]))

        }
        
        
    }
    

    func testEye(){
        do{
            XCTAssertEqual(Matft.eye(dim: 3), MfArray<Int>([[ 1,  0,  0],
                                                            [ 0,  1,  0],
                                                            [ 0,  0,  1]]))
        }
        do{
            XCTAssertEqual(Matft.eye(dim: 3), MfArray<Float>([[ 1,  0,  0],
                                                              [ 0,  1,  0],
                                                              [ 0,  0,  1]]))
        }
    }
    

}
