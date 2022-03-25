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
}
