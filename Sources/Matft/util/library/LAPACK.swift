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
        
        try _withNNStackedColumnMajorPtr(mfarray: mfarray, type: T.self){
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
        try _withNNStackedColumnMajorPtr(mfarray: mfarray, type: T.self){
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


/**
    - Important: This function for last shape is NxN
 */
fileprivate func _withNNStackedColumnMajorPtr<T: MfStorable>(mfarray: MfArray, type: T.Type, _ body: (UnsafeMutablePointer<T>, Int, Int) throws -> Void) rethrows -> Void{
    let shape = mfarray.shape
    let squaredSize = shape[mfarray.ndim - 1]
    let matricesNum = mfarray.size / (squaredSize * squaredSize)
    
    // get stacked row major and copy
    let rowmajorMfarray = to_row_major(mfarray)
    var offset = 0
    try rowmajorMfarray.withDataUnsafeMBPtrT(datatype: T.self){
        for _ in 0..<matricesNum{
            try body($0.baseAddress! + offset, squaredSize, offset)
            
            offset += squaredSize * squaredSize
        }
    }
}
