//
//  LAPACK.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

// MARK: - Pure Swift Eigenvalue Implementation
// This implementation is used on WASI where CLAPACK doesn't include dgeev.
// It's also available on other platforms for testing purposes.

/// Computes the Euclidean norm of a vector segment using SIMD for performance
@usableFromInline
internal func _eigenVectorNorm(_ v: [Double], start: Int, count: Int) -> Double {
    if count == 0 { return 0.0 }

    return v.withUnsafeBufferPointer { buffer in
        let basePtr = buffer.baseAddress! + start
        var sum = SIMD4<Double>.zero

        let simdCount = count / 4
        let remainder = count % 4

        // Process 4 elements at a time with SIMD
        for i in 0..<simdCount {
            let vec = SIMD4<Double>(
                basePtr[i * 4],
                basePtr[i * 4 + 1],
                basePtr[i * 4 + 2],
                basePtr[i * 4 + 3]
            )
            sum = sum.addingProduct(vec, vec)
        }

        // Sum SIMD lanes and handle remainder
        var scalarSum = sum[0] + sum[1] + sum[2] + sum[3]
        let tailStart = simdCount * 4
        for i in 0..<remainder {
            let val = basePtr[tailStart + i]
            scalarSum += val * val
        }

        return sqrt(scalarSum)
    }
}

/// Applies a Householder reflection to transform a matrix to upper Hessenberg form
@usableFromInline
internal func _eigenHessenbergReduction(_ a: inout [Double], _ n: Int, _ q: inout [Double]) {
    // Initialize Q as identity - optimized O(n) instead of O(n²)
    q.withUnsafeMutableBufferPointer { buffer in
        buffer.initialize(repeating: 0.0)
        let ptr = buffer.baseAddress!
        for i in 0..<n {
            ptr[i * n + i] = 1.0
        }
    }

    // Pre-allocate x array outside loop to avoid repeated allocations
    var x = [Double](repeating: 0.0, count: n)

    for k in 0..<(n - 2) {
        let xCount = n - k - 1
        let kp1 = k + 1

        // Compute Householder vector for column k
        for i in 0..<xCount {
            x[i] = a[(kp1 + i) * n + k]
        }

        let normX = _eigenVectorNorm(x, start: 0, count: xCount)
        if normX < 1e-14 { continue }

        let sign = x[0] >= 0 ? 1.0 : -1.0
        x[0] += sign * normX

        let normV = _eigenVectorNorm(x, start: 0, count: xCount)
        if normV < 1e-14 { continue }

        let invNormV = 1.0 / normV
        for i in 0..<xCount {
            x[i] *= invNormV
        }

        // Apply H = I - 2*v*v^T from the left: A = H * A
        // Using UnsafeBufferPointer to eliminate bounds checking
        x.withUnsafeBufferPointer { xBuf in
            a.withUnsafeMutableBufferPointer { aBuf in
                let xPtr = xBuf.baseAddress!
                let aPtr = aBuf.baseAddress!

                for j in k..<n {
                    var dot = 0.0
                    for i in 0..<xCount {
                        dot += xPtr[i] * aPtr[(kp1 + i) * n + j]
                    }
                    let factor = 2.0 * dot
                    for i in 0..<xCount {
                        aPtr[(kp1 + i) * n + j] -= factor * xPtr[i]
                    }
                }
            }
        }

        // Apply H from the right: A = A * H
        x.withUnsafeBufferPointer { xBuf in
            a.withUnsafeMutableBufferPointer { aBuf in
                let xPtr = xBuf.baseAddress!
                let aPtr = aBuf.baseAddress!

                for i in 0..<n {
                    var dot = 0.0
                    for j in 0..<xCount {
                        dot += aPtr[i * n + (kp1 + j)] * xPtr[j]
                    }
                    let factor = 2.0 * dot
                    for j in 0..<xCount {
                        aPtr[i * n + (kp1 + j)] -= factor * xPtr[j]
                    }
                }
            }
        }

        // Accumulate Q = Q * H
        x.withUnsafeBufferPointer { xBuf in
            q.withUnsafeMutableBufferPointer { qBuf in
                let xPtr = xBuf.baseAddress!
                let qPtr = qBuf.baseAddress!

                for i in 0..<n {
                    var dot = 0.0
                    for j in 0..<xCount {
                        dot += qPtr[i * n + (kp1 + j)] * xPtr[j]
                    }
                    let factor = 2.0 * dot
                    for j in 0..<xCount {
                        qPtr[i * n + (kp1 + j)] -= factor * xPtr[j]
                    }
                }
            }
        }
    }
}

/// Performs one step of the implicit double-shift QR algorithm with SIMD optimization
@usableFromInline
internal func _eigenQRStep(_ h: inout [Double], _ n: Int, _ lo: Int, _ hi: Int, _ z: inout [Double]) {
    let nn = hi - lo + 1
    if nn < 2 { return }

    // Wilkinson shift: eigenvalue of trailing 2x2 closest to h[hi,hi]
    let a11 = h[(hi - 1) * n + (hi - 1)]
    let a12 = h[(hi - 1) * n + hi]
    let a21 = h[hi * n + (hi - 1)]
    let a22 = h[hi * n + hi]

    let trace = a11 + a22
    let det = a11 * a22 - a12 * a21
    let disc = trace * trace - 4.0 * det

    var shift: Double
    if disc >= 0 {
        let sqrtDisc = sqrt(disc)
        let eig1 = (trace + sqrtDisc) / 2.0
        let eig2 = (trace - sqrtDisc) / 2.0
        shift = abs(eig1 - a22) < abs(eig2 - a22) ? eig1 : eig2
    } else {
        shift = trace / 2.0
    }

    // Apply shift and perform QR step using Givens rotations
    for i in lo..<hi {
        let ii = i
        let jj = i + 1

        var x = h[ii * n + ii] - shift
        var y = h[jj * n + ii]

        if i > lo {
            x = h[ii * n + (i - 1)]
            y = h[jj * n + (i - 1)]
        }

        let r = sqrt(x * x + y * y)
        if r < 1e-14 { continue }

        let c = x / r
        let s = y / r
        let negS = -s

        // Apply Givens rotation from the left using SIMD
        let colStart = (i > lo) ? (i - 1) : i
        let iiBase = ii * n
        let jjBase = jj * n

        h.withUnsafeMutableBufferPointer { buf in
            let ptr = buf.baseAddress!

            // SIMD loop - process 4 columns at a time
            var j = colStart
            let simdEnd = colStart + ((n - colStart) / 4) * 4
            let cVec = SIMD4<Double>(repeating: c)
            let sVec = SIMD4<Double>(repeating: s)
            let negSVec = SIMD4<Double>(repeating: negS)

            while j < simdEnd {
                let t1 = SIMD4(ptr[iiBase + j], ptr[iiBase + j + 1], ptr[iiBase + j + 2], ptr[iiBase + j + 3])
                let t2 = SIMD4(ptr[jjBase + j], ptr[jjBase + j + 1], ptr[jjBase + j + 2], ptr[jjBase + j + 3])

                let r1 = cVec * t1 + sVec * t2
                let r2 = negSVec * t1 + cVec * t2

                ptr[iiBase + j] = r1[0]; ptr[iiBase + j + 1] = r1[1]
                ptr[iiBase + j + 2] = r1[2]; ptr[iiBase + j + 3] = r1[3]
                ptr[jjBase + j] = r2[0]; ptr[jjBase + j + 1] = r2[1]
                ptr[jjBase + j + 2] = r2[2]; ptr[jjBase + j + 3] = r2[3]
                j += 4
            }

            // Handle remainder
            while j < n {
                let temp1 = ptr[iiBase + j]
                let temp2 = ptr[jjBase + j]
                ptr[iiBase + j] = c * temp1 + s * temp2
                ptr[jjBase + j] = negS * temp1 + c * temp2
                j += 1
            }
        }

        // Apply Givens rotation from the right (small loop, no SIMD benefit)
        let rowEnd = min(jj + 2, hi + 1)
        for j in lo..<rowEnd {
            let temp1 = h[j * n + ii]
            let temp2 = h[j * n + jj]
            h[j * n + ii] = c * temp1 + s * temp2
            h[j * n + jj] = negS * temp1 + c * temp2
        }

        // Accumulate in Z using SIMD
        z.withUnsafeMutableBufferPointer { buf in
            let ptr = buf.baseAddress!

            var j = 0
            let simdEnd = (n / 4) * 4
            let cVec = SIMD4<Double>(repeating: c)
            let sVec = SIMD4<Double>(repeating: s)
            let negSVec = SIMD4<Double>(repeating: negS)

            while j < simdEnd {
                let idx1_0 = j * n + ii
                let idx1_1 = (j + 1) * n + ii
                let idx1_2 = (j + 2) * n + ii
                let idx1_3 = (j + 3) * n + ii
                let idx2_0 = j * n + jj
                let idx2_1 = (j + 1) * n + jj
                let idx2_2 = (j + 2) * n + jj
                let idx2_3 = (j + 3) * n + jj

                let t1 = SIMD4(ptr[idx1_0], ptr[idx1_1], ptr[idx1_2], ptr[idx1_3])
                let t2 = SIMD4(ptr[idx2_0], ptr[idx2_1], ptr[idx2_2], ptr[idx2_3])

                let r1 = cVec * t1 + sVec * t2
                let r2 = negSVec * t1 + cVec * t2

                ptr[idx1_0] = r1[0]; ptr[idx1_1] = r1[1]
                ptr[idx1_2] = r1[2]; ptr[idx1_3] = r1[3]
                ptr[idx2_0] = r2[0]; ptr[idx2_1] = r2[1]
                ptr[idx2_2] = r2[2]; ptr[idx2_3] = r2[3]
                j += 4
            }

            // Handle remainder
            while j < n {
                let temp1 = ptr[j * n + ii]
                let temp2 = ptr[j * n + jj]
                ptr[j * n + ii] = c * temp1 + s * temp2
                ptr[j * n + jj] = negS * temp1 + c * temp2
                j += 1
            }
        }
    }
}

