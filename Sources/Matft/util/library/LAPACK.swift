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

internal func inv_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lu_lapack_func: lapack_LU<T>, _ inv_lapack_func: lapack_inv<T>, _ retMfType: MfType) throws -> MfArray{
    
    let newmfdata = try withDummyDataMRPtr(retMfType, storedSize: mfarray.size){
        dstptr in
        let dstptrF = dstptr.bindMemory(to: T.self, capacity: mfarray.size)
        
        try _withNNStackedMajorPtr(mfarray: mfarray, type: T.self, mforder: .Row){
            srcptr, squaredSize, offset in
            //LU decomposition
            var IPIV = try _run_lu(squaredSize, squaredSize, srcdstptr: srcptr, lapack_func: lu_lapack_func)
            
            //calculate inv
            try _run_inv(squaredSize, srcdstptr: srcptr, &IPIV, lapack_func: inv_lapack_func)
            
            //move
            (dstptrF + offset).moveAssign(from: srcptr, count: squaredSize*squaredSize)
        }
    }
    
    let newmfstructure = withDummyShapeStridesMBPtr(mfarray.ndim){
        [unowned mfarray] (shapeptr, stridesptr) in
        
        //shape
        mfarray.withShapeUnsafeMBPtr{
            [unowned mfarray] in
            shapeptr.baseAddress!.assign(from: $0.baseAddress!, count: mfarray.ndim)
        }
        
        //strides
        let newstridesptr = shape2strides(shapeptr, mforder: .Row)
        stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: mfarray.ndim)
        
        newstridesptr.deallocate()
    }
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}


internal func det_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lu_lapack_func: lapack_LU<T>, _ retMfType: MfType, _ retSize: Int) throws -> MfArray{
    let newmfdata = try withDummyDataMRPtr(retMfType, storedSize: retSize){
        dstptr in
        let dstptrF = dstptr.bindMemory(to: T.self, capacity: retSize)
        
        var dstoffset = 0
        try _withNNStackedMajorPtr(mfarray: mfarray, type: T.self, mforder: .Row){
            srcptr, squaredSize, offset in
            //LU decomposition
            let IPIV = try _run_lu(squaredSize, squaredSize, srcdstptr: srcptr, lapack_func: lu_lapack_func)
            
            //calculate L and U's determinant
            //Note that L and U's determinant are calculated by product of diagonal elements
            // L's determinant is always one
            //ref: https://stackoverflow.com/questions/47315471/compute-determinant-from-lu-decomposition-in-lapack
            var det = T.num(1)
            for i in 0..<squaredSize{
                det *= IPIV[i] != __CLPK_integer(i+1) ? srcptr.advanced(by: i + i*squaredSize).pointee : -(srcptr.advanced(by: i + i*squaredSize).pointee)
            }
            
            //assign
            (dstptrF + dstoffset).assign(from: &det, count: 1)
            dstoffset += 1
        }
    }
    let retndim = mfarray.ndim - 2 != 0 ? mfarray.ndim - 2 : 1
    let newmfstructure = withDummyShapeStridesMBPtr(retndim){
        [unowned mfarray] (shapeptr, stridesptr) in
        
        //shape
        if mfarray.ndim - 2 != 0{
            mfarray.withShapeUnsafeMBPtr{
                shapeptr.baseAddress!.assign(from: $0.baseAddress!, count: retndim)
            }
            
            //strides
            let newstridesptr = shape2strides(shapeptr, mforder: .Row)
            stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: retndim)
            
            newstridesptr.deallocate()
        }
        else{
            shapeptr[0] = 1
            stridesptr[0] = 1
        }
        
    }
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

