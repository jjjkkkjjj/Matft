//
//  LAPACK.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal typealias lapack_solve<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

//ref: http://www.netlib.org/lapack/explore-html/d7/d3b/group__double_g_esolve_ga5ee879032a8365897c3ba91e3dc8d512.html
fileprivate func _run_lapack<T: MfStorable>(copiedCoefPtr: UnsafeMutablePointer<T>, _ eqNum: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstColNum: Int, _ lapack_func: lapack_solve<T>) throws {
    // row number of coefficients matrix
    var N = __CLPK_integer(eqNum)
    var LDA = __CLPK_integer(eqNum)// leading dimension >= max(1, N)
    
    // column number of b
    var NRHS = __CLPK_integer(dstColNum)
    var LDB = __CLPK_integer(eqNum)// leading dimension >= max(1, N)
    
    //pivot indices
    var IPIV = Array<__CLPK_integer>(repeating: 0, count: eqNum)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run
    let _ = lapack_func(&N, &NRHS, copiedCoefPtr, &LDA, &IPIV, dstptr, &LDB, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }
}
internal func solve_by_lapack<T: MfStorable>(_ coef: MfArray, _ b: MfArray, _ eqNum: Int, _ dstColNum: Int, _ lapack_func: lapack_solve<T>) throws -> MfArray{
    assert(coef.storedType == b.storedType, "must be same storedType")
    
    //get column flatten
    let coef_column_major = to_column_major(coef) // copied and contiguous
    let b_column_major = to_column_major(b) // copied and contiguous
    
    let ret = b_column_major.deepcopy() //even if original one is float, create copy for lapack calculation
    
    try coef_column_major.withDataUnsafeMBPtrT(datatype: T.self){
        coefptr in
        try ret.withDataUnsafeMBPtrT(datatype: T.self){
            try _run_lapack(copiedCoefPtr: coefptr.baseAddress!, eqNum, $0.baseAddress!, dstColNum, lapack_func)
        }
    }
    
    return ret
}


internal typealias lapack_LU<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

//ref: http://www.netlib.org/lapack/explore-html/d8/ddc/group__real_g_ecomputational_ga8d99c11b94db3d5eac75cac46a0f2e17.html
internal func LU_by_lapack<T: MfStorable>(_ rowNum: Int, _ colNum: Int, srcdstptr: UnsafeMutablePointer<T>, lapack_func: lapack_LU<T>) throws -> [__CLPK_integer] {
    var M = __CLPK_integer(rowNum)
    var N = __CLPK_integer(colNum)
    var LDA = __CLPK_integer(rowNum)
    
    //pivot indices
    var IPIV = Array<__CLPK_integer>(repeating: 0, count: min(rowNum, colNum))
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run
    let _ = lapack_func(&M, &N, srcdstptr, &LDA, &IPIV, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }
    
    return IPIV
}

internal typealias lapack_inv<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

//ref: http://www.netlib.org/lapack/explore-html/d8/ddc/group__real_g_ecomputational_ga1af62182327d0be67b1717db399d7d83.html
//Note that
//The pivot indices from SGETRF; for 1<=i<=N, row i of the
//matrix was interchanged with row IPIV(i)
internal func inv_by_lapack<T: MfStorable>(_ squaredSize: Int, srcdstptr: UnsafeMutablePointer<T>, _ IPIV: UnsafeMutablePointer<__CLPK_integer>, lapack_func: lapack_inv<T>) throws {
    var N = __CLPK_integer(squaredSize)
    var LDA = __CLPK_integer(squaredSize)
    
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //work space
    var WORK = Array<T>(repeating: T.zero, count: squaredSize)
    var LWORK = __CLPK_integer(squaredSize)
    
    //run
    let _ = lapack_func(&N, srcdstptr, &LDA, IPIV, &WORK, &LWORK, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }
}
/*
sgeev_(<#T##__jobvl: UnsafeMutablePointer<Int8>!##UnsafeMutablePointer<Int8>!#>, <#T##__jobvr: UnsafeMutablePointer<Int8>!##UnsafeMutablePointer<Int8>!#>, <#T##__n: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__a: UnsafeMutablePointer<__CLPK_real>!##UnsafeMutablePointer<__CLPK_real>!#>, <#T##__lda: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__wr: UnsafeMutablePointer<__CLPK_real>!##UnsafeMutablePointer<__CLPK_real>!#>, <#T##__wi: UnsafeMutablePointer<__CLPK_real>!##UnsafeMutablePointer<__CLPK_real>!#>, <#T##__vl: UnsafeMutablePointer<__CLPK_real>!##UnsafeMutablePointer<__CLPK_real>!#>, <#T##__ldvl: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__vr: UnsafeMutablePointer<__CLPK_real>!##UnsafeMutablePointer<__CLPK_real>!#>, <#T##__ldvr: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__work: UnsafeMutablePointer<__CLPK_real>!##UnsafeMutablePointer<__CLPK_real>!#>, <#T##__lwork: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__info: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>)

internal typealias lapack_eigen<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>)
//ref: http://www.netlib.org/lapack/explore-html/d3/dfb/group__real_g_eeigen_ga104525b749278774f7b7f57195aa6798.html
//ref: https://stackoverflow.com/questions/27887215/trouble-with-the-accelerate-framework-in-swift
internal func eigen_by_lapack<T: MfStorable>(_ squaredSize: Int, copiedSrcPtr: UnsafeMutablePointer<T>, _ dstLVecPtr: UnsafeMutablePointer<T>, _ dstRVecPtr: UnsafeMutablePointer<T>, _ dstValPtr: UnsafeMutablePointer<T>, lapack_func: lapack_eigen<T>) throws {
    var JOBVL = ("V" as NSString).UTF8String
    var JOBVR = ("V" as NSString).UTF8String
    
    var N = __CLPK_integer(squaredSize)

    var LDA = __CLPK_integer(squaredSize)

    // Real parts of eigenvalues
    var WR = Array<T>(repeating: T.zero, count: squaredSize)
    // Imaginary parts of eigenvalues
    var WI = Array<T>(repeating: T.zero, count: squaredSize)
    // Left eigenvectors
    var VL = Array<T>(repeating: T.zero, count: squaredSize*squaredSize)
    var LDVL = __CLPK_integer(squaredSize)
    // Right eigenvectors
    var VR = Array<T>(repeating: T.zero, count: squaredSize*squaredSize)
    var LDVR = __CLPK_integer(squaredSize)

    //work space
    var WORKQ = T.zero //workspace query
    var LWORK = __CLPK_integer(-1)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run (calculate workspace query)
    let _ = lapack_func(&JOBVL, &JOBVR, &N, copiedSrcPtr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORKQ, &LWORK, &INFO)
    
    var WORK = Array<T>(repeating: T.zero, count: Int(WORKQ))
    LWORK = __CLPK_integer(WORKQ)
    //run
    let _ = lapack_func(&JOBVL, &JOBVR, &N, copiedSrcPtr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORK, &LWORK, &INFO)
    
    
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.notConverge("the QR algorithm failed to compute all the eigenvalues, and no eigenvectors have been computed; elements \(INFO)+1:N of WR and WI contain eigenvalues which have converged.")
}
*/
