//
//  vDSP.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(Accelerate)

internal typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

// vDSP_ctoz or vDSP_ztoc
internal typealias vDSP_convertz_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<U>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_biopvv_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void
internal typealias vDSP_biopzvv_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_biopvs_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void
internal typealias vDSP_biopzvs_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<U>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_biopsv_func<T> = (UnsafePointer<T>, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_vcmprs_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_vminmg_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_viclip_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>,  UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_clip_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_vthrsc_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_sort_func<T> = (UnsafeMutablePointer<T>, vDSP_Length, Int32) -> Void

internal typealias vDSP_argsort_func<T> = (UnsafePointer<T>, UnsafeMutablePointer<vDSP_Length>, UnsafeMutablePointer<vDSP_Length>?, vDSP_Length, Int32) -> Void

internal typealias vDSP_stats_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Length) -> Void

internal typealias vDSP_stats_index_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length) -> Void


internal typealias vDSP_math_func<T, U> = vDSP_convert_func<T, U>

internal typealias vDSP_vgathr_func<T> = (UnsafePointer<T>, UnsafePointer<vDSP_Length>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_dotpr_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Length) -> Void

internal typealias vDSP_z2r_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void


@inline(__always)
internal func vDSP_zvmul_(_ __A: UnsafePointer<DSPSplitComplex>, _ __IA: vDSP_Stride, _ __B: UnsafePointer<DSPSplitComplex>, _ __IB: vDSP_Stride, _ __C: UnsafePointer<DSPSplitComplex>, _ __IC: vDSP_Stride, _ __N: vDSP_Length) -> Void{
    vDSP_zvmul(__A, __IA, __B, __IB, __C, __IC, __N, Int32(1))
}
@inline(__always)
internal func vDSP_zvmulD_(_ __A: UnsafePointer<DSPDoubleSplitComplex>, _ __IA: vDSP_Stride, _ __B: UnsafePointer<DSPDoubleSplitComplex>, _ __IB: vDSP_Stride, _ __C: UnsafePointer<DSPDoubleSplitComplex>, _ __IC: vDSP_Stride, _ __N: vDSP_Length) -> Void{
    vDSP_zvmulD(__A, __IA, __B, __IB, __C, __IC, __N, Int32(1))
}
// `wrap_vDSP_biopzvv` passes the right operand first (vDSP_zvdiv computes B / A), but vDSP_zvsub computes A - B
@inline(__always)
internal func vDSP_zvsub_(_ __B: UnsafePointer<DSPSplitComplex>, _ __IB: vDSP_Stride, _ __A: UnsafePointer<DSPSplitComplex>, _ __IA: vDSP_Stride, _ __C: UnsafePointer<DSPSplitComplex>, _ __IC: vDSP_Stride, _ __N: vDSP_Length) -> Void{
    vDSP_zvsub(__A, __IA, __B, __IB, __C, __IC, __N)
}
@inline(__always)
internal func vDSP_zvsubD_(_ __B: UnsafePointer<DSPDoubleSplitComplex>, _ __IB: vDSP_Stride, _ __A: UnsafePointer<DSPDoubleSplitComplex>, _ __IA: vDSP_Stride, _ __C: UnsafePointer<DSPDoubleSplitComplex>, _ __IC: vDSP_Stride, _ __N: vDSP_Length) -> Void{
    vDSP_zvsubD(__A, __IA, __B, __IB, __C, __IC, __N)
}

