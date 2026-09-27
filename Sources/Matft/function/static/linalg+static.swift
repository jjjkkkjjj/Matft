//
//  linalg.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

extension Matft.linalg{
    /**
       Solve a linear matrix equation `coef * x = b` for `x`.

       Equivalent to `numpy.linalg.solve`. Solved with LAPACK `gesv` (LU decomposition with partial pivoting).

       ```swift
       let coef = MfArray([[3, 2], [1, 2]])
       let b = MfArray([7, 1])
       let x = try Matft.linalg.solve(coef, b: b) // MfArray([3.0, -1.0], mftype: .Float)
       ```

       - Parameters:
            - coef: The square coefficient matrix of shape `(M, M)`.
            - b: The ordinate values of shape `(M,)` or `(M, K)`.
       - Returns: The solution `x` with the same shape as `b`. It is `.Double` if either `coef` or `b` is stored as `Double`, and `.Float` otherwise.
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.singularMatrix` if the matrix is exactly singular.
       - Precondition: `coef` must be 2-d and square, `b` must be 1-d or 2-d with `b.shape[0] == M`. Complex arrays are not supported. Unlike Numpy, stacked (batched) `coef` is not supported.
    */
    public static func solve(_ coef: MfArray, b: MfArray) throws -> MfArray{
        unsupport_complex(coef)
        unsupport_complex(b)
        
        let returnedType = StoredType.priority(coef.storedType, b.storedType)

        switch returnedType{
        case .Float:
            return try solve_by_lapack(coef, b, ret_mftype: .Float, sgesv_)
            
        case .Double:
            return try solve_by_lapack(coef, b, ret_mftype: .Double, dgesv_)
        }
    }
    