internal typealias lapack_eigen<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32
//ref: http://www.netlib.org/lapack/explore-html/d3/dfb/group__real_g_eeigen_ga104525b749278774f7b7f57195aa6798.html
//ref: https://stackoverflow.com/questions/27887215/trouble-with-the-accelerate-framework-in-swift
fileprivate func _run_eigen<T: MfStorable>(_ squaredSize: Int, copiedSrcPtr: UnsafeMutablePointer<T>, _ dstLVecRePtr: UnsafeMutablePointer<T>, _ dstLVecImPtr: UnsafeMutablePointer<T>, _ dstRVecRePtr: UnsafeMutablePointer<T>, _ dstRVecImPtr: UnsafeMutablePointer<T>, _ dstValRePtr: UnsafeMutablePointer<T>, _ dstValImPtr: UnsafeMutablePointer<T>, lapack_func: lapack_eigen<T>) throws {
    let JOBVL = UnsafeMutablePointer(mutating: ("V" as NSString).utf8String)!
    let JOBVR = UnsafeMutablePointer(mutating: ("V" as NSString).utf8String)!
    
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
    
    //run (calculate optimal workspace)
    let _ = lapack_func(JOBVL, JOBVR, &N, copiedSrcPtr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORKQ, &LWORK, &INFO)
    
    var WORK = Array<T>(repeating: T.zero, count: T.toInt(WORKQ))
    LWORK = __CLPK_integer(T.toInt(WORKQ))
    //run
    let _ = lapack_func(JOBVL, JOBVR, &N, copiedSrcPtr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORK, &LWORK, &INFO)
    
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
        var VLRe = Array<T>(repeating: T.zero, count: squaredSize*squaredSize)
        var VLIm = Array<T>(repeating: T.zero, count: squaredSize*squaredSize)
        var VRRe = Array<T>(repeating: T.zero, count: squaredSize*squaredSize)
        var VRIm = Array<T>(repeating: T.zero, count: squaredSize*squaredSize)
        for k in 0..<squaredSize{
            var j = 0
        
            while j < squaredSize{
                let index = k*squaredSize + j
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
            dstValRePtr.moveAssign(from: $0.baseAddress!, count: squaredSize)
        }
        WI.withUnsafeMutableBufferPointer{
            dstValImPtr.moveAssign(from: $0.baseAddress!, count: squaredSize)
        }
        VLRe.withUnsafeMutableBufferPointer{
            dstLVecRePtr.moveAssign(from: $0.baseAddress!, count: squaredSize*squaredSize)
        }
        VLIm.withUnsafeMutableBufferPointer{
            dstLVecImPtr.moveAssign(from: $0.baseAddress!, count: squaredSize*squaredSize)
        }
        VRRe.withUnsafeMutableBufferPointer{
            dstRVecRePtr.moveAssign(from: $0.baseAddress!, count: squaredSize*squaredSize)
        }
        VRIm.withUnsafeMutableBufferPointer{
            dstRVecImPtr.moveAssign(from: $0.baseAddress!, count: squaredSize*squaredSize)
        }
    }
}