/// Wrapper of vDSP conversion function
/// - Parameters:
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - size: A size to be copied
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_convert<T, U>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<U>, _ dstStride: Int, _ vDSP_func: vDSP_convert_func<T, U>){
    vDSP_func(srcptr, vDSP_Stride(srcStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP conversion function
/// - Parameters:
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - size: A size to be copied
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_convertz<T, U>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafePointer<U>, _ dstStride: Int, _ vDSP_func: vDSP_convertz_func<T, U>){
    vDSP_func(srcptr, vDSP_Stride(srcStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP binary operation function
/// - Parameters:
///   - size: A size
///   - lsrcptr: A left  source pointer
///   - lsrcStride: A left source stride
///   - rsrcptr: A right source pointer
///   - rsrcStride: A right source stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_biopvv<T>(_ size: Int, _ lsrcptr: UnsafePointer<T>, _ lsrcStride: Int, _ rsrcptr: UnsafePointer<T>, _ rsrcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopvv_func<T>){
    vDSP_func(rsrcptr, vDSP_Stride(rsrcStride), lsrcptr, vDSP_Stride(lsrcStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP binary operation function
/// - Parameters:
///   - size: A size
///   - lsrcptr: A left  source pointer
///   - lsrcStride: A left source stride
///   - rsrcptr: A right source pointer
///   - rsrcStride: A right source stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_biopzvv<T>(_ size: Int, _ lsrcptr: UnsafePointer<T>, _ lsrcStride: Int, _ rsrcptr: UnsafePointer<T>, _ rsrcStride: Int, _ dstptr: UnsafePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopzvv_func<T>){
    vDSP_func(rsrcptr, vDSP_Stride(rsrcStride), lsrcptr, vDSP_Stride(lsrcStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP binary operation function
/// - Parameters:
///   - size: A size
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - scalar: A source scalar pointer
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_biopvs<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ scalar: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopvs_func<T>){
    vDSP_func(srcptr, vDSP_Stride(srcStride), scalar, dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP binary complex operation function
/// - Parameters:
///   - size: A size
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - scalar: A source scalar pointer
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_biopzvs<T: vDSP_ComplexTypable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ realptr: UnsafePointer<T.T>, _ realStride: Int, _ dstptr: UnsafePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopzvs_func<T, T.T>){
    vDSP_func(srcptr, vDSP_Stride(srcStride), realptr, vDSP_Stride(realStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP binary operation function
/// - Parameters:
///   - size: A size
///   - scalar: A source scalar pointer
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_biopsv<T>(_ size: Int, _ scalar: UnsafePointer<T>, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopsv_func<T>){
    vDSP_func(scalar, srcptr, vDSP_Stride(srcStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// The values written by `wrap_vDSP_compare`
internal enum CompareOutput{
    /// +1 where the comparison holds, otherwise -1
    case plusMinusOne
    /// 1 where the comparison holds, otherwise 0
    case oneZero
    /// 0 where the comparison holds, otherwise 1
    case zeroOne
    
    /// (a, b) of `a*x + b` converting the output into 1/0
    var toBool: (Float, Float)?{
        switch self {
        case .plusMinusOne: return (0.5, 0.5)
        case .oneZero: return nil
        case .zeroOne: return (-1, 1)
        }
    }
}

/// Wrapper of vDSP comparison function. NaN never satisfies the comparison except for `.notEqual`.
/// - Parameters:
///   - size: A size to be compared
///   - srcptr: A source pointer
///   - op: The comparison operator
///   - scalar: The right-hand scalar
///   - dstptr: A destination pointer (may be used as a work buffer). Must not be srcptr: `vDSP_vnabs` in place is about 4x slower
///   - vDSP_vthrsc_func: The vDSP vthrsc function
///   - vDSP_vneg_func: The vDSP vneg function
///   - vDSP_vadd_func: The vDSP vadd function
///   - vDSP_vnabs_func: The vDSP vnabs function
/// - Returns: The form of the values written into dstptr
@inline(__always)
internal func wrap_vDSP_compare<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ op: MfCompareOp, _ scalar: T, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vthrsc_func: vDSP_vthrsc_func<T>, _ vDSP_vneg_func: vDSP_math_func<T, T>, _ vDSP_vadd_func: vDSP_biopvv_func<T>, _ vDSP_vnabs_func: vDSP_math_func<T, T>) -> CompareOutput{
    let n = vDSP_Length(size)
    // vthrsc: dst = threshold <= src ? +c : -c
    // Every comparison is rewritten into the form `x >= threshold` so that NaN yields -c.
    func thrsc(_ src: UnsafePointer<T>, _ threshold: T, _ c: T, _ dst: UnsafeMutablePointer<T>){
        var threshold = threshold
        var c = c
        vDSP_vthrsc_func(src, vDSP_Stride(1), &threshold, &c, dst, vDSP_Stride(1), n)
    }
    func neg(){
        vDSP_vneg_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), n)
    }
    
    switch op {
    case .greater where scalar == .infinity, .less where scalar == -.infinity:
        // nothing is greater than inf (nextUp(inf) is inf itself)
        dstptr.update(repeating: T.from(-1), count: size)
    case .greater: // x >= nextUp(s)
        thrsc(srcptr, scalar.nextUp, T.from(1), dstptr)
    case .greaterEqual: // x >= s
        thrsc(srcptr, scalar, T.from(1), dstptr)
    case .less: // -x >= nextUp(-s)
        neg()
        thrsc(dstptr, (-scalar).nextUp, T.from(1), dstptr)
    case .lessEqual: // -x >= -s
        neg()
        thrsc(dstptr, -scalar, T.from(1), dstptr)
    case .equal, .notEqual:
        let c = op == .equal ? T.from(1) : T.from(-1)
        if scalar.isInfinite{
            // x - inf is NaN, so compare x >= inf or -x >= inf instead
            if scalar > 0{
                thrsc(srcptr, scalar, c, dstptr)
            }
            else{
                neg()
                thrsc(dstptr, -scalar, c, dstptr)
            }
        }
        else if scalar.isZero{
            // -|x| >= 0
            vDSP_vnabs_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), n)
            thrsc(dstptr, T.zero, c, dstptr)
        }
        else{
            // (x >= s ? 0.5 : -0.5) + (x >= nextUp(s) ? -0.5 : 0.5) is 1 only where x == s, and 0 for NaN.
            // 3 passes instead of vsadd, vnabs, vthrsc (and the conversion into 1/0)
            let tmpptr = UnsafeMutablePointer<T>.allocate(capacity: size)
            defer { tmpptr.deallocate() }
            // read srcptr into tmpptr first since dstptr may be srcptr
            thrsc(srcptr, scalar.nextUp, T.from(-0.5), tmpptr)
            thrsc(srcptr, scalar, T.from(0.5), dstptr)
            vDSP_vadd_func(dstptr, vDSP_Stride(1), tmpptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), n)
            return op == .equal ? .oneZero : .zeroOne
        }
    }
    return .plusMinusOne
}

/// Wrapper of vDSP sign generation function
/// - Parameters:
///   - size: A size to be converted
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - vDSP_vthrsc_func: The vDSP vthrsc function
///   - vDSP_vadd_func: The vDSP vadd function
///   - vDSP_sve_func: The vDSP sve function
@inline(__always)
internal func wrap_vDSP_sign<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vthrsc_func: vDSP_vthrsc_func<T>, _ vDSP_vadd_func: vDSP_biopvv_func<T>, _ vDSP_sve_func: vDSP_stats_func<T>){
    let n = vDSP_Length(size)
    let workptr = UnsafeMutablePointer<T>.allocate(capacity: size)
    defer { workptr.deallocate() }
    
    var half = T.from(1) / T.from(2)
    // x > 0  => +0.5, otherwise -0.5
    var tiny = T.leastNonzeroMagnitude
    vDSP_vthrsc_func(srcptr, vDSP_Stride(1), &tiny, &half, dstptr, vDSP_Stride(1), n)
    // x >= 0 => +0.5, otherwise -0.5
    var zero = T.zero
    vDSP_vthrsc_func(srcptr, vDSP_Stride(1), &zero, &half, workptr, vDSP_Stride(1), n)
    // x > 0 => 1, x == ±0 => +0, x < 0 => -1 (NaN => -1)
    vDSP_vadd_func(dstptr, vDSP_Stride(1), workptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), n)
    
    // sign(NaN) is NaN. The sum is NaN only when src contains NaN (or both of +inf and -inf), so fix them up only then
    var sum = T.zero
    vDSP_sve_func(srcptr, vDSP_Stride(1), &sum, n)
    if sum.isNaN{
        for i in 0..<size where srcptr[i].isNaN{
            dstptr[i] = srcptr[i]
        }
    }
}

/// Wrapper of vDSP clip function
/// - Parameters:
///   - size: A size to be converted
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - vDSP_clip_func: The vDSP clip function
@inline(__always)
internal func wrap_vDSP_clip<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ minptr: UnsafePointer<T>, _ maxptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_clip_func: vDSP_clip_func<T>){
    vDSP_clip_func(srcptr, vDSP_Stride(1), minptr, maxptr, dstptr, vDSP_Stride(1), vDSP_Length(size))
}

/// Wrapper of vDSP sort function
/// - Parameters:
///   - size: A size to be copied
///   - srcdstptr: A source pointer
///   - order: MfSortOrder
///   - vDSP_func: The vDSP sort function
@inline(__always)
internal func wrap_vDSP_sort<T>(_ size: Int, _ srcdstptr: UnsafeMutablePointer<T>, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_func<T>){
    vDSP_func(srcdstptr, vDSP_Length(size), order.rawValue)
}

/// Wrapper of vDSP argsort function
/// - Parameters:
///   - size: A size to be copied
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - order: MfSortOrder
///   - vDSP_func: The vDSP argsort function
@inline(__always)
internal func wrap_vDSP_argsort<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<UInt>, _ order: MfSortOrder, _ vDSP_func: vDSP_argsort_func<T>){
    // the temporary buffer is not used by vDSP
    vDSP_func(srcptr, dstptr, nil, vDSP_Length(size), order.rawValue)
}

/// Wrapper of vDSP stats function
/// - Parameters:
///   - size: A size to be copied
///   - srcptr: A source pointer
///   - stride: A stride
///   - dstptr: A destination pointer
///   - vDSP_func: The vDSP stats function
@inline(__always)
internal func wrap_vDSP_stats<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ stride: Int, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_func: vDSP_stats_func<T>){
    vDSP_func(srcptr, vDSP_Stride(stride), dstptr, vDSP_Length(size))
}

/// Wrapper of vDSP stats index function
/// - Parameters:
///   - size: A size to be copied
///   - srcptr: A source pointer
///   - stride: A stride
///   - dstptr: A destination pointer
///   - vDSP_func: The vDSP stats index function
@inline(__always)
internal func wrap_vDSP_stats_index<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ stride: Int, _ dstptr: UnsafeMutablePointer<UInt>, _ vDSP_func: vDSP_stats_index_func<T>){
    // the max / min value (not used)
    var value = T.zero
    vDSP_func(srcptr, vDSP_Stride(stride), &value, dstptr, vDSP_Length(size))
}

/// Wrapper of vDSP compress function
/// - Parameters:
///   - size: A size to be copied
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - indptr: A indices pointer
///   - indStride: A indices stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP cmprs function
@inline(__always)
internal func wrap_vDSP_cmprs<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ indptr: UnsafePointer<T>, _ indStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_vcmprs_func<T>){
    vDSP_func(srcptr, vDSP_Stride(srcStride), indptr, vDSP_Stride(indStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP gather function
/// - Parameters:
///   - size: A size to be copied
///   - srcptr: A source pointer
///   - indptr: A indices pointer
///   - indStride: A indices stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP cmprs function
@inline(__always)
internal func wrap_vDSP_gathr<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ indptr: UnsafePointer<vDSP_Length>, _ indStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_vgathr_func<T>){
    vDSP_func(srcptr, indptr, vDSP_Stride(indStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Wrapper of vDSP dot product operation function
/// - Parameters:
///   - size: A size
///   - lsrcptr: A left  source pointer
///   - lsrcStride: A left source stride
///   - rsrcptr: A right source pointer
///   - rsrcStride: A right source stride
///   - dstptr: A destination pointer
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_dotpr<T>(_ size: Int, _ lsrcptr: UnsafePointer<T>, _ lsrcStride: Int, _ rsrcptr: UnsafePointer<T>, _ rsrcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_func: vDSP_dotpr_func<T>){
    vDSP_func(lsrcptr, vDSP_Stride(lsrcStride), rsrcptr, vDSP_Stride(rsrcStride), dstptr, vDSP_Length(size))
}

/// Convert type and contiguous mfarray
/// - Parameters:
///   - src_mfarray: An input mfarray
///   - mftype: The new mftype
///   - mforder: The order
///   - vDSP_func: vDSP_convert_func
/// - Returns: Pre operated mfarray
internal func contiguous_and_astype_by_vDSP<T: MfStorable, U: MfStorable>(_ src_mfarray: MfArray, mftype: MfType, mforder: MfOrder, vDSP_func: vDSP_convert_func<T, U>) -> MfArray{
    var ret_shape = src_mfarray.shape
    let ret_strides = shape2strides(&ret_shape, mforder: mforder)
    
    let newdata = MfData(uninitializedSize: src_mfarray.size, mftype: mftype)
    
    newdata.withUnsafeMutableStartPointer(datatype: U.self){
        dstptrU in
        src_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned src_mfarray] srcptrT in
            
            for vDSPPrams in OptOffsetParamsSequence(shape: ret_shape, bigger_strides: ret_strides, smaller_strides: src_mfarray.strides){
                
                wrap_vDSP_convert(vDSPPrams.blocksize, srcptrT + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrU + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
            }
            
        }
    }
    
    let newstructure = MfStructure(shape: ret_shape, strides: ret_strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Convert type and contiguous mfarray
/// - Parameters:
///   - src_mfarray: An input mfarray
///   - mftype: The new mftype
///   - mforder: The order
///   - vDSP_func: vDSP_convertz_func
/// - Returns: Pre operated mfarray
internal func zcontiguous_and_astype_by_vDSP<T: vDSP_ComplexTypable, U: vDSP_ComplexTypable>(_ src_mfarray: MfArray, mftype: MfType, mforder: MfOrder, src_type: T.Type, dst_type: U.Type,  vDSP_func: vDSP_convert_func<T.T, U.T>) -> MfArray{
    var ret_shape = src_mfarray.shape
    let ret_strides = shape2strides(&ret_shape, mforder: mforder)
    
    let newdata = MfData(uninitializedSize: src_mfarray.size, mftype: mftype, complex: true)
    
    newdata.withUnsafeMutablevDSPComplexPointer(datatype: U.self){
        dstptrU in
        let dstptrr = dstptrU.pointee.realp
        let dstptri = dstptrU.pointee.imagp
        src_mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
            [unowned src_mfarray] srcptrT in
            let srcptrr = srcptrT.pointee.realp
            let srcptri = srcptrT.pointee.imagp
            
            for vDSPPrams in OptOffsetParamsSequence(shape: ret_shape, bigger_strides: ret_strides, smaller_strides: src_mfarray.strides){
                
                wrap_vDSP_convert(vDSPPrams.blocksize, srcptrr + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrr + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                wrap_vDSP_convert(vDSPPrams.blocksize, srcptri + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptri + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
            }
            
        }
    }
    
    let newstructure = MfStructure(shape: ret_shape, strides: ret_strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Copy mfarray by vDSP
/// - Parameters:
///   - mfarray: The source mfarray
///   - mforder: The order
///   - vDSP_func: vDSP_copy_function
internal func zcontiguous_by_vDSP<T: vDSP_ComplexTypable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convertz_func<T, T>, mforder: MfOrder) -> MfArray{
    let shape = mfarray.shape
    
    let newdata = MfData(uninitializedSize: mfarray.size, mftype: mfarray.mftype, complex: true)
    let newstructure = MfStructure(shape: shape, mforder: mforder)

    let bigger_strides = newstructure.strides
    let smaller_strides = mfarray.strides
    
    newdata.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
        dstptr in
        mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
            srcptr in
            for vDSPPrams in OptOffsetParamsSequence(shape: shape, bigger_strides: bigger_strides, smaller_strides: smaller_strides){
                var dst = dstptr +++ vDSPPrams.b_offset
                var src = srcptr +++ vDSPPrams.s_offset
                wrap_vDSP_convertz(vDSPPrams.blocksize, &src, vDSPPrams.s_stride, &dst, vDSPPrams.b_stride, vDSP_func)
            }
        }
    }
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Pre operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_convert_func
/// - Returns: Pre operated mfarray
internal func preop_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_dense(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_convert(mfarray.storedSize, $0, 1, dstptrT, 1, vDSP_func)
            //vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// ZPre operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_convert_func
/// - Returns: Pre operated mfarray
internal func zpreop_by_vDSP<T: vDSP_ComplexTypable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convertz_func<T, T>) -> MfArray{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_dense(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype, complex: true)
    newdata.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_convertz(mfarray.storedSize, $0, 1, dstptrT, 1, vDSP_func)
            //vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Phase operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_z2r_func
/// - Returns: Pre operated mfarray
internal func z2r_by_vDSP<T: vDSP_ComplexTypable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T.T>) -> MfArray{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_dense(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype, complex: false)
    newdata.withUnsafeMutableStartPointer(datatype: T.T.self){
        dstptrT in
        mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_convert(mfarray.storedSize, $0, 1, dstptrT, 1, vDSP_func)
            //vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Conjugate operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_conjugate_func
/// - Returns: Pre operated mfarray
internal func conjugate_by_vDSP<T: vDSP_ComplexTypable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convertz_func<T, T>) -> MfArray{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_dense(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype, complex: true)
    newdata.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_convertz(mfarray.storedSize, $0, 1, dstptrT, 1, vDSP_func)
            //vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Math operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_convert_func
/// - Returns: Math operated mfarray
internal func math_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    return preop_by_vDSP(mfarray, vDSP_func)
}

/// Binary operation by vDSP
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_scalr: The right scalar
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
internal func biopvs_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_scalar: T, _ vDSP_func: vDSP_biopvs_func<T>) -> MfArray{
    var mfarray = l_mfarray
    var r_scalar = r_scalar
    
    mfarray = check_dense(mfarray)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_biopvs(mfarray.storedSize, $0, 1, &r_scalar, dstptrT, 1, vDSP_func)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Binary operation of complex mfarray and real scalar by vDSP, applying the real function to the real and imaginary parts separately
/// - Parameters:
///   - l_mfarray: The left complex mfarray
///   - r_scalar: The right real scalar
///   - vDSP_func: The vDSP biop function for real vectors
/// - Returns: The result mfarray
internal func biopzvs_separately_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_scalar: T, _ vDSP_func: vDSP_biopvs_func<T>) -> MfArray{
    var r_scalar = r_scalar
    let mfarray = check_dense(l_mfarray)
    let size = mfarray.storedSize

    let newdata = MfData(uninitializedSize: size, mftype: mfarray.mftype, complex: true)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            wrap_vDSP_biopvs(size, $0, 1, &r_scalar, dstptrT, 1, vDSP_func)
        }
    }
    newdata.withUnsafeMutableStartImagPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartImagPointer(datatype: T.self){
            wrap_vDSP_biopvs(size, $0!, 1, &r_scalar, dstptrT!, 1, vDSP_func)
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// ZBinary operation by vDSP
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_scalr: The right scalar
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
internal func biopzvs_by_vDSP<T: vDSP_ComplexTypable>(_ l_mfarray: MfArray, _ r_scalar: T.T, _ vDSP_func: vDSP_biopzvs_func<T, T.T>) -> MfArray{
    var mfarray = l_mfarray
    var r_scalar = r_scalar
    
    mfarray = check_dense(mfarray)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype, complex: true)
    newdata.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_biopzvs(mfarray.storedSize, $0, 1, &r_scalar, 0, dstptrT, 1, vDSP_func)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Binary operation by vDSP
/// - Parameters:
///   - l_scalar: The left scalar
///   - r_mfarray: The right mfarray
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
internal func biopsv_by_vDSP<T: MfStorable>(_ l_scalar: T, _ r_mfarray: MfArray, _ vDSP_func: vDSP_biopsv_func<T>) -> MfArray{
    var mfarray = r_mfarray
    var l_scalar = l_scalar
    
    mfarray = check_dense(mfarray)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_biopsv(mfarray.storedSize, &l_scalar, $0, 1, dstptrT, 1, vDSP_func)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Binary operation by vDSP
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_mfarray: The right mfarray
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
/// Convert the smaller mfarray into the bigger one's layout when their common contiguous block is small.
/// e.g. `a - a.transpose(axes: [0,3,4,2,1,5])` would need 100k vDSP calls of 10 elements,
/// while a 2D block copy and a single vDSP call are several times faster.
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_mfarray: The right mfarray
///   - biggerL: Whether the left is bigger (i.e. row or column contiguous)
/// - Returns: The left and right mfarrays
internal func align_biop_layout(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ biggerL: Bool) -> (l: MfArray, r: MfArray){
    let (b_mfarray, s_mfarray) = biggerL ? (l_mfarray, r_mfarray) : (r_mfarray, l_mfarray)
    guard b_mfarray.mfstructure.row_contiguous || b_mfarray.mfstructure.column_contiguous else { return (l_mfarray, r_mfarray) }
    
    let iterator = OptOffsetParamsSequence(shape: b_mfarray.shape, bigger_strides: b_mfarray.strides, smaller_strides: s_mfarray.strides).makeIterator()
    // copy2d_by_vDSP needs a unit stride block on both sides
    guard iterator.blocksize < copy2dThreshold && iterator.stride.b == 1 && iterator.stride.s == 1 else { return (l_mfarray, r_mfarray) }
    
    let aligned = s_mfarray.to_contiguous(mforder: b_mfarray.mfstructure.row_contiguous ? .Row : .Column)
    return biggerL ? (l_mfarray, aligned) : (aligned, r_mfarray)
}

internal func biopvv_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_biopvv_func<T>) -> MfArray{
    // biggerL: flag whether l is bigger than r
    //return mfarray must be either row or column major
    let (l_contiguous, r_contiguous, biggerL, retsize) = check_biop_contiguous(l_mfarray, r_mfarray, .Row, convertL: true)
    let (l_mfarray, r_mfarray) = align_biop_layout(l_contiguous, r_contiguous, biggerL)
    
    let newdata = MfData(uninitializedSize: retsize, mftype: l_mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        l_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned l_mfarray] (lptr) in
            r_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                [unowned r_mfarray] (rptr) in
                //print(l_mfarray, r_mfarray)
                //print(l_mfarray.storedSize, r_mfarray.storedSize)
                //print(biggerL)
                if biggerL{// l is bigger
                    for vDSPPrams in OptOffsetParamsSequence(shape: l_mfarray.shape, bigger_strides: l_mfarray.strides, smaller_strides: r_mfarray.strides){
                        /*
                        let bptr = bptr.baseAddress! + vDSPPrams.b_offset
                        let sptr = sptr.baseAddress! + vDSPPrams.s_offset
                        dstptrT = dstptrT + vDSPPrams.b_offset*/
                        wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                        //print(vDSPPrams.blocksize, vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                    }
                }
                else{// r is bigger
                    for vDSPPrams in OptOffsetParamsSequence(shape: r_mfarray.shape, bigger_strides: r_mfarray.strides, smaller_strides: l_mfarray.strides){
                        wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr + vDSPPrams.s_offset, vDSPPrams.s_stride, rptr + vDSPPrams.b_offset, vDSPPrams.b_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                        //print(vDSPPrams.blocksize, vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                    }
                }
            }
        }
    }
    
    let newstructure: MfStructure
    if biggerL{
        newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
    }
    else{
        newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
    }

    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Binary operation by vDSP
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_mfarray: The right mfarray
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
internal func biopzvv_by_vDSP<T: vDSP_ComplexTypable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_biopzvv_func<T>) -> MfArray{
    // biggerL: flag whether l is bigger than r
    //return mfarray must be either row or column major
    let (l_mfarray, r_mfarray, biggerL, retsize) = check_biop_contiguous(l_mfarray, r_mfarray, .Row, convertL: true)

    let newdata = MfData(uninitializedSize: retsize, mftype: l_mfarray.mftype, complex: true)
    newdata.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
        dstptrT in
        l_mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
            [unowned l_mfarray] (lptr) in
            r_mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.self){
                [unowned r_mfarray] (rptr) in
                if biggerL{// l is bigger
                    for vDSPPrams in OptOffsetParamsSequence(shape: l_mfarray.shape, bigger_strides: l_mfarray.strides, smaller_strides: r_mfarray.strides){
                        var lhs = lptr +++ vDSPPrams.b_offset
                        var rhs = rptr +++ vDSPPrams.s_offset
                        var dst = dstptrT +++ vDSPPrams.b_offset
                        wrap_vDSP_biopzvv(vDSPPrams.blocksize, &lhs, vDSPPrams.b_stride, &rhs, vDSPPrams.s_stride, &dst, vDSPPrams.b_stride, vDSP_func)
                    }
                }
                else{// r is bigger
                    for vDSPPrams in OptOffsetParamsSequence(shape: r_mfarray.shape, bigger_strides: r_mfarray.strides, smaller_strides: l_mfarray.strides){
                        var lhs = lptr +++ vDSPPrams.s_offset
                        var rhs = rptr +++ vDSPPrams.b_offset
                        var dst = dstptrT +++ vDSPPrams.b_offset
                        wrap_vDSP_biopzvv(vDSPPrams.blocksize, &lhs, vDSPPrams.s_stride, &rhs, vDSPPrams.b_stride, &dst, vDSPPrams.b_stride, vDSP_func)
                    }
                }
            }
        }
    }
    
    let newstructure: MfStructure
    if biggerL{
        newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
    }
    else{
        newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
    }

    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Stats operation by vDSP
/// - Parameters:
///   - typedMfarray: An input **typed** mfarray. Returned mfarray will have same type.
///   - axis; An axis index
///   - keepDims: Whether to keep dimension or not
///   - vDSP_func: The vDSP stats function
/// - Returns: The stats operated mfarray
internal func stats_by_vDSP<T: MfStorable>(_ typedMfarray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_func<T>) -> MfArray{
    
    let mfarray = check_contiguous(typedMfarray, .Row)
    
    if let axis = axis, mfarray.ndim > 1{
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        var ret_shape = mfarray.shape
        let count = ret_shape.remove(at: axis)
        var ret_strides = mfarray.strides
        //remove and get stride at given axis
        let stride = ret_strides.remove(at: axis)
        
        let ret_size = shape2size(&ret_shape)
        
        let newdata = MfData(uninitializedSize: ret_size, mftype: mfarray.mftype)
        var dst_offset = 0
        
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            // FlattenIndSequence yields one index even for a shape containing 0, so an empty result must not be written
            guard ret_size > 0 else { return }
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                for flat in FlattenIndSequence(shape: &ret_shape, strides: &ret_strides){
                    wrap_vDSP_stats(count, $0 + flat.flattenIndex, stride, dstptrT + dst_offset, vDSP_func)
                    dst_offset += 1
                }
            }
        }
        
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        
        let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{
        let newdata = MfData(uninitializedSize: 1, mftype: mfarray.mftype)
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                wrap_vDSP_stats(mfarray.size, $0, 1, dstptrT, vDSP_func)
            }
        }
        
        let ret_shape = keepDims ? Array(repeating: 1, count: mfarray.ndim) : [1]
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}

/// Sort operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis; An axis index
///   - order: MfSortOrder
///   - vDSP_func: The vDSP sort function
/// - Returns: The sorted mfarray
internal func sort_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ axis: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_func<T>) -> MfArray{
    let retndim = mfarray.ndim
    let count = mfarray.shape[axis]
    
    let lastaxis = retndim - 1
    // move lastaxis and given axis and align order
    let srcdst_mfarray = mfarray.moveaxis(src: axis, dst: lastaxis).to_contiguous(mforder: .Row)

    var offset = 0
    
    srcdst_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
        srcdstptr in
        // no lanes when the sorted axis (or another axis) is zero-length
        for _ in 0..<(count > 0 ? srcdst_mfarray.size / count : 0){
            sort_lane(count, srcdstptr + offset, order, vDSP_func)
            offset += count
        }
    }
    
    // re-move axis and lastaxis
    return srcdst_mfarray.moveaxis(src: lastaxis, dst: axis)
}


/// Argsort operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis; An axis index
///   - order: MfSortOrder
///   - vDSP_func: The vDSP sort function
/// - Returns: The sorted mfarray
internal func argsort_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ axis: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_argsort_func<T>) -> MfArray{

    let count = mfarray.shape[axis]
    
    let lastaxis = mfarray.ndim - 1
    // move lastaxis and given axis and align order
    let srcmfarray = mfarray.moveaxis(src: axis, dst: lastaxis).to_contiguous(mforder: .Row)
    var retShape = srcmfarray.shape
    
    var offset = 0

    let retSize = shape2size(&retShape)
    let newdata = MfData(uninitializedSize: retSize, mftype: .Int)
    newdata.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptrF in
        srcmfarray.withUnsafeMutableStartPointer(datatype: T.self){
            srcptr in
            
            // one index buffer for every row
            var uiarray = Array<UInt>(repeating: 0, count: count)
            for _ in 0..<(count > 0 ? srcmfarray.size / count : 0){
                argsort_lane(count, srcptr + offset, &uiarray, order, vDSP_func)
                for j in 0..<count{
                    dstptrF[offset + j] = Float(uiarray[j])
                }
                
                offset += count
            }
            
        }
    }
    
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    // re-move axis and lastaxis
    return ret.moveaxis(src: lastaxis, dst: axis)
    
}


