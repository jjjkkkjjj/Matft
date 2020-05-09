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
    
    func testSVD(){
        do{/*
            let a = MfArray([[2, 4, 1, 3],
                             [1, 5, 3, 2],
                             [5, 7, 0, 7]], mftype: .Double)
            let ret = try! Matft.mfarray.linalg.svd(a)
            //astype is for avoiding minute error
            XCTAssertEqual(ret.v.astype(.Float), MfArray([[-0.40783698, -0.12444751,  0.90453403],
                                                          [-0.40538262, -0.86299238, -0.30151134],
                                                          [-0.81812831,  0.48964985, -0.30151134]], mftype: .Float))
            XCTAssertEqual(ret.s.astype(.Float), MfArray([1.33853840e+01, 3.58210781e+00, 5.07054122e-16], mftype: .Float))
            XCTAssertEqual(ret.rt.astype(.Float), MfArray([[-0.39682822, -0.70114979, -0.12132523, -0.57982456],
                                                           [ 0.37306578, -0.38670052, -0.75749385,  0.37079333],
                                                           [-0.82742746,  0.06343221, -0.18163613,  0.5275874 ],
                                                           [ 0.13679576, -0.59567443,  0.61521668,  0.49796317]], mftype: .Float))
 */
        }
    }
    
    func testPolar(){
        do{
            let a = MfArray([[1, -1],
                             [2, 4]])
            let retR = try! Matft.mfarray.linalg.polar_right(a)
            XCTAssertEqual(retR.u, MfArray([[ 0.85749293, -0.51449576],
                                           [ 0.51449576,  0.85749293]], mftype: .Float))
            XCTAssertEqual(retR.p, MfArray([[ 1.88648444,  1.2004901 ],
                                           [ 1.2004901 ,  3.94446746]], mftype: .Float))
            
            let retL = try! Matft.mfarray.linalg.polar_left(a)
            XCTAssertEqual(retL.l, MfArray([[ 0.85749293, -0.51449576],
                                            [ 0.51449576,  0.85749293]], mftype: .Float))
            XCTAssertEqual(retL.p, MfArray([[ 1.37198868, -0.34299717],
                                            [-0.34299717,  4.45896321]], mftype: .Float))
            
        }
        do{
            let a = MfArray([[0.5, 1, 2],
                             [1.5, 3, 4],
                             [2, 3.5, 1]])
            let retR = try! Matft.mfarray.linalg.polar_right(a)
            XCTAssertEqual(retR.u.astype(.Float), MfArray([[ 0.72794019, -0.42246022,  0.54002819],
                                                          [-0.28527167,  0.52959999,  0.79883911],
                                                          [ 0.62347667,  0.73556183, -0.26500119]], mftype: .Float))
            XCTAssertEqual(retR.p.astype(.Float), MfArray([[1.18301594, 2.05429354, 0.93827039],
                                                           [2.05429354, 3.74080617, 2.00904136],
                                                           [0.93827039, 2.00904136, 4.01041163]], mftype: .Float))
            let retL = try! Matft.mfarray.linalg.polar_left(a)
            XCTAssertEqual(retL.l.astype(.Float), MfArray([[ 0.72794019, -0.42246022,  0.54002819],
                                                           [-0.28527167,  0.52959999,  0.79883911],
                                                           [ 0.62347667,  0.73556183, -0.26500119]], mftype: .Float))
            XCTAssertEqual(retL.p.astype(.Float), MfArray([[1.02156625, 1.98464238, 0.51729779],
                                                           [1.98464238, 4.35624892, 2.08189576],
                                                           [0.51729779, 2.08189576, 3.55641857]], mftype: .Float))
            
        }
    }
}
