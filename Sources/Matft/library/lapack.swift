//
//  lapack.swift
//  
//
//  Created by Junnosuke Kado on 2022/03/24.
//

import Foundation
import Accelerate

public typealias lapack_solve_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_LU_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_inv_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

/// Wrapper of lapck solve function
/// - Parameters:
///   - rownum: A destination row number
///   - colnum: A dstination column number
///   - coef_ptr: A coef pointer
///   - dst_b_ptr: A destination and b pointer
///   - lapack_func: The lapack solve function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
@inline(__always)
internal func wrap_lapack_solve<T: MfStoredTypeUsable>(_ rownum: Int, _ colnum: Int, _ coef_ptr: UnsafeMutablePointer<T>, _ dst_b_ptr: UnsafeMutablePointer<T>, lapack_func: lapack_solve_func<T>) throws {
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
internal func wrap_lapack_LU<T: MfStoredTypeUsable>(_ rownum: Int, _ colnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, lapack_func: lapack_LU_func<T>) throws -> [__CLPK_integer] {
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
internal func wrap_lapack_inv<T: MfStoredTypeUsable>(_ rowcolnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, _ IPIV: UnsafeMutablePointer<__CLPK_integer>, lapack_func: lapack_inv_func<T>) throws{
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


/// Solve by lapack
/// - Parameters:
///   - coef: coef MfArray
///   - b: b MfArray
///   - lapack_func: The lapack solve function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func solve_by_lapack<T: MfTypeUsable>(_ coef: MfArray<T>, _ b: MfArray<T>, _ lapack_func: lapack_solve_func<T.StoredType>) throws -> MfArray<T.StoredType>{
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
    let coef_column_major = coef.to_contiguous(mforder: .Column) // copied and contiguous
    let ret = b.astype(newtype: T.StoredType.self, mforder: .Column) // copied and contiguous
    
    try coef_column_major.withUnsafeMutableStartPointer{
        coef_ptr in
        try ret.withUnsafeMutableStartPointer{
            dst_ptr in
            let dst_ptr = dst_ptr as! UnsafeMutablePointer<T.StoredType>
            try wrap_lapack_solve(dst_rownum, dst_colnum, coef_ptr, dst_ptr, lapack_func: lapack_func)
        }
    }
    
    return ret
}

/// Inverse by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - lapack_func_lu: The lapack LU factorization function
///   - lapack_func_inv: The lapack inverse function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func inv_by_lapack<T: MfTypeUsable>(_ mfarray: MfArray<T>, _ lapack_func_lu: lapack_LU_func<T.StoredType>, _ lapack_func_inv: lapack_inv_func<T.StoredType>) throws -> MfArray<T.StoredType>{
    let shape = mfarray.shape
    
    precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
    
    let newdata: MfData<T.StoredType> = MfData(size: mfarray.size)
    let dstptr = newdata.storedPtr.baseAddress! as! UnsafeMutablePointer<T.StoredType>
    try mfarray.withMNStackedMajorPointer(mforder: .Row){
        srcptr, row, col, offset in
        //LU decomposition
        var IPIV = try wrap_lapack_LU(row, col, srcptr, lapack_func: lapack_func_lu)
        
        //calculate inv
        // note that row == col
        try wrap_lapack_inv(row, srcptr, &IPIV, lapack_func: lapack_func_inv)
        
        //move
        (dstptr + offset).moveAssign(from: srcptr, count: row*col)
    }
    
    let newmfstructure = MfStructure(shape: shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