/// Clip operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - minval: The minimum value
///   - maxval: The maximum value
///   - vDSP_func: The vDSP clip function
/// - Returns: The clipped mfarray
internal func clip_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ minval: T, _ maxval: T, _ vDSP_func: vDSP_clip_func<T>) -> MfArray{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    var minval = minval
    var maxval = maxval
    
    //print(mfarray)
    mfarray = check_dense(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_clip(mfarray.storedSize, $0, &minval, &maxval, dstptrT, vDSP_func)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Generate sign by vDSP
/// - Parameters:
///    - mfarray: An input mfarray
///    - vDSP_vthrsc_func: vDSP_vthrsc function
///    - vDSP_vadd_func: vDSP_vadd function
///    - vDSP_sve_func: vDSP_sve function
/// - Returns: Converted mfarray
internal func sign_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_vthrsc_func: vDSP_vthrsc_func<T>, _ vDSP_vadd_func: vDSP_biopvv_func<T>, _ vDSP_sve_func: vDSP_stats_func<T>) -> MfArray{
    let mfarray = check_dense(mfarray)
        
    let size = mfarray.storedSize
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            wrap_vDSP_sign(size, $0, dstptrT, vDSP_vthrsc_func, vDSP_vadd_func, vDSP_sve_func)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Compare mfarray's elements with a scalar by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - op: The comparison operator
///   - scalar: The right-hand scalar
///   - vDSP_vthrsc_func: The vDSP vthrsc function
///   - vDSP_vneg_func: The vDSP vneg function
///   - vDSP_vadd_func: The vDSP vadd function
///   - vDSP_vnabs_func: The vDSP vnabs function
///   - vDSP_toFloat_func: The vDSP conversion function into Float. nil when T is Float
/// - Returns: Bool mfarray
internal func compare_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ op: MfCompareOp, _ scalar: T, _ vDSP_vthrsc_func: vDSP_vthrsc_func<T>, _ vDSP_vneg_func: vDSP_math_func<T, T>, _ vDSP_vadd_func: vDSP_biopvv_func<T>, _ vDSP_vnabs_func: vDSP_math_func<T, T>, _ vDSP_toFloat_func: vDSP_convert_func<T, Float>?) -> MfArray{
    let mfarray = check_dense(mfarray)
    
    let size = mfarray.storedSize
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    let newdata = MfData(uninitializedSize: size, mftype: .Bool)
    newdata.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptrF in
        let output = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            srcptr -> CompareOutput in
            if let vDSP_toFloat_func = vDSP_toFloat_func{
                let workptr = UnsafeMutablePointer<T>.allocate(capacity: size)
                defer { workptr.deallocate() }
                let output = wrap_vDSP_compare(size, srcptr, op, scalar, workptr, vDSP_vthrsc_func, vDSP_vneg_func, vDSP_vadd_func, vDSP_vnabs_func)
                vDSP_toFloat_func(workptr, vDSP_Stride(1), dstptrF, vDSP_Stride(1), vDSP_Length(size))
                return output
            }
            else{
                return dstptrF.withMemoryRebound(to: T.self, capacity: size){
                    wrap_vDSP_compare(size, srcptr, op, scalar, $0, vDSP_vthrsc_func, vDSP_vneg_func, vDSP_vadd_func, vDSP_vnabs_func)
                }
            }
        }
        _to_bool(dstptrF, size, output)
    }
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func compare_by_vDSP(_ mfarray: MfArray, _ op: MfCompareOp, _ scalar: Float) -> MfArray{
    return compare_by_vDSP(mfarray, op, scalar, vDSP_vthrsc, vDSP_vneg, vDSP_vadd, vDSP_vnabs, nil)
}

/// Convert the output of `wrap_vDSP_compare` into 1/0 in place
@inline(__always)
fileprivate func _to_bool(_ ptr: UnsafeMutablePointer<Float>, _ size: Int, _ output: CompareOutput){
    guard var (a, b) = output.toBool else { return }
    vDSP_vsmsa(ptr, vDSP_Stride(1), &a, &b, ptr, vDSP_Stride(1), vDSP_Length(size))
}

internal func compare_by_vDSP(_ mfarray: MfArray, _ op: MfCompareOp, _ scalar: Double) -> MfArray{
    return compare_by_vDSP(mfarray, op, scalar, vDSP_vthrscD, vDSP_vnegD, vDSP_vaddD, vDSP_vnabsD, vDSP_vdpsp)
}

// generate(arange)
/*
internal typealias vDSP_arange_func<T> = (UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

fileprivate func _arange_run<T: MfStorable>(_ startptr: UnsafePointer<T>, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ stride: Int, _ count: Int, _ vDSP_func: vDSP_arange_func<T>){
    vDSP_func(startptr, srcptr, dstptr, vDSP_Stride(stride), vDSP_Length(count))
}

internal func arange_by_vDSP<T: MfStorable>(_ start: T, _ by: T, _ count: Int, _ mftype: MfType, vDSP_func: vDSP_arange_func<T>) -> MfArray{
    let newdata = withDummyDataMRPtr(mftype, storedSize: count){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: count)
        var start = start
        var by = by
        _arange_run(&start, &by, dstptrT, 1, count, vDSP_func)
    }
    
    let newstructure = withDummyShapeStridesMBPtr(retShape.count){
        shapeptr, stridesptr in
        retShape.withUnsafeMutableBufferPointer{
            shapeptr.baseAddress!.moveUpdate(from: $0.baseAddress!, count: shapeptr.count)
        }
        
        let newstrides = shape2strides(shapeptr, mforder: .Row)
        stridesptr.baseAddress!.moveUpdate(from: newstrides.baseAddress!, count: shapeptr.count)
        
        newstrides.deallocate()
    }
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
*/

//TODO: ret dim = ori dim - ind dim + 1.