internal func eigen_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ retMfType: MfType, _ lapack_func: lapack_eigen<T>) throws -> (valRe: MfArray, valIm: MfArray, lvecRe: MfArray, lvecIm: MfArray, rvecRe: MfArray, rvecIm: MfArray){
    let shape = mfarray.shape
    let squaredSize = shape[mfarray.ndim - 1]
    //let eigValNum = mfarray.size / (squaredSize * squaredSize)
    
    // create mfarraies
    //eigenvectors
    let lvecRe = Matft.mfarray.nums(T.zero, shape: shape, mftype: retMfType, mforder: .Row)
    let lvecIm = Matft.mfarray.nums(T.zero, shape: shape, mftype: retMfType, mforder: .Row)
    let rvecRe = Matft.mfarray.nums(T.zero, shape: shape, mftype: retMfType, mforder: .Row)
    let rvecIm = Matft.mfarray.nums(T.zero, shape: shape, mftype: retMfType, mforder: .Row)
    
    //eigenvalues
    let valshape = Array(shape.prefix(mfarray.ndim - 1))
    let valRe = Matft.mfarray.nums(T.zero, shape: valshape, mftype: retMfType, mforder: .Row)
    let valIm = Matft.mfarray.nums(T.zero, shape: valshape, mftype: retMfType, mforder: .Row)
    //offset for calculation
    var vec_offset = 0
    var val_offset = 0
    
    try withDataMBPtr_multi(datatype: T.self, lvecRe, lvecIm){
        lvecRePtr, lvecImPtr in
        try withDataMBPtr_multi(datatype: T.self, rvecRe, rvecIm){
            rvecRePtr, rvecImPtr in
            try withDataMBPtr_multi(datatype: T.self, valRe, valIm){
                valRePtr, valImPtr in
                try _withNNStackedMajorPtr(mfarray: mfarray, type: T.self, mforder: .Column){
                srcptr, _, offset in
                    
                    try _run_eigen(squaredSize, copiedSrcPtr: srcptr, lvecRePtr.baseAddress! + vec_offset, lvecImPtr.baseAddress! + vec_offset, rvecRePtr.baseAddress! + vec_offset, rvecImPtr.baseAddress! + vec_offset, valRePtr.baseAddress! + val_offset, valImPtr.baseAddress! + val_offset, lapack_func: lapack_func)
                    
                    //calculate offset
                    val_offset += squaredSize
                    vec_offset += offset
                }
            }
        }
    }
    /*
    try lvec.withDataUnsafeMBPtrT(datatype: T.self){
        lvecptr in
        try rvec.withDataUnsafeMBPtrT(datatype: T.self){
            rvecptr in
            try valRe.withDataUnsafeMBPtrT(datatype: T.self){
                valReptr in
                try valIm.withDataUnsafeMBPtrT(datatype: T.self){
                    valImptr in
                    try _withNNStackedMajorPtr(mfarray: mfarray, type: T.self, mforder: .Column){
                    srcptr, _, offset in
                        
                        try _run_eigen(squaredSize, copiedSrcPtr: srcptr, lvecptr.baseAddress! + vec_offset, rvecptr.baseAddress! + vec_offset, valReptr.baseAddress! + val_offset, valImptr.baseAddress! + val_offset, lapack_func: lapack_func)
                        
                        //calculate offset
                        val_offset += squaredSize
                        vec_offset += offset
                    }
                }
            }
        }*/
    
    
    return (valRe, valIm, lvecRe, lvecIm, rvecRe, rvecIm)
    
}


internal typealias lapack_svd<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>,UnsafeMutablePointer<__CLPK_integer>) -> Int32
// ref: https://www.netlib.org/lapack/explore-html/d4/dca/group__real_g_esing_gac2cd4f1079370ac908186d77efcd5ea8.html
fileprivate func _run_svd<T: MfStorable>(_ rowNum: Int, _ colNum: Int, _ srcptr: UnsafeMutablePointer<T>, _ vptr: UnsafeMutablePointer<T>, _ sptr: UnsafeMutablePointer<T>, _ rtptr: UnsafeMutablePointer<T>, lapack_func: lapack_svd<T>) throws{
    let JOBZ = UnsafeMutablePointer(mutating: ("A" as NSString).utf8String)!
    
    var M = __CLPK_integer(rowNum)
    var N = __CLPK_integer(colNum)
    
    var LDA = __CLPK_integer(rowNum)
    
    let snum = min(rowNum, colNum)
    var S = Array<T>(repeating: T.zero, count: snum)
    
    var U = Array<T>(repeating: T.zero, count: rowNum*rowNum)
    var LDU = __CLPK_integer(rowNum)
    
    var VT = Array<T>(repeating: T.zero, count: colNum*colNum)
    var LDVT = __CLPK_integer(colNum)
    
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
            vptr.moveAssign(from: $0.baseAddress!, count: rowNum*rowNum)
        }
        S.withUnsafeMutableBufferPointer{
            sptr.moveAssign(from: $0.baseAddress!, count: snum)
        }
        VT.withUnsafeMutableBufferPointer{
            rtptr.moveAssign(from: $0.baseAddress!, count: colNum*colNum)
        }
    }
}

