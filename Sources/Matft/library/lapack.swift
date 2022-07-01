//
//  LAPACK.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

public typealias lapack_solve_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_LU_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_inv_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_eigen_func<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_svd_func<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>,UnsafeMutablePointer<__CLPK_integer>) -> Int32

/// Wrapper of lapck solve function
/// - Parameters:
///   - rownum: A destination row number
///   - colnum: A dstination column number
///   - coef_ptr: A coef pointer
///   - dst_b_ptr: A destination and b pointer
///   - lapack_func: The lapack solve function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
/// ref: http://www.netlib.org/lapack/explore-html/d7/d3b/group__double_g_esolve_ga5ee879032a8365897c3ba91e3dc8d512.html
@inline(__always)
internal func wrap_lapack_solve<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ coef_ptr: UnsafeMutablePointer<T>, _ dst_b_ptr: UnsafeMutablePointer<T>, lapack_func: lapack_solve_func<T>) throws {
    // row number of coefficients matrix
    var N = __CLPK_integer(rownum)
    var LDA = __CLPK_integer(rownum)// leading dimension >= max(1, N)
    
    // column number of b
    var NRHS = __CLPK_integer(colnum)
    var LDB = __CLPK_integer(rownum)// leading dimension >= max(1, N)
    
    //pivot indices
    var IPIV = Array<__CLPK_integer>(repeating: 0, count: rownum)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run
    let _ = lapack_func(&N, &NRHS, coef_ptr, &LDA, &IPIV, dst_b_ptr, &LDB, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }
    
}

