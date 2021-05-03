//
//  linalg.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.linalg{
    /**
        Solve N simultaneous equation. Get x in coef*x = b. Returned mfarray's type will be float but be double in case that  mftype of either coef or b is double.
        - parameters:
            - coef: Coefficients MfArray for N simultaneous equation
            - b: Biases MfArray for N simultaneous equation
        - throws:
        An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
     
            /*
            //must be flatten....?
            let a = MfArray([[4, 2],
                            [4, 5]])
            let b = MfArray([[2, -7]])
            let x = try! Matft.linalg.solve(a, b: b)
            print(x)
            ==> mfarray =
                [[    2.0,        -3.0]], type=Float, shape=[1, 2]
     
            
            //numpy
            >>> a = np.array([[4,2],[4,5]])
            >>> b = np.array([2,-7])
            >>> np.linalg.solve(a,b)
            array([ 2., -3.])
            >>> np.linalg.solve(a,b.T)
            array([ 2., -3.])
            >>> b = np.array([[2,-7]])
            >>> np.linalg.solve(a,b.T)
            array([[ 2.],
                   [-3.]])

                
            */
     */
    public static func solve(_ coef: MfArray, b: MfArray) throws -> MfArray{
        precondition((coef.ndim == 2), "cannot solve non linear simultaneous equations")
        
        let coefShape = coef.shape
        let bShape = b.shape
        
        precondition(b.ndim <= 2, "Invalid b. Dimension must be 1 or 2")
        var dstColNum = 0
        // check argument
        if b.ndim == 1{
            //(m,m)(m)=(m)
            precondition((coefShape[0] == coefShape[1] && bShape[0] == coefShape[0]), "cannot solve (\(coefShape[0]),\(coefShape[1]))(\(bShape[0]))=(\(bShape[0])) problem")
            dstColNum = 1
        }
        else{//ndim == 2
            //(m,m)(m,n)=(m,n)
            precondition((coefShape[0] == coefShape[1] && bShape[0] == coefShape[0]), "cannot solve (\(coefShape[0]),\(coefShape[1]))(\(bShape[0]),\(bShape[1]))=(\(bShape[0]),\(bShape[1])) problem")
            dstColNum = bShape[1]
        }
                
        let returnedType = StoredType.priority(coef.storedType, b.storedType)
        func _solve<T: MfStorable>(_ mftype: MfType, _ lapack_func: lapack_solve<T>) throws -> MfArray{
            let coefT = coef.astype(mftype) //even if original one is float, create copy
            let bT = b.astype(mftype)
            
            return try solve_by_lapack(coefT, bT, coefShape[0], dstColNum, lapack_func)
        }

        switch returnedType{
        case .Float:
            return try _solve(.Float, sgesv_)
            
        case .Double:
            return try _solve(.Double, dgesv_)
        }
    }
    
    /**
       Get last 2 dim's NxN mfarray's inverse. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    */
    public static func inv(_ mfarray: MfArray) throws -> MfArray{
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        switch mfarray.storedType {
        case .Float:
            return try inv_by_lapack(mfarray, sgetrf_, sgetri_, .Float)
        case .Double:
            return try inv_by_lapack(mfarray, dgetrf_, dgetri_, .Double)
        }

    }
    
    /**
       Get last 2 dim's NxN mfarray's determinant. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    */
    public static func det(_ mfarray: MfArray) throws -> MfArray{
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get a determinant from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        let retSize = mfarray.size / (shape[mfarray.ndim - 1] * shape[mfarray.ndim - 1])
        switch mfarray.storedType {
        case .Float:
            return try det_by_lapack(mfarray, sgetrf_, .Float, retSize)
            
        case .Double:
            return try det_by_lapack(mfarray, dgetrf_, .Double, retSize)
        }

    }
    
    /**
        Get eigenvelues with real only. if eigenvalues contain imaginary part, raise `MfError.LinAlgError.foundComplex`. Returned mfarray's type will be converted properly.
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
       Get eigenvelues of passed mfarray. Returned mfarray's type will be converted properly.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.notConverge`
    */
    public static func eigen(_ mfarray: MfArray) throws -> (valRe: MfArray, valIm: MfArray, lvecRe: MfArray, lvecIm: MfArray, rvecRe: MfArray, rvecIm: MfArray){
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        switch mfarray.storedType {
        case .Float:
            return try eigen_by_lapack(mfarray, .Float, sgeev_)
            
        case .Double:
            return try eigen_by_lapack(mfarray, .Double, dgeev_)
        }

    }
    
    /**
       Do singular value decomposition of passed mfarray. Returned mfarray's type will be converted properly.
       - parameters:
           - mfarray: mfarray
           - full_matrices: Bool, if true returned v and rt have the shapes (..., M, M) and (..., N, N) respectively. Otherwise, the shapes are (..., M, K) and (..., K, N), respectively, where K = min(M, N).
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.notConverge`
    */
    public static func svd(_ mfarray: MfArray, full_matrices: Bool = true) throws -> (v: MfArray, s: MfArray, rt: MfArray){
        switch mfarray.storedType {
        case .Float:
            return try svd_by_lapack(mfarray, .Float, full_matrices, sgesdd_)
            
        case .Double:
            return try svd_by_lapack(mfarray, .Double, full_matrices, dgesdd_)
        }
    }
    
    /**
       Get last 2 dim's MxN mfarray's pseudo-inverse. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    */
    public static func pinv(_ mfarray: MfArray, rcond: Float = 1e-15) throws -> MfArray{
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
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
       Do left polar decomposition of passed mfarray. Returned mfarray's type will be converted properly.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.notConverge`
    */
    public static func polar_left(_ mfarray: MfArray) throws -> (p: MfArray, l: MfArray){
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        let svd = try Matft.linalg.svd(mfarray)
        // M(=mfarray) = USV
        let s = Matft.diag(v: svd.s)
        
        // M = PL = VSRt => P=VSVt, L=VRt
        let p = svd.v *& s *& svd.v.T
        let l = svd.v *& svd.rt
        
        return (p, l)
    }
    /**
       Do right polar decomposition of passed mfarray. Returned mfarray's type will be converted properly.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.notConverge`
    */
    public static func polar_right(_ mfarray: MfArray) throws -> (u: MfArray, p: MfArray){
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        let svd = try Matft.linalg.svd(mfarray)
        // M(=mfarray) = USV
        let s = Matft.diag(v: svd.s)
        
        // M = UP = VSRt => U=VRt P=RSRt
        let u = svd.v *& svd.rt
        let p = svd.rt.T *& s *& svd.rt
        return (u, p)
    }
    
    
    /**
       Calculate lp norm along given axis. Note that ord = Float.infinity and -Float.infinity are also available.
       - parameters:
            - mfarray: mfarray
            - ord: (Optional) Order of the norm
            - axis: (Optional) axis, if not given, get mean for all elements
            - keepDims: (Optional) whether to keep original dimension, default is true
    */
    public static func normlp_vec(_ mfarray: MfArray, ord: Float = 2, axis: Int = -1, keepDims: Bool = false) -> MfArray{
        /*
         // ref: https://github.com/numpy/numpy/blob/91118b3363b636f932f7ff6748d8259e9eb2c23a/numpy/linalg/linalg.py#L2316-L2557
         vDSP_svesq(<#T##__A: UnsafePointer<Float>##UnsafePointer<Float>#>, <#T##__IA: vDSP_Stride##vDSP_Stride#>, <#T##__C: UnsafeMutablePointer<Float>##UnsafeMutablePointer<Float>#>, <#T##__N: vDSP_Length##vDSP_Length#>)
         dlange_(<#T##__norm: UnsafeMutablePointer<Int8>!##UnsafeMutablePointer<Int8>!#>, <#T##__m: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__n: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__a: UnsafeMutablePointer<__CLPK_doublereal>!##UnsafeMutablePointer<__CLPK_doublereal>!#>, <#T##__lda: UnsafeMutablePointer<__CLPK_integer>!##UnsafeMutablePointer<__CLPK_integer>!#>, <#T##__work: UnsafeMutablePointer<__CLPK_doublereal>!##UnsafeMutablePointer<__CLPK_doublereal>!#>)
         cblas_dnrm2(<#T##__N: Int32##Int32#>, <#T##__X: UnsafePointer<Double>!##UnsafePointer<Double>!#>, <#T##__incX: Int32##Int32#>)
         */
        if ord == Float.infinity{
            return Matft.math.abs(mfarray).max(axis: axis, keepDims: keepDims)
        }
        else if ord == -Float.infinity{
            return Matft.math.abs(mfarray).min(axis: axis, keepDims: keepDims)
        }
        if ord != 0{
            let abspow = Matft.math.power(bases: Matft.math.abs(mfarray), exponent: ord)
            return Matft.math.power(bases: abspow.sum(axis: axis, keepDims: keepDims), exponent: 1/ord)
        }
        else{
            // remove mfarray == 0, and count up non-zero
            return (mfarray !== 0).astype(mfarray.mftype).sum(axis: axis, keepDims: keepDims)
        }
    }
    
    /**
       Calculate norm for matrix. When ord is 2, same as frobenius norm.
       - parameters:
           - mfarray: mfarray
    */
    public static func normlp_mat(_ mfarray: MfArray, ord: Float? = 2, axes: (row: Int, col: Int) = (-1, -2), keepDims: Bool = false) -> MfArray{
        var axes: (row: Int, col: Int) = (get_axis(axes.row, ndim: mfarray.ndim), get_axis(axes.col, ndim: mfarray.ndim))
        
        precondition(axes.row != axes.col, "Duplicate axes given.")
        
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
            retShape[axes.row] = 1
            retShape[axes.col] = 1
            ret = ret.reshape(retShape)
        }
        
        return ret
    }
    
    /**
       Calculate frobenius norm for matrix.
       - parameters:
           - mfarray: mfarray
    */
    public static func normfro_mat(_ mfarray: MfArray, axes: (row: Int, col: Int) = (-1, -2), keepDims: Bool = false) -> MfArray{
        let axes: (row: Int, col: Int) = (get_axis(axes.row, ndim: mfarray.ndim), get_axis(axes.col, ndim: mfarray.ndim))
        
        precondition(axes.row != axes.col, "Duplicate axes given.")
        
        let abspow = Matft.math.power(bases: Matft.math.abs(mfarray), exponent: 2)
        
        var ret = Matft.math.power(bases: abspow.sum(axis: max(axes.row, axes.col), keepDims: false).sum(axis: min(axes.row, axes.col), keepDims: false), exponent: 1/2)
        
        if keepDims{
            var retShape = mfarray.shape
            retShape[axes.row] = 1
            retShape[axes.col] = 1
            ret = ret.reshape(retShape)
        }
        
        return ret
    }
    
    /**
       Calculate nuclear norm for matrix.
       - parameters:
           - mfarray: mfarray
    */
    public static func normnuc_mat(_ mfarray: MfArray, axes: (row: Int, col: Int) = (-1, -2), keepDims: Bool = false) -> MfArray{
        var axes: (row: Int, col: Int) = (get_axis(axes.row, ndim: mfarray.ndim), get_axis(axes.col, ndim: mfarray.ndim))
        
        precondition(axes.row != axes.col, "Duplicate axes given.")
        
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
