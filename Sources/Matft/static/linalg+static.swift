//
//  linalg+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/14.
//

import Foundation

extension Matft.linalg{
    
    /// Solve N simultaneous equation. Get x in coef*x = b. Returned mfarray's type will be float but be double in case that  mftype of either coef or b is double.
    /// - parameters:
    ///   - coef: Coefficients MfArray for N simultaneous equation
    ///   - b: Biases MfArray for N simultaneous equation
    /// - throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    ///
    ///  must be flatten....?
    ///  let a = MfArray([[4, 2],
    ///             [4, 5]])
    ///  let b = MfArray([[2, -7]])
    ///  let x = try! Matft.linalg.solve(a, b: b)
    ///  print(x)
    ///  ==> mfarray =
    ///  [[    2.0,        -3.0]], type=Float, shape=[1, 2]
    ///
    ///  //numpy
    ///  >>> a = np.array([[4,2],[4,5]])
    ///  >>> b = np.array([2,-7])
    ///  >>> np.linalg.solve(a,b)
    ///  array([ 2., -3.])
    ///  >>> np.linalg.solve(a,b.T)
    ///  array([ 2., -3.])
    ///  >>> b = np.array([[2,-7]])
    ///  >>> np.linalg.solve(a,b.T)
    ///  array([[ 2.],
    ///       [-3.]])
    ///
    /// - Returns: Solved MfArray
    public static func solve<T: MfTypeUsable>(_ coef: MfArray<T>, b: MfArray<T>) throws -> MfArray<T.StoredType>{
        return try solve_by_lapack(coef, b, T.StoredType.lapack_solve_func)
    }
    
    
    /// Get last 2 dim's NxN mfarray's inverse. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
    /// - parameters:
    ///   - mfarray: The source mfarray
    /// - throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    /// - Returns: The inverse mfarray
    public static func inv<T: MfTypeUsable>(_ mfarray: MfArray<T>) throws -> MfArray<T.StoredType>{
        return try inv_by_lapack(mfarray, T.StoredType.lapack_LU_func, T.StoredType.lapack_inv_func)
    }
    
    /// Get last 2 dim's NxN mfarray's determinant. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
    /// - parameters:
    ///   - mfarray: The source mfarray
    /// - throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    /// - Returns: The determinant mfarray
    public static func det<T: MfTypeUsable>(_ mfarray: MfArray<T>) throws -> MfArray<T.StoredType>{
        return try det_by_lapack(mfarray, T.StoredType.lapack_LU_func)
    }
    
    /// Get eigenvelues of passed mfarray. Returned mfarray's type will be converted properly.
    /// - parameters:
    ///   - mfarray: The source mfarray
    /// - throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    /// - Returns: The eigen mfarraies
    public static func eigen<T: MfTypeUsable>(_ mfarray: MfArray<T>) throws -> (valRe: MfArray<T.StoredType>, valIm: MfArray<T.StoredType>, lvecRe: MfArray<T.StoredType>, lvecIm: MfArray<T.StoredType>, rvecRe: MfArray<T.StoredType>, rvecIm: MfArray<T.StoredType>){
        return try eigen_by_lapack(mfarray, T.StoredType.lapack_eigen_func)
    }
    
    ///  Do singular value decomposition of passed mfarray. Returned mfarray's type will be converted properly.
    /// - parameters:
    ///   - mfarray: The source mfarray
    ///   - full_matrices: if true returned v and rt have the shapes (..., M, M) and (..., N, N) respectively. Otherwise, the shapes are (..., M, K) and (..., K, N), respectively, where K = min(M, N).
    /// - throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    /// - Returns: The SVD mfarraies
    public static func svd<T: MfTypeUsable>(_ mfarray: MfArray<T>, full_matrices: Bool = true) throws -> (v: MfArray<T.StoredType>, s: MfArray<T.StoredType>, rt: MfArray<T.StoredType>){
        return try svd_by_lapack(mfarray, full_matrices, T.StoredType.lapack_svd_func)
    }
    
    
    ///  Get last 2 dim's MxN mfarray's pseudo-inverse. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
    /// - parameters:
    ///   - mfarray: The source mfarray
    /// - throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    /// - Returns: The pseudo-inverse  mfarraies
    public static func pinv<T: MfTypeUsable>(_ mfarray: MfArray<T>, rcond: Float = 1e-15) throws -> MfArray<T.StoredType>{
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        
        // v's shape = (...,N,X)
        // s's shape = (min(X,Y),)
        // rt.shape = (...,Y,M)
        let (v, s, rt) = try Matft.linalg.svd(mfarray, full_matrices: false)
        let smax = s.max().scalar!
        let condition = T.StoredType.from(rcond) * smax
        
        let spinv_array = s.toFlattenArray().map{ $0 <= condition ? T.StoredType.zero : 1/$0 }
        let spinv = MfArray<T.StoredType>(spinv_array)
        return rt.swapaxes(axis1: -1, axis2: -2) *& (spinv.expand_dims(axis: 1) * v.swapaxes(axis1: -1, axis2: -2))
    }
}
