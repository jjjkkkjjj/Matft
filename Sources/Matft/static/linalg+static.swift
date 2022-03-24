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
}