/// Boolean getter operation mfarray by vDSP
/// - Parameters:
///   - src_mfarray: An input mfarray
///   - indices: An indices boolean mfarray
///   - vDSP_func: vDSP_vcmprs_func
/// - Returns: Result mfarray
internal func boolget_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ vDSP_func: vDSP_vcmprs_func<T>) -> MfArray{
    assert(indices.mftype == .Bool, "must be bool")
    /*
     Note that returned shape must be (true number in original indices, (mfarray's shape - original indices' shape));
     i.e. returned dim = 1(=true number in original indices) + mfarray's dim - indices' dim
     */
    let true_num = Float.toInt(indices.sum().scalar(Float.self)!)
    let orig_ind_dim = indices.ndim
    
    // broadcast
    let indices = bool_broadcast_to(indices, shape: mfarray.shape)

    // must be row major
    let indicesT: MfArray
    switch mfarray.storedType {
    case .Float:
        indicesT = indices // indices must have float raw values
    case .Double:
        indicesT = indices.astype(.Double)
    }
    // compressed results are written sequentially, so both mfarray and indices must be row contiguous
    let mfarray = check_contiguous(mfarray, .Row)
    let size = mfarray.size
    
    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    var retShape = [true_num] + lastShape
    let retSize = shape2size(&retShape)
    
    if mfarray.isReal{
        let newdata = MfData(uninitializedSize: retSize, mftype: mfarray.mftype)
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            indicesT.withUnsafeMutableStartPointer(datatype: T.self){
                //[unowned indicesT](indptr) in
                indptr in
                // note that indices and mfarray is row contiguous
                mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                    srcptr in
                    
                    wrap_vDSP_cmprs(size, srcptr, 1, indptr, 1, dstptrT, 1, vDSP_func)
                    //vDSP_func(srcptr.baseAddress!, vDSP_Stride(1), indptr.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(indicesT.size))
                }
            }
        }
        
        
        let newstructure = MfStructure(shape: retShape, mforder: .Row)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    else{
        let newdata = MfData(uninitializedSize: retSize, mftype: mfarray.mftype, complex: true)
        newdata.withUnsafeMutablevDSPComplexPointer(datatype: T.vDSPComplexType.self){
            dstptrT in
            indicesT.withUnsafeMutableStartPointer(datatype: T.self){
                //[unowned indicesT](indptr) in
                indptr in
                // note that indices and mfarray is row contiguous
                mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.vDSPComplexType.self){
                    srcptr in
                    let srcptrr = srcptr.pointee.realp as! UnsafeMutablePointer<T>
                    let srcptri = srcptr.pointee.imagp as! UnsafeMutablePointer<T>
                    let dstptrTr = dstptrT.pointee.realp as! UnsafeMutablePointer<T>
                    let dstptrTi = dstptrT.pointee.imagp as! UnsafeMutablePointer<T>
                    
                    wrap_vDSP_cmprs(size, srcptrr, 1, indptr, 1, dstptrTr, 1, vDSP_func)
                    wrap_vDSP_cmprs(size, srcptri, 1, indptr, 1, dstptrTi, 1, vDSP_func)
                    //vDSP_func(srcptr.baseAddress!, vDSP_Stride(1), indptr.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(indicesT.size))
                }
            }
        }
        
        
        let newstructure = MfStructure(shape: retShape, mforder: .Row)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}


/// Getter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray. Must be 1d
///   - indices: An input Interger indices array
///   - vDSP_func: vDSP_vgathr_func
/// - Returns: The mfarray
internal func fancy1dgetcol_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ vDSP_func: vDSP_vgathr_func<T>) -> MfArray{
    assert(indices.mftype == .Int, "must be int")
    assert(mfarray.ndim == 1, "must be 1d")
    // fancy indexing
    // note that if not assignment, returned copy value not view.
    /*
     >>> a = np.arange(9).reshape(3,3)
     >>> a
     array([[0, 1, 2],
            [3, 4, 5],
            [6, 7, 8]])
     >>> a[[1,2],[2,2]].base
     None
     */
    // boolean indexing
    // note that if not assignment, returned copy value not view.
    /*
     a = np.arange(5)
     >>> a[a==1]
     array([1])
     >>> a[a==1].base
     None
     */
    /*
     var a = [0.0, 2.0, 3.0, 1.0]
     var c = [0.0, 0, 0]
     var bb: [UInt] = [1, 1, 3]
     vDSP_vgathrD(&a, &bb, vDSP_Stride(1), &c, vDSP_Stride(1), vDSP_Length(c.count))
     print(c)
     //[0.0, 0.0, 3.0]
     */
    if mfarray.isReal{
        let newdata = MfData(uninitializedSize: indices.size, mftype: mfarray.mftype)
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            let _ = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                srcptr in
                var offsets = index_values(indices).map{ UInt(get_positive_index($0, axissize: mfarray.size, axis: 0) * mfarray.strides[0] + 1) }
                wrap_vDSP_gathr(indices.size, srcptr, &offsets, 1, dstptrT, 1, vDSP_func)
            }
        }
        
        let newstructure = MfStructure(shape: indices.shape, mforder: .Row) // gathered in the row major order of indices
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    else{
        let newdata = MfData(uninitializedSize: indices.size, mftype: mfarray.mftype, complex: true)
        newdata.withUnsafeMutablevDSPComplexPointer(datatype: T.vDSPComplexType.self){
            dstptrT in
            let _ = mfarray.withUnsafeMutablevDSPComplexPointer(datatype: T.vDSPComplexType.self){
                srcptr in
                let srcptrr = srcptr.pointee.realp as! UnsafeMutablePointer<T>
                let srcptri = srcptr.pointee.imagp as! UnsafeMutablePointer<T>
                let dstptrTr = dstptrT.pointee.realp as! UnsafeMutablePointer<T>
                let dstptrTi = dstptrT.pointee.imagp as! UnsafeMutablePointer<T>
                
                var offsets = index_values(indices).map{ UInt(get_positive_index($0, axissize: mfarray.size, axis: 0) * mfarray.strides[0] + 1) }
                wrap_vDSP_gathr(indices.size, srcptrr, &offsets, 1, dstptrTr, 1, vDSP_func)
                wrap_vDSP_gathr(indices.size, srcptri, &offsets, 1, dstptrTi, 1, vDSP_func)
            }
        }
        
        let newstructure = MfStructure(shape: indices.shape, mforder: .Row) // gathered in the row major order of indices
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}

/*
internal typealias vDSP_vlim_func<T: MfStorable> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func lim_by_vDSP<T: MfStorable>(_ mfarray: MfArray, point: T, to: T, _ vDSP_func: vDSP_vlim_func<T>){
    let mfarray = check_contiguous(mfarray)
    var point = point
    var to = to
    
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned mfarray] dataptr in
        vDSP_func(dataptr.baseAddress!, vDSP_Stride(1), &point, &to, dataptr.baseAddress!, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
    }
}
*/

/// Dot product between multiple dimensional arraies
/// - Parameters:
///   - l_mfarray: A left mfarray
///   - r_mfarray: A right mfarray
///   - vDSP_func: vDSP_dotpr_func
/// - Returns: Dot producted mfarray
internal func dotpr_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_dotpr_func<T>) -> MfArray{
    let l_shape = l_mfarray.shape
    let r_shape = r_mfarray.shape
    assert(l_shape[0] == r_shape[1])
    
    // calculate loop size
    let size = l_shape[0]
    
    // to row major
    let l_mfarray = check_contiguous(l_mfarray, .Row)
    let r_mfarray = r_mfarray.swapaxes(axis1: -1, axis2: -2).to_contiguous(mforder: .Row)
    
    // calculate shape
    var l_rest_shape = Array(l_shape.prefix(l_shape.count - 1))
    var r_rest_shape = Array(r_shape.prefix(r_shape.count - 2) + r_shape.suffix(1))
    var ret_shape = l_rest_shape + r_rest_shape
    
    // calculate size
    let l_rest_size = l_rest_shape.count > 0 ? shape2size(&l_rest_shape) : 1
    let r_rest_size = shape2size(&r_rest_shape)
    let ret_size = shape2size(&ret_shape)
    
    let newdata = MfData(uninitializedSize: ret_size, mftype: l_mfarray.mftype)
    
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptr in
        l_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            lptr in
            r_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                rptr in
                for l_ind in 0..<l_rest_size{
                    for r_ind in 0..<r_rest_size{
                        wrap_vDSP_dotpr(size, lptr + l_ind*size, 1, rptr + r_ind*size, 1, dstptr + (l_ind*r_rest_size + r_ind), vDSP_func)
                    }
                }
            }
        }
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Real forward FFT by vDSP. Same as `np.fft.rfft`.
/// - Parameters:
///   - mfarray: A real mfarray
///   - number: The number of points along the axis. The signal is cropped or zero-padded to it. Must be a power of 2
///   - axis: The axis
///   - norm: The normalization mode
/// - Returns: The complex mfarray whose size along the axis is number/2+1
internal func rfft_by_vDSP(_ mfarray: MfArray, number: Int, axis: Int, norm: FFTNorm) -> MfArray{
    switch mfarray.storedType{
    case .Float:
        return _rfft_by_vDSP(mfarray, number: number, axis: axis, norm: norm, DSPSplitComplex.self,
                             create_setup: { vDSP_create_fftsetup($0, FFTRadix(kFFTRadix2)) },
                             destroy_setup: { vDSP_destroy_fftsetup($0) },
                             ctoz: { src, dst, n in
                                src.withMemoryRebound(to: DSPComplex.self, capacity: n){ vDSP_ctoz($0, 2, dst, 1, vDSP_Length(n)) }
                             },
                             fft: { setup, dst, log2n in vDSP_fft_zrip(setup, dst, 1, vDSP_Length(log2n), FFTDirection(kFFTDirection_Forward)) },
                             vsmul: vDSP_vsmul)
    case .Double:
        return _rfft_by_vDSP(mfarray, number: number, axis: axis, norm: norm, DSPDoubleSplitComplex.self,
                             create_setup: { vDSP_create_fftsetupD($0, FFTRadix(kFFTRadix2)) },
                             destroy_setup: { vDSP_destroy_fftsetupD($0) },
                             ctoz: { src, dst, n in
                                src.withMemoryRebound(to: DSPDoubleComplex.self, capacity: n){ vDSP_ctozD($0, 2, dst, 1, vDSP_Length(n)) }
                             },
                             fft: { setup, dst, log2n in vDSP_fft_zripD(setup, dst, 1, vDSP_Length(log2n), FFTDirection(kFFTDirection_Forward)) },
                             vsmul: vDSP_vsmulD)
    }
}

fileprivate func _rfft_by_vDSP<S: vDSP_ComplexTypable>(_ mfarray: MfArray, number: Int, axis: Int, norm: FFTNorm, _ splitType: S.Type,
                                                         create_setup: (vDSP_Length) -> OpaquePointer?,
                                                         destroy_setup: (OpaquePointer?) -> Void,
                                                         ctoz: (UnsafeMutablePointer<S.T>, UnsafeMutablePointer<S>, Int) -> Void,
                                                         fft: (OpaquePointer, UnsafeMutablePointer<S>, Int) -> Void,
                                                         vsmul: vDSP_biopvs_func<S.T>) -> MfArray{
    typealias T = S.T
    precondition(mfarray.isReal, "Must be real in REAL FFT. Use FFT instead")
    precondition(number >= 2 && number & (number - 1) == 0, "vDSP rfft supports a power of 2 number only. Use vDSP: false for other numbers")
    let axis = get_positive_axis(axis, ndim: mfarray.ndim)
    let log2n = number.trailingZeroBitCount
    let half = number / 2
    
    // signals along the last axis, cropped to `number`
    var src = mfarray.moveaxis(src: axis, dst: -1)
    if src.shape[src.ndim - 1] > number{
        src = src.moveaxis(src: -1, dst: 0)[0~<number].moveaxis(src: 0, dst: -1)
    }
    src = check_contiguous(src, .Row)
    let srcLength = src.shape[src.ndim - 1]
    // the number of signals (an empty signal is zero padded to `number`, so it still gives an output row)
    let rows = src.shape.dropLast().reduce(1, *)
    
    var retShape = src.shape
    retShape[retShape.count - 1] = half + 1
    let dstLength = half + 1
    let newdata = MfData(uninitializedSize: rows * dstLength, mftype: MfType.storedType(mfarray.mftype).to_mftype(), complex: true)
    
    let setup = create_setup(vDSP_Length(log2n))!
    defer { destroy_setup(setup) }
    // a zero padded signal is copied into this buffer. Its tail stays 0
    let padded: UnsafeMutablePointer<T>? = srcLength < number ? allocate_unsafeMPtrT(type: T.self, count: number, zeroed: true) : nil
    defer { padded?.deallocate() }
    
    newdata.withUnsafeMutablevDSPComplexPointer(datatype: S.self){
        dstptr in
        src.withUnsafeMutableStartPointer(datatype: T.self){
            srcptr in
            for r in 0..<rows{
                var signal = srcptr + r * srcLength
                if let padded = padded{
                    padded.update(from: signal, count: srcLength)
                    signal = padded
                }
                var dst = S(realp: dstptr.pointee.realp + r * dstLength, imagp: dstptr.pointee.imagp + r * dstLength)
                // pack the real signal into the split complex form (even -> realp, odd -> imagp) and transform in place
                ctoz(signal, &dst, half)
                fft(setup, &dst, log2n)
                // the DC and Nyquist components (both real) are packed in realp[0] and imagp[0]
                dst.realp[half] = dst.imagp[0]
                dst.imagp[half] = T.zero
                dst.imagp[0] = T.zero
            }
        }
        // vDSP's real FFT is 2x of the mathematical one
        var scale: T
        switch norm{
        case .backward:
            scale = T.from(0.5)
        case .ortho:
            scale = T.from(0.5 / Double(number).squareRoot())
        case .forward:
            scale = T.from(0.5 / Double(number))
        }
        let size = vDSP_Length(rows * dstLength)
        vsmul(dstptr.pointee.realp, 1, &scale, dstptr.pointee.realp, 1, size)
        vsmul(dstptr.pointee.imagp, 1, &scale, dstptr.pointee.imagp, 1, size)
    }
    
    return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: retShape, mforder: .Row)).moveaxis(src: -1, dst: axis)
}