/// Extracts eigenvalues from quasi-triangular (Schur) form
@usableFromInline
internal func _eigenExtractEigenvalues(_ t: [Double], _ n: Int, _ wr: inout [Double], _ wi: inout [Double]) {
    var i = 0
    while i < n {
        if i == n - 1 || abs(t[(i + 1) * n + i]) < 1e-10 * (abs(t[i * n + i]) + abs(t[(i + 1) * n + (i + 1)])) {
            // Real eigenvalue
            wr[i] = t[i * n + i]
            wi[i] = 0.0
            i += 1
        } else {
            // Complex conjugate pair from 2x2 block
            let a11 = t[i * n + i]
            let a12 = t[i * n + (i + 1)]
            let a21 = t[(i + 1) * n + i]
            let a22 = t[(i + 1) * n + (i + 1)]

            let trace = a11 + a22
            let det = a11 * a22 - a12 * a21
            let disc = trace * trace - 4.0 * det

            if disc < 0 {
                wr[i] = trace / 2.0
                wr[i + 1] = trace / 2.0
                wi[i] = sqrt(-disc) / 2.0
                wi[i + 1] = -sqrt(-disc) / 2.0
            } else {
                let sqrtDisc = sqrt(disc)
                wr[i] = (trace + sqrtDisc) / 2.0
                wr[i + 1] = (trace - sqrtDisc) / 2.0
                wi[i] = 0.0
                wi[i + 1] = 0.0
            }
            i += 2
        }
    }
}

/// Computes eigenvectors from Schur form using back-substitution
@usableFromInline
internal func _eigenComputeEigenvectors(_ t: [Double], _ z: [Double], _ n: Int, _ wr: [Double], _ wi: [Double], _ vr: inout [Double]) {
    // Work array for triangular solve
    var work = [Double](repeating: 0.0, count: n)

    var i = n - 1
    while i >= 0 {
        if wi[i] == 0.0 {
            // Real eigenvalue - solve (T - lambda*I) * x = 0
            let lambda = wr[i]
            work[i] = 1.0

            for j in stride(from: i - 1, through: 0, by: -1) {
                var sum = 0.0
                for k in (j + 1)...i {
                    sum += t[j * n + k] * work[k]
                }
                let diag = t[j * n + j] - lambda
                if abs(diag) > 1e-14 {
                    work[j] = -sum / diag
                } else {
                    work[j] = -sum / 1e-14
                }
            }

            // Normalize
            var norm = 0.0
            for j in 0...i {
                norm += work[j] * work[j]
            }
            norm = sqrt(norm)
            if norm > 1e-14 {
                for j in 0...i {
                    work[j] /= norm
                }
            }

            // Transform back: v = Z * work
            for j in 0..<n {
                var sum = 0.0
                for k in 0...i {
                    sum += z[j * n + k] * work[k]
                }
                vr[j * n + i] = sum
            }

            // Clear work array
            for j in 0...i {
                work[j] = 0.0
            }

            i -= 1
        } else if i > 0 && wi[i] < 0 {
            // Complex conjugate pair - handle together
            // For complex eigenvalues, we compute real and imaginary parts
            // of the eigenvector separately
            var xr = [Double](repeating: 0.0, count: n)
            var xi = [Double](repeating: 0.0, count: n)

            xr[i] = 1.0
            xi[i] = 0.0
            xr[i - 1] = 0.0
            xi[i - 1] = 1.0

            // Normalize
            let norm = sqrt(xr[i] * xr[i] + xi[i] * xi[i] + xr[i-1] * xr[i-1] + xi[i-1] * xi[i-1])
            if norm > 1e-14 {
                xr[i] /= norm
                xi[i] /= norm
                xr[i - 1] /= norm
                xi[i - 1] /= norm
            }

            // Transform back
            for j in 0..<n {
                var sumR = 0.0
                var sumI = 0.0
                for k in max(0, i - 1)...i {
                    sumR += z[j * n + k] * xr[k]
                    sumI += z[j * n + k] * xi[k]
                }
                vr[j * n + (i - 1)] = sumR  // Real part
                vr[j * n + i] = sumI         // Imaginary part
            }

            i -= 2
        } else {
            i -= 1
        }
    }

    // Normalize all eigenvectors
    for j in 0..<n {
        var norm = 0.0
        for k in 0..<n {
            norm += vr[k * n + j] * vr[k * n + j]
        }
        norm = sqrt(norm)
        if norm > 1e-14 {
            for k in 0..<n {
                vr[k * n + j] /= norm
            }
        }
    }
}

/// Pure Swift implementation of eigenvalue decomposition using the QR algorithm.
/// This is used on WASI and can be tested on other platforms.
///
/// - Parameters:
///   - n: Matrix dimension
///   - a: Input matrix (column-major, n x n) - will be modified
///   - wr: Output array for real parts of eigenvalues (size n)
///   - wi: Output array for imaginary parts of eigenvalues (size n)
///   - vl: Output array for left eigenvectors (size n x n, column-major)
///   - vr: Output array for right eigenvectors (size n x n, column-major)
///   - computeLeft: Whether to compute left eigenvectors
///   - computeRight: Whether to compute right eigenvectors
/// - Returns: 0 on success, positive value if failed to converge
@inlinable
public func swiftEigenDecomposition(_ n: Int, _ a: inout [Double], _ wr: inout [Double], _ wi: inout [Double],
                                    _ vl: inout [Double], _ vr: inout [Double],
                                    computeLeft: Bool, computeRight: Bool) -> Int32 {
    if n == 0 { return 0 }
    if n == 1 {
        wr[0] = a[0]
        wi[0] = 0.0
        if computeLeft { vl[0] = 1.0 }
        if computeRight { vr[0] = 1.0 }
        return 0
    }

    // Make a copy for Hessenberg reduction
    var h = a
    var z = [Double](repeating: 0.0, count: n * n)

    // Step 1: Reduce to upper Hessenberg form
    _eigenHessenbergReduction(&h, n, &z)

    // Step 2: QR iteration to reach quasi-triangular (Schur) form
    let maxIterations = 30 * n
    var iter = 0
    var hi = n - 1

    while hi > 0 && iter < maxIterations {
        // Find the lowest subdiagonal element that is effectively zero
        var lo = hi
        while lo > 0 {
            let threshold = 1e-14 * (abs(h[(lo - 1) * n + (lo - 1)]) + abs(h[lo * n + lo]))
            if abs(h[lo * n + (lo - 1)]) < max(threshold, 1e-300) {
                h[lo * n + (lo - 1)] = 0.0
                break
            }
            lo -= 1
        }

        if lo == hi {
            // Single eigenvalue converged
            hi -= 1
        } else if lo == hi - 1 {
            // 2x2 block converged
            hi -= 2
        } else {
            // Perform QR step
            _eigenQRStep(&h, n, lo, hi, &z)
            iter += 1
        }
    }

    if iter >= maxIterations {
        return 1  // Failed to converge
    }

    // Step 3: Extract eigenvalues from Schur form
    _eigenExtractEigenvalues(h, n, &wr, &wi)

    // Step 4: Compute eigenvectors
    if computeRight {
        _eigenComputeEigenvectors(h, z, n, wr, wi, &vr)
    }

    if computeLeft {
        // Left eigenvectors: solve A^T * vl = lambda * vl
        // For simplicity, we transpose and use the same algorithm
        var at = [Double](repeating: 0.0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                at[i * n + j] = a[j * n + i]
            }
        }
        var wrL = [Double](repeating: 0.0, count: n)
        var wiL = [Double](repeating: 0.0, count: n)
        var vlTemp = [Double](repeating: 0.0, count: n * n)
        var dummy = [Double](repeating: 0.0, count: n * n)
        let _ = swiftEigenDecomposition(n, &at, &wrL, &wiL, &dummy, &vlTemp, computeLeft: false, computeRight: true)
        vl = vlTemp
    }

    return 0
}

