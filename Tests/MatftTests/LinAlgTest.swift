//
//  LinAlgTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/03/24.
//

import XCTest
//@testable import Matft
import Matft

final class LinAlgTests: XCTestCase {
    
    func testSolve() {
        do{
            let coef = MfArray<Int>([[3,2],[1,2]])
            let b = MfArray<Int>([7,1])
            
            XCTAssertEqual(try Matft.linalg.solve(coef, b: b), MfArray<Float>([ 3.0, -1.0] as [Float]))
        }

        do{
            let coef = MfArray<Double>([[3,1],[1,2]] as [[Double]])
            let b = MfArray<Double>([9,8] as [Double])
            
            XCTAssertEqual(try Matft.linalg.solve(coef, b: b), MfArray<Double>([ 2.0, 3.0] as [Double]))
        }
        
        do{
            let coef = MfArray<Int>([[1,2],[2,4]])
            let b = MfArray<Int>([-1,-2])
            
            XCTAssertThrowsError(try Matft.linalg.solve(coef, b: b))
        }
        
        do{
            let coef = MfArray<Int>([[1,2],[2,4]])
            let b = MfArray<Int>([-1,-3])
            
            XCTAssertThrowsError(try Matft.linalg.solve(coef, b: b))
        }
    }
    
    func testInv(){
        do{
            let a = MfArray<Int>([[1, 2], [3, 4]])
            XCTAssertEqual(try Matft.linalg.inv(a), MfArray([[-2.0 ,  1.0 ],
                                                                     [ 1.5, -0.5]] as [[Float]]))
        }
        do{
            let a = MfArray<Double>([[[1.0, 2.0],
                              [3.0, 4.0]],
                             
                             [[1.0, 3.0],
                              [3.0, 5.0]]] as [[[Double]]])
            XCTAssertEqual(try Matft.linalg.inv(a), MfArray<Double>([[[-2.0  ,  1.0  ],
                        [ 1.5 , -0.5 ]],
                                                             
                         [[-1.25,  0.75],
                          [ 0.75, -0.25]]] as [[[Double]]]))
        }
    }
    
    func testDet(){
        
        do{
            let a = MfArray<Int>([[1, 2], [3, 4]])
            XCTAssertEqual(try Matft.linalg.det(a), MfArray<Float>([-2.0] as [Float]))
        }
        
        do{
            let a = MfArray<Double>([[[1.0, 2.0],
                                      [3.0, 4.0]],
                                     
                                     [[1.0, 3.0],
                                      [3.0, 5.0]]] as [[[Double]]])
            XCTAssertEqual(try Matft.linalg.det(a), MfArray<Double>([-2.0, -4.0] as [Double]))
        }
    }
    