    /**
       Compute the inverse of a square matrix, or of each matrix in a stack.

       Equivalent to `numpy.linalg.inv`. The inverse is taken over the last two dimensions (LAPACK `getrf` + `getri`).

       ```swift
       let a = MfArray([[1, 2], [3, 4]])
       let ainv = try Matft.linalg.inv(a) // MfArray([[-2.0, 1.0], [1.5, -0.5]], mftype: .Float)
       ```

       - Parameters:
            - mfarray: The array of shape `(..., M, M)`.
       - Returns: The inverse with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.singularMatrix` if the matrix is exactly singular.
       - Precondition: `mfarray` must be at least 2-d and its last two dimensions must be square. Complex arrays are not supported.
    */
    public static func inv(_ mfarray: MfArray) throws -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return try inv_by_lapack(mfarray, sgetrf_, sgetri_, .Float)
        case .Double:
            return try inv_by_lapack(mfarray, dgetrf_, dgetri_, .Double)
        }

    }
    
    /**
       Compute the determinant of a square matrix, or of each matrix in a stack.

       Equivalent to `numpy.linalg.det`. The determinant is computed from the LU decomposition (LAPACK `getrf`) of the last two dimensions.

       - Parameters:
            - mfarray: The array of shape `(..., M, M)`.
       - Returns: The determinants with shape `(...)`, or `[1]` for a single 2-d matrix. The result keeps the `mftype` of `mfarray`; the values are computed in `Float` (`Double` for `.Double` input).
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.singularMatrix` if the matrix is exactly singular.
       - Precondition: `mfarray` must be at least 2-d and its last two dimensions must be square. Complex arrays are not supported.
       - Note: Unlike Numpy, which returns 0, an exactly singular matrix throws `MfError.LinAlgError.singularMatrix`.
    */
    public static func det(_ mfarray: MfArray) throws -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return try det_by_lapack(mfarray, sgetrf_)
            
        case .Double:
            return try det_by_lapack(mfarray, dgetrf_)
        }

    }
    
    /* (documentation of the disabled eigen_real below)
        Get eigenvalues with real only. if eigenvalues contain imaginary part, raise `MfError.LinAlgError.foundComplex`. Returned mfarray's type will be converted properly.
        - parameters:
            - mfarray: mfarray
        - throws:
        An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.notConverge` and `MfError.LinAlgError.foundComplex`
     */
    /*
    public static func eigen_real(_ mfarray: MfArray) throws -> MfArray{
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        switch mfarray.storedType {
        case .Float:
            return eigen_by_lapack(mfarray, .Float, sgeev_)
            
        case .Double:
            return eigen_by_lapack(mfarray, .Double, dgeev_)
        }

    }*/
    
    /**
       Compute the eigenvalues and the left and right eigenvectors of a square matrix, or of each matrix in a stack.

       Similar to `numpy.linalg.eig` (LAPACK `geev`), but the real and imaginary parts are returned as separate real arrays, and the left eigenvectors are also returned.

       - Parameters:
            - mfarray: The array of shape `(..., M, M)`.
       - Returns: A tuple of real arrays (`.Double` for `.Double` input and `.Float` otherwise):
            - `valRe`, `valIm`: The real and imaginary parts of the eigenvalues, shape `(..., M)`.
            - `lvecRe`, `lvecIm`: The real and imaginary parts of the left eigenvectors, shape `(..., M, M)`.
            - `rvecRe`, `rvecIm`: The real and imaginary parts of the right eigenvectors, shape `(..., M, M)`. The column `[:, i]` corresponds to the eigenvalue `i`, as in Numpy.
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.notConverge` if the decomposition does not converge.
       - Precondition: `mfarray` must be at least 2-d and its last two dimensions must be square. Complex arrays are not supported.
    */
    public static func eigen(_ mfarray: MfArray) throws -> (valRe: MfArray, valIm: MfArray, lvecRe: MfArray, lvecIm: MfArray, rvecRe: MfArray, rvecIm: MfArray){
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return try eigen_by_lapack(mfarray, sgeev_)
            
        case .Double:
            return try eigen_by_lapack(mfarray, dgeev_)
        }

    }
    
    /**
       Compute the singular value decomposition `mfarray = v * diag(s) * rt`.

       Equivalent to `numpy.linalg.svd` (LAPACK `gesdd`). Note the naming: the returned `v` is Numpy's `U` (the left singular vectors) and `rt` is Numpy's `Vh`.

       ```swift
       let a = MfArray([[1, 2],
                        [3, 4]])
       let ret = try Matft.linalg.svd(a)
       // ret.v  == MfArray([[-0.40455358, -0.9145143 ], [-0.9145143 , 0.40455358]], mftype: .Float)
       // ret.s  == MfArray([ 5.4649857 , 0.36596619], mftype: .Float)
       // ret.rt == MfArray([[-0.57604844, -0.81741556], [ 0.81741556, -0.57604844]], mftype: .Float)
       ```

       - Parameters:
            - mfarray: The array of shape `(..., M, N)`.
            - full_matrices: If `true` (default), `v` and `rt` have the shapes `(..., M, M)` and `(..., N, N)`. Otherwise, the shapes are `(..., M, K)` and `(..., K, N)`, where `K = min(M, N)`.
       - Returns: A tuple of `v` (left singular vectors), `s` (singular values in descending order, shape `(..., K)`) and `rt` (right singular vectors, transposed). The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.notConverge` if the decomposition does not converge.
       - Precondition: `mfarray` must be at least 2-d. Complex arrays are not supported.
    */
    public static func svd(_ mfarray: MfArray, full_matrices: Bool = true) throws -> (v: MfArray, s: MfArray, rt: MfArray){
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return try svd_by_lapack(mfarray, full_matrices, sgesdd_)
            
        case .Double:
            return try svd_by_lapack(mfarray, full_matrices, dgesdd_)
        }
    }
    
    /**
       Compute the (Moore-Penrose) pseudo-inverse of a matrix.

       Equivalent to `numpy.linalg.pinv`. It is computed from the SVD, and singular values not larger than `rcond * max(s)` are treated as zero.

       - Parameters:
            - mfarray: The matrix of shape `(M, N)`.
            - rcond: The cutoff ratio for small singular values. Default is `1e-15`.
       - Returns: The pseudo-inverse of shape `(N, M)`. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.notConverge` if the decomposition does not converge.
       - Precondition: `mfarray` must be at least 2-d. Complex arrays are not supported.
       - Note: The cutoff and the reciprocal singular values are computed over all singular values at once, so only a single 2-d matrix is handled correctly; stacked matrices are not supported like in Numpy.
    */
    public static func pinv(_ mfarray: MfArray, rcond: Float = 1e-15) throws -> MfArray{
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        unsupport_complex(mfarray)
        
        // v's shape = (...,N,X)
        // s's shape = (min(X,Y),)
        // rt.shape = (...,Y,M)
        let (v, s, rt) = try Matft.linalg.svd(mfarray, full_matrices: false)
        
        func _pinv<T: MfStorable>(_ type: T.Type) -> MfArray{
            let smax = s.max().scalar(T.self)!
            let condition = T.from(rcond) * smax
            let spinv_array = s.toFlattenArray(datatype: T.self){ $0 <= condition ? T.zero : 1/$0 }
            let spinv = MfArray(spinv_array)
            return rt.swapaxes(axis1: -1, axis2: -2) *& (spinv.expand_dims(axis: 1) * v.swapaxes(axis1: -1, axis2: -2))
        }
        switch mfarray.storedType {
        case .Float:
            return _pinv(Float.self)
            
        case .Double:
            return _pinv(Double.self)
        }
        
        
    }
    
    /**
       Compute the left polar decomposition `mfarray = p * l` of a square matrix.

       Similar to `scipy.linalg.polar(a, side="left")`, but the factors are returned in the order `(p, l)`. It is computed from the SVD `a = U S Vh` as `p = U S U^T` and `l = U Vh`.

       - Parameters:
            - mfarray: The square matrix of shape `(M, M)`.
       - Returns: A tuple of `p` (the symmetric positive semi-definite factor) and `l` (the orthogonal factor). The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.notConverge` if the decomposition does not converge.
       - Precondition: `mfarray` must be at least 2-d and its last two dimensions must be square. Complex arrays are not supported.
       - Note: The transposes use `.T`, which reverses all axes, so only 2-d input is handled correctly.
    */
    public static func polar_left(_ mfarray: MfArray) throws -> (p: MfArray, l: MfArray){
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        unsupport_complex(mfarray)
        
        let svd = try Matft.linalg.svd(mfarray)
        // M(=mfarray) = USV
        let s = Matft.diag(v: svd.s)
        
        // M = PL = VSRt => P=VSVt, L=VRt
        let p = svd.v *& s *& svd.v.T
        let l = svd.v *& svd.rt
        
        return (p, l)
    }
    /**
       Compute the right polar decomposition `mfarray = u * p` of a square matrix.

       Equivalent to `scipy.linalg.polar(a, side="right")`. It is computed from the SVD `a = U S Vh` as `u = U Vh` and `p = Vh^T S Vh`.

       - Parameters:
            - mfarray: The square matrix of shape `(M, M)`.
       - Returns: A tuple of `u` (the orthogonal factor) and `p` (the symmetric positive semi-definite factor). The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Throws: `MfError.LinAlgError.factorizationError` if LAPACK reports an illegal argument, or `MfError.LinAlgError.notConverge` if the decomposition does not converge.
       - Precondition: `mfarray` must be at least 2-d and its last two dimensions must be square. Complex arrays are not supported.
       - Note: The transposes use `.T`, which reverses all axes, so only 2-d input is handled correctly.
    */
    public static func polar_right(_ mfarray: MfArray) throws -> (u: MfArray, p: MfArray){
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        unsupport_complex(mfarray)
        
        let svd = try Matft.linalg.svd(mfarray)
        // M(=mfarray) = USV
        let s = Matft.diag(v: svd.s)
        
        // M = UP = VSRt => U=VRt P=RSRt
        let u = svd.v *& svd.rt
        let p = svd.rt.T *& s *& svd.rt
        return (u, p)
    }
    
    
    /**
       Compute the vector p-norm along the given axis.

       Equivalent to `numpy.linalg.norm(x, ord, axis)` for vectors: `sum(|x|^ord)^(1/ord)`. `ord = Float.infinity` gives `max(|x|)`, `ord = -Float.infinity` gives `min(|x|)` and `ord = 0` counts the non-zero elements.

       - Parameters:
            - mfarray: The input array.
            - ord: The order of the norm. Default is 2 (Euclidean norm).
            - axis: The axis along which to compute the norm. Default is -1 (the last axis). Unlike Numpy, `nil` (all elements) is not accepted.
            - keepDims: If `true`, the reduced axis is kept with size 1. Default is `false`.
       - Returns: The norm. The result is `.Double` for `.Double` input and `.Float` otherwise. For `ord = 0`, the count has the same `mftype` as `mfarray`.
       - Precondition: Complex arrays are not supported.
    */
    public static func normlp_vec(_ mfarray: MfArray, ord: Float = 2, axis: Int = -1, keepDims: Bool = false) -> MfArray{
        /*
         // ref: https://github.com/numpy/numpy/blob/91118b3363b636f932f7ff6748d8259e9eb2c23a/numpy/linalg/linalg.py#L2316-L2557
         vDSP_svesq(<#T##__A: UnsafePointer<Float>##UnsafePointer<Float>#>, <#T##__IA: vDSP_Stride##vDSP_Stride#>, <#T##__C: UnsafeMutablePointer<Float>##UnsafeMutablePointer<Float>#>, <#T##__N: vDSP_Length##vDSP_Length#>)
         dlange_(<#T##__norm: UnsafeMutablePointer<Int8>!##UnsafeMutablePointer<Int8>!#>, <#T##__m: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__n: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__a: UnsafeMutablePointer<__CLPK_doublereal>!##UnsafeMutablePointer<__CLPK_doublereal>!#>, <#T##__lda: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__work: UnsafeMutablePointer<__CLPK_doublereal>!##UnsafeMutablePointer<__CLPK_doublereal>!#>)
         cblas_dnrm2(<#T##__N: Int32##Int32#>, <#T##__X: UnsafePointer<Double>!##UnsafePointer<Double>!#>, <#T##__incX: Int32##Int32#>)
         */
        unsupport_complex(mfarray)
        
        if ord == Float.infinity{
            return Matft.math.abs(mfarray).max(axis: axis, keepDims: keepDims)
        }
        else if ord == -Float.infinity{
            return Matft.math.abs(mfarray).min(axis: axis, keepDims: keepDims)
        }
        if ord != 0{
            let abspow = Matft.math.power(bases: Matft.math.abs(mfarray), exponents: ord)
            let sum = abspow.sum(axis: axis, keepDims: keepDims)
            switch sum.storedType{
            case .Float:
                return Matft.math.power(bases: sum, exponents: 1/ord)
            case .Double:
                // 1/ord in Float (e.g. 1/3) would limit a Double result to Float precision
                return Matft.math.power(bases: sum, exponents: Matft.nums(1 / Double(ord), shape: [1], mftype: .Double))
            }
        }
        else{
            // remove mfarray == 0, and count up non-zero
            return (mfarray !== 0).astype(mfarray.mftype).sum(axis: axis, keepDims: keepDims)
        }
    }
    
    /**
       Compute a matrix norm over the two given axes.

       Equivalent to `numpy.linalg.norm(x, ord, axis=(row, col))` for matrices. The supported orders are
       - `2`: the largest singular value (spectral norm),
       - `-2`: the smallest singular value,
       - `1` / `-1`: the maximum / minimum absolute sum along `row`,
       - `Float.infinity` / `-Float.infinity`: the maximum / minimum absolute sum along `col`.

       Use `normfro_mat(_:axes:keepDims:)` for the Frobenius norm and `normnuc_mat(_:axes:keepDims:)` for the nuclear norm.

       - Parameters:
            - mfarray: The input array with at least 2 dimensions.
            - ord: The order of the norm. Default is 2. `nil` computes the Frobenius norm like Numpy.
            - axes: The `(row, col)` axes that hold the matrices. Default is `(-2, -1)` like Numpy.
            - keepDims: If `true`, the two reduced axes are kept with size 1. Default is `false`.
       - Returns: The norms with the two axes removed. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: `axes.row` and `axes.col` must differ, and `ord` must be one of the supported values. Complex arrays are not supported.
       - Note: `axes` is `(row, col)`, where `row` is the axis reduced first for `ord = 1 / -1` and `col` is reduced first for `ord = inf / -inf`, matching Numpy's `axis=(row, col)`.
    */
    public static func normlp_mat(_ mfarray: MfArray, ord: Float? = 2, axes: (row: Int, col: Int) = (-2, -1), keepDims: Bool = false) -> MfArray{
        // ord=None is the frobenius norm like numpy
        guard let ord = ord else {
            return Matft.linalg.normfro_mat(mfarray, axes: axes, keepDims: keepDims)
        }
        var axes: (row: Int, col: Int) = (get_positive_axis(axes.row, ndim: mfarray.ndim), get_positive_axis(axes.col, ndim: mfarray.ndim))
        
        precondition(axes.row != axes.col, "Duplicate axes given.")
        unsupport_complex(mfarray)
        // `axes` is shifted below for the second reduction, so keep the original ones for keepDims
        let keptAxes = axes

        var ret: MfArray
        if ord == 2{
            ret = _multi_svd_norm(mfarray: mfarray, axes: &axes, op: Matft.stats.max)
        }
        else if ord == -2{
            ret = _multi_svd_norm(mfarray: mfarray, axes: &axes, op: Matft.stats.min)
        }
        else if ord == 1{
            if axes.col > axes.row{
                axes.col -= 1
            }
            ret = Matft.math.abs(mfarray).sum(axis: axes.row, keepDims: false).max(axis: axes.col, keepDims: false)
        }
        else if ord == Float.infinity{
            if axes.row > axes.col{
                axes.row -= 1
            }
            ret = Matft.math.abs(mfarray).sum(axis: axes.col, keepDims: false).max(axis: axes.row, keepDims: false)
        }
        else if ord == -1{
            if axes.col > axes.row{
                axes.col -= 1
            }
            ret = Matft.math.abs(mfarray).sum(axis: axes.row, keepDims: false).min(axis: axes.col, keepDims: false)
        }
        else if ord == -Float.infinity{
            if axes.row > axes.col{
                axes.row -= 1
            }
            ret = Matft.math.abs(mfarray).sum(axis: axes.col, keepDims: false).min(axis: axes.row, keepDims: false)
        }
        else{
            preconditionFailure("Invalid norm order for matrices.")
        }

        if keepDims{
            var retShape = mfarray.shape
            retShape[keptAxes.row] = 1
            retShape[keptAxes.col] = 1
            ret = ret.reshape(retShape)
        }
        
        return ret
    }
    
    /**
       Compute the Frobenius norm of matrices over the two given axes.

       Equivalent to `numpy.linalg.norm(x, "fro", axis=(row, col))`, i.e. `sqrt(sum(|x|^2))` over the two axes.

       - Parameters:
            - mfarray: The input array with at least 2 dimensions.
            - axes: The `(row, col)` axes that hold the matrices. Default is `(-2, -1)`; the result does not depend on the order.
            - keepDims: If `true`, the two reduced axes are kept with size 1. Default is `false`.
       - Returns: The norms with the two axes removed. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: `axes.row` and `axes.col` must differ. Complex arrays are not supported.
    */
    public static func normfro_mat(_ mfarray: MfArray, axes: (row: Int, col: Int) = (-2, -1), keepDims: Bool = false) -> MfArray{
        let axes: (row: Int, col: Int) = (get_positive_axis(axes.row, ndim: mfarray.ndim), get_positive_axis(axes.col, ndim: mfarray.ndim))
        
        precondition(axes.row != axes.col, "Duplicate axes given.")
        unsupport_complex(mfarray)
        
        let abspow = Matft.math.power(bases: Matft.math.abs(mfarray), exponents: 2)
        
        var ret = Matft.math.power(bases: abspow.sum(axis: max(axes.row, axes.col), keepDims: false).sum(axis: min(axes.row, axes.col), keepDims: false), exponents: 1/2)
        
        if keepDims{
            var retShape = mfarray.shape
            retShape[axes.row] = 1
            retShape[axes.col] = 1
            ret = ret.reshape(retShape)
        }
        
        return ret
    }
    
    /**
       Compute the nuclear norm (the sum of the singular values) of matrices over the two given axes.

       Equivalent to `numpy.linalg.norm(x, "nuc", axis=(row, col))`.

       - Parameters:
            - mfarray: The input array with at least 2 dimensions.
            - axes: The `(row, col)` axes that hold the matrices. Default is `(-2, -1)`; the result does not depend on the order.
            - keepDims: If `true`, the two reduced axes are kept with size 1. Default is `false`.
       - Returns: The norms with the two axes removed. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: `axes.row` and `axes.col` must differ. Complex arrays are not supported.
    */
    public static func normnuc_mat(_ mfarray: MfArray, axes: (row: Int, col: Int) = (-1, -2), keepDims: Bool = false) -> MfArray{
        var axes: (row: Int, col: Int) = (get_positive_axis(axes.row, ndim: mfarray.ndim), get_positive_axis(axes.col, ndim: mfarray.ndim))
        
        precondition(axes.row != axes.col, "Duplicate axes given.")
        unsupport_complex(mfarray)
        
        var ret = _multi_svd_norm(mfarray: mfarray, axes: &axes, op: Matft.stats.sum)
        
        if keepDims{
            var retShape = mfarray.shape
            retShape[axes.row] = 1
            retShape[axes.col] = 1
            ret = ret.reshape(retShape)
        }
        
        return ret
    }
}

fileprivate typealias _norm_op = (MfArray, Int?, Bool) -> MfArray
fileprivate func _multi_svd_norm(mfarray: MfArray, axes: inout (row: Int, col: Int), op: _norm_op) -> MfArray{
    do{
        let mfarray = mfarray.moveaxis(src: [axes.row, axes.col], dst: [-2, -1])
        let ret = op(try Matft.linalg.svd(mfarray).s, -1, false)
        return ret
    }
    catch{
        fatalError("Cannot calculate svd")
    }
}