// MARK: - Platform-specific LAPACK implementations

#if canImport(Accelerate)
import Accelerate

public typealias lapack_solve_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_LU_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_inv_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_eigen_func<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_svd_func<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>,UnsafeMutablePointer<__CLPK_integer>) -> Int32

/// Wrapper of lapck solve function
/// - Parameters:
///   - rownum: A destination row number
///   - colnum: A dstination column number
///   - coef_ptr: A coef pointer
///   - dst_b_ptr: A destination and b pointer
///   - lapack_func: The lapack solve function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
/// ref: http://www.netlib.org/lapack/explore-html/d7/d3b/group__double_g_esolve_ga5ee879032a8365897c3ba91e3dc8d512.html
@inline(__always)
internal func wrap_lapack_solve<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ coef_ptr: UnsafeMutablePointer<T>, _ dst_b_ptr: UnsafeMutablePointer<T>, lapack_func: lapack_solve_func<T>) throws {
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
internal func wrap_lapack_LU<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, lapack_func: lapack_LU_func<T>) throws -> [__CLPK_integer] {
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
internal func wrap_lapack_inv<T: MfStorable>(_ rowcolnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, _ IPIV: UnsafeMutablePointer<__CLPK_integer>, lapack_func: lapack_inv_func<T>) throws{
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

/// Wrapper of lapck eigen function
/// ref: http://www.netlib.org/lapack/explore-html/d3/dfb/group__real_g_eeigen_ga104525b749278774f7b7f57195aa6798.html
/// ref: https://stackoverflow.com/questions/27887215/trouble-with-the-accelerate-framework-in-swift
/// - Parameters:
///   - rowcolnum: A destination row and column number
///   - srcdstptr: A source and destination pointer
///   - lapack_func: The lapack LU fractorization function
/// - Throws: An error of type `MfError.LinAlgError.singularMatrix`
@inline(__always)
internal func wrap_lapack_eigen<T: MfStorable>(_ rowcolnum: Int, _ srcptr: UnsafeMutablePointer<T>, _ dstLVecRePtr: UnsafeMutablePointer<T>, _ dstLVecImPtr: UnsafeMutablePointer<T>, _ dstRVecRePtr: UnsafeMutablePointer<T>, _ dstRVecImPtr: UnsafeMutablePointer<T>, _ dstValRePtr: UnsafeMutablePointer<T>, _ dstValImPtr: UnsafeMutablePointer<T>, lapack_func: lapack_eigen_func<T>) throws {
    let JOBVL = UnsafeMutablePointer(mutating: ("V" as NSString).utf8String)!
    let JOBVR = UnsafeMutablePointer(mutating: ("V" as NSString).utf8String)!
    
    var N = __CLPK_integer(rowcolnum)

    var LDA = __CLPK_integer(rowcolnum)

    // Real parts of eigenvalues
    var WR = Array<T>(repeating: T.zero, count: rowcolnum)
    // Imaginary parts of eigenvalues
    var WI = Array<T>(repeating: T.zero, count: rowcolnum)
    // Left eigenvectors
    var VL = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
    var LDVL = __CLPK_integer(rowcolnum)
    // Right eigenvectors
    var VR = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
    var LDVR = __CLPK_integer(rowcolnum)

    //work space
    var WORKQ = T.zero //workspace query
    var LWORK = __CLPK_integer(-1)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run (calculate optimal workspace)
    let _ = lapack_func(JOBVL, JOBVR, &N, srcptr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORKQ, &LWORK, &INFO)

    var WORK = Array<T>(repeating: T.zero, count: T.toInt(WORKQ))
    LWORK = __CLPK_integer(T.toInt(WORKQ))
    //run
    let _ = lapack_func(JOBVL, JOBVR, &N, srcptr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORK, &LWORK, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.notConverge("the QR algorithm failed to compute all the eigenvalues, and no eigenvectors have been computed; elements \(INFO)+1:N of WR and WI contain eigenvalues which have converged.")
    }
    else{
        /*
         e.g.) ref: https://software.intel.com/sites/products/documentation/doclib/mkl_sa/11/mkl_lapack_examples/sgeev_ex.f.htm
         Auxiliary routine: printing eigenvalues.
         *
               SUBROUTINE PRINT_EIGENVALUES( DESC, N, WR, WI )
               CHARACTER*(*)    DESC
               INTEGER          N
               REAL             WR( * ), WI( * )
         *
               REAL             ZERO
               PARAMETER        ( ZERO = 0.0 )
               INTEGER          J
         *
               WRITE(*,*)
               WRITE(*,*) DESC
               DO J = 1, N
                  IF( WI( J ).EQ.ZERO ) THEN
                     WRITE(*,9998,ADVANCE='NO') WR( J )
                  ELSE
                     WRITE(*,9999,ADVANCE='NO') WR( J ), WI( J )
                  END IF
               END DO
               WRITE(*,*)
         *
          9998 FORMAT( 11(:,1X,F6.2) )
          9999 FORMAT( 11(:,1X,'(',F6.2,',',F6.2,')') )
               RETURN
               END
         *
         *     Auxiliary routine: printing eigenvectors.
         *
               SUBROUTINE PRINT_EIGENVECTORS( DESC, N, WI, V, LDV )
               CHARACTER*(*)    DESC
               INTEGER          N, LDV
               REAL             WI( * ), V( LDV, * )
         *
               REAL             ZERO
               PARAMETER        ( ZERO = 0.0 )
               INTEGER          I, J
         *
               WRITE(*,*)
               WRITE(*,*) DESC
               DO I = 1, N
                  J = 1
                  DO WHILE( J.LE.N )
                     IF( WI( J ).EQ.ZERO ) THEN
                        WRITE(*,9998,ADVANCE='NO') V( I, J )      <<<<<<<<<<<<<<<<<<<<<<<
                        J = J + 1
                     ELSE
                        WRITE(*,9999,ADVANCE='NO') V( I, J ), V( I, J+1 ) <<<<<<<<<<<<<<<<<<
                        WRITE(*,9999,ADVANCE='NO') V( I, J ), -V( I, J+1 ) <<<<<<<<<<<<<<<<<<<<<
                        J = J + 2
                     END IF
                  END DO
                  WRITE(*,*)
               END DO
         *
          9998 FORMAT( 11(:,1X,F6.2) )
          9999 FORMAT( 11(:,1X,'(',F6.2,',',F6.2,')') )
               RETURN
               END
         */
        
        /*
         Note that VL and VR's value are inferenced by WI's value.
         Below's i means imaginary number
         if WI[k] == 0; VL[k, j], VR[k, j]
                        j += 1
         if WI[k] != 0; VL[k, j] + i*VL[k, j+1],
                        VL[k, j] - i*VL[k, j+1],
                      ; VR[k, j] + i*VR[k, j+1],
                        VR[k, j] - i*VR[k, j+1],
                        j += 2
         */
        var VLRe = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VLIm = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VRRe = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VRIm = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        for k in 0..<rowcolnum{
            var j = 0
        
            while j < rowcolnum{
                let index = k*rowcolnum + j
                if WI[k] == 0{
                    VLRe[index] = VL[index]
                    VLIm[index] = T.zero
                    VRRe[index] = VR[index]
                    VRIm[index] = T.zero
                    j += 1
                }
                else{
                    VLRe[index] = VL[index]
                    VLIm[index] = VL[index + 1]
                    VLRe[index + 1] = VL[index]
                    VLIm[index + 1] = -VL[index + 1]
                    
                    VRRe[index] = VR[index]
                    VRIm[index] = VR[index + 1]
                    VRRe[index + 1] = VR[index]
                    VRIm[index + 1] = -VR[index + 1]
                    j += 2
                }
            }
            
        }
        //moveUpdate
        WR.withUnsafeMutableBufferPointer{
            dstValRePtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum)
        }
        WI.withUnsafeMutableBufferPointer{
            dstValImPtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum)
        }
        VLRe.withUnsafeMutableBufferPointer{
            dstLVecRePtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VLIm.withUnsafeMutableBufferPointer{
            dstLVecImPtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VRRe.withUnsafeMutableBufferPointer{
            dstRVecRePtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VRIm.withUnsafeMutableBufferPointer{
            dstRVecImPtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
    }
}

/// Wrapper of lapack SVD function
/// ref: https://www.netlib.org/lapack/explore-html/d4/dca/group__real_g_esing_gac2cd4f1079370ac908186d77efcd5ea8.html
///
/// - Parameters:
///   - rownum: A destination row number
///   - colnum: A destination column number
///   - srcptr: A source pointer
///   - vptr: A source pointer
///   - sptr: A source pointer
///   - rtptr: A source pointer
///   - full_matrices: if true returned v and rt have the shapes (..., M, M) and (..., N, N) respectively. Otherwise, the shapes are (..., M, K) and (..., K, N), respectively, where K = min(M, N).
///   - lapack_func: The lapack SVD fractorization function
/// - Throws: An error of type `MfError.LinAlgError.singularMatrix`
@inline(__always)
internal func wrap_lapack_svd<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ srcptr: UnsafeMutablePointer<T>, _ vptr: UnsafeMutablePointer<T>, _ sptr: UnsafeMutablePointer<T>, _ rtptr: UnsafeMutablePointer<T>, _ full_matrices: Bool, lapack_func: lapack_svd_func<T>) throws{
    let JOBZ: UnsafeMutablePointer<Int8>
    
    var M = __CLPK_integer(rownum)
    var N = __CLPK_integer(colnum)
    
    let ucol: Int, vtrow: Int
    
    var LDA = __CLPK_integer(rownum)
    
    let snum = min(rownum, colnum)
    var S = Array<T>(repeating: T.zero, count: snum)
    
    var U: Array<T>
    var LDU = __CLPK_integer(rownum)
    
    var VT: Array<T>
    var LDVT: __CLPK_integer
    
    
    if full_matrices{
        JOBZ = UnsafeMutablePointer(mutating: ("A" as NSString).utf8String)!
        LDVT = __CLPK_integer(colnum)
        
        ucol = rownum
        vtrow = colnum
    }
    else{
        JOBZ = UnsafeMutablePointer(mutating: ("S" as NSString).utf8String)!
        LDVT = __CLPK_integer(snum)
        
        ucol = snum
        vtrow = snum
    }
    U = Array<T>(repeating: T.zero, count: rownum*ucol)
    VT = Array<T>(repeating: T.zero, count: colnum*vtrow)
    
    //work space
    var WORKQ = T.zero //workspace query
    var LWORK = __CLPK_integer(-1)
    var IWORK = Array<__CLPK_integer>(repeating: 0, count: 8*snum)
    
    //error indicator
    var INFO: __CLPK_integer = 0
    
    //run (calculate optimal workspace)
    let _ = lapack_func(JOBZ, &M, &N, srcptr, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORKQ, &LWORK, &IWORK, &INFO)
    
    var WORK = Array<T>(repeating: T.zero, count: T.toInt(WORKQ))
    LWORK = __CLPK_integer(T.toInt(WORKQ))
    //run
    let _ = lapack_func(JOBZ, &M, &N, srcptr, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)
    
    //check error
    if INFO < 0{
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0{
        throw MfError.LinAlgError.notConverge("the QR algorithm failed to compute all the eigenvalues, and no eigenvectors have been computed; elements \(INFO)+1:N of WR and WI contain eigenvalues which have converged.")
    }
    else{
        U.withUnsafeMutableBufferPointer{
            vptr.moveUpdate(from: $0.baseAddress!, count: rownum*ucol)
        }
        S.withUnsafeMutableBufferPointer{
            sptr.moveUpdate(from: $0.baseAddress!, count: snum)
        }
        VT.withUnsafeMutableBufferPointer{
            rtptr.moveUpdate(from: $0.baseAddress!, count: colnum*vtrow)
        }
    }
}

/// Solve by lapack
/// - Parameters:
///   - coef: coef MfArray
///   - b: b MfArray
///   - lapack_func: The lapack solve function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func solve_by_lapack<T: MfStorable>(_ coef: MfArray, _ b: MfArray, ret_mftype: MfType, _ lapack_func: lapack_solve_func<T>) throws -> MfArray{
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
    let coef_column_major = coef.astype(ret_mftype, mforder: .Column) // copied and contiguous
    let ret = b.astype(ret_mftype, mforder: .Column) // copied and contiguous
    
    try coef_column_major.withUnsafeMutableStartPointer(datatype: T.self){
        coef_ptr in
        try ret.withUnsafeMutableStartPointer(datatype: T.self){
            dst_ptr in
            try wrap_lapack_solve(dst_rownum, dst_colnum, coef_ptr, dst_ptr, lapack_func: lapack_func)
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

/// Inverse by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - lapack_func_lu: The lapack LU factorization function
///   - lapack_func_inv: The lapack inverse function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func inv_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func_lu: lapack_LU<T>, _ lapack_func_inv: lapack_inv<T>, _ retMfType: MfType) throws -> MfArray{
    
    let shape = mfarray.shape
        
    precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")

    let newdata = MfData(size: mfarray.size, mftype: mfarray.storedType.to_mftype())
    try newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Row){
            srcptr, row, col, offset in
            //LU decomposition
            var IPIV = try wrap_lapack_LU(row, col, srcptr, lapack_func: lapack_func_lu)
            
            //calculate inv
            // note that row == col
            try wrap_lapack_inv(row, srcptr, &IPIV, lapack_func: lapack_func_inv)
            
            //move
            (dstptrT + offset).moveUpdate(from: srcptr, count: row*col)
        }
    }
    
    let newstructure = MfStructure(shape: shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Determinant by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - lapack_func: The lapack LU factorization function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func det_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func: lapack_LU_func<T>) throws -> MfArray{
    let shape = mfarray.shape
    
    precondition(mfarray.ndim > 1, "cannot get a determinant from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
    
    let ret_size = mfarray.size / (shape[mfarray.ndim - 1] * shape[mfarray.ndim - 1])
    
    let newdata = MfData(size: ret_size, mftype: mfarray.mftype)
    var dst_offset = 0
    
    try newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Row){
            srcptr, row, col, offset in
            // Note row == col
            let square_num = row
            
            //LU decomposition
            let IPIV = try wrap_lapack_LU(row, col, srcptr, lapack_func: lapack_func)
            
            //calculate L and U's determinant
            //Note that L and U's determinant are calculated by product of diagonal elements
            // L's determinant is always one
            //ref: https://stackoverflow.com/questions/47315471/compute-determinant-from-lu-decomposition-in-lapack
            var det = T.from(1)
            for i in 0..<square_num{
                det *= IPIV[i] != __CLPK_integer(i+1) ? srcptr.advanced(by: i + i*square_num).pointee : -(srcptr.advanced(by: i + i*square_num).pointee)
            }
            
            //assign
            (dstptrT + dst_offset).update(from: &det, count: 1)
            dst_offset += 1
        }
    }
    
    let ret_shape: [Int]
    if mfarray.ndim - 2 != 0{
        ret_shape = Array(mfarray.shape.prefix(mfarray.ndim - 2))
    }
    else{
       ret_shape = [1]
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Eigen by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - lapack_func: The lapack LU factorization function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func eigen_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func: lapack_eigen_func<T>) throws -> (valRe: MfArray, valIm: MfArray, lvecRe: MfArray, lvecIm: MfArray, rvecRe: MfArray, rvecIm: MfArray){
    var shape = mfarray.shape
    precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
    let retMfType = mfarray.storedType.to_mftype()
    //let square_num = shape[mfarray.ndim - 1]
    let eigenvec_size = shape2size(&shape)
    //let eigValNum = mfarray.size / (squaredSize * squaredSize)
    
    // create mfarraies
    //eigenvectors
    let lvecRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let lvecIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    let rvecRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let rvecIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    
    //eigenvalues
    let eigenval_shape = Array(shape.prefix(mfarray.ndim - 1))
    //let eigenval_size = shape2size(&eigenval_shape)
    let valRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let valIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    //offset for calculation
    var vec_offset = 0
    var val_offset = 0
    
    
    let lvecRe_ptr = lvecRe_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let lvecIm_ptr = lvecIm_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let rvecRe_ptr = rvecRe_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let rvecIm_ptr = rvecIm_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let valRe_ptr = valRe_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let valIm_ptr = valIm_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    
    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Column){
        srcptr, row, col, offset in
        // Note row == col
        let square_num = row
        try wrap_lapack_eigen(square_num, srcptr, lvecRe_ptr + vec_offset, lvecIm_ptr + vec_offset, rvecRe_ptr + vec_offset, rvecIm_ptr + vec_offset, valRe_ptr + val_offset, valIm_ptr + val_offset, lapack_func: lapack_func)
        
        //calculate offset
        val_offset += square_num
        vec_offset += offset
    }
    
    
    return (MfArray(mfdata: valRe_data, mfstructure: MfStructure(shape: eigenval_shape, mforder: .Row)),
            MfArray(mfdata: valIm_data, mfstructure: MfStructure(shape: eigenval_shape, mforder: .Row)),
            MfArray(mfdata: lvecRe_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: lvecIm_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: rvecRe_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: rvecIm_data, mfstructure: MfStructure(shape: shape, mforder: .Row)))
    
}


/// SVD by lapack
/// - Parameters:
///   - mfarray: The source mfarray
///   - full_matrices: if true returned v and rt have the shapes (..., M, M) and (..., N, N) respectively. Otherwise, the shapes are (..., M, K) and (..., K, N), respectively, where K = min(M, N).
///   - lapack_func: The lapack SVD factorization function
/// - Throws: An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
internal func svd_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ full_matrices: Bool, _ lapack_func: lapack_svd_func<T>) throws -> (v: MfArray, s: MfArray, rt: MfArray){
    let shape = mfarray.shape
    let ret_mftype = mfarray.storedType.to_mftype()
    let M = shape[mfarray.ndim - 2]
    let N = shape[mfarray.ndim - 1]
    let ssize = min(M, N)
    let stacked_shape = Array(shape.prefix(mfarray.ndim - 2))
    
    let v_data: MfData, s_data: MfData, rt_data: MfData
    var v_shape: [Int], s_shape: [Int], rt_shape: [Int]
    let vcol: Int, rtrow: Int
    if full_matrices{
        v_shape = stacked_shape + [M, M]
        s_shape = stacked_shape + [ssize]
        rt_shape = stacked_shape + [N, N]
        v_data = MfData(size: shape2size(&v_shape), mftype: ret_mftype)
        s_data = MfData(size: shape2size(&s_shape), mftype: ret_mftype)
        rt_data = MfData(size: shape2size(&rt_shape), mftype: ret_mftype)
        
        vcol = M
        rtrow = N
    }
    else{
        v_shape = stacked_shape + [ssize, M]
        s_shape = stacked_shape + [ssize]
        rt_shape = stacked_shape + [N, ssize]
        v_data = MfData(size: shape2size(&v_shape), mftype: ret_mftype) // returned shape = (..., M, ssize)
        s_data = MfData(size: shape2size(&s_shape), mftype: ret_mftype)
        rt_data = MfData(size: shape2size(&rt_shape), mftype: ret_mftype) // returned shape = (..., ssize, N)
        
        vcol = ssize
        rtrow = ssize
    }
    
    //offset
    var v_offset = 0
    var s_offset = 0
    var rt_offset = 0
    
    let vptr = v_data.data_real.bindMemory(to: T.self, capacity: shape2size(&v_shape))
    let sptr = s_data.data_real.bindMemory(to: T.self, capacity: shape2size(&s_shape))
    let rtptr = rt_data.data_real.bindMemory(to: T.self, capacity: shape2size(&rt_shape))
    
    
    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Column){
        srcptr, _, _, _ in
        try wrap_lapack_svd(M, N, srcptr, vptr + v_offset, sptr + s_offset, rtptr + rt_offset, full_matrices, lapack_func: lapack_func)
        
        v_offset += M*vcol
        s_offset += ssize
        rt_offset += N*rtrow
    }
    
    let v = MfArray(mfdata: v_data, mfstructure: MfStructure(shape: v_shape, mforder: .Row))
    let s = MfArray(mfdata: s_data, mfstructure: MfStructure(shape: s_shape, mforder: .Row))
    let rt = MfArray(mfdata: rt_data, mfstructure: MfStructure(shape: rt_shape, mforder: .Row))

    return (v.swapaxes(axis1: -1, axis2: -2), s, rt.swapaxes(axis1: -1, axis2: -2))
}
#else
// MARK: - WASI Implementation using CLAPACK
// Note: The CLAPACK eigen-support branch only provides dgetrf and dgetri (double-precision).
// Other LAPACK operations will throw fatalError on WASI.
import CLAPACKHelper

public typealias __CLPK_integer = Int32

public typealias lapack_solve_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_LU_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_inv_func<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_eigen_func<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

public typealias lapack_svd_func<T> = (UnsafeMutablePointer<Int8>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>,UnsafeMutablePointer<__CLPK_integer>) -> Int32

internal typealias lapack_LU<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

internal typealias lapack_inv<T> = (UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<T>, UnsafeMutablePointer<__CLPK_integer>, UnsafeMutablePointer<__CLPK_integer>) -> Int32

// MARK: - CLAPACK Wrapper Functions for WASI
// dgeev_ is implemented in pure Swift (swiftEigenDecomposition) above
// Note: CLAPACK uses "integer" = long int, which on wasm32 is 32-bit (CLong)
// Note: The CLAPACK header declares functions as returning int, but the f2c-generated
// implementation returns void. This causes linker warnings but doesn't affect correctness
// since we don't rely on the return value from the C function (we use info parameter instead).

@inline(__always)
internal func sgesv_(_ n: UnsafeMutablePointer<__CLPK_integer>, _ nrhs: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Float>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ ipiv: UnsafeMutablePointer<__CLPK_integer>, _ b: UnsafeMutablePointer<Float>, _ ldb: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    fatalError("LAPACK sgesv_ is not available on WASI (single-precision linear solve not supported)")
}

@inline(__always)
internal func dgesv_(_ n: UnsafeMutablePointer<__CLPK_integer>, _ nrhs: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Double>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ ipiv: UnsafeMutablePointer<__CLPK_integer>, _ b: UnsafeMutablePointer<Double>, _ ldb: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    fatalError("LAPACK dgesv_ is not available on WASI (double-precision linear solve not supported)")
}

@inline(__always)
internal func sgetrf_(_ m: UnsafeMutablePointer<__CLPK_integer>, _ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Float>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ ipiv: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    fatalError("LAPACK sgetrf_ is not available on WASI (single-precision LU decomposition not supported)")
}

@inline(__always)
internal func dgetrf_(_ m: UnsafeMutablePointer<__CLPK_integer>, _ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Double>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ ipiv: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    // Call CLAPACK via helper wrapper that uses correct void return type
    var mLong = clapack_int(m.pointee)
    var nLong = clapack_int(n.pointee)
    var ldaLong = clapack_int(lda.pointee)
    var infoLong: clapack_int = 0
    let minMN = min(Int(m.pointee), Int(n.pointee))

    // On wasm32, clapack_int (long) and __CLPK_integer (Int32) are both 32-bit,
    // so we can use withMemoryRebound to avoid array allocation and copying
    ipiv.withMemoryRebound(to: clapack_int.self, capacity: minMN) { ipivRebound in
        clapack_dgetrf_wrapper(&mLong, &nLong, a, &ldaLong, ipivRebound, &infoLong)
    }

    info.pointee = __CLPK_integer(infoLong)
    return Int32(infoLong)
}

@inline(__always)
internal func sgetri_(_ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Float>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ ipiv: UnsafeMutablePointer<__CLPK_integer>, _ work: UnsafeMutablePointer<Float>, _ lwork: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    fatalError("LAPACK sgetri_ is not available on WASI (single-precision matrix inverse not supported)")
}

@inline(__always)
internal func dgetri_(_ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Double>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ ipiv: UnsafeMutablePointer<__CLPK_integer>, _ work: UnsafeMutablePointer<Double>, _ lwork: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    // Call CLAPACK via helper wrapper that uses correct void return type
    var nLong = clapack_int(n.pointee)
    var ldaLong = clapack_int(lda.pointee)
    var lworkLong = clapack_int(lwork.pointee)
    var infoLong: clapack_int = 0
    let nVal = Int(n.pointee)

    // On wasm32, clapack_int (long) and __CLPK_integer (Int32) are both 32-bit,
    // so we can use withMemoryRebound to avoid array allocation and copying
    ipiv.withMemoryRebound(to: clapack_int.self, capacity: nVal) { ipivRebound in
        clapack_dgetri_wrapper(&nLong, a, &ldaLong, ipivRebound, work, &lworkLong, &infoLong)
    }

    info.pointee = __CLPK_integer(infoLong)
    return Int32(infoLong)
}

@inline(__always)
internal func sgeev_(_ jobvl: UnsafeMutablePointer<Int8>, _ jobvr: UnsafeMutablePointer<Int8>, _ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Float>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ wr: UnsafeMutablePointer<Float>, _ wi: UnsafeMutablePointer<Float>, _ vl: UnsafeMutablePointer<Float>, _ ldvl: UnsafeMutablePointer<__CLPK_integer>, _ vr: UnsafeMutablePointer<Float>, _ ldvr: UnsafeMutablePointer<__CLPK_integer>, _ work: UnsafeMutablePointer<Float>, _ lwork: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    fatalError("LAPACK sgeev_ is not available on WASI (single-precision eigenvalue decomposition not supported)")
}

@inline(__always)
internal func dgeev_(_ jobvl: UnsafeMutablePointer<Int8>, _ jobvr: UnsafeMutablePointer<Int8>, _ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Double>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ wr: UnsafeMutablePointer<Double>, _ wi: UnsafeMutablePointer<Double>, _ vl: UnsafeMutablePointer<Double>, _ ldvl: UnsafeMutablePointer<__CLPK_integer>, _ vr: UnsafeMutablePointer<Double>, _ ldvr: UnsafeMutablePointer<__CLPK_integer>, _ work: UnsafeMutablePointer<Double>, _ lwork: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    let size = Int(n.pointee)

    // Handle workspace query
    if lwork.pointee == -1 {
        // Return optimal workspace size (not really used in pure Swift implementation)
        work.pointee = Double(4 * size)
        info.pointee = 0
        return 0
    }

    // Check job flags
    let computeLeft = (jobvl.pointee == Int8(UInt8(ascii: "V")))
    let computeRight = (jobvr.pointee == Int8(UInt8(ascii: "V")))

    // Copy input matrix (dgeev destroys the input)
    var aCopy = [Double](repeating: 0.0, count: size * size)
    for i in 0..<(size * size) {
        aCopy[i] = a[i]
    }

    // Prepare output arrays
    var wrArr = [Double](repeating: 0.0, count: size)
    var wiArr = [Double](repeating: 0.0, count: size)
    var vlArr = [Double](repeating: 0.0, count: size * size)
    var vrArr = [Double](repeating: 0.0, count: size * size)

    // Call pure Swift implementation
    let result = swiftEigenDecomposition(size, &aCopy, &wrArr, &wiArr, &vlArr, &vrArr,
                                         computeLeft: computeLeft, computeRight: computeRight)

    // Copy results back
    for i in 0..<size {
        wr[i] = wrArr[i]
        wi[i] = wiArr[i]
    }
    if computeLeft {
        for i in 0..<(size * size) {
            vl[i] = vlArr[i]
        }
    }
    if computeRight {
        for i in 0..<(size * size) {
            vr[i] = vrArr[i]
        }
    }

    info.pointee = __CLPK_integer(result)
    return result
}

@inline(__always)
internal func sgesdd_(_ jobz: UnsafeMutablePointer<Int8>, _ m: UnsafeMutablePointer<__CLPK_integer>, _ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Float>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ s: UnsafeMutablePointer<Float>, _ u: UnsafeMutablePointer<Float>, _ ldu: UnsafeMutablePointer<__CLPK_integer>, _ vt: UnsafeMutablePointer<Float>, _ ldvt: UnsafeMutablePointer<__CLPK_integer>, _ work: UnsafeMutablePointer<Float>, _ lwork: UnsafeMutablePointer<__CLPK_integer>, _ iwork: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    fatalError("LAPACK sgesdd_ is not available on WASI (single-precision SVD not supported)")
}

@inline(__always)
internal func dgesdd_(_ jobz: UnsafeMutablePointer<Int8>, _ m: UnsafeMutablePointer<__CLPK_integer>, _ n: UnsafeMutablePointer<__CLPK_integer>, _ a: UnsafeMutablePointer<Double>, _ lda: UnsafeMutablePointer<__CLPK_integer>, _ s: UnsafeMutablePointer<Double>, _ u: UnsafeMutablePointer<Double>, _ ldu: UnsafeMutablePointer<__CLPK_integer>, _ vt: UnsafeMutablePointer<Double>, _ ldvt: UnsafeMutablePointer<__CLPK_integer>, _ work: UnsafeMutablePointer<Double>, _ lwork: UnsafeMutablePointer<__CLPK_integer>, _ iwork: UnsafeMutablePointer<__CLPK_integer>, _ info: UnsafeMutablePointer<__CLPK_integer>) -> Int32 {
    fatalError("LAPACK dgesdd_ is not available on WASI (double-precision SVD not supported)")
}

// MARK: - LAPACK Wrapper Functions for WASI

@inline(__always)
internal func wrap_lapack_solve<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ coef_ptr: UnsafeMutablePointer<T>, _ dst_b_ptr: UnsafeMutablePointer<T>, lapack_func: lapack_solve_func<T>) throws {
    var N = __CLPK_integer(rownum)
    var LDA = __CLPK_integer(rownum)
    var NRHS = __CLPK_integer(colnum)
    var LDB = __CLPK_integer(rownum)
    var IPIV = Array<__CLPK_integer>(repeating: 0, count: rownum)
    var INFO: __CLPK_integer = 0

    let _ = lapack_func(&N, &NRHS, coef_ptr, &LDA, &IPIV, dst_b_ptr, &LDB, &INFO)

    if INFO < 0 {
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0 {
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }
}

@inline(__always)
internal func wrap_lapack_LU<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, lapack_func: lapack_LU_func<T>) throws -> [__CLPK_integer] {
    var M = __CLPK_integer(rownum)
    var N = __CLPK_integer(colnum)
    var LDA = __CLPK_integer(rownum)
    var IPIV = Array<__CLPK_integer>(repeating: 0, count: min(rownum, colnum))
    var INFO: __CLPK_integer = 0

    let _ = lapack_func(&M, &N, srcdstptr, &LDA, &IPIV, &INFO)

    if INFO < 0 {
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0 {
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }

    return IPIV
}

@inline(__always)
internal func wrap_lapack_inv<T: MfStorable>(_ rowcolnum: Int, _ srcdstptr: UnsafeMutablePointer<T>, _ IPIV: UnsafeMutablePointer<__CLPK_integer>, lapack_func: lapack_inv_func<T>) throws {
    var N = __CLPK_integer(rowcolnum)
    var LDA = __CLPK_integer(rowcolnum)
    var INFO: __CLPK_integer = 0
    var WORK = Array<T>(repeating: T.zero, count: rowcolnum)
    var LWORK = __CLPK_integer(rowcolnum)

    let _ = lapack_func(&N, srcdstptr, &LDA, IPIV, &WORK, &LWORK, &INFO)

    if INFO < 0 {
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0 {
        throw MfError.LinAlgError.singularMatrix("The factorization has been completed, but the factor U(of A=PLU) is exactly singular, so the solution could not be computed.")
    }
}

@inline(__always)
internal func wrap_lapack_eigen<T: MfStorable>(_ rowcolnum: Int, _ srcptr: UnsafeMutablePointer<T>, _ dstLVecRePtr: UnsafeMutablePointer<T>, _ dstLVecImPtr: UnsafeMutablePointer<T>, _ dstRVecRePtr: UnsafeMutablePointer<T>, _ dstRVecImPtr: UnsafeMutablePointer<T>, _ dstValRePtr: UnsafeMutablePointer<T>, _ dstValImPtr: UnsafeMutablePointer<T>, lapack_func: lapack_eigen_func<T>) throws {
    // Use Swift String instead of NSString for WASM compatibility
    var jobvlStr = Array("V".utf8CString)
    var jobvrStr = Array("V".utf8CString)
    let JOBVL = UnsafeMutablePointer<CChar>(&jobvlStr)
    let JOBVR = UnsafeMutablePointer<CChar>(&jobvrStr)

    var N = __CLPK_integer(rowcolnum)
    var LDA = __CLPK_integer(rowcolnum)
    var WR = Array<T>(repeating: T.zero, count: rowcolnum)
    var WI = Array<T>(repeating: T.zero, count: rowcolnum)
    var VL = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
    var LDVL = __CLPK_integer(rowcolnum)
    var VR = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
    var LDVR = __CLPK_integer(rowcolnum)
    var WORKQ = T.zero
    var LWORK = __CLPK_integer(-1)
    var INFO: __CLPK_integer = 0

    let _ = lapack_func(JOBVL, JOBVR, &N, srcptr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORKQ, &LWORK, &INFO)

    var WORK = Array<T>(repeating: T.zero, count: T.toInt(WORKQ))
    LWORK = __CLPK_integer(T.toInt(WORKQ))
    let _ = lapack_func(JOBVL, JOBVR, &N, srcptr, &LDA, &WR, &WI, &VL, &LDVL, &VR, &LDVR, &WORK, &LWORK, &INFO)

    if INFO < 0 {
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0 {
        throw MfError.LinAlgError.notConverge("the QR algorithm failed to compute all the eigenvalues, and no eigenvectors have been computed; elements \(INFO)+1:N of WR and WI contain eigenvalues which have converged.")
    }
    else {
        var VLRe = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VLIm = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VRRe = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        var VRIm = Array<T>(repeating: T.zero, count: rowcolnum*rowcolnum)
        for k in 0..<rowcolnum {
            var j = 0
            while j < rowcolnum {
                let index = k*rowcolnum + j
                if WI[k] == 0 {
                    VLRe[index] = VL[index]
                    VLIm[index] = T.zero
                    VRRe[index] = VR[index]
                    VRIm[index] = T.zero
                    j += 1
                }
                else {
                    VLRe[index] = VL[index]
                    VLIm[index] = VL[index + 1]
                    VLRe[index + 1] = VL[index]
                    VLIm[index + 1] = -VL[index + 1]
                    VRRe[index] = VR[index]
                    VRIm[index] = VR[index + 1]
                    VRRe[index + 1] = VR[index]
                    VRIm[index + 1] = -VR[index + 1]
                    j += 2
                }
            }
        }
        WR.withUnsafeMutableBufferPointer {
            dstValRePtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum)
        }
        WI.withUnsafeMutableBufferPointer {
            dstValImPtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum)
        }
        VLRe.withUnsafeMutableBufferPointer {
            dstLVecRePtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VLIm.withUnsafeMutableBufferPointer {
            dstLVecImPtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VRRe.withUnsafeMutableBufferPointer {
            dstRVecRePtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
        VRIm.withUnsafeMutableBufferPointer {
            dstRVecImPtr.moveUpdate(from: $0.baseAddress!, count: rowcolnum*rowcolnum)
        }
    }
}

@inline(__always)
internal func wrap_lapack_svd<T: MfStorable>(_ rownum: Int, _ colnum: Int, _ srcptr: UnsafeMutablePointer<T>, _ vptr: UnsafeMutablePointer<T>, _ sptr: UnsafeMutablePointer<T>, _ rtptr: UnsafeMutablePointer<T>, _ full_matrices: Bool, lapack_func: lapack_svd_func<T>) throws {
    // Use Swift String instead of NSString for WASM compatibility
    var jobzStr = full_matrices ? Array("A".utf8CString) : Array("S".utf8CString)
    let JOBZ = UnsafeMutablePointer<CChar>(&jobzStr)
    var M = __CLPK_integer(rownum)
    var N = __CLPK_integer(colnum)
    let ucol: Int, vtrow: Int
    var LDA = __CLPK_integer(rownum)
    let snum = min(rownum, colnum)
    var S = Array<T>(repeating: T.zero, count: snum)
    var U: Array<T>
    var LDU = __CLPK_integer(rownum)
    var VT: Array<T>
    var LDVT: __CLPK_integer

    if full_matrices {
        LDVT = __CLPK_integer(colnum)
        ucol = rownum
        vtrow = colnum
    }
    else {
        LDVT = __CLPK_integer(snum)
        ucol = snum
        vtrow = snum
    }
    U = Array<T>(repeating: T.zero, count: rownum*ucol)
    VT = Array<T>(repeating: T.zero, count: colnum*vtrow)

    var WORKQ = T.zero
    var LWORK = __CLPK_integer(-1)
    var IWORK = Array<__CLPK_integer>(repeating: 0, count: 8*snum)
    var INFO: __CLPK_integer = 0

    let _ = lapack_func(JOBZ, &M, &N, srcptr, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORKQ, &LWORK, &IWORK, &INFO)

    var WORK = Array<T>(repeating: T.zero, count: T.toInt(WORKQ))
    LWORK = __CLPK_integer(T.toInt(WORKQ))
    let _ = lapack_func(JOBZ, &M, &N, srcptr, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)

    if INFO < 0 {
        throw MfError.LinAlgError.factorizationError("Illegal value found: \(-INFO)th argument")
    }
    else if INFO > 0 {
        throw MfError.LinAlgError.notConverge("the QR algorithm failed to compute all the eigenvalues, and no eigenvectors have been computed; elements \(INFO)+1:N of WR and WI contain eigenvalues which have converged.")
    }
    else {
        U.withUnsafeMutableBufferPointer {
            vptr.moveUpdate(from: $0.baseAddress!, count: rownum*ucol)
        }
        S.withUnsafeMutableBufferPointer {
            sptr.moveUpdate(from: $0.baseAddress!, count: snum)
        }
        VT.withUnsafeMutableBufferPointer {
            rtptr.moveUpdate(from: $0.baseAddress!, count: colnum*vtrow)
        }
    }
}

// MARK: - LAPACK High-Level Functions for WASI

internal func solve_by_lapack<T: MfStorable>(_ coef: MfArray, _ b: MfArray, ret_mftype: MfType, _ lapack_func: lapack_solve_func<T>) throws -> MfArray {
    precondition((coef.ndim == 2), "cannot solve non linear simultaneous equations")
    precondition(b.ndim <= 2, "Invalid b. Dimension must be 1 or 2")

    let coef_shape = coef.shape
    let b_shape = b.shape
    var dst_colnum = 0
    let dst_rownum = coef_shape[0]

    if b.ndim == 1 {
        precondition((coef_shape[0] == coef_shape[1] && b_shape[0] == coef_shape[0]), "cannot solve (\(coef_shape[0]),\(coef_shape[1]))(\(b_shape[0]))=(\(b_shape[0])) problem")
        dst_colnum = 1
    }
    else {
        precondition((coef_shape[0] == coef_shape[1] && b_shape[0] == coef_shape[0]), "cannot solve (\(coef_shape[0]),\(coef_shape[1]))(\(b_shape[0]),\(b_shape[1]))=(\(b_shape[0]),\(b_shape[1])) problem")
        dst_colnum = b_shape[1]
    }

    let coef_column_major = coef.astype(ret_mftype, mforder: .Column)
    let ret = b.astype(ret_mftype, mforder: .Column)

    try coef_column_major.withUnsafeMutableStartPointer(datatype: T.self) {
        coef_ptr in
        try ret.withUnsafeMutableStartPointer(datatype: T.self) {
            dst_ptr in
            try wrap_lapack_solve(dst_rownum, dst_colnum, coef_ptr, dst_ptr, lapack_func: lapack_func)
        }
    }

    return ret
}

internal func inv_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func_lu: lapack_LU<T>, _ lapack_func_inv: lapack_inv<T>, _ retMfType: MfType) throws -> MfArray {
    let shape = mfarray.shape

    precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")

    let newdata = MfData(size: mfarray.size, mftype: mfarray.storedType.to_mftype())
    try newdata.withUnsafeMutableStartPointer(datatype: T.self) {
        dstptrT in
        try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Row) {
            srcptr, row, col, offset in
            var IPIV = try wrap_lapack_LU(row, col, srcptr, lapack_func: lapack_func_lu)
            try wrap_lapack_inv(row, srcptr, &IPIV, lapack_func: lapack_func_inv)
            (dstptrT + offset).moveUpdate(from: srcptr, count: row*col)
        }
    }

    let newstructure = MfStructure(shape: shape, mforder: .Row)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func det_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func: lapack_LU_func<T>) throws -> MfArray {
    let shape = mfarray.shape

    precondition(mfarray.ndim > 1, "cannot get a determinant from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")

    let ret_size = mfarray.size / (shape[mfarray.ndim - 1] * shape[mfarray.ndim - 1])

    let newdata = MfData(size: ret_size, mftype: mfarray.mftype)
    var dst_offset = 0

    try newdata.withUnsafeMutableStartPointer(datatype: T.self) {
        dstptrT in
        try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Row) {
            srcptr, row, col, offset in
            let square_num = row
            let IPIV = try wrap_lapack_LU(row, col, srcptr, lapack_func: lapack_func)
            var det = T.from(1)
            for i in 0..<square_num {
                det *= IPIV[i] != __CLPK_integer(i+1) ? srcptr.advanced(by: i + i*square_num).pointee : -(srcptr.advanced(by: i + i*square_num).pointee)
            }
            (dstptrT + dst_offset).update(from: &det, count: 1)
            dst_offset += 1
        }
    }

    let ret_shape: [Int]
    if mfarray.ndim - 2 != 0 {
        ret_shape = Array(mfarray.shape.prefix(mfarray.ndim - 2))
    }
    else {
        ret_shape = [1]
    }

    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func eigen_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ lapack_func: lapack_eigen_func<T>) throws -> (valRe: MfArray, valIm: MfArray, lvecRe: MfArray, lvecIm: MfArray, rvecRe: MfArray, rvecIm: MfArray) {
    var shape = mfarray.shape
    precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
    let retMfType = mfarray.storedType.to_mftype()
    let eigenvec_size = shape2size(&shape)

    let lvecRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let lvecIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    let rvecRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let rvecIm_data = MfData(size: eigenvec_size, mftype: retMfType)

    let eigenval_shape = Array(shape.prefix(mfarray.ndim - 1))
    let valRe_data = MfData(size: eigenvec_size, mftype: retMfType)
    let valIm_data = MfData(size: eigenvec_size, mftype: retMfType)
    var vec_offset = 0
    var val_offset = 0

    let lvecRe_ptr = lvecRe_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let lvecIm_ptr = lvecIm_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let rvecRe_ptr = rvecRe_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let rvecIm_ptr = rvecIm_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let valRe_ptr = valRe_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)
    let valIm_ptr = valIm_data.data_real.bindMemory(to: T.self, capacity: eigenvec_size)

    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Column) {
        srcptr, row, col, offset in
        let square_num = row
        try wrap_lapack_eigen(square_num, srcptr, lvecRe_ptr + vec_offset, lvecIm_ptr + vec_offset, rvecRe_ptr + vec_offset, rvecIm_ptr + vec_offset, valRe_ptr + val_offset, valIm_ptr + val_offset, lapack_func: lapack_func)
        val_offset += square_num
        vec_offset += offset
    }

    return (MfArray(mfdata: valRe_data, mfstructure: MfStructure(shape: eigenval_shape, mforder: .Row)),
            MfArray(mfdata: valIm_data, mfstructure: MfStructure(shape: eigenval_shape, mforder: .Row)),
            MfArray(mfdata: lvecRe_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: lvecIm_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: rvecRe_data, mfstructure: MfStructure(shape: shape, mforder: .Row)),
            MfArray(mfdata: rvecIm_data, mfstructure: MfStructure(shape: shape, mforder: .Row)))
}