/// Convert mfarray into CGImage. Supported color space is Gray (h, w), (h, w, 1)  or RGB (h, w, 4)
/// - Parameters:
///   - src_mfarray: An input mfarray
///   - vDSP_func: vDSP_convert_func
/// - Returns: CGImage
/// ref: https://stackoverflow.com/questions/34677133/how-to-reconstruct-grayscale-image-from-intensity-values
/// OpenCV: https://github.com/opencv/opencv/blob/ed69bcae2d171d9426cd3688a8b0ee14b8a140cd/modules/imgcodecs/src/apple_conversions.mm#L47
internal func mfarray2cgimage_by_vDSP<T: MfStorable>(_ src_mfarray: MfArray, vDSP_func: vDSP_convert_func<T, UInt8>) -> CGImage{
    var (mfarray, height, width, channel) = check_and_convert_image_dim(src_mfarray)

    let colorSpace: CGColorSpace
    let bitmapInfo: CGBitmapInfo
    
    if src_mfarray.mftype == .Float{
        if channel == 1{// gray
            colorSpace = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
        }
        else if channel == 4{
            colorSpace = CGColorSpaceCreateDeviceRGB()
            // straight alpha like UInt8
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
        }
        else{
            preconditionFailure("Unsupported channel number: \(mfarray.shape[2])")
        }
        
        mfarray = check_contiguous(mfarray, .Row)
        return mfarray.withUnsafeMutableStartRawPointer{
            srcptr in
            // NOTE: Force cast to UInt8
            return _rawptr2cgimage(srcptr.assumingMemoryBound(to: UInt8.self), bitmapInfo: bitmapInfo, colorSpace: colorSpace, byteNumber: 4, width: width, height: height, channel: channel)
        }
    }
    else{
        if channel == 1{// gray
            colorSpace = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        }
        else if channel == 4{
            colorSpace = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        }
        else{
            preconditionFailure("Unsupported channel number: \(mfarray.shape[2])")
        }
        var shape = mfarray.shape
        var arr = Array<UInt8>(repeating: UInt8.zero, count: src_mfarray.size)
        let dst_strides = shape2strides(&shape, mforder: .Row)
        
        // StoredType to UInt8 (row_contiguous)
        arr.withUnsafeMutableBufferPointer{
            dstptrU in
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                [unowned mfarray] srcptrT in
                
                for vDSPPrams in OptOffsetParamsSequence(shape: shape, bigger_strides: dst_strides, smaller_strides: mfarray.strides){
                    
                    wrap_vDSP_convert(vDSPPrams.blocksize, srcptrT + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrU.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                }
                
            }
        }
        
        return _rawptr2cgimage(&arr, bitmapInfo: bitmapInfo, colorSpace: colorSpace, byteNumber: 1, width: width, height: height, channel: channel)
    }
}

fileprivate func _rawptr2cgimage(_ srcrawptr: UnsafeMutablePointer<UInt8>, bitmapInfo: CGBitmapInfo, colorSpace: CGColorSpace, byteNumber: Int, width: Int, height: Int, channel: Int) -> CGImage{
    let provider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, srcrawptr, width*height*channel*byteNumber))
    let cgimage =  CGImage(width: width, height: height, bitsPerComponent: 8*byteNumber, bitsPerPixel: 8*channel*byteNumber, bytesPerRow: width*channel*byteNumber, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
    
    return cgimage
}

/// The largest absolute value over the real and imaginary parts. NaN if any element is NaN
/// - Parameter mfarray: An input mfarray
/// - Returns: The largest absolute value. 0 for an empty mfarray
internal func maxmg_by_vDSP(_ mfarray: MfArray) -> Double{
    let mfarray = check_dense(mfarray)
    let size = mfarray.size
    guard size > 0 else { return 0 }
    var ret = 0.0
    switch mfarray.storedType{
    case .Float:
        var m = Float.zero
        mfarray.withUnsafeMutableStartPointer(datatype: Float.self){ vDSP_maxmgv($0, 1, &m, vDSP_Length(size)) }
        ret = Double(m)
        mfarray.withUnsafeMutableStartImagPointer(datatype: Float.self){
            guard let ptr = $0 else { return }
            vDSP_maxmgv(ptr, 1, &m, vDSP_Length(size))
            ret = ret.isNaN || m.isNaN ? .nan : Swift.max(ret, Double(m))
        }
    case .Double:
        var m = Double.zero
        mfarray.withUnsafeMutableStartPointer(datatype: Double.self){ vDSP_maxmgvD($0, 1, &m, vDSP_Length(size)) }
        ret = m
        mfarray.withUnsafeMutableStartImagPointer(datatype: Double.self){
            guard let ptr = $0 else { return }
            vDSP_maxmgvD(ptr, 1, &m, vDSP_Length(size))
            ret = ret.isNaN || m.isNaN ? .nan : Swift.max(ret, m)
        }
    }
    // vDSP_maxmgv drops NaN on x86_64 (maxps returns the other operand). The sum of magnitudes always propagates NaN
    if !ret.isNaN && _sumOfMagnitudes_by_vDSP(mfarray).isNaN{
        return .nan
    }
    return ret
}

/// The sum of |real| and |imag| over a dense mfarray
fileprivate func _sumOfMagnitudes_by_vDSP(_ mfarray: MfArray) -> Double{
    let size = mfarray.size
    var ret = 0.0
    switch mfarray.storedType{
    case .Float:
        var s = Float.zero
        mfarray.withUnsafeMutableStartPointer(datatype: Float.self){ vDSP_svemg($0, 1, &s, vDSP_Length(size)) }
        ret = Double(s)
        mfarray.withUnsafeMutableStartImagPointer(datatype: Float.self){
            guard let ptr = $0 else { return }
            vDSP_svemg(ptr, 1, &s, vDSP_Length(size))
            ret += Double(s)
        }
    case .Double:
        var s = Double.zero
        mfarray.withUnsafeMutableStartPointer(datatype: Double.self){ vDSP_svemgD($0, 1, &s, vDSP_Length(size)) }
        ret = s
        mfarray.withUnsafeMutableStartImagPointer(datatype: Double.self){
            guard let ptr = $0 else { return }
            vDSP_svemgD(ptr, 1, &s, vDSP_Length(size))
            ret += s
        }
    }
    return ret
}

#else
// MARK: - WASI Fallback Implementations

internal typealias vDSP_biopvv_func<T> = (UnsafePointer<T>, Int, UnsafePointer<T>, Int, UnsafeMutablePointer<T>, Int, Int) -> Void
internal typealias vDSP_biopvs_func<T> = (UnsafePointer<T>, Int, UnsafePointer<T>, UnsafeMutablePointer<T>, Int, Int) -> Void
internal typealias vDSP_biopsv_func<T> = (UnsafePointer<T>, UnsafePointer<T>, Int, UnsafeMutablePointer<T>, Int, Int) -> Void
internal typealias vDSP_stats_func<T> = (UnsafePointer<T>, Int, UnsafeMutablePointer<T>, Int) -> Void
internal typealias vDSP_stats_index_func<T> = (UnsafePointer<T>, Int, UnsafeMutablePointer<T>, UnsafeMutablePointer<UInt>, Int) -> Void
internal typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, Int, UnsafeMutablePointer<U>, Int, Int) -> Void
internal typealias vDSP_sort_func<T> = (UnsafeMutablePointer<T>, Int, Int32) -> Void
internal typealias vDSP_argsort_func<T> = (UnsafePointer<T>, UnsafeMutablePointer<UInt>, UnsafeMutablePointer<UInt>, Int, Int32) -> Void
internal typealias vDSP_clip_func<T> = (UnsafePointer<T>, Int, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, Int, Int, UnsafeMutablePointer<UInt>, UnsafeMutablePointer<UInt>) -> Void
internal typealias vDSP_vminmg_func<T> = (UnsafePointer<T>, Int, UnsafePointer<T>, Int, UnsafeMutablePointer<T>, Int, Int) -> Void
internal typealias vDSP_viclip_func<T> = (UnsafePointer<T>, Int, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, Int, Int) -> Void
internal typealias vDSP_vcmprs_func<T> = (UnsafePointer<T>, Int, UnsafePointer<T>, Int, UnsafeMutablePointer<T>, Int, Int) -> Void
internal typealias vDSP_vgathr_func<T> = (UnsafePointer<T>, UnsafePointer<UInt>, Int, UnsafeMutablePointer<T>, Int, Int) -> Void
internal typealias vDSP_dotpr_func<T> = (UnsafePointer<T>, Int, UnsafePointer<T>, Int, UnsafeMutablePointer<T>, Int) -> Void

// MARK: - Comparison

/// Pure Swift fallback for compare_by_vDSP
internal func compare_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ op: MfCompareOp, _ scalar: T) -> MfArray{
    let mfarray = check_dense(mfarray)
    
    let size = mfarray.storedSize
    let newdata = MfData(uninitializedSize: size, mftype: .Bool)
    newdata.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptr in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            srcptr in
            for i in 0..<size{
                let x = srcptr[i]
                let ret: Bool
                switch op {
                case .greater: ret = x > scalar
                case .greaterEqual: ret = x >= scalar
                case .less: ret = x < scalar
                case .lessEqual: ret = x <= scalar
                case .equal: ret = x == scalar
                case .notEqual: ret = x != scalar
                }
                dstptr[i] = ret ? Float(1) : Float.zero
            }
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

// MARK: - vDSP Binary Operations (Vector-Vector)

@inline(__always)
internal func vDSP_vadd(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcA[i * strideA] + srcB[i * strideB]
    }
}

@inline(__always)
internal func vDSP_vaddD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcA[i * strideA] + srcB[i * strideB]
    }
}

@inline(__always)
internal func vDSP_vsub(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcB[i * strideB] - srcA[i * strideA]
    }
}

@inline(__always)
internal func vDSP_vsubD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcB[i * strideB] - srcA[i * strideA]
    }
}

@inline(__always)
internal func vDSP_vmul(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcA[i * strideA] * srcB[i * strideB]
    }
}

@inline(__always)
internal func vDSP_vmulD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcA[i * strideA] * srcB[i * strideB]
    }
}

@inline(__always)
internal func vDSP_vdiv(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcB[i * strideB] / srcA[i * strideA]
    }
}

@inline(__always)
internal func vDSP_vdivD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcB[i * strideB] / srcA[i * strideA]
    }
}

@inline(__always)
internal func vDSP_vmax(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = Swift.max(srcA[i * strideA], srcB[i * strideB])
    }
}

@inline(__always)
internal func vDSP_vmaxD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = Swift.max(srcA[i * strideA], srcB[i * strideB])
    }
}

@inline(__always)
internal func vDSP_vmin(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = Swift.min(srcA[i * strideA], srcB[i * strideB])
    }
}

@inline(__always)
internal func vDSP_vminD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = Swift.min(srcA[i * strideA], srcB[i * strideB])
    }
}

// MARK: - vDSP Binary Operations (Vector-Scalar)

@inline(__always)
internal func vDSP_vsmsa(_ src: UnsafePointer<Float>, _ srcStride: Int, _ scale: UnsafePointer<Float>, _ add: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = src[i * srcStride] * scale.pointee + add.pointee
    }
}

@inline(__always)
internal func vDSP_vsma(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ scale: UnsafePointer<Float>, _ srcC: UnsafePointer<Float>, _ strideC: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = srcA[i * strideA] * scale.pointee + srcC[i * strideC]
    }
}

@inline(__always)
internal func vDSP_vsadd(_ src: UnsafePointer<Float>, _ srcStride: Int, _ scalar: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = src[i * srcStride] + s
    }
}

@inline(__always)
internal func vDSP_vsaddD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ scalar: UnsafePointer<Double>, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = src[i * srcStride] + s
    }
}

@inline(__always)
internal func vDSP_vsmul(_ src: UnsafePointer<Float>, _ srcStride: Int, _ scalar: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = src[i * srcStride] * s
    }
}

@inline(__always)
internal func vDSP_vsmulD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ scalar: UnsafePointer<Double>, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = src[i * srcStride] * s
    }
}

@inline(__always)
internal func vDSP_vsdiv(_ src: UnsafePointer<Float>, _ srcStride: Int, _ scalar: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = src[i * srcStride] / s
    }
}

@inline(__always)
internal func vDSP_vsdivD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ scalar: UnsafePointer<Double>, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = src[i * srcStride] / s
    }
}

@inline(__always)
internal func vDSP_svdiv(_ scalar: UnsafePointer<Float>, _ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = s / src[i * srcStride]
    }
}

@inline(__always)
internal func vDSP_svdivD(_ scalar: UnsafePointer<Double>, _ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    let s = scalar.pointee
    for i in 0..<count {
        dst[i * dstStride] = s / src[i * srcStride]
    }
}

// MARK: - vDSP Stats Functions

@inline(__always)
internal func vDSP_meanv(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ count: Int) {
    var sum: Float = 0
    for i in 0..<count {
        sum += src[i * srcStride]
    }
    dst.pointee = sum / Float(count)
}

