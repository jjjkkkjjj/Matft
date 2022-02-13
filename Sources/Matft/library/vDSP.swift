//
//  vDSP.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/05.
//

import Foundation
import Accelerate

public typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_biopvv_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_biopvs_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_biopsv_func<T> = (UnsafePointer<T>, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_vcmprs_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_vminmg_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_viclip_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>,  UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_clip_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length, UnsafeMutablePointer<vDSP_Length>, UnsafeMutablePointer<vDSP_Length>) -> Void

public typealias vDSP_sort_func<T> = (UnsafeMutablePointer<T>, vDSP_Length, Int32) -> Void

public typealias vDSP_argsort_func<T> = (UnsafePointer<T>, UnsafeMutablePointer<vDSP_Length>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length, Int32) -> Void

public typealias vDSP_stats_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Length) -> Void

public typealias vDSP_stats_index_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length) -> Void


public typealias vDSP_math_func<T, U> = vDSP_convert_func<T, U>

public typealias vDSP_vgathr_func<T> = (UnsafePointer<T>, UnsafePointer<vDSP_Length>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

/// Wrapper of vDSP conversion function
/// - Parameters:
///   - size: A size to be copied
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - vDSP_func: The vDSP conversion function
@inline(__always)
internal func wrap_vDSP_convert<T, U>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<U>, _ dstStride: Int, _ vDSP_func: vDSP_convert_func<T, U>){
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

/// Wrapper of vDSP boolean conversion function
/// - Parameters:
///   - size: A size to be converted
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - vDSP_vminmg_func: The vDSP vminmg function
///   - vDSP_viclip_func: The vDSP viclip function
@inline(__always)
internal func wrap_vDSP_toBool<T: MfStoredTypeUsable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vminmg_func: vDSP_vminmg_func<T>, _ vDSP_viclip_func: vDSP_viclip_func<T>){
    // if |src| <= 1  => dst = |src|
    //    |src| > 1   => dst = 1
    // Note that the 0<= dst <= 1
    var one = T.from(1)
    vDSP_vminmg_func(srcptr, vDSP_Stride(1), &one, vDSP_Stride(0), dstptr, vDSP_Stride(1), vDSP_Length(size))
    
    var zero = T.zero
    one = T.from(1)
    // if src <= 0, 1 <= src   => dst = src
    //    0 < src <= 1         => dst = 1
    vDSP_viclip_func(dstptr, vDSP_Stride(1), &zero, &one, dstptr, vDSP_Stride(1), vDSP_Length(size))
}

/// Wrapper of vDSP boolean conversion function
/// - Parameters:
///   - size: A size to be converted
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - vDSP_vminmg_func: The vDSP vminmg function
///   - vDSP_viclip_func: The vDSP viclip function
@inline(__always)
internal func wrap_vDSP_toIBool<T: MfStoredTypeUsable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vminmg_func: vDSP_vminmg_func<T>, _ vDSP_viclip_func: vDSP_viclip_func<T>, _ vDSP_addvs_func: vDSP_biopvs_func<T>, _ vForce_abs_func: vForce_math_func<T>){
    var i32size = Int32(size)
    // if |src| <= 1  => dst = |src|
    //    |src| > 1   => dst = 1
    // Note that the 0<= dst <= 1
    var one = T.from(1)
    vDSP_vminmg_func(srcptr, vDSP_Stride(1), &one, vDSP_Stride(0), dstptr, vDSP_Stride(1), vDSP_Length(size))
    
    var zero = T.zero
    one = T.from(1)
    // if src <= 0, 1 <= src   => dst = src
    //    0 < src <= 1         => dst = 1
    vDSP_viclip_func(dstptr, vDSP_Stride(1), &zero, &one, dstptr, vDSP_Stride(1), vDSP_Length(size))
    
    one = T.from(-1)
    vDSP_addvs_func(dstptr, vDSP_Stride(1), &one, dstptr, vDSP_Stride(1), vDSP_Length(size))
    
    vForce_abs_func(dstptr, dstptr, &i32size)
}


