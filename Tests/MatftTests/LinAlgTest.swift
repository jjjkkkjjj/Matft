import XCTest
//@testable import Matft
import Matft

final class LinAlgTests: XCTestCase {
    
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
    
    func testDet(){
        
        do{
            let a = MfArray([[1, 2], [3, 4]])
            XCTAssertEqual(try Matft.mfarray.linalg.det(a), MfArray([-2.0], mftype: .Float))
        }
        
        do{
            let a = MfArray([[[1.0, 2.0],
                              [3.0, 4.0]],
                             
                             [[1.0, 3.0],
                              [3.0, 5.0]]], mftype: .Double)
            XCTAssertEqual(try Matft.mfarray.linalg.det(a), MfArray([-2.0, -4.0], mftype: .Double))
        }
    }
    
    func testEigen(){
        do{
            let a = MfArray([[1, -1], [1, 1]])
            let ret = try! Matft.mfarray.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray([1, 1], mftype: .Float))
            XCTAssertEqual(ret.valIm, MfArray([1, -1], mftype: .Float))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray([[-0.70710677, -0.70710677],
                                                [0.0, 0.0]], mftype: .Float))
            XCTAssertEqual(ret.lvecIm, MfArray([[0.0, 0.0],
                                                [0.70710677, -0.70710677]], mftype: .Float))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray([[0.70710677, 0.70710677],
                                                [0.0, 0.0]], mftype: .Float))
            XCTAssertEqual(ret.rvecIm, MfArray([[0.0, 0.0],
                                                [-0.70710677, 0.70710677]], mftype: .Float))
            
        }
        do{
            let a = MfArray([[[1,0,0],
                              [0,2,0],
                              [0,0,3]]], mftype: .Double)
            let ret = try! Matft.mfarray.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray([[1, 2, 3]], mftype: .Double))
            XCTAssertEqual(ret.valIm, MfArray([[0, 0, 0]], mftype: .Double))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray([[[1.0, 0.0, 0.0],
                                                [0.0, 1.0, 0.0],
                                                [0.0, 0.0, 1.0]]], mftype: .Double))
            XCTAssertEqual(ret.lvecIm, MfArray([[[0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0]]], mftype: .Double))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray([[[1.0, 0.0, 0.0],
                                                [0.0, 1.0, 0.0],
                                                [0.0, 0.0, 1.0]]], mftype: .Double))
            XCTAssertEqual(ret.rvecIm, MfArray([[[0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0]]], mftype: .Double))
            
        }
        do{
            let a = MfArray([[0, -1],
                             [1, 0]], mftype: .Double)
            let ret = try! Matft.mfarray.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray([0, 0], mftype: .Double))
            XCTAssertEqual(ret.valIm, MfArray([1, -1], mftype: .Double))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray([[-0.707106781186547, -0.707106781186547],
                                                [0.0, 0.0]], mftype: .Double))
            XCTAssertEqual(ret.lvecIm, MfArray([[0.0, 0.0],
                                                [0.707106781186547, -0.707106781186547]], mftype: .Double))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray([[0.707106781186547, 0.707106781186547],
                                                [0.0, 0.0]], mftype: .Double))
            XCTAssertEqual(ret.rvecIm, MfArray([[0.0, 0.0],
                                                [-0.707106781186547, 0.707106781186547]], mftype: .Double))
            
        }
    }
}