@inline(__always)
internal func vDSP_meanvD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ count: Int) {
    var sum: Double = 0
    for i in 0..<count {
        sum += src[i * srcStride]
    }
    dst.pointee = sum / Double(count)
}

@inline(__always)
internal func vDSP_maxv(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; return }
    var maxVal = src[0]
    for i in 1..<count {
        let val = src[i * srcStride]
        if val > maxVal { maxVal = val }
    }
    dst.pointee = maxVal
}

@inline(__always)
internal func vDSP_maxvD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; return }
    var maxVal = src[0]
    for i in 1..<count {
        let val = src[i * srcStride]
        if val > maxVal { maxVal = val }
    }
    dst.pointee = maxVal
}

@inline(__always)
internal func vDSP_minv(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; return }
    var minVal = src[0]
    for i in 1..<count {
        let val = src[i * srcStride]
        if val < minVal { minVal = val }
    }
    dst.pointee = minVal
}

@inline(__always)
internal func vDSP_minvD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; return }
    var minVal = src[0]
    for i in 1..<count {
        let val = src[i * srcStride]
        if val < minVal { minVal = val }
    }
    dst.pointee = minVal
}

@inline(__always)
internal func vDSP_maxvi(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ idx: UnsafeMutablePointer<UInt>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; idx.pointee = 0; return }
    var maxVal = src[0]
    var maxIdx: UInt = 0
    for i in 1..<count {
        let val = src[i * srcStride]
        if val > maxVal {
            maxVal = val
            maxIdx = UInt(i * srcStride)
        }
    }
    dst.pointee = maxVal
    idx.pointee = maxIdx
}

@inline(__always)
internal func vDSP_maxviD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ idx: UnsafeMutablePointer<UInt>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; idx.pointee = 0; return }
    var maxVal = src[0]
    var maxIdx: UInt = 0
    for i in 1..<count {
        let val = src[i * srcStride]
        if val > maxVal {
            maxVal = val
            maxIdx = UInt(i * srcStride)
        }
    }
    dst.pointee = maxVal
    idx.pointee = maxIdx
}

@inline(__always)
internal func vDSP_minvi(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ idx: UnsafeMutablePointer<UInt>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; idx.pointee = 0; return }
    var minVal = src[0]
    var minIdx: UInt = 0
    for i in 1..<count {
        let val = src[i * srcStride]
        if val < minVal {
            minVal = val
            minIdx = UInt(i * srcStride)
        }
    }
    dst.pointee = minVal
    idx.pointee = minIdx
}

@inline(__always)
internal func vDSP_minviD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ idx: UnsafeMutablePointer<UInt>, _ count: Int) {
    guard count > 0 else { dst.pointee = 0; idx.pointee = 0; return }
    var minVal = src[0]
    var minIdx: UInt = 0
    for i in 1..<count {
        let val = src[i * srcStride]
        if val < minVal {
            minVal = val
            minIdx = UInt(i * srcStride)
        }
    }
    dst.pointee = minVal
    idx.pointee = minIdx
}

@inline(__always)
internal func vDSP_sve(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ count: Int) {
    var sum: Float = 0
    for i in 0..<count {
        sum += src[i * srcStride]
    }
    dst.pointee = sum
}

@inline(__always)
internal func vDSP_sveD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ count: Int) {
    var sum: Double = 0
    for i in 0..<count {
        sum += src[i * srcStride]
    }
    dst.pointee = sum
}

@inline(__always)
internal func vDSP_svesq(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ count: Int) {
    var sum: Float = 0
    for i in 0..<count {
        let val = src[i * srcStride]
        sum += val * val
    }
    dst.pointee = sum
}

@inline(__always)
internal func vDSP_svesqD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ count: Int) {
    var sum: Double = 0
    for i in 0..<count {
        let val = src[i * srcStride]
        sum += val * val
    }
    dst.pointee = sum
}

// MARK: - vDSP Math Functions

@inline(__always)
internal func vDSP_vsq(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        let val = src[i * srcStride]
        dst[i * dstStride] = val * val
    }
}

@inline(__always)
internal func vDSP_vsqD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        let val = src[i * srcStride]
        dst[i * dstStride] = val * val
    }
}

@inline(__always)
internal func vDSP_vneg(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = -src[i * srcStride]
    }
}

@inline(__always)
internal func vDSP_vnegD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = -src[i * srcStride]
    }
}

// MARK: - vDSP Sort Functions

@inline(__always)
internal func vDSP_vsort(_ src: UnsafeMutablePointer<Float>, _ count: Int, _ order: Int32) {
    var arr = Array(UnsafeBufferPointer(start: src, count: count))
    if order == 1 {
        arr.sort(by: <)
    } else {
        arr.sort(by: >)
    }
    for i in 0..<count {
        src[i] = arr[i]
    }
}

@inline(__always)
internal func vDSP_vsortD(_ src: UnsafeMutablePointer<Double>, _ count: Int, _ order: Int32) {
    var arr = Array(UnsafeBufferPointer(start: src, count: count))
    if order == 1 {
        arr.sort(by: <)
    } else {
        arr.sort(by: >)
    }
    for i in 0..<count {
        src[i] = arr[i]
    }
}

@inline(__always)
internal func vDSP_vsorti(_ src: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<UInt>, _ tmp: UnsafeMutablePointer<UInt>, _ count: Int, _ order: Int32) {
    var indices = Array(0..<UInt(count))
    if order == 1 {
        indices.sort { src[Int($0)] < src[Int($1)] }
    } else {
        indices.sort { src[Int($0)] > src[Int($1)] }
    }
    for i in 0..<count {
        dst[i] = indices[i]
    }
}

@inline(__always)
internal func vDSP_vsortiD(_ src: UnsafePointer<Double>, _ dst: UnsafeMutablePointer<UInt>, _ tmp: UnsafeMutablePointer<UInt>, _ count: Int, _ order: Int32) {
    var indices = Array(0..<UInt(count))
    if order == 1 {
        indices.sort { src[Int($0)] < src[Int($1)] }
    } else {
        indices.sort { src[Int($0)] > src[Int($1)] }
    }
    for i in 0..<count {
        dst[i] = indices[i]
    }
}

// MARK: - vDSP Clip Functions

@inline(__always)
internal func vDSP_vclip(_ src: UnsafePointer<Float>, _ srcStride: Int, _ low: UnsafePointer<Float>, _ high: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int, _ lowCount: UnsafeMutablePointer<UInt>, _ highCount: UnsafeMutablePointer<UInt>) {
    let lo = low.pointee
    let hi = high.pointee
    var lc: UInt = 0
    var hc: UInt = 0
    for i in 0..<count {
        let val = src[i * srcStride]
        if val < lo {
            dst[i * dstStride] = lo
            lc += 1
        } else if val > hi {
            dst[i * dstStride] = hi
            hc += 1
        } else {
            dst[i * dstStride] = val
        }
    }
    lowCount.pointee = lc
    highCount.pointee = hc
}

@inline(__always)
internal func vDSP_vclipD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ low: UnsafePointer<Double>, _ high: UnsafePointer<Double>, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int, _ lowCount: UnsafeMutablePointer<UInt>, _ highCount: UnsafeMutablePointer<UInt>) {
    let lo = low.pointee
    let hi = high.pointee
    var lc: UInt = 0
    var hc: UInt = 0
    for i in 0..<count {
        let val = src[i * srcStride]
        if val < lo {
            dst[i * dstStride] = lo
            lc += 1
        } else if val > hi {
            dst[i * dstStride] = hi
            hc += 1
        } else {
            dst[i * dstStride] = val
        }
    }
    lowCount.pointee = lc
    highCount.pointee = hc
}

// MARK: - vDSP Misc Functions

@inline(__always)
internal func vDSP_vminmg(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = Swift.min(abs(srcA[i * strideA]), abs(srcB[i * strideB]))
    }
}

@inline(__always)
internal func vDSP_vminmgD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ strideDst: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * strideDst] = Swift.min(abs(srcA[i * strideA]), abs(srcB[i * strideB]))
    }
}

@inline(__always)
internal func vDSP_viclip(_ src: UnsafePointer<Float>, _ srcStride: Int, _ low: UnsafePointer<Float>, _ high: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    let lo = low.pointee
    let hi = high.pointee
    for i in 0..<count {
        let val = src[i * srcStride]
        if val > lo && val < hi {
            dst[i * dstStride] = hi
        } else {
            dst[i * dstStride] = val
        }
    }
}

@inline(__always)
internal func vDSP_viclipD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ low: UnsafePointer<Double>, _ high: UnsafePointer<Double>, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    let lo = low.pointee
    let hi = high.pointee
    for i in 0..<count {
        let val = src[i * srcStride]
        if val > lo && val < hi {
            dst[i * dstStride] = hi
        } else {
            dst[i * dstStride] = val
        }
    }
}

@inline(__always)
internal func vDSP_vcmprs(_ src: UnsafePointer<Float>, _ srcStride: Int, _ gate: UnsafePointer<Float>, _ gateStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    var dstIdx = 0
    for i in 0..<count {
        if gate[i * gateStride] != 0 {
            dst[dstIdx * dstStride] = src[i * srcStride]
            dstIdx += 1
        }
    }
}

@inline(__always)
internal func vDSP_vcmprsD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ gate: UnsafePointer<Double>, _ gateStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    var dstIdx = 0
    for i in 0..<count {
        if gate[i * gateStride] != 0 {
            dst[dstIdx * dstStride] = src[i * srcStride]
            dstIdx += 1
        }
    }
}

@inline(__always)
internal func vDSP_vgathr(_ src: UnsafePointer<Float>, _ indices: UnsafePointer<UInt>, _ indStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        let idx = Int(indices[i * indStride]) - 1
        dst[i * dstStride] = src[idx]
    }
}

@inline(__always)
internal func vDSP_vgathrD(_ src: UnsafePointer<Double>, _ indices: UnsafePointer<UInt>, _ indStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        let idx = Int(indices[i * indStride]) - 1
        dst[i * dstStride] = src[idx]
    }
}

@inline(__always)
internal func vDSP_dotpr(_ srcA: UnsafePointer<Float>, _ strideA: Int, _ srcB: UnsafePointer<Float>, _ strideB: Int, _ dst: UnsafeMutablePointer<Float>, _ count: Int) {
    var sum: Float = 0
    for i in 0..<count {
        sum += srcA[i * strideA] * srcB[i * strideB]
    }
    dst.pointee = sum
}

@inline(__always)
internal func vDSP_dotprD(_ srcA: UnsafePointer<Double>, _ strideA: Int, _ srcB: UnsafePointer<Double>, _ strideB: Int, _ dst: UnsafeMutablePointer<Double>, _ count: Int) {
    var sum: Double = 0
    for i in 0..<count {
        sum += srcA[i * strideA] * srcB[i * strideB]
    }
    dst.pointee = sum
}

// MARK: - vDSP Conversion Functions