/// Wrapper of vDSP sign generation function
/// - Parameters:
///   - size: A size to be converted
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - vDSP_vminmg_func: The vDSP vminmg function
///   - vDSP_viclip_func: The vDSP viclip function
///   - vForce_copysign_func: The vForce copysign function
@inline(__always)
internal func wrap_vDSP_sign<T: MfStoredTypeUsable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vminmg_func: vDSP_vminmg_func<T>, _ vDSP_viclip_func: vDSP_viclip_func<T>, _ vForce_copysign_func: vForce_copysign_func<T>){
    var i32size = Int32(size)
    
    // if |src| <= 1  => dst = |src|
    //    |src| > 1   => dst = 1
    // Note that the 0<= dst <= 1
    var one = T.from(1)
    vDSP_vminmg_func(srcptr, vDSP_Stride(1), &one, vDSP_Stride(0), dstptr, vDSP_Stride(1), vDSP_Length(size))
    
    var zero = T.zero
    one = T.from(1)
    // if src <= 0, 1 <= src   => dst = src
    //    0 < src <= 1         => dst = 1
    vDSP_viclip_func(dstptr, vDSP_Stride(1), &zero, &one, dstptr, vDSP_Stride(1), vDSP_Length(size))
    vForce_copysign_func(dstptr, dstptr, srcptr, &i32size)
}

/// Wrapper of vDSP clip function
/// - Parameters:
///   - size: A size to be converted
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - vDSP_clip_func: The vDSP clip function
@inline(__always)
internal func wrap_vDSP_clip<T: MfStoredTypeUsable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ minptr: UnsafePointer<T>, _ maxptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_clip_func: vDSP_clip_func<T>){
    var mincount = vDSP_Length(0)
    var maxcount = vDSP_Length(0)
    
    vDSP_clip_func(srcptr, vDSP_Stride(1), minptr, maxptr, dstptr, vDSP_Stride(1), vDSP_Length(size), &mincount, &maxcount)
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
    var tmp = Array<vDSP_Length>(repeating: 0, count: size)
    vDSP_func(srcptr, dstptr, &tmp, vDSP_Length(size), order.rawValue)
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
internal func wrap_vDSP_stats_index<T: MfStoredTypeUsable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ stride: Int, _ dstptr: UnsafeMutablePointer<UInt>, _ vDSP_func: vDSP_stats_index_func<T>){
    var tmp = Array(repeating: T.zero, count: size)
    vDSP_func(srcptr, vDSP_Stride(stride), &tmp, dstptr, vDSP_Length(size))
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
internal func wrap_vDSP_cmprs<T: MfStoredTypeUsable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ indptr: UnsafePointer<T>, _ indStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ vDSP_func: vDSP_vcmprs_func<T>){
    vDSP_func(srcptr, vDSP_Stride(srcStride), indptr, vDSP_Stride(indStride), dstptr, vDSP_Stride(dstStride), vDSP_Length(size))
}