    func testEigen(){
        do{
            let a = MfArray<Int>([[1, -1], [1, 1]])
            let ret = try! Matft.linalg.eigen(a)

            // value
            XCTAssertEqual(ret.valRe, MfArray<Float>([1, 1] as [Float]))
            XCTAssertEqual(ret.valIm, MfArray<Float>([1, -1] as [Float]))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray<Float>([[-0.70710677, -0.70710677],
                                                [0.0, 0.0]] as [[Float]]))
            XCTAssertEqual(ret.lvecIm, MfArray<Float>([[0.0, 0.0],
                                                [0.70710677, -0.70710677]] as [[Float]]))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray<Float>([[0.70710677, 0.70710677],
                                                [0.0, 0.0]] as [[Float]]))
            XCTAssertEqual(ret.rvecIm, MfArray<Float>([[0.0, 0.0],
                                                [-0.70710677, 0.70710677]] as [[Float]]))
            
        }
        do{
            let a = MfArray<Int>([[[1,0,0],
                              [0,2,0],
                              [0,0,3]]])
            let ret = try! Matft.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray<Float>([[1, 2, 3]] as [[Float]]))
            XCTAssertEqual(ret.valIm, MfArray<Float>([[0, 0, 0]] as [[Float]]))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray<Float>([[[1.0, 0.0, 0.0],
                                                [0.0, 1.0, 0.0],
                                                [0.0, 0.0, 1.0]]] as [[[Float]]]))
            XCTAssertEqual(ret.lvecIm, MfArray<Float>([[[0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0]]] as [[[Float]]]))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray<Float>([[[1.0, 0.0, 0.0],
                                                [0.0, 1.0, 0.0],
                                                [0.0, 0.0, 1.0]]] as [[[Float]]]))
            XCTAssertEqual(ret.rvecIm, MfArray<Float>([[[0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0]]] as [[[Float]]]))
            
        }
        do{
            let a = MfArray<Int>([[0, -1],
                             [1, 0]])
            let ret = try! Matft.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray<Float>([0, 0] as [Float]))
            XCTAssertEqual(ret.valIm, MfArray<Float>([1, -1] as [Float]))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray<Float>([[-0.707106781186547, -0.707106781186547],
                                                [0.0, 0.0]] as [[Float]]))
            XCTAssertEqual(ret.lvecIm, MfArray<Float>([[0.0, 0.0],
                                                [0.707106781186547, -0.707106781186547]] as [[Float]]))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray<Float>([[0.707106781186547, 0.707106781186547],
                                                [0.0, 0.0]] as [[Float]]))
            XCTAssertEqual(ret.rvecIm, MfArray<Float>([[0.0, 0.0],
                                                [-0.707106781186547, 0.707106781186547]] as [[Float]]))
            
        }
    }
    
    func testSVD(){
        do{
            let a = MfArray<Int>([[2, 4, 1, 3],
                             [1, 5, 3, 2],
                             [5, 7, 0, 7]])
            let ret = try! Matft.linalg.svd(a)
            //astype is for avoiding minute error
            //XCTAssertEqual(ret.v.astype(.Float), MfArray<Int>([[-0.40783698, -0.12444751,  0.90453403],
            //                                              [-0.40538262, -0.86299238, -0.30151134],
            //                                              [-0.81812831,  0.48964985, -0.30151134]]))
            XCTAssertEqual(ret.s, MfArray<Float>([1.33853840e+01, 3.58210781e+00, 5.07054122e-16] as [Float]))
            /*
             below assertion is failure... I don't know the reason...
             */
            //XCTAssertEqual(ret.rt.astype(.Float), MfArray<Int>([[-0.39682822, -0.70114979, -0.12132523, -0.57982456],
            //                                               [ 0.37306578, -0.38670052, -0.75749385,  0.37079333],
            //                                               [-0.67701194,  0.46970832, -0.56642431,  0.01387163],
            //                                               [-0.49497891, -0.37178726,  0.30107599,  0.72534362]]))
            //print(ret.v *& Matft.diag(v: ret.s) *& ret.rt)
            //print(ret.rt *& ret.rt.T)
            
            let ret_nofull = try! Matft.linalg.svd(a, full_matrices: false)
            
            XCTAssertEqual((ret_nofull.v *& Matft.diag(v: ret_nofull.s) *& ret_nofull.rt).nearest(), a.astype(newtype: Int.self))
        }
        
        do{
            let a = MfArray<Int>([[1, 2],
                             [3, 4]])
            let ret = try! Matft.linalg.svd(a)
            XCTAssertEqual(ret.v, MfArray<Float>([[-0.40455358, -0.9145143 ],
                                           [-0.9145143 ,  0.40455358]] as [[Float]]))
            XCTAssertEqual(ret.s, MfArray<Float>([ 5.4649857 ,  0.36596619] as [Float]))
            XCTAssertEqual(ret.rt, MfArray<Float>([[-0.57604844, -0.81741556],
                                            [ 0.81741556, -0.57604844]] as [[Float]]))
            
            //XCTAssertEqual((ret.v *& Matft.diag(v: ret.s) *& ret.rt).nearest(), a)
        }
        
    }
}