internal func svd_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ retMfType: MfType, _ lapack_func: lapack_svd<T>) throws -> (v: MfArray, s: MfArray, rt: MfArray){
    let shape = mfarray.shape
    let M = shape[mfarray.ndim - 2]
    let N = shape[mfarray.ndim - 1]
    let ssize = min(M, N)
    let stackedShape = Array(shape.prefix(mfarray.ndim - 2))
    
    let v = Matft.mfarray.nums(T.zero, shape: stackedShape + [M, M], mftype: retMfType, mforder: .Row)
    let s = Matft.mfarray.nums(T.zero, shape: stackedShape + [ssize], mftype: retMfType, mforder: .Row)
    let rt = Matft.mfarray.nums(T.zero, shape: stackedShape + [N, N], mftype: retMfType, mforder: .Row)
    
    //offset
    var v_offset = 0
    var s_offset = 0
    var rt_offset = 0
    
    try v.withDataUnsafeMBPtrT(datatype: T.self){
        vptr in
        try s.withDataUnsafeMBPtrT(datatype: T.self){
            sptr in
            try rt.withDataUnsafeMBPtrT(datatype: T.self){
                rtptr in
                try _withMNStackedMajorPtr(mfarray: mfarray, type: T.self, mforder: .Column){
                    srcptr, _, _, _ in
                    
                    try _run_svd(M, N, srcptr, vptr.baseAddress! + v_offset, sptr.baseAddress! + s_offset, rtptr.baseAddress! + rt_offset, lapack_func: lapack_func)
                    
                    v_offset += M*M
                    s_offset += ssize
                    rt_offset += N*N
                }
                
            }
        }
    }
    
    return (v.swapaxes(axis1: -1, axis2: -2), s, rt.swapaxes(axis1: -1, axis2: -2))
}

/**
    - Important: This function for last shape is NxN
 */
fileprivate func _withNNStackedMajorPtr<T: MfStorable>(mfarray: MfArray, type: T.Type, mforder: MfOrder, _ body: (UnsafeMutablePointer<T>, Int, Int) throws -> Void) rethrows -> Void{
    let shape = mfarray.shape
    let squaredSize = shape[mfarray.ndim - 1]
    let matricesNum = mfarray.size / (squaredSize * squaredSize)
    
    // get stacked row major and copy
    let rowmajorMfarray = mforder == .Row ? to_row_major(mfarray) : to_column_major(mfarray)
    var offset = 0
    try rowmajorMfarray.withDataUnsafeMBPtrT(datatype: T.self){
        for _ in 0..<matricesNum{
            try body($0.baseAddress! + offset, squaredSize, offset)
            
            offset += squaredSize * squaredSize
        }
    }
}

/**
    - Important: This function for last shape is MxN
 */
fileprivate func _withMNStackedMajorPtr<T: MfStorable>(mfarray: MfArray, type: T.Type, mforder: MfOrder, _ body: (UnsafeMutablePointer<T>, Int, Int, Int) throws -> Void) rethrows -> Void{
    let shape = mfarray.shape
    let M = shape[mfarray.ndim - 2]
    let N = shape[mfarray.ndim - 1]
    let matricesNum = mfarray.size / (M * N)
    
    // get stacked row major and copy
    let rowmajorMfarray = mforder == .Row ? to_row_major(mfarray) : to_column_major(mfarray)
    var offset = 0
    try rowmajorMfarray.withDataUnsafeMBPtrT(datatype: T.self){
        for _ in 0..<matricesNum{
            try body($0.baseAddress! + offset, M, N, offset)
            
            offset += M * N
        }
    }
}
