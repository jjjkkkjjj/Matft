//
//  fit+static.swift
//  Matft
//
//  Least squares, polynomial fitting and covariance
//

import Foundation

extension Matft.linalg{
    /**
       Return the least-squares solution to a linear matrix equation `a * x = b`.

       Equivalent to `numpy.linalg.lstsq` (SVD based). The returned tuple has the same order as Numpy's.

       - Parameters:
            - a: The coefficient matrix of shape `(M, N)`.
            - b: The ordinate values of shape `(M,)` or `(M, K)`.
            - rcond: The cutoff ratio for small singular values: singular values not larger than `rcond * max(s)` are treated as zero. If `nil` (default), the machine epsilon (of `Float`, or `Double` if either input is `.Double`) times `max(M, N)` is used.
       - Returns: A tuple of the following values. The arrays are `.Double` if either `a` or `b` is stored as `Double` and `.Float` otherwise (the computation itself is done in `Double`):
            - `x`: The least-squares solution of shape `(N,)` or `(N, K)`. For a rank-deficient `a`, the minimum-norm solution.
            - `residuals`: The sums of squared residuals of shape `(1,)` or `(K,)`. Empty if `rank < N` or `M <= N`.
            - `rank`: The effective rank of `a`.
            - `s`: The singular values of `a`.
       - Throws: `MfError.LinAlgError.factorizationError` or `MfError.LinAlgError.notConverge` if the underlying SVD fails.
       - Precondition: `a` must be 2-d, `b` must be 1-d or 2-d, and `a.shape[0] == b.shape[0]`. Complex arrays are not supported.
    */
    public static func lstsq(_ a: MfArray, _ b: MfArray, rcond: Double? = nil) throws -> (x: MfArray, residuals: MfArray, rank: Int, s: MfArray){
        precondition(a.ndim == 2, "a must be 2d")
        precondition(b.ndim == 1 || b.ndim == 2, "b must be 1d or 2d")
        precondition(a.shape[0] == b.shape[0], "Incompatible dimensions")
        unsupport_complex(a)
        unsupport_complex(b)

        let isDouble = a.storedType == .Double || b.storedType == .Double
        let rettype: MfType = isDouble ? .Double : .Float
        let (m, n) = (a.shape[0], a.shape[1])
        let eps = isDouble ? Double.ulpOfOne : Double(Float.ulpOfOne)
        let rcond = rcond ?? eps * Double(Swift.max(m, n))

        let A = a.astype(.Double)
        let B = b.ndim == 1 ? b.astype(.Double).expand_dims(axis: 1) : b.astype(.Double)

        // x = V diag(1/s) U^T b with the small singular values cut off
        let (u, s, vt) = try Matft.linalg.svd(A, full_matrices: false)
        let sv = s.toFlattenArray(datatype: Double.self){ $0 }
        let cutoff = rcond * (sv.max() ?? 0)
        let rank = sv.filter{ $0 > cutoff }.count
        let sinv = MfArray(sv.map{ $0 > cutoff ? 1 / $0 : 0 }, mftype: .Double).expand_dims(axis: 1)
        let x = vt.T *& (sinv * (u.T *& B))

        var residuals = MfArray([] as [Double], mftype: .Double, shape: [0])
        if rank == n && m > n{
            let r = B - A *& x
            residuals = Matft.stats.sum(r * r, axis: 0)
        }

        let retx = b.ndim == 1 ? x.reshape([n]) : x
        return (retx.astype(rettype), residuals.astype(rettype), rank, s.astype(rettype))
    }

