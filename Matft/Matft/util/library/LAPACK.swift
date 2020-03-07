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
internal func solve_by_lapack<T>(copiedCoefPtr: UnsafeMutablePointer<T>, _ coefRowNum: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstColNum: Int, _ lapack_solve_func: lapack_solve<T>) throws {
    // row number of coefficients matrix
    var N = __CLPK_integer(coefRowNum)
    var LDA = __CLPK_integer(coefRowNum)// leading dimension >= max(1, N)
    
    // column number of b
    var NRHS = __CLPK_integer(dstColNum)
    var LDB = __CLPK_integer(dstColNum)// leading dimension >= max(1, N)
    
    //pivot indices
    var IPIV = Array<__CLPK_integer>(repeating: 0, count: coefRowNum)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run
    let _ = lapack_solve_func(&N, &NRHS, copiedCoefPtr, &LDA, &IPIV, dstptr, &LDB, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }
}