@inline(__always)
internal func vDSP_vflt8(_ src: UnsafePointer<Int8>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Float(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vflt16(_ src: UnsafePointer<Int16>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Float(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vflt32(_ src: UnsafePointer<Int32>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Float(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfltu8(_ src: UnsafePointer<UInt8>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Float(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfltu16(_ src: UnsafePointer<UInt16>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Float(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfltu32(_ src: UnsafePointer<UInt32>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Float(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfix8(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int8(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfix16(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int16(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfix32(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int32(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfixu8(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt8(Swift.max(0, Swift.min(255, src[i * srcStride])))
    }
}

@inline(__always)
internal func vDSP_vfixu16(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt16(Swift.max(0, src[i * srcStride]))
    }
}

@inline(__always)
internal func vDSP_vfixu32(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt32(Swift.max(0, src[i * srcStride]))
    }
}

@inline(__always)
internal func vDSP_vspdp(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Double(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vdpsp(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Float(src[i * srcStride])
    }
}

// MARK: - vDSP Double Conversion Functions

@inline(__always)
internal func vDSP_vflt8D(_ src: UnsafePointer<Int8>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Double(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vflt16D(_ src: UnsafePointer<Int16>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Double(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vflt32D(_ src: UnsafePointer<Int32>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Double(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfltu8D(_ src: UnsafePointer<UInt8>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Double(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfltu16D(_ src: UnsafePointer<UInt16>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Double(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfltu32D(_ src: UnsafePointer<UInt32>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Double(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfix8D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int8(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfix16D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int16(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfix32D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int32(src[i * srcStride])
    }
}

@inline(__always)
internal func vDSP_vfixu8D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt8(Swift.max(0, Swift.min(255, src[i * srcStride])))
    }
}

@inline(__always)
internal func vDSP_vfixu16D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt16(Swift.max(0, src[i * srcStride]))
    }
}

@inline(__always)
internal func vDSP_vfixu32D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt32(Swift.max(0, src[i * srcStride]))
    }
}

// MARK: - vDSP Rounded Conversion Functions (Float to Integer with rounding)

/// Round to the nearest (even) and wrap around out of range values like vDSP, e.g. -5 -> 251 for UInt8. Non-finite values become 0
@inline(__always)
fileprivate func _wrapping_round<T: FixedWidthInteger>(_ value: Float, to type: T.Type) -> T{
    let rounded = value.rounded(.toNearestOrEven)
    guard rounded.isFinite && Swift.abs(rounded) < 9.2e18 else { return 0 }
    return T(truncatingIfNeeded: Int64(rounded))
}

@inline(__always)
internal func vDSP_vfixr8(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = _wrapping_round(src[i * srcStride], to: Int8.self)
    }
}

@inline(__always)
internal func vDSP_vfixr16(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = _wrapping_round(src[i * srcStride], to: Int16.self)
    }
}

@inline(__always)
internal func vDSP_vfixr32(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = _wrapping_round(src[i * srcStride], to: Int32.self)
    }
}

@inline(__always)
internal func vDSP_vfixru8(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = _wrapping_round(src[i * srcStride], to: UInt8.self)
    }
}

@inline(__always)
internal func vDSP_vfixru16(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = _wrapping_round(src[i * srcStride], to: UInt16.self)
    }
}

@inline(__always)
internal func vDSP_vfixru32(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = _wrapping_round(src[i * srcStride], to: UInt32.self)
    }
}

// MARK: - vDSP Rounded Conversion Functions (Double to Integer with rounding)

@inline(__always)
internal func vDSP_vfixr8D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int8(clamping: Int(src[i * srcStride].rounded()))
    }
}

@inline(__always)
internal func vDSP_vfixr16D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int16(clamping: Int(src[i * srcStride].rounded()))
    }
}

@inline(__always)
internal func vDSP_vfixr32D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Int32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = Int32(clamping: Int64(src[i * srcStride].rounded()))
    }
}

@inline(__always)
internal func vDSP_vfixru8D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt8>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt8(truncatingIfNeeded: Int(src[i * srcStride].rounded()))
    }
}

@inline(__always)
internal func vDSP_vfixru16D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt16>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt16(clamping: Int(src[i * srcStride].rounded()))
    }
}

@inline(__always)
internal func vDSP_vfixru32D(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<UInt32>, _ dstStride: Int, _ count: Int) {
    for i in 0..<count {
        dst[i * dstStride] = UInt32(clamping: Int64(src[i * srcStride].rounded()))
    }
}

// MARK: - vDSP Wrapper Functions for WASI

@inline(__always)
internal func wrap_vDSP_convert<T, U>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<U>, _ dstStride: Int, _ vDSP_func: (UnsafePointer<T>, Int, UnsafeMutablePointer<U>, Int, Int) -> Void){
    vDSP_func(srcptr, srcStride, dstptr, dstStride, size)
}

@inline(__always)
internal func wrap_vDSP_biopvv<T>(_ size: Int, _ lsrcptr: UnsafePointer<T>, _ lsrcStride: Int, _ rsrcptr: UnsafePointer<T>, _ rsrcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopvv_func<T>){
    vDSP_func(rsrcptr, rsrcStride, lsrcptr, lsrcStride, dstptr, dstStride, size)
}

@inline(__always)
internal func wrap_vDSP_biopvs<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ scalar: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopvs_func<T>){
    vDSP_func(srcptr, srcStride, scalar, dstptr, dstStride, size)
}

@inline(__always)
internal func wrap_vDSP_biopsv<T>(_ size: Int, _ scalar: UnsafePointer<T>, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_biopsv_func<T>){
    vDSP_func(scalar, srcptr, srcStride, dstptr, dstStride, size)
}

@inline(__always)
internal func wrap_vDSP_stats<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ stride: Int, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_func: vDSP_stats_func<T>){
    vDSP_func(srcptr, stride, dstptr, size)
}

@inline(__always)
internal func wrap_vDSP_stats_index<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ stride: Int, _ dstptr: UnsafeMutablePointer<UInt>, _ vDSP_func: vDSP_stats_index_func<T>){
    // the max / min value (not used)
    var value = T.zero
    vDSP_func(srcptr, stride, &value, dstptr, size)
}

@inline(__always)
internal func wrap_vDSP_sort<T>(_ size: Int, _ srcdstptr: UnsafeMutablePointer<T>, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_func<T>){
    vDSP_func(srcdstptr, size, order.rawValue)
}

@inline(__always)
internal func wrap_vDSP_argsort<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<UInt>, _ order: MfSortOrder, _ vDSP_func: vDSP_argsort_func<T>){
    var tmp = Array<UInt>(repeating: 0, count: size)
    vDSP_func(srcptr, dstptr, &tmp, size, order.rawValue)
}

@inline(__always)
internal func wrap_vDSP_clip<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ minptr: UnsafePointer<T>, _ maxptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_clip_func: vDSP_clip_func<T>){
    var mincount = UInt(0)
    var maxcount = UInt(0)
    vDSP_clip_func(srcptr, 1, minptr, maxptr, dstptr, 1, size, &mincount, &maxcount)
}

@inline(__always)
internal func wrap_vDSP_cmprs<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ indptr: UnsafePointer<T>, _ indStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_vcmprs_func<T>){
    vDSP_func(srcptr, srcStride, indptr, indStride, dstptr, dstStride, size)
}

@inline(__always)
internal func wrap_vDSP_gathr<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ indptr: UnsafePointer<UInt>, _ indStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_vgathr_func<T>){
    vDSP_func(srcptr, indptr, indStride, dstptr, dstStride, size)
}

@inline(__always)
internal func wrap_vDSP_dotpr<T>(_ size: Int, _ lsrcptr: UnsafePointer<T>, _ lsrcStride: Int, _ rsrcptr: UnsafePointer<T>, _ rsrcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_func: vDSP_dotpr_func<T>){
    vDSP_func(lsrcptr, lsrcStride, rsrcptr, rsrcStride, dstptr, size)
}

// MARK: - vDSP High-Level Functions for WASI

internal func contiguous_and_astype_by_vDSP<T: MfStorable, U: MfStorable>(_ src_mfarray: MfArray, mftype: MfType, mforder: MfOrder, vDSP_func: vDSP_convert_func<T, U>) -> MfArray{
    var ret_shape = src_mfarray.shape
    let ret_strides = shape2strides(&ret_shape, mforder: mforder)

    let newdata = MfData(uninitializedSize: src_mfarray.size, mftype: mftype)

    newdata.withUnsafeMutableStartPointer(datatype: U.self){
        dstptrU in
        src_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned src_mfarray] srcptrT in

            for vDSPPrams in OptOffsetParamsSequence(shape: ret_shape, bigger_strides: ret_strides, smaller_strides: src_mfarray.strides){

                wrap_vDSP_convert(vDSPPrams.blocksize, srcptrT + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrU + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
            }

        }
    }

    let newstructure = MfStructure(shape: ret_shape, strides: ret_strides)

    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func preop_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    var mfarray = mfarray
    mfarray = check_dense(mfarray)

    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_convert(mfarray.storedSize, $0, 1, dstptrT, 1, vDSP_func)
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func math_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    return preop_by_vDSP(mfarray, vDSP_func)
}

internal func biopvs_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_scalar: T, _ vDSP_func: vDSP_biopvs_func<T>) -> MfArray{
    var mfarray = l_mfarray
    var r_scalar = r_scalar

    mfarray = check_dense(mfarray)

    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_biopvs(mfarray.storedSize, $0, 1, &r_scalar, dstptrT, 1, vDSP_func)
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func biopsv_by_vDSP<T: MfStorable>(_ l_scalar: T, _ r_mfarray: MfArray, _ vDSP_func: vDSP_biopsv_func<T>) -> MfArray{
    var mfarray = r_mfarray
    var l_scalar = l_scalar

    mfarray = check_dense(mfarray)

    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_biopsv(mfarray.storedSize, &l_scalar, $0, 1, dstptrT, 1, vDSP_func)
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func biopvv_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_biopvv_func<T>) -> MfArray{
    let (l_mfarray, r_mfarray, biggerL, retsize) = check_biop_contiguous(l_mfarray, r_mfarray, .Row, convertL: true)

    let newdata = MfData(uninitializedSize: retsize, mftype: l_mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        l_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned l_mfarray] (lptr) in
            r_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                [unowned r_mfarray] (rptr) in
                if biggerL{
                    for vDSPPrams in OptOffsetParamsSequence(shape: l_mfarray.shape, bigger_strides: l_mfarray.strides, smaller_strides: r_mfarray.strides){
                        wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                    }
                }
                else{
                    for vDSPPrams in OptOffsetParamsSequence(shape: r_mfarray.shape, bigger_strides: r_mfarray.strides, smaller_strides: l_mfarray.strides){
                        wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr + vDSPPrams.s_offset, vDSPPrams.s_stride, rptr + vDSPPrams.b_offset, vDSPPrams.b_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                    }
                }
            }
        }
    }

    let newstructure: MfStructure
    if biggerL{
        newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
    }
    else{
        newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
    }

    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func stats_by_vDSP<T: MfStorable>(_ typedMfarray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_func<T>) -> MfArray{

    let mfarray = check_contiguous(typedMfarray, .Row)

    if let axis = axis, mfarray.ndim > 1{
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        var ret_shape = mfarray.shape
        let count = ret_shape.remove(at: axis)
        var ret_strides = mfarray.strides
        let stride = ret_strides.remove(at: axis)

        let ret_size = shape2size(&ret_shape)

        let newdata = MfData(uninitializedSize: ret_size, mftype: mfarray.mftype)
        var dst_offset = 0

        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            // FlattenIndSequence yields one index even for a shape containing 0, so an empty result must not be written
            guard ret_size > 0 else { return }
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                for flat in FlattenIndSequence(shape: &ret_shape, strides: &ret_strides){
                    wrap_vDSP_stats(count, $0 + flat.flattenIndex, stride, dstptrT + dst_offset, vDSP_func)
                    dst_offset += 1
                }
            }
        }

        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)

        let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{
        let newdata = MfData(uninitializedSize: 1, mftype: mfarray.mftype)
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                wrap_vDSP_stats(mfarray.size, $0, 1, dstptrT, vDSP_func)
            }
        }

        let ret_shape = keepDims ? Array(repeating: 1, count: mfarray.ndim) : [1]
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}

internal func sort_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ axis: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_func<T>) -> MfArray{
    let retndim = mfarray.ndim
    let count = mfarray.shape[axis]

    let lastaxis = retndim - 1
    let srcdst_mfarray = mfarray.moveaxis(src: axis, dst: lastaxis).to_contiguous(mforder: .Row)

    var offset = 0

    srcdst_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
        srcdstptr in
        // no lanes when the sorted axis (or another axis) is zero-length
        for _ in 0..<(count > 0 ? srcdst_mfarray.size / count : 0){
            sort_lane(count, srcdstptr + offset, order, vDSP_func)
            offset += count
        }
    }

    return srcdst_mfarray.moveaxis(src: lastaxis, dst: axis)
}

internal func argsort_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ axis: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_argsort_func<T>) -> MfArray{

    let count = mfarray.shape[axis]

    let lastaxis = mfarray.ndim - 1
    let srcmfarray = mfarray.moveaxis(src: axis, dst: lastaxis).to_contiguous(mforder: .Row)
    var retShape = srcmfarray.shape

    var offset = 0

    let retSize = shape2size(&retShape)
    let newdata = MfData(uninitializedSize: retSize, mftype: .Int)
    newdata.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptrF in
        srcmfarray.withUnsafeMutableStartPointer(datatype: T.self){
            srcptr in

            for _ in 0..<(count > 0 ? srcmfarray.size / count : 0){
                var uiarray = Array<UInt>(repeating: 0, count: count)
                argsort_lane(count, srcptr + offset, &uiarray, order, vDSP_func)

                var flarray = uiarray.map{ Float($0) }
                flarray.withUnsafeMutableBufferPointer{
                    (dstptrF + offset).moveUpdate(from: $0.baseAddress!, count: count)
                }

                offset += count
            }

        }
    }

    let newstructure = MfStructure(shape: retShape, mforder: .Row)

    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)

    return ret.moveaxis(src: lastaxis, dst: axis)

}

internal func clip_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ minval: T, _ maxval: T, _ vDSP_func: vDSP_clip_func<T>) -> MfArray{
    var mfarray = mfarray
    var minval = minval
    var maxval = maxval

    mfarray = check_dense(mfarray)

    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            wrap_vDSP_clip(mfarray.storedSize, $0, &minval, &maxval, dstptrT, vDSP_func)
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func boolget_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ vDSP_func: vDSP_vcmprs_func<T>) -> MfArray{
    assert(indices.mftype == .Bool, "must be bool")

    let true_num = Float.toInt(indices.sum().scalar(Float.self)!)
    let orig_ind_dim = indices.ndim

    let indices = bool_broadcast_to(indices, shape: mfarray.shape)

    let indicesT: MfArray
    switch mfarray.storedType {
    case .Float:
        indicesT = indices
    case .Double:
        indicesT = indices.astype(.Double)
    }
    // compressed results are written sequentially, so both mfarray and indices must be row contiguous
    let mfarray = check_contiguous(mfarray, .Row)
    let size = mfarray.size

    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    var retShape = [true_num] + lastShape
    let retSize = shape2size(&retShape)

    if mfarray.isReal{
        let newdata = MfData(uninitializedSize: retSize, mftype: mfarray.mftype)
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            indicesT.withUnsafeMutableStartPointer(datatype: T.self){
                indptr in
                mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                    srcptr in

                    wrap_vDSP_cmprs(size, srcptr, 1, indptr, 1, dstptrT, 1, vDSP_func)
                }
            }
        }


        let newstructure = MfStructure(shape: retShape, mforder: .Row)

        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    else{
        fatalError("Complex boolean indexing not supported on WASI")
    }
}