    /**
       Return the rank of a matrix computed from its singular values.

       Equivalent to `numpy.linalg.matrix_rank`.

       - Parameters:
            - a: A 1-d or 2-d array. A 1-d array has rank 1 unless all its elements are zero.
            - tol: The threshold below which singular values are considered zero. If `nil` (default), `max(s) * max(M, N) * eps` is used, where `eps` is the machine epsilon of `Float` (`Double` for `.Double` input).
       - Returns: The rank of `a`.
       - Throws: `MfError.LinAlgError.factorizationError` or `MfError.LinAlgError.notConverge` if the underlying SVD fails.
       - Precondition: `a` must be 1-d or 2-d. Complex arrays are not supported.
    */
    public static func matrix_rank(_ a: MfArray, tol: Double? = nil) throws -> Int{
        precondition(a.ndim == 1 || a.ndim == 2, "a must be 1d or 2d")
        unsupport_complex(a)
        if a.ndim == 1{
            return a.toFlattenArray(datatype: Double.self){ $0 }.contains{ $0 != 0 } ? 1 : 0
        }
        let eps = a.storedType == .Double ? Double.ulpOfOne : Double(Float.ulpOfOne)
        let sv = try Matft.linalg.svd(a.astype(.Double), full_matrices: false).s.toFlattenArray(datatype: Double.self){ $0 }
        let tol = tol ?? (sv.max() ?? 0) * Double(Swift.max(a.shape[0], a.shape[1])) * eps
        return sv.filter{ $0 > tol }.count
    }
}

extension Matft{
    /**
       Fit a polynomial of the given degree to points `(x, y)` by least squares.

       Equivalent to `numpy.polyfit` (without the optional outputs). As in Numpy, the columns of the Vandermonde matrix are scaled to improve the condition number.

       - Parameters:
            - x: The 1-d, non-empty x-coordinates of the sample points.
            - y: The y-coordinates of shape `(M,)`, or `(M, K)` to fit `K` data sets at once.
            - deg: The degree of the polynomial (at least 0).
       - Returns: The polynomial coefficients, highest power first, of shape `(deg + 1,)` or `(deg + 1, K)`. The result is `.Double` if either input is stored as `Double`, and `.Float` otherwise.
       - Throws: `MfError.LinAlgError.factorizationError` or `MfError.LinAlgError.notConverge` if the underlying SVD fails.
       - Precondition: `deg >= 0`, `x` must be 1-d and non-empty, and `y.shape[0]` must equal the size of `x`.
    */
    public static func polyfit(_ x: MfArray, _ y: MfArray, deg: Int) throws -> MfArray{
        precondition(deg >= 0, "expected deg >= 0")
        precondition(x.ndim == 1 && x.size > 0, "expected 1d non-empty x")
        precondition(y.shape[0] == x.size, "expected x and y to have the same length")

        let xv = x.toFlattenArray(datatype: Double.self){ $0 }
        let m = xv.count
        let isDouble = x.storedType == .Double || y.storedType == .Double
        let eps = isDouble ? Double.ulpOfOne : Double(Float.ulpOfOne)

        // the Vandermonde matrix whose columns are scaled to improve the condition number, as numpy does
        var lhs = [Double](repeating: 0, count: m * (deg + 1))
        for i in 0..<m{
            for j in 0...deg{
                lhs[i * (deg + 1) + j] = pow(xv[i], Double(deg - j))
            }
        }
        var scale = [Double](repeating: 0, count: deg + 1)
        for j in 0...deg{
            var sq = 0.0
            for i in 0..<m{
                sq += lhs[i * (deg + 1) + j] * lhs[i * (deg + 1) + j]
            }
            scale[j] = sq.squareRoot()
        }
        for i in 0..<m{
            for j in 0...deg{
                lhs[i * (deg + 1) + j] /= scale[j]
            }
        }

        let (c, _, _, _) = try Matft.linalg.lstsq(MfArray(lhs, mftype: .Double, shape: [m, deg + 1]), y.astype(.Double), rcond: Double(m) * eps)
        let scaleArray = MfArray(scale, mftype: .Double)
        let ret = c.ndim == 1 ? c / scaleArray : c / scaleArray.expand_dims(axis: 1)
        return ret.astype(isDouble ? .Double : .Float)
    }