/// Pre operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_convert_func
/// - Returns: Pre operated mfarray
internal func preop_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>, _ vDSP_func: vDSP_convert_func<T.StoredType, T.StoredType>) -> MfArray<T>{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_contiguous(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata: MfData<T> = MfData(size: mfarray.storedSize)
    mfarray.withUnsafeMutableStartPointer{
        wrap_vDSP_convert(mfarray.storedSize, $0, 1, newdata.storedPtr.baseAddress!, 1, T.StoredType.vDSP_neg_func)
    }
    
    
    let newmfstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}


/// Boolean conversion by vDSP
/// - Parameter mfarray: An input mfarray
/// - Returns: Converted mfarray
internal func toBool_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Bool>{
    
    let size = mfarray.storedSize
    let newdata: MfData<Bool> = MfData(size: mfarray.storedSize)
    
    mfarray.withUnsafeMutableStartPointer{
        if let srcptr = $0 as? UnsafeMutablePointer<Float>{
            wrap_vDSP_toBool(size, srcptr, newdata.storedPtr.baseAddress!, Bool.StoredType.vDSP_vminmg_func, Bool.StoredType.vDSP_viclip_func)
        }
        else if let srcptr = $0 as? UnsafeMutablePointer<Double>{
            // Double to Float
            wrap_vDSP_convert(mfarray.storedSize, srcptr, 1, newdata.storedPtr.baseAddress!, 1, vDSP_vdpsp)
            wrap_vDSP_toBool(size, newdata.storedPtr.baseAddress!, newdata.storedPtr.baseAddress!, Bool.StoredType.vDSP_vminmg_func, Bool.StoredType.vDSP_viclip_func)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Boolean conversion by vDSP
/// - Parameter mfarray: An input mfarray
/// - Returns: Converted mfarray
internal func toIBool_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Bool>{
    
    let size = mfarray.storedSize
    let newdata: MfData<Bool> = MfData(size: mfarray.storedSize)
    
    mfarray.withUnsafeMutableStartPointer{
        if let srcptr = $0 as? UnsafeMutablePointer<Float>{
            wrap_vDSP_toIBool(size, srcptr, newdata.storedPtr.baseAddress!, Bool.StoredType.vDSP_vminmg_func, Bool.StoredType.vDSP_viclip_func,
                Bool.StoredType.vDSP_addvs_func,
                Bool.StoredType.vForce_abs_func)
        }
        else if let srcptr = $0 as? UnsafeMutablePointer<Double>{
            // Double to Float
            wrap_vDSP_convert(mfarray.storedSize, srcptr, 1, newdata.storedPtr.baseAddress!, 1, vDSP_vdpsp)
            wrap_vDSP_toIBool(size, newdata.storedPtr.baseAddress!, newdata.storedPtr.baseAddress!, Bool.StoredType.vDSP_vminmg_func, Bool.StoredType.vDSP_viclip_func,
                Bool.StoredType.vDSP_addvs_func,
                Bool.StoredType.vForce_abs_func)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Generate sign by vDSP
/// - Parameter mfarray: An input mfarray
/// - Returns: Converted mfarray
internal func sign_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T>{
    let mfarray = check_contiguous(mfarray)
    
    let size = mfarray.storedSize
    let newdata: MfData<T> = MfData(size: mfarray.storedSize)
    mfarray.withUnsafeMutableStartPointer{
        wrap_vDSP_sign(size, $0, newdata.storedPtr.baseAddress!, T.StoredType.vDSP_vminmg_func, T.StoredType.vDSP_viclip_func,
            T.StoredType.vForce_copysign_func)
    }
    
    let newmfstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}


/// Binary operation by vDSP
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_mfarray: The right mfarray
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
internal func biopvv_by_vDSP<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, vDSP_func: vDSP_biopvv_func<T.StoredType>) -> MfArray<T>{
    // biggerL: flag whether l is bigger than r
    // return mfarray must be either row or column major
    let (l_mfarray, r_mfarray, biggerL, retsize) = check_biop_contiguous(l_mfarray, r_mfarray, .Row, convertL: true)
    
    let newdata: MfData<T> = MfData(size: retsize)
    l_mfarray.withUnsafeMutableStartPointer{
        [unowned l_mfarray] (lptr) in
        r_mfarray.withUnsafeMutableStartPointer{
            [unowned r_mfarray] (rptr) in
            if biggerL{ // l is bigger
                for vDSPPrams in OptOffsetParamsSequence(shape: l_mfarray.shape, bigger_strides: l_mfarray.strides, smaller_strides: r_mfarray.strides){
                    wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr + vDSPPrams.s_offset, vDSPPrams.s_stride, newdata.storedPtr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                }
            }
            else{ // r is bigger
                for vDSPPrams in OptOffsetParamsSequence(shape: r_mfarray.shape, bigger_strides: r_mfarray.strides, smaller_strides: l_mfarray.strides){
                    wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr + vDSPPrams.s_offset, vDSPPrams.s_stride, rptr + vDSPPrams.b_offset, vDSPPrams.b_stride, newdata.storedPtr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
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
///   - r_scalr: The right scalar
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
internal func biopvs_by_vDSP<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T.StoredType, vDSP_func: vDSP_biopvs_func<T.StoredType>) -> MfArray<T>{
    let l_mfarray = check_contiguous(l_mfarray)
    var r_scalar = r_scalar
    
    let newdata: MfData<T> = MfData(size: l_mfarray.storedSize)
    l_mfarray.withUnsafeMutableStartPointer{
        [unowned l_mfarray] in
        wrap_vDSP_biopvs(l_mfarray.storedSize, $0, 1, &r_scalar, newdata.storedPtr.baseAddress!, 1, vDSP_func)
    }
    
    let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Binary operation by vDSP
/// - Parameters:
///   - l_scalar: The left scalar
///   - r_mfarray: The right mfarray
///   - vDSP_func: The vDSP biop function
/// - Returns: The result mfarray
internal func biopsv_by_vDSP<T: MfTypeUsable>(_ l_scalar: T.StoredType, _ r_mfarray: MfArray<T>, vDSP_func: vDSP_biopsv_func<T.StoredType>) -> MfArray<T>{
    let r_mfarray = check_contiguous(r_mfarray)
    var l_scalar = l_scalar
    
    let newdata: MfData<T> = MfData(size: r_mfarray.storedSize)
    r_mfarray.withUnsafeMutableStartPointer{
        [unowned r_mfarray] in
        wrap_vDSP_biopsv(r_mfarray.storedSize, &l_scalar, $0, 1, newdata.storedPtr.baseAddress!, 1, vDSP_func)
    }
    
    let newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Clip operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - minval: The minimum value
///   - maxval: The maximum value
///   - vDSP_func: The vDSP clip function
/// - Returns: The clipped mfarray
internal func clip_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>, _ minval: T.StoredType, _ maxval: T.StoredType, vDSP_func: vDSP_clip_func<T.StoredType>) -> MfArray<T>{
    var minval = minval
    var maxval = maxval
    let mfarray = check_contiguous(mfarray)
    
    let newdata: MfData<T> = MfData(size: mfarray.storedSize)
    mfarray.withUnsafeMutableStartPointer{
        wrap_vDSP_clip(mfarray.storedSize, $0, &minval, &maxval, newdata.storedPtr.baseAddress!, T.StoredType.vDSP_clip_func)
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Sort operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis; An axis index
///   - order: MfSortOrder
///   - vDSP_func: The vDSP sort function
/// - Returns: The sorted mfarray
internal func sort_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int, order: MfSortOrder, vDSP_func: vDSP_sort_func<T.StoredType>) -> MfArray<T>{
    let ret_ndim = mfarray.ndim
    let count = mfarray.shape[axis]
    
    let last_axis = ret_ndim - 1
    // move lastaxis and given axis and align order
    let srcdst_mfarray = mfarray.moveaxis(src: axis, dst: last_axis).to_contiguous(mforder: .Row)

    var offset = 0
    
    srcdst_mfarray.withUnsafeMutableStartPointer{
        for _ in 0..<mfarray.storedSize / count{
            wrap_vDSP_sort(count, $0 + offset, order, vDSP_func)
            offset += count
        }
    }
    
    // re-move axis and lastaxis
    return srcdst_mfarray.moveaxis(src: last_axis, dst: axis)
}

/// Argsort operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis; An axis index
///   - order: MfSortOrder
///   - vDSP_func: The vDSP sort function
/// - Returns: The sorted mfarray
internal func argsort_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int, order: MfSortOrder, vDSP_func: vDSP_argsort_func<T.StoredType>) -> MfArray<UInt>{
    let count = mfarray.shape[axis]
        
    let last_axis = mfarray.ndim - 1
    // move lastaxis and given axis and align order
    let src_mfarray = mfarray.moveaxis(src: axis, dst: last_axis).to_contiguous(mforder: .Row)
    var ret_shape = src_mfarray.shape
    
    var offset = 0

    let ret_size = shape2size(&ret_shape)
    
    let newdata: MfData<UInt> = MfData(size: ret_size)
    
    src_mfarray.withUnsafeMutableStartPointer{
        for _ in 0..<mfarray.storedSize / count{
            var uiarray = Array<UInt>(stride(from: 0, to: UInt(count), by: 1))

            wrap_vDSP_argsort(count, $0 + offset, &uiarray, order, T.StoredType.vDSP_argsort_func)
            
            //convert dataptr(int) to float
            _ = ArrayConversionToStoredType<UInt, UInt.StoredType>(src: &uiarray, dst: newdata.storedPtr.baseAddress! + offset, size: count)
            
            offset += count
        }
    }
    
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    // re-move axis and lastaxis
    return ret.moveaxis(src: last_axis, dst: axis)
}


/// Stats operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis; An axis index
///   - keepDims: Whether to keep dimension or not
///   - vDSP_func: The vDSP stats function
/// - Returns: The sorted mfarray
internal func stats_by_vDSP<T: MfTypeUsable, U: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_func<U.StoredType>) -> MfArray<U> where T.StoredType == U.StoredType{
    
    let mfarray = check_contiguous(mfarray, .Row)
    
    if let axis = axis, mfarray.ndim > 1{
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        var ret_shape = mfarray.shape
        let count = ret_shape.remove(at: axis)
        var ret_strides = mfarray.strides
        //remove and get stride at given axis
        let stride = ret_strides.remove(at: axis)
        
        let ret_size = shape2size(&ret_shape)
        
        let newdata: MfData<U> = MfData(size: ret_size)
        
        var dst_offset = 0
        mfarray.withUnsafeMutableStartPointer{
            for flat in FlattenIndSequence(shape: &ret_shape, strides: &ret_strides){
                wrap_vDSP_stats(count, $0 + flat.flattenIndex, stride, newdata.storedPtr.baseAddress! + dst_offset, vDSP_func)
                dst_offset += 1
            }
        }
        
        
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        
        let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{
        let newdata: MfData<U> = MfData(size: 1)
        
        mfarray.withUnsafeMutableStartPointer{
            wrap_vDSP_stats(mfarray.size, $0, 1, newdata.storedPtr.baseAddress!, vDSP_func)
        }
        
        let ret_shape = keepDims ? Array(repeating: 1, count: mfarray.ndim) : [1]
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}

/// Stats operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - axis; An axis index
///   - keepDims: Whether to keep dimension or not
///   - vDSP_func: The vDSP stats function
/// - Returns: The sorted mfarray
internal func stats_index_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_index_func<T.StoredType>) -> MfArray<UInt>{
    
    let mfarray = check_contiguous(mfarray, .Row)
    
    if let axis = axis, mfarray.ndim > 1{
        let axis = get_positive_axis(axis, ndim: mfarray.ndim)
        var ret_shape = mfarray.shape
        let count = ret_shape.remove(at: axis)
        var ret_strides = mfarray.strides
        //remove and get stride at given axis
        let stride = ret_strides.remove(at: axis)
        let ui_stride = UInt(stride)
        
        let ret_size = shape2size(&ret_shape)
        
        let newdata: MfData<UInt> = MfData(size: ret_size)
        
        var dst_offset = 0
        mfarray.withUnsafeMutableStartPointer{
            for flat in FlattenIndSequence(shape: &ret_shape, strides: &ret_strides){
                var uival = UInt.zero
                wrap_vDSP_stats_index(count, $0 + flat.flattenIndex, stride, &uival, vDSP_func)
                (newdata.storedPtr.baseAddress! + dst_offset).pointee = UInt.StoredType(uival / ui_stride)
                
                dst_offset += 1//koko
            }
        }
        
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        
        let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{
        let newdata: MfData<UInt> = MfData(size: 1)
        
        var uival = UInt.zero
        mfarray.withUnsafeMutableStartPointer{
            wrap_vDSP_stats_index(mfarray.size, $0, 1, &uival, vDSP_func)
        }
        
        newdata.storedPtr.baseAddress!.pointee = Double(uival)
        
        let ret_shape = keepDims ? Array(repeating: 1, count: mfarray.ndim) : [1]
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}

/// Math operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_math_func
/// - Returns: Math operated mfarray
internal func math_by_vDSP<T: MfTypeUsable>(_ mfarray: MfArray<T>, _ vDSP_func: vDSP_math_func<T.StoredType, T.StoredType>) -> MfArray<T>{
    return preop_by_vDSP(mfarray, vDSP_func)
}



/// Boolean getter operation mfarray by vDSP
/// - Parameters:
///   - src_mfarray: An input mfarray
///   - indices: An indices boolean mfarray
///   - vDSP_func: vDSP_vcmprs_func
/// - Returns: Result mfarray
internal func boolget_by_vDSP<T: MfTypeUsable>(_ src_mfarray: MfArray<T>, _ indices: MfArray<Bool>, _ vDSP_func: vDSP_vcmprs_func<T.StoredType>) -> MfArray<T>{
    
    /*
     Note that returned shape must be (true number in original indices, (mfarray's shape - original indices' shape));
     i.e. returned dim = 1(=true number in original indices) + mfarray's dim - indices' dim
     */
    let true_num = Int(indices.astype(newtype: Float.self).sum().scalar!)
    let orig_ind_dim = indices.ndim
    
    // broadcast
    let indices = bool_broadcast_to(indices, shape: src_mfarray.shape)
    
    // must be row major
    let indicesT = indices.astype(newtype: T.self, mforder: .Row)
    let src_mfarray = check_contiguous(src_mfarray, .Row)
    
    
    let last_shape = Array(src_mfarray.shape.suffix(src_mfarray.ndim - orig_ind_dim))
    var ret_shape = [true_num] + last_shape
    let ret_size = shape2size(&ret_shape)
    
    let newdata: MfData<T> = MfData(size: ret_size)
    
    src_mfarray.withUnsafeMutableStartPointer{
        wrap_vDSP_cmprs(indicesT.size, $0, 1, indicesT.mfdata.storedPtr.baseAddress!, 1, newdata.storedPtr.baseAddress!, 1, vDSP_func)
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Getter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray. Must be 1d
///   - indices: An input Interger indices array
///   - vDSP_func: vDSP_vgathr_func
/// - Returns: The mfarray
internal func fancy1dget_by_vDSP<T: MfTypeUsable, U: MfInterger>(_ mfarray: MfArray<T>, _ indices: MfArray<U>, vDSP_func: vDSP_vgathr_func<T.StoredType>) -> MfArray<T>{
    assert(mfarray.ndim == 1, "must be 1d!")
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
    let indicesT = indices.astype(newtype: Int.self, mforder: .Row)
    
    let newdata: MfData<T> = MfData(size: indices.size)
    
    var offsets = indicesT.data.map{ UInt(get_positive_index($0, axissize: mfarray.size, axis: 0) * mfarray.strides[0] + 1) }
    mfarray.withUnsafeMutableStartPointer{
        vDSP_func($0, &offsets, vDSP_Stride(1), newdata.storedPtr.baseAddress!, vDSP_Stride(1), vDSP_Length(indices.size))
    }
    
    let newstructure = MfStructure(shape: indices.shape, strides: indices.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