/// Wrapper of lapck LU fractorization function
/// ref: http://www.netlib.org/lapack/explore-html/d8/ddc/group__real_g_ecomputational_ga8d99c11b94db3d5eac75cac46a0f2e17.html
///
/// - Parameters:
///   - rownum: A destination row number
///   - colnum: A dstination column number
///   - srcdstptr: A source and destination pointer
///   - lapack_func: The lapack LU fractorization function
/// - Throws: An error of type `MfError.LinAlgError.singularMatrix`
@inline(__always)
internal func wrap_lapack_LU<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, lapack_func: lapack_LU_func<T>) throws -> [__CLPK_integer] {
    var M = __CLPK_integer(rownum)
    var N = __CLPK_integer(colnum)
    var LDA = __CLPK_integer(rownum)
    
    //pivot indices
    var IPIV = Array<__CLPK_integer>(repeating: 0, count: min(rownum, colnum))
    
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

/// Wrapper of lapck inverse function
/// ref: http://www.netlib.org/lapack/explore-html/d8/ddc/group__real_g_ecomputational_ga1af62182327d0be67b1717db399d7d83.html
/// Note that
/// The pivot indices from SGETRF; for 1<=i<=N, row i of the
/// matrix was interchanged with row IPIV(i)
///
/// - Parameters:
///   - rowcolnum: A destination row and column number
///   - srcdstptr: A source and destination pointer
///   - lapack_func: The lapack LU fractorization function
/// - Throws: An error of type `MfError.LinAlgError.singularMatrix`
@inline(__always)
internal func wrap_lapack_inv<T: MfStorable>(_ rowcolnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, _ IPIV: UnsafeMutablePointer<__CLPK_integer>, lapack_func: lapack_inv_func<T>) throws{
    var N = __CLPK_integer(rowcolnum)
    var LDA = __CLPK_integer(rowcolnum)
    
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //work space
    var WORK = Array<T>(repeating: T.zero, count: rowcolnum)
    var LWORK = __CLPK_integer(rowcolnum)
    
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

/// Wrapper of lapck eigen function
/// ref: http://www.netlib.org/lapack/explore-html/d3/dfb/group__real_g_eeigen_ga104525b749278774f7b7f57195aa6798.html
/// ref: https://stackoverflow.com/questions/27887215/trouble-with-the-accelerate-framework-in-swift
/// - Parameters:
///   - rowcolnum: A destination row and column number
///   - srcdstptr: A source and destination pointer
///   - lapack_func: The lapack LU fractorization function
/// - Throws: An error of type `MfError.LinAlgError.singularMatrix`
@inline(__always)
internal func wrap_lapack_eigen<T: MfStorable>(_ rowcolnum: Int, _ srcptr: UnsafeMutablePointer<T>, _ dstLVecRePtr: UnsafeMutablePointer<T>, _ dstLVecImPtr: UnsafeMutablePointer<T>, _ dstRVecRePtr: UnsafeMutablePointer<T>, _ dstRVecImPtr: UnsafeMutablePointer<T>, _ dstValRePtr: UnsafeMutablePointer<T>, _ dstValImPtr: UnsafeMutablePointer<T>, lapack_func: lapack_eigen_func<T>) throws {
    let JOBVL = UnsafeMutablePointer(mutating: ("V" as NSString).utf8String)!
    let JOBVR = UnsafeMutablePointer(mutating: ("V" as NSString).utf8String)!
    
    var N = __CLPK_integer(rowcolnum)

    var LDA = __CLPK_integer(rowcolnum)

    // Real parts of eigenvalues
    var WR = Array<T>(repeating: T.zero, count: rowcolnum)
    // Imaginary parts of eigenvalues
    var WI = Array<T>(repeating: T.zero, count: rowcolnum)
    // Left eigenvectors
    var VL = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
    var LDVL = __CLPK_integer(rowcolnum)
    // Right eigenvectors
    var VR = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
    var LDVR = __CLPK_integer(rowcolnum)

    //work space
    var WORKQ = T.zero //workspace query
    var LWORK = __CLPK_integer(-1)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run (calculate optimal workspace)
    let _ = lapack_func(JOBVL, JOBVR, &N, srcptr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORKQ, &LWORK, &INFO)

    var WORK = Array<T>(repeating: T.zero, count: T.toInt(WORKQ))
    LWORK = __CLPK_integer(T.toInt(WORKQ))
    //run
    let _ = lapack_func(JOBVL, JOBVR, &N, srcptr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORK, &LWORK, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.notConverge("the QR algorithm failed to compute all the eigenvalues, and no eigenvectors have been computed; elements \(INFO)+1:N of WR and WI contain eigenvalues which have converged.")
    }
    else{
        /*
         e.g.) ref: https://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/sgeev_ex.f.htm
         Auxiliary routine: printing eigenvalues.
         *
               SUBROUTINE PRINT_EIGENVALUES( DESC, N, WR, WI )
               CHARACTER*(*)    DESC
               INTEGER          N
               REAL             WR( * ), WI( * )
         *
               REAL             ZERO
               PARAMETER        ( ZERO = 0.0 )
               INTEGER          J
         *
               WRITE(*,*)
               WRITE(*,*) DESC
               DO J = 1, N
                  IF( WI( J ).EQ.ZERO ) THEN
                     WRITE(*,9998,ADVANCE='NO') WR( J )
                  ELSE
                     WRITE(*,9999,ADVANCE='NO') WR( J ), WI( J )
                  END IF
               END DO
               WRITE(*,*)
         *
          9998 FORMAT( 11(:,1X,F6.2) )
          9999 FORMAT( 11(:,1X,'(',F6.2,',',F6.2,')') )
               RETURN
               END
         *
         *     Auxiliary routine: printing eigenvectors.
         *
               SUBROUTINE PRINT_EIGENVECTORS( DESC, N, WI, V, LDV )
               CHARACTER*(*)    DESC
               INTEGER          N, LDV
               REAL             WI( * ), V( LDV, * )
         *
               REAL             ZERO
               PARAMETER        ( ZERO = 0.0 )
               INTEGER          I, J
         *
               WRITE(*,*)
               WRITE(*,*) DESC
               DO I = 1, N
                  J = 1
                  DO WHILE( J.LE.N )
                     IF( WI( J ).EQ.ZERO ) THEN
                        WRITE(*,9998,ADVANCE='NO') V( I, J )      <<<<<<<<<<<<<<<<<<<<<<<
                        J = J + 1
                     ELSE
                        WRITE(*,9999,ADVANCE='NO') V( I, J ), V( I, J+1 ) <<<<<<<<<<<<<<<<<<
                        WRITE(*,9999,ADVANCE='NO') V( I, J ), -V( I, J+1 ) <<<<<<<<<<<<<<<<<<<<<
                        J = J + 2
                     END IF
                  END DO
                  WRITE(*,*)
               END DO
         *
          9998 FORMAT( 11(:,1X,F6.2) )
          9999 FORMAT( 11(:,1X,'(',F6.2,',',F6.2,')') )
               RETURN
               END
         */
        
        /*
         Note that VL and VR's value are inferenced by WI's value.
         Below's i means imaginary number
         if WI[k] == 0; VL[k, j], VR[k, j]
                        j += 1
         if WI[k] != 0; VL[k, j] + i*VL[k, j+1],
                        VL[k, j] - i*VL[k, j+1],
                      ; VR[k, j] + i*VR[k, j+1],
                        VR[k, j] - i*VR[k, j+1],
                        j += 2
         */
        var VLRe = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VLIm = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VRRe = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VRIm = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        for k in 0..<rowcolnum{
            var j = 0
        
            while j < rowcolnum{
                let index = k*rowcolnum + j
                if WI[k] == 0{
                    VLRe[index] = VL[index]
                    VLIm[index] = T.zero
                    VRRe[index] = VR[index]
                    VRIm[index] = T.zero
                    j += 1
                }
                else{
                    VLRe[index] = VL[index]
                    VLIm[index] = VL[index + 1]
                    VLRe[index + 1] = VL[index]
                    VLIm[index + 1] = -VL[index + 1]
                    
                    VRRe[index] = VR[index]
                    VRIm[index] = VR[index + 1]
                    VRRe[index + 1] = VR[index]
                    VRIm[index + 1] = -VR[index + 1]
                    j += 2
                }
            }
            
        }
        //moveAssign
        WR.withUnsafeMutableBufferPointer{
            dstValRePtr.moveAssign(from: $0.baseAddress!, count: rowcolnum)
        }
        WI.withUnsafeMutableBufferPointer{
            dstValImPtr.moveAssign(from: $0.baseAddress!, count: rowcolnum)
        }
        VLRe.withUnsafeMutableBufferPointer{
            dstLVecRePtr.moveAssign(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VLIm.withUnsafeMutableBufferPointer{
            dstLVecImPtr.moveAssign(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VRRe.withUnsafeMutableBufferPointer{
            dstRVecRePtr.moveAssign(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VRIm.withUnsafeMutableBufferPointer{
            dstRVecImPtr.moveAssign(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
    }
}

/// Wrapper of lapack SVD function
/// ref: https://www.netlib.org/lapack/explore-html/d4/dca/group__real_g_esing_gac2cd4f1079370ac908186d77efcd5ea8.html
///
/// - Parameters:
///   - rownum: A destination row number
///   - colnum: A destination column number
///   - srcptr: A source pointer
///   - vptr: A source pointer
///   - sptr: A source pointer
///   - rtptr: A source pointer
///   - full_matrices: if true returned v and rt have the shapes (..., M, M) and (..., N, N) respectively. Otherwise, the shapes are (..., M, K) and (..., K, N), respectively, where K = min(M, N).
///   - lapack_func: The lapack SVD fractorization function
/// - Throws: An error of type `MfError.LinAlgError.singularMatrix`
@inline(__always)
internal func wrap_lapack_svd<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ srcptr: UnsafeMutablePointer<T>, _ vptr: UnsafeMutablePointer<T>, _ sptr: UnsafeMutablePointer<T>, _ rtptr: UnsafeMutablePointer<T>, _ full_matrices: Bool, lapack_func: lapack_svd_func<T>) throws{
    let JOBZ: UnsafeMutablePointer<Int8>
    
    var M = __CLPK_integer(rownum)
    var N = __CLPK_integer(colnum)
    
    let ucol: Int, vtrow: Int
    
    var LDA = __CLPK_integer(rownum)
    
    let snum = min(rownum, colnum)
    var S = Array<T>(repeating: T.zero, count: snum)
    
    var U: Array<T>
    var LDU = __CLPK_integer(rownum)
    
    var VT: Array<T>
    var LDVT: __CLPK_integer
    
    
    if full_matrices{
        JOBZ = UnsafeMutablePointer(mutating: ("A" as NSString).utf8String)!
        LDVT = __CLPK_integer(colnum)
        
        ucol = rownum
        vtrow = colnum
    }
    else{
        JOBZ = UnsafeMutablePointer(mutating: ("S" as NSString).utf8String)!
        LDVT = __CLPK_integer(snum)
        
        ucol = snum
        vtrow = snum
    }
    U = Array<T>(repeating: T.zero, count: rownum*ucol)
    VT = Array<T>(repeating: T.zero, count: colnum*vtrow)
    
    //work space
    var WORKQ = T.zero //workspace query
    var LWORK = __CLPK_integer(-1)
    var IWORK = Array<__CLPK_integer>(repeating: 0, count: 8*snum)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run (calculate optimal workspace)
    let _ = lapack_func(JOBZ, &M, &N, srcptr, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORKQ, &LWORK, &IWORK, &INFO)
    
    var WORK = Array<T>(repeating: T.zero, count: T.toInt(WORKQ))
    LWORK = __CLPK_integer(T.toInt(WORKQ))
    //run
    let _ = lapack_func(JOBZ, &M, &N, srcptr, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.notConverge("the QR algorithm failed to compute all the eigenvalues, and no eigenvectors have been computed; elements \(INFO)+1:N of WR and WI contain eigenvalues which have converged.")
    }
    else{
        U.withUnsafeMutableBufferPointer{
            vptr.moveAssign(from: $0.baseAddress!, count: rownum*ucol)
        }
        S.withUnsafeMutableBufferPointer{
            sptr.moveAssign(from: $0.baseAddress!, count: snum)
        }
        VT.withUnsafeMutableBufferPointer{
            rtptr.moveAssign(from: $0.baseAddress!, count: colnum*vtrow)
        }
    }
}

/// Solve by lapack
/// - Parameters:
///   - coef: coef MfArray
///   - b: b MfArray
///   - lapack_func: The lapack solve function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func solve_by_lapack<T: MfStorable>(_ coef: MfArray, _ b: MfArray, ret_mftype: MfType, _ lapack_func: lapack_solve_func<T>) throws -> MfArray{
    precondition((coef.ndim == 2), "cannot solve non linear simultaneous equations")
    precondition(b.ndim <= 2, "Invalid b. Dimension must be 1 or 2")
    
    let coef_shape = coef.shape
    let b_shape = b.shape
    var dst_colnum = 0
    let dst_rownum = coef_shape[0]
    
    // check argument
    if b.ndim == 1{
        //(m,m)(m)=(m)
        precondition((coef_shape[0] == coef_shape[1] && b_shape[0] == coef_shape[0]), "cannot solve (\(coef_shape[0]),\(coef_shape[1]))(\(b_shape[0]))=(\(b_shape[0])) problem")
        dst_colnum = 1
    }
    else{//ndim == 2
        //(m,m)(m,n)=(m,n)
        precondition((coef_shape[0] == coef_shape[1] && b_shape[0] == coef_shape[0]), "cannot solve (\(coef_shape[0]),\(coef_shape[1]))(\(b_shape[0]),\(b_shape[1]))=(\(b_shape[0]),\(b_shape[1])) problem")
        dst_colnum = b_shape[1]
    }
    
    //get column flatten
    let coef_column_major = coef.astype(ret_mftype, mforder: .Column) // copied and contiguous
    let ret = b.astype(ret_mftype, mforder: .Column) // copied and contiguous
    
    try coef_column_major.withUnsafeMutableStartPointer(datatype: T.self){
        coef_ptr in
        try ret.withUnsafeMutableStartPointer(datatype: T.self){
            dst_ptr in
            try wrap_lapack_solve(dst_rownum, dst_colnum, coef_ptr, dst_ptr, lapack_func: lapack_func)
        }
    }
    
    return ret
}


internal typealias lapack_LU<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

//ref: http://www.netlib.org/lapack/explore-html/d8/ddc/group__real_g_ecomputational_ga8d99c11b94db3d5eac75cac46a0f2e17.html
fileprivate func _run_lu<T: MfStorable>(_ rowNum: Int, _ colNum: Int, srcdstptr: UnsafeMutablePointer<T>, lapack_func: lapack_LU<T>) throws -> [__CLPK_integer] {
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
fileprivate func _run_inv<T: MfStorable>(_ squaredSize: Int, srcdstptr: UnsafeMutablePointer<T>, _ IPIV: UnsafeMutablePointer<__CLPK_integer>, lapack_func: lapack_inv<T>) throws {
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

/// Inverse by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - lapack_func_lu: The lapack LU factorization function
///   - lapack_func_inv: The lapack inverse function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func inv_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func_lu: lapack_LU<T>, _ lapack_func_inv: lapack_inv<T>, _ retMfType: MfType) throws -> MfArray{
    
    let shape = mfarray.shape
        
    precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")

    let newdata = MfData(size: mfarray.size, mftype: mfarray.storedType.to_mftype())
    let dstptr = newdata.data.bindMemory(to: T.self, capacity: mfarray.size)
    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Row){
        srcptr, row, col, offset in
        //LU decomposition
        var IPIV = try wrap_lapack_LU(row, col, srcptr, lapack_func: lapack_func_lu)
        
        //calculate inv
        // note that row == col
        try wrap_lapack_inv(row, srcptr, &IPIV, lapack_func: lapack_func_inv)
        
        //move
        (dstptr + offset).moveAssign(from: srcptr, count: row*col)
    }
    
    let newstructure = MfStructure(shape: shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Determinant by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - lapack_func: The lapack LU factorization function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func det_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func: lapack_LU_func<T>) throws -> MfArray{
    let shape = mfarray.shape
    
    precondition(mfarray.ndim > 1, "cannot get a determinant from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
    
    let ret_size = mfarray.size / (shape[mfarray.ndim - 1] * shape[mfarray.ndim - 1])
    
    let newdata = MfData(size: ret_size, mftype: mfarray.mftype)
    let dstptr = newdata.data.bindMemory(to: T.self, capacity: ret_size)
    var dst_offset = 0

    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Row){
        srcptr, row, col, offset in
        // Note row == col
        let square_num = row
        
        //LU decomposition
        let IPIV = try wrap_lapack_LU(row, col, srcptr, lapack_func: lapack_func)
        
        //calculate L and U's determinant
        //Note that L and U's determinant are calculated by product of diagonal elements
        // L's determinant is always one
        //ref: https://stackoverflow.com/questions/47315471/compute-determinant-from-lu-decomposition-in-lapack
        var det = T.from(1)
        for i in 0..<square_num{
            det *= IPIV[i] != __CLPK_integer(i+1) ? srcptr.advanced(by: i + i*square_num).pointee : -(srcptr.advanced(by: i + i*square_num).pointee)
        }
        
        //assign
        (dstptr + dst_offset).assign(from: &det, count: 1)
        dst_offset += 1
    }
    
    let ret_shape: [Int]
    if mfarray.ndim - 2 != 0{
        ret_shape = Array(mfarray.shape.prefix(mfarray.ndim - 2))
    }
    else{
       ret_shape = [1]
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Eigen by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - lapack_func: The lapack LU factorization function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func eigen_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func: lapack_eigen_func<T>) throws -> (valRe: MfArray, valIm: MfArray, lvecRe: MfArray, lvecIm: MfArray, rvecRe: MfArray, rvecIm: MfArray){
    var shape = mfarray.shape
    precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
    let retMfType = mfarray.storedType.to_mftype()
    //let square_num = shape[mfarray.ndim - 1]
    let eigenvec_size = shape2size(&shape)
    //let eigValNum = mfarray.size / (squaredSize * squaredSize)
    
    // create mfarraies
    //eigenvectors
    let lvecRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let lvecIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    let rvecRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let rvecIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    
    //eigenvalues
    let eigenval_shape = Array(shape.prefix(mfarray.ndim - 1))
    //let eigenval_size = shape2size(&eigenval_shape)
    let valRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let valIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    //offset for calculation
    var vec_offset = 0
    var val_offset = 0
    
    
    let lvecRe_ptr = lvecRe_data.data.bindMemory(to: T.self, capacity: eigenvec_size)
    let lvecIm_ptr = lvecIm_data.data.bindMemory(to: T.self, capacity: eigenvec_size)
    let rvecRe_ptr = rvecRe_data.data.bindMemory(to: T.self, capacity: eigenvec_size)
    let rvecIm_ptr = rvecIm_data.data.bindMemory(to: T.self, capacity: eigenvec_size)
    let valRe_ptr = valRe_data.data.bindMemory(to: T.self, capacity: eigenvec_size)
    let valIm_ptr = valIm_data.data.bindMemory(to: T.self, capacity: eigenvec_size)
    
    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Column){
        srcptr, row, col, offset in
        // Note row == col
        let square_num = row
        try wrap_lapack_eigen(square_num, srcptr, lvecRe_ptr + vec_offset, lvecIm_ptr + vec_offset, rvecRe_ptr + vec_offset, rvecIm_ptr + vec_offset, valRe_ptr + val_offset, valIm_ptr + val_offset, lapack_func: lapack_func)
        
        //calculate offset
        val_offset += square_num
        vec_offset += offset
    }
    
    
    return (MfArray(mfdata: valRe_data, mfstructure: MfStructure(shape: eigenval_shape, mforder: .Row)),
            MfArray(mfdata: valIm_data, mfstructure: MfStructure(shape: eigenval_shape, mforder: .Row)),
            MfArray(mfdata: lvecRe_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: lvecIm_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: rvecRe_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: rvecIm_data, mfstructure: MfStructure(shape: shape, mforder: .Row)))
    
}


/// SVD by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - full_matrices: if true returned v and rt have the shapes (..., M, M) and (..., N, N) respectively. Otherwise, the shapes are (..., M, K) and (..., K, N), respectively, where K = min(M, N).
///   - lapack_func: The lapack SVD factorization function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func svd_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ full_matrices: Bool, _ lapack_func: lapack_svd_func<T>) throws -> (v: MfArray, s: MfArray, rt: MfArray){
    let shape = mfarray.shape
    let ret_mftype = mfarray.storedType.to_mftype()
    let M = shape[mfarray.ndim - 2]
    let N = shape[mfarray.ndim - 1]
    let ssize = min(M, N)
    let stacked_shape = Array(shape.prefix(mfarray.ndim - 2))
    
    let v_data: MfData, s_data: MfData, rt_data: MfData
    var v_shape: [Int], s_shape: [Int], rt_shape: [Int]
    let vcol: Int, rtrow: Int
    if full_matrices{
        v_shape = stacked_shape + [M, M]
        s_shape = stacked_shape + [ssize]
        rt_shape = stacked_shape + [N, N]
        v_data = MfData(size: shape2size(&v_shape), mftype: ret_mftype)
        s_data = MfData(size: shape2size(&s_shape), mftype: ret_mftype)
        rt_data = MfData(size: shape2size(&rt_shape), mftype: ret_mftype)
        
        vcol = M
        rtrow = N
    }
    else{
        v_shape = stacked_shape + [ssize, M]
        s_shape = stacked_shape + [ssize]
        rt_shape = stacked_shape + [N, ssize]
        v_data = MfData(size: shape2size(&v_shape), mftype: ret_mftype) // returned shape = (..., M, ssize)
        s_data = MfData(size: shape2size(&s_shape), mftype: ret_mftype)
        rt_data = MfData(size: shape2size(&rt_shape), mftype: ret_mftype) // returned shape = (..., ssize, N)
        
        vcol = ssize
        rtrow = ssize
    }
    
    //offset
    var v_offset = 0
    var s_offset = 0
    var rt_offset = 0
    
    let vptr = v_data.data.bindMemory(to: T.self, capacity: shape2size(&v_shape))
    let sptr = s_data.data.bindMemory(to: T.self, capacity: shape2size(&s_shape))
    let rtptr = rt_data.data.bindMemory(to: T.self, capacity: shape2size(&rt_shape))
    
    
    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Column){
        srcptr, _, _, _ in
        try wrap_lapack_svd(M, N, srcptr, vptr + v_offset, sptr + s_offset, rtptr + rt_offset, full_matrices, lapack_func: lapack_func)
        
        v_offset += M*vcol
        s_offset += ssize
        rt_offset += N*rtrow
    }
    
    let v = MfArray(mfdata: v_data, mfstructure: MfStructure(shape: v_shape, mforder: .Row))
    let s = MfArray(mfdata: s_data, mfstructure: MfStructure(shape: s_shape, mforder: .Row))
    let rt = MfArray(mfdata: rt_data, mfstructure: MfStructure(shape: rt_shape, mforder: .Row))
    
    return (v.swapaxes(axis1: -1, axis2: -2), s, rt.swapaxes(axis1: -1, axis2: -2))
}