    /**
       Evaluate a polynomial at the given values.

       Equivalent to `numpy.polyval`. It is computed with Horner's method in `Double`.

       - Parameters:
            - p: The 1-d polynomial coefficients, highest power first.
            - x: The values at which to evaluate the polynomial. Any shape.
       - Returns: The values of the polynomial with the same shape as `x`. Its `mftype` is the promoted type of `p` and `x`.
       - Precondition: `p` must be 1-d.
    */
    public static func polyval(_ p: MfArray, _ x: MfArray) -> MfArray{
        precondition(p.ndim == 1, "p must be 1d")
        let rettype = MfType.priority(p.mftype, x.mftype)
        let coefs = p.toFlattenArray(datatype: Double.self){ $0 }
        let xd = x.astype(.Double)
        // Horner's method
        var y = Matft.nums_like(0.0, mfarray: xd)
        for c in coefs{
            y = y * xd + c
        }
        return y.astype(rettype)
    }
}

extension Matft.stats{
    /**
       Estimate the covariance matrix.

       Equivalent to `numpy.cov` (without `fweights` / `aweights`).

       - Parameters:
            - m: A 1-d or 2-d array. If `rowvar` is `true`, each row is a variable and each column is an observation.
            - y: An optional additional set of variables with the same form as `m`, stacked below `m`.
            - rowvar: If `true` (default), each row represents a variable. Otherwise, each column represents a variable.
            - bias: If `true`, the normalization is by `N`. Otherwise (default) it is by `N - 1`.
            - ddof: If given, the normalization is by `N - ddof`, overriding `bias`.
       - Returns: The covariance matrix of the variables. Unlike Numpy's 0-d result, a single variable gives shape `[1]`. The result is `.Double` if `m` or `y` is stored as `Double`, and `.Float` otherwise.
       - Precondition: `m` must have at most 2 dimensions. Complex arrays are not supported.
    */
    public static func cov(_ m: MfArray, y: MfArray? = nil, rowvar: Bool = true, bias: Bool = false, ddof: Int? = nil) -> MfArray{
        precondition(m.ndim <= 2, "m has more than 2 dimensions")
        unsupport_complex(m)
        let rettype: MfType = m.storedType == .Double || y?.storedType == .Double ? .Double : .Float

        func variables(_ a: MfArray) -> MfArray{
            let a = a.astype(.Double)
            if a.ndim == 1{
                return a.expand_dims(axis: 0)
            }
            return rowvar ? a : a.T
        }
        var X = variables(m)
        if let y = y{
            X = Matft.vstack([X, variables(y)])
        }

        let ddof = ddof ?? (bias ? 0 : 1)
        let fact = Double(X.shape[1] - ddof)
        let centered = X - Matft.stats.mean(X, axis: 1, keepDims: true)
        let c = (centered *& centered.T) / fact
        return (c.size == 1 ? c.reshape([1]) : c).astype(rettype)
    }

    /**
       Return the Pearson product-moment correlation coefficients.

       Equivalent to `numpy.corrcoef`. The coefficients are computed from `cov(_:y:rowvar:bias:ddof:)` and clipped to [-1, 1].

       - Parameters:
            - x: A 1-d or 2-d array. If `rowvar` is `true`, each row is a variable and each column is an observation.
            - y: An optional additional set of variables with the same form as `x`.
            - rowvar: If `true` (default), each row represents a variable. Otherwise, each column represents a variable.
       - Returns: The correlation coefficient matrix. The result is `.Double` if `x` or `y` is stored as `Double`, and `.Float` otherwise. For a single variable it is `[1.0]` with shape `[1]` and is always `.Double`.
       - Precondition: `x` must have at most 2 dimensions. Complex arrays are not supported.
    */
    public static func corrcoef(_ x: MfArray, y: MfArray? = nil, rowvar: Bool = true) -> MfArray{
        let c = Matft.stats.cov(x, y: y, rowvar: rowvar).astype(.Double)
        if c.ndim == 1{
            // a single variable: c / c
            return (c / c).astype(c.mftype)
        }
        let n = c.shape[0]
        let stddev = MfArray((0..<n).map{ (c[$0, $0] as! Double).squareRoot() }, mftype: .Double)
        let ret = c / stddev.expand_dims(axis: 1) / stddev.expand_dims(axis: 0)
        let rettype: MfType = x.storedType == .Double || y?.storedType == .Double ? .Double : .Float
        return Matft.clip(ret, min: -1.0, max: 1.0).astype(rettype)
    }
}
