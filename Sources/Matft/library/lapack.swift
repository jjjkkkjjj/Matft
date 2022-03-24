//
//  lapack.swift
//  
//
//  Created by Junnosuke Kado on 2022/03/24.
//

import Foundation
import Accelerate

public typealias lapack_solve_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

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