internal func fancy1dgetcol_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ vDSP_func: vDSP_vgathr_func<T>) -> MfArray{
    assert(indices.mftype == .Int, "must be int")
    assert(mfarray.ndim == 1, "must be 1d")

    if mfarray.isReal{
        let newdata = MfData(uninitializedSize: indices.size, mftype: mfarray.mftype)
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            let _ = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                srcptr in
                var offsets = index_values(indices).map{ UInt(get_positive_index($0, axissize: mfarray.size, axis: 0) * mfarray.strides[0] + 1) }
                wrap_vDSP_gathr(indices.size, srcptr, &offsets, 1, dstptrT, 1, vDSP_func)
            }
        }

        let newstructure = MfStructure(shape: indices.shape, mforder: .Row) // gathered in the row major order of indices
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    else{
        fatalError("Complex fancy indexing not supported on WASI")
    }
}

internal func dotpr_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_dotpr_func<T>) -> MfArray{
    let l_shape = l_mfarray.shape
    let r_shape = r_mfarray.shape
    assert(l_shape[0] == r_shape[1])

    let size = l_shape[0]

    let l_mfarray = check_contiguous(l_mfarray, .Row)
    let r_mfarray = r_mfarray.swapaxes(axis1: -1, axis2: -2).to_contiguous(mforder: .Row)

    var l_rest_shape = Array(l_shape.prefix(l_shape.count - 1))
    var r_rest_shape = Array(r_shape.prefix(r_shape.count - 2) + r_shape.suffix(1))
    var ret_shape = l_rest_shape + r_rest_shape

    let l_rest_size = l_rest_shape.count > 0 ? shape2size(&l_rest_shape) : 1
    let r_rest_size = shape2size(&r_rest_shape)
    let ret_size = shape2size(&ret_shape)

    let newdata = MfData(uninitializedSize: ret_size, mftype: l_mfarray.mftype)

    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptr in
        l_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            lptr in
            r_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                rptr in
                for l_ind in 0..<l_rest_size{
                    for r_ind in 0..<r_rest_size{
                        wrap_vDSP_dotpr(size, lptr + l_ind*size, 1, rptr + r_ind*size, 1, dstptr + (l_ind*r_rest_size + r_ind), vDSP_func)
                    }
                }
            }
        }
    }

    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)

    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

// MARK: - Sign Functions for WASI

/// Pure Swift fallback for sign_by_vDSP (numpy semantics: sign(NaN) = NaN, sign(-0.0) = +0.0)
internal func sign_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ type: T.Type) -> MfArray{
    let mfarray = check_dense(mfarray)

    let size = mfarray.storedSize
    let newdata = MfData(uninitializedSize: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptr in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            srcptr in
            for i in 0..<size{
                let x = srcptr[i]
                dstptr[i] = x > T.zero ? T.from(1) : (x < T.zero ? T.from(-1) : (x.isNaN ? x : T.zero))
            }
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

// MARK: - Clip Functions with C-style signatures for WASI

@inline(__always)
internal func vDSP_vclipc(_ src: UnsafePointer<Float>, _ srcStride: Int, _ low: UnsafePointer<Float>, _ high: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, _ dstStride: Int, _ count: Int, _ lowCount: UnsafeMutablePointer<UInt>, _ highCount: UnsafeMutablePointer<UInt>) {
    vDSP_vclip(src, srcStride, low, high, dst, dstStride, count, lowCount, highCount)
}

@inline(__always)
internal func vDSP_vclipcD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ low: UnsafePointer<Double>, _ high: UnsafePointer<Double>, _ dst: UnsafeMutablePointer<Double>, _ dstStride: Int, _ count: Int, _ lowCount: UnsafeMutablePointer<UInt>, _ highCount: UnsafeMutablePointer<UInt>) {
    vDSP_vclipD(src, srcStride, low, high, dst, dstStride, count, lowCount, highCount)
}

/// The largest absolute value over the real and imaginary parts. NaN if any element is NaN
/// - Parameter mfarray: An input mfarray
/// - Returns: The largest absolute value. 0 for an empty mfarray
internal func maxmg_by_vDSP(_ mfarray: MfArray) -> Double{
    let mfarray = check_dense(mfarray)
    let size = mfarray.size
    guard size > 0 else { return 0 }
    var ret = 0.0
    switch mfarray.storedType{
    case .Float:
        var m = Float.zero
        mfarray.withUnsafeMutableStartPointer(datatype: Float.self){ vDSP_maxmgv($0, 1, &m, size) }
        ret = Double(m)
        mfarray.withUnsafeMutableStartImagPointer(datatype: Float.self){
            guard let ptr = $0 else { return }
            vDSP_maxmgv(ptr, 1, &m, size)
            ret = ret.isNaN || m.isNaN ? .nan : Swift.max(ret, Double(m))
        }
    case .Double:
        var m = Double.zero
        mfarray.withUnsafeMutableStartPointer(datatype: Double.self){ vDSP_maxmgvD($0, 1, &m, size) }
        ret = m
        mfarray.withUnsafeMutableStartImagPointer(datatype: Double.self){
            guard let ptr = $0 else { return }
            vDSP_maxmgvD(ptr, 1, &m, size)
            ret = ret.isNaN || m.isNaN ? .nan : Swift.max(ret, m)
        }
    }
    return ret
}

@inline(__always)
internal func vDSP_maxmgv(_ src: UnsafePointer<Float>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Float>, _ count: Int) {
    var m = Float.zero
    for i in 0..<count {
        let v = Swift.abs(src[i * srcStride])
        // propagate NaN like vDSP
        if v.isNaN { m = .nan; break }
        m = Swift.max(m, v)
    }
    dst.pointee = m
}

@inline(__always)
internal func vDSP_maxmgvD(_ src: UnsafePointer<Double>, _ srcStride: Int, _ dst: UnsafeMutablePointer<Double>, _ count: Int) {
    var m = Double.zero
    for i in 0..<count {
        let v = Swift.abs(src[i * srcStride])
        if v.isNaN { m = .nan; break }
        m = Swift.max(m, v)
    }
    dst.pointee = m
}

#endif // canImport(Accelerate)


// MARK: - Shared by the Accelerate and WASI paths

/// Sort one contiguous lane in place, placing NaN like numpy: last for `.Ascending`, first for `.Descending`
/// (the exact reverse of the ascending order). vDSP's sort leaves NaN anywhere, so the NaNs are moved out first.
/// - Parameters:
///   - count: The number of elements
///   - ptr: The lane
///   - order: MfSortOrder
///   - vDSP_func: The vDSP sort function
internal func sort_lane<T: MfStorable>(_ count: Int, _ ptr: UnsafeMutablePointer<T>, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_func<T>){
    var nanCount = 0
    for i in 0..<count where ptr[i].isNaN{
        nanCount += 1
    }
    if nanCount == 0{
        wrap_vDSP_sort(count, ptr, order, vDSP_func)
        return
    }
    let valueCount = count - nanCount
    if order == .Ascending{
        // values to the front, NaN to the back
        var j = 0
        for i in 0..<count where !ptr[i].isNaN{
            ptr[j] = ptr[i]
            j += 1
        }
        (ptr + valueCount).update(repeating: T.nan, count: nanCount)
        wrap_vDSP_sort(valueCount, ptr, order, vDSP_func)
    }
    else{
        // NaN to the front, values to the back
        var j = count - 1
        for i in stride(from: count - 1, through: 0, by: -1) where !ptr[i].isNaN{
            ptr[j] = ptr[i]
            j -= 1
        }
        ptr.update(repeating: T.nan, count: nanCount)
        wrap_vDSP_sort(valueCount, ptr + nanCount, order, vDSP_func)
    }
}

/// Argsort one contiguous lane, placing NaN like numpy: the NaN indices come last in increasing order for `.Ascending`,
/// and first in decreasing order for `.Descending` (the exact reverse of the ascending order).
/// - Parameters:
///   - count: The number of elements
///   - srcptr: The lane
///   - indices: The result, `count` indices
///   - order: MfSortOrder
///   - vDSP_func: The vDSP argsort function
internal func argsort_lane<T: MfStorable>(_ count: Int, _ srcptr: UnsafePointer<T>, _ indices: inout [UInt], _ order: MfSortOrder, _ vDSP_func: vDSP_argsort_func<T>){
    var nanCount = 0
    for i in 0..<count where srcptr[i].isNaN{
        nanCount += 1
    }
    if nanCount == 0{
        // vDSP's argsort needs the indices to start with 0..<count
        for j in 0..<count{
            indices[j] = UInt(j)
        }
        wrap_vDSP_argsort(count, srcptr, &indices, order, vDSP_func)
        return
    }
    // argsort the non-NaN values compacted into a buffer, then map back to the original indices
    var positions: [UInt] = [], nanPositions: [UInt] = []
    var values: [T] = []
    positions.reserveCapacity(count - nanCount)
    values.reserveCapacity(count - nanCount)
    nanPositions.reserveCapacity(nanCount)
    for i in 0..<count{
        if srcptr[i].isNaN{
            nanPositions.append(UInt(i))
        }
        else{
            positions.append(UInt(i))
            values.append(srcptr[i])
        }
    }
    var sorted = Array<UInt>(0..<UInt(values.count))
    if !values.isEmpty{
        values.withUnsafeBufferPointer{
            wrap_vDSP_argsort($0.count, $0.baseAddress!, &sorted, order, vDSP_func)
        }
    }
    let ordered = sorted.map{ positions[Int($0)] }
    let result = order == .Ascending ? ordered + nanPositions : nanPositions.reversed() + ordered
    for j in 0..<count{
        indices[j] = result[j]
    }
}

/// argmax / argmin by vDSP (`vDSP_maxvi`, `vDSP_minvi`, ...), following numpy:
/// the indices are `.Int`, the first index wins for ties, and the first NaN wins when the lane contains NaN
/// (vDSP ignores NaN, and its behaviour differs between architectures).
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis: An axis index. `nil` searches the flattened (row-major) array
///   - keepDims: Whether to keep dimension or not
///   - vDSP_func: The vDSP stats index function
///   - vDSP_sum_func: The vDSP sum function, used to detect NaN in one vectorized pass
/// - Returns: The `.Int` indices
internal func stats_index_by_vDSP<T: MfStorable>(_ mfarray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_index_func<T>, vDSP_sum_func: vDSP_stats_func<T>) -> MfArray{
    let mfarray = check_contiguous(mfarray, .Row)

    // the sum is NaN whenever a NaN exists (also for inf - inf, then the lanes are just scanned in vain)
    var total = T.zero
    if mfarray.size > 0{
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            wrap_vDSP_stats(mfarray.size, $0, 1, &total, vDSP_sum_func)
        }
    }
    let checkNaN = total.isNaN

    let count: Int
    let stride: Int
    var ret_shape: [Int]
    var ret_strides: [Int]
    let reducedAxis: Int?
    if let axis = axis, mfarray.ndim > 1{
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        ret_shape = mfarray.shape
        count = ret_shape.remove(at: axis)
        ret_strides = mfarray.strides
        stride = ret_strides.remove(at: axis)
        reducedAxis = axis
    }
    else{
        count = mfarray.size
        stride = 1
        ret_shape = [1]
        ret_strides = [0]
        reducedAxis = nil
    }
    let ret_size = shape2size(&ret_shape)
    // numpy raises "attempt to get argmax of an empty sequence"
    precondition(count > 0 || ret_size == 0, "attempt to get argmax/argmin of an empty sequence")

    // the indices are stored like any other .Int array
    let newdata = MfData(uninitializedSize: ret_size, mftype: .Int)
    if ret_size > 0{
        newdata.withUnsafeMutableStartPointer(datatype: Float.self){
            dstptr in
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                srcptr in
                var dst_offset = 0
                for flat in FlattenIndSequence(shape: &ret_shape, strides: &ret_strides){
                    dstptr[dst_offset] = Float(_first_arg_index(count, srcptr + flat.flattenIndex, stride, checkNaN: checkNaN, vDSP_func))
                    dst_offset += 1
                }
            }
        }
    }

    guard let axis = reducedAxis else{
        let shape = keepDims ? Array(repeating: 1, count: mfarray.ndim) : [1]
        return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: shape, mforder: .Row))
    }
    let ret = MfArray(mfdata: newdata, mfstructure: MfStructure(shape: ret_shape, mforder: .Row))
    return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
}

/// The index of the first NaN (when `checkNaN`), otherwise the index vDSP finds
@inline(__always)
private func _first_arg_index<T: MfStorable>(_ count: Int, _ srcptr: UnsafePointer<T>, _ stride: Int, checkNaN: Bool, _ vDSP_func: vDSP_stats_index_func<T>) -> Int{
    if checkNaN{
        for i in 0..<count where srcptr[i * stride].isNaN{
            return i
        }
    }
    var uival = UInt.zero
    wrap_vDSP_stats_index(count, srcptr, stride, &uival, vDSP_func)
    // vDSP returns the offset in elements, i.e. index * stride
    return Int(uival) / stride
}