internal func svd_by_lapack<T: MfStorable>(_ mfarray: MfArray, _ full_matrices: Bool, _ lapack_func: lapack_svd_func<T>) throws -> (v: MfArray, s: MfArray, rt: MfArray) {
    let shape = mfarray.shape
    let ret_mftype = mfarray.storedType.to_mftype()
    let M = shape[mfarray.ndim - 2]
    let N = shape[mfarray.ndim - 1]
    let ssize = min(M, N)
    let stacked_shape = Array(shape.prefix(mfarray.ndim - 2))

    let v_data: MfData, s_data: MfData, rt_data: MfData
    var v_shape: [Int], s_shape: [Int], rt_shape: [Int]
    let vcol: Int, rtrow: Int
    if full_matrices {
        v_shape = stacked_shape + [M, M]
        s_shape = stacked_shape + [ssize]
        rt_shape = stacked_shape + [N, N]
        v_data = MfData(size: shape2size(&v_shape), mftype: ret_mftype)
        s_data = MfData(size: shape2size(&s_shape), mftype: ret_mftype)
        rt_data = MfData(size: shape2size(&rt_shape), mftype: ret_mftype)
        vcol = M
        rtrow = N
    }
    else {
        v_shape = stacked_shape + [ssize, M]
        s_shape = stacked_shape + [ssize]
        rt_shape = stacked_shape + [N, ssize]
        v_data = MfData(size: shape2size(&v_shape), mftype: ret_mftype)
        s_data = MfData(size: shape2size(&s_shape), mftype: ret_mftype)
        rt_data = MfData(size: shape2size(&rt_shape), mftype: ret_mftype)
        vcol = ssize
        rtrow = ssize
    }

    var v_offset = 0
    var s_offset = 0
    var rt_offset = 0

    let vptr = v_data.data_real.bindMemory(to: T.self, capacity: shape2size(&v_shape))
    let sptr = s_data.data_real.bindMemory(to: T.self, capacity: shape2size(&s_shape))
    let rtptr = rt_data.data_real.bindMemory(to: T.self, capacity: shape2size(&rt_shape))

    try mfarray.withMNStackedMajorPointer(datatype: T.self, mforder: .Column) {
        srcptr, _, _, _ in
        try wrap_lapack_svd(M, N, srcptr, vptr + v_offset, sptr + s_offset, rtptr + rt_offset, full_matrices, lapack_func: lapack_func)
        v_offset += M*vcol
        s_offset += ssize
        rt_offset += N*rtrow
    }

    let v = MfArray(mfdata: v_data, mfstructure: MfStructure(shape: v_shape, mforder: .Row))
    let s = MfArray(mfdata: s_data, mfstructure: MfStructure(shape: s_shape, mforder: .Row))
    let rt = MfArray(mfdata: rt_data, mfstructure: MfStructure(shape: rt_shape, mforder: .Row))

    return (v.swapaxes(axis1: -1, axis2: -2), s, rt.swapaxes(axis1: -1, axis2: -2))
}

#endif // canImport(Accelerate)
