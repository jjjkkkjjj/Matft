import XCTest
//@testable import Matft
import Matft

final class LinAlgTests: XCTestCase {
    
    static var allTests = [
        ("testSolve", testSolve),
        ("testInv", testInv),
    ]
    
    func testSolve() {
        do{
            let coef = MfArray([[3,2],[1,2]])
            let b = MfArray([7,1])
            
            XCTAssertEqual(try Matft.mfarray.linalg.solve(coef, b: b), MfArray([ 3.0, -1.0], mftype: .Float))
        }

        do{
            let coef = MfArray([[3,1],[1,2]], mftype: .Double)
            let b = MfArray([9,8])
            
            XCTAssertEqual(try Matft.mfarray.linalg.solve(coef, b: b), MfArray([ 2.0, 3.0], mftype: .Double))
        }
        
        do{
            let coef = MfArray([[1,2],[2,4]])
            let b = MfArray([-1,-2])
            
            XCTAssertThrowsError(try Matft.mfarray.linalg.solve(coef, b: b))
        }
        
        do{
            let coef = MfArray([[1,2],[2,4]])
            let b = MfArray([-1,-3])
            
            XCTAssertThrowsError(try Matft.mfarray.linalg.solve(coef, b: b))
        }
    }
    

    func testInv(){
        do{
            let a = MfArray([[1, 2], [3, 4]])
            XCTAssertEqual(try Matft.mfarray.linalg.inv(a), MfArray([[-2.0 ,  1.0 ],
                                                                     [ 1.5, -0.5]], mftype: .Float))
        }
        do{
            let a = MfArray([[[1.0, 2.0],
                              [3.0, 4.0]],
                             
                             [[1.0, 3.0],
                              [3.0, 5.0]]], mftype: .Double)
            XCTAssertEqual(try Matft.mfarray.linalg.inv(a), MfArray([[[-2.0  ,  1.0  ],
                                                [ 1.5 , -0.5 ]],
                                                                     [[-1.25,  0.75],
                                                                      [ 0.75, -0.25]]], mftype: .Double))
        }
    }
}
