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
    
    func testPInv(){
        do{
            let a = MfArray<Int>([[2, -1, 0],
                             [4,3,-2]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 5),
                           MfArray<Float>([[ 0.31666667,  0.08333333],
                                    [-0.36666667,  0.16666667],
                                    [ 0.08333333, -0.08333333]]
                                   as [[Float]]).round(decimals: 5))
        }
        
        do{
            let a = MfArray<Float>([[ 0.10122714, -1.7555435 ,  0.72242671],
                             [ 0.70605646, -3.03520525, -0.8974524 ],
                             [ 0.89382228,  0.53009567,  1.59680764],
                             [-0.61128203, -0.75155814,  0.00382533]] as [[Float]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 5), MfArray<Float>([[-0.34872843,  0.42493471,  0.39808427, -0.62075487],
                                [-0.24171501, -0.14397516,  0.0288316 , -0.16416708],
                                [ 0.40742503, -0.2408292 ,  0.30600237,  0.23674046]] as [[Float]]).round(decimals: 5))
        }
        
        do{
            let a = MfArray<Int>([[-33,  43,  25],
                             [-65, -36, -33],
                             [-26,  44, -65],
                             [-35,  -7,  40]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 7), MfArray<Float>([[-0.00586522, -0.00820323, -0.00198698, -0.00633075],
                                [ 0.00937469, -0.00758197,  0.00732988, -0.00020324],
                                [ 0.00565919, -0.00350739, -0.00734483,  0.00663407]] as [[Float]]).round(decimals: 7))
        }
        
        do{
            let a = MfArray<Double>([[7, 2],
                             [3, 4],
                             [5, 3]] as [[Double]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 7),
                           MfArray<Double>([[ 0.16666667, -0.10606061,  0.03030303],
                            [-0.16666667,  0.28787879,  0.06060606]]).round(decimals: 7))
        }
        
        do{
            let a = MfArray<Int>([[ -6,   4,  -1,   8,   2],
                             [ -1,   6, -10,  -1,   6],
                             [  3,  -4,   5,  -7,   5]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret, MfArray<Float>([[-0.06456498,  0.00644501, -0.01798566],
                                         [ 0.01267183,  0.02793085, -0.01456178],
                                         [ 0.0539209 , -0.0576122 ,  0.05869991],
                                         [ 0.05795672, -0.02618938, -0.0251714 ],
                                         [ 0.07609496,  0.03942475,  0.10520211]] as [[Float]]))
        }
    }
}
