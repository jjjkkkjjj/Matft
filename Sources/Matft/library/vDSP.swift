//
//  vDSP.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_biopvv_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_biopvs_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_biopsv_func<T> = (UnsafePointer<T>, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_vcmprs_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_vminmg_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_viclip_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>,  UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal typealias vDSP_clip_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length, UnsafeMutablePointer<vDSP_Length>, UnsafeMutablePointer<vDSP_Length>) -> Void

internal typealias vDSP_sort_func<T> = (UnsafeMutablePointer<T>, vDSP_Length, Int32) -> Void

internal typealias vDSP_argsort_func<T> = (UnsafePointer<T>, UnsafeMutablePointer<vDSP_Length>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length, Int32) -> Void

internal typealias vDSP_stats_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Length) -> Void

internal typealias vDSP_stats_index_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length) -> Void


internal typealias vDSP_math_func<T, U> = vDSP_convert_func<T, U>

internal typealias vDSP_vgathr_func<T> = (UnsafePointer<T>, UnsafePointer<vDSP_Length>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void


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
internal func wrap_vDSP_toBool<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vminmg_func: vDSP_vminmg_func<T>, _ vDSP_viclip_func: vDSP_viclip_func<T>){
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
internal func wrap_vDSP_toIBool<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vminmg_func: vDSP_vminmg_func<T>, _ vDSP_viclip_func: vDSP_viclip_func<T>, _ vDSP_addvs_func: vDSP_biopvs_func<T>, _ vForce_abs_func: vForce_math_func<T>){
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
internal func wrap_vDSP_sign<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_vminmg_func: vDSP_vminmg_func<T>, _ vDSP_viclip_func: vDSP_viclip_func<T>, _ vForce_copysign_func: vForce_copysign_func<T>){
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
internal func wrap_vDSP_clip<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ minptr: UnsafePointer<T>, _ maxptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ vDSP_clip_func: vDSP_clip_func<T>){
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
internal func wrap_vDSP_stats_index<T: MfStorable>(_ size: Int, _ srcptr: UnsafePointer<T>, _ stride: Int, _ dstptr: UnsafeMutablePointer<UInt>, _ vDSP_func: vDSP_stats_index_func<T>){
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

/// Pre operation mfarray by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vDSP_func: vDSP_convert_func
/// - Returns: Pre operated mfarray
internal func preop_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_contiguous(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = MfData(size: mfarray.storedSize, mftype: mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: mfarray.storedSize)
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned mfarray] in
        wrap_vDSP_convert(mfarray.storedSize, $0.baseAddress!, 1, dstptrT, 1, vDSP_func)
        //vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
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
    
    mfarray = check_contiguous(mfarray)
    
    let newdata = MfData(size: mfarray.storedSize, mftype: mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: mfarray.storedSize)
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned mfarray] in
        wrap_vDSP_biopvs(mfarray.storedSize, $0.baseAddress!, 1, &r_scalar, dstptrT, 1, vDSP_func)
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
    
    mfarray = check_contiguous(mfarray)
    
    let newdata = MfData(size: mfarray.storedSize, mftype: mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: mfarray.storedSize)
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned mfarray] in
        wrap_vDSP_biopsv(mfarray.storedSize, &l_scalar, $0.baseAddress!, 1, dstptrT, 1, vDSP_func)
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
internal func biopvv_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_biopvv_func<T>) -> MfArray{
    // biggerL: flag whether l is bigger than r
    //return mfarray must be either row or column major
    let (l_mfarray, r_mfarray, biggerL, retsize) = check_biop_contiguous(l_mfarray, r_mfarray, .Row, convertL: true)
    
    let newdata = MfData(size: retsize, mftype: l_mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: retsize)
    
    l_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned l_mfarray] (lptr) in
        r_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
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
                    wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                    //print(vDSPPrams.blocksize, vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                }
            }
            else{// r is bigger
                for vDSPPrams in OptOffsetParamsSequence(shape: r_mfarray.shape, bigger_strides: r_mfarray.strides, smaller_strides: l_mfarray.strides){
                    wrap_vDSP_biopvv(vDSPPrams.blocksize, lptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, rptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
                    //print(vDSPPrams.blocksize, vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
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
        
        let newdata = MfData(size: ret_size, mftype: mfarray.mftype)
        let dstptrT = newdata.data.bindMemory(to: T.self, capacity: ret_size)
        var dst_offset = 0
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            for flat in FlattenIndSequence(shape: &ret_shape, strides: &ret_strides){
                wrap_vDSP_stats(count, $0.baseAddress! + flat.flattenIndex, stride, dstptrT + dst_offset, vDSP_func)
                dst_offset += 1
            }
        }
        
        
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        
        let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{
        let newdata = MfData(size: 1, mftype: mfarray.mftype)
        let dstptrT = newdata.data.bindMemory(to: T.self, capacity: 1)
        
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            wrap_vDSP_stats(mfarray.size, $0.baseAddress!, 1, dstptrT, vDSP_func)
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
internal func stats_index_by_vDSP<T: MfStorable>(_ mfarray: MfArray, axis: Int?, keepDims: Bool, vDSP_func: vDSP_stats_index_func<T>) -> MfArray{
    
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
        
        let newdata = MfData(size: ret_size, mftype: mfarray.mftype)
        let dstptrT = newdata.data.bindMemory(to: T.self, capacity: ret_size)
        
        var dst_offset = 0
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            for flat in FlattenIndSequence(shape: &ret_shape, strides: &ret_strides){
                var uival = UInt.zero
                wrap_vDSP_stats_index(count, $0.baseAddress! + flat.flattenIndex, stride, &uival, vDSP_func)
                (dstptrT + dst_offset).pointee = T.from(uival / ui_stride)
                
                dst_offset += 1//koko
            }
        }
        
        let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
        
        let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
    else{
        let newdata = MfData(size: 1, mftype: mfarray.mftype)
        let dstptrT = newdata.data.bindMemory(to: T.self, capacity: 1)
        
        var uival = UInt.zero
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            wrap_vDSP_stats_index(mfarray.size, $0.baseAddress!, 1, &uival, vDSP_func)
        }
        
        dstptrT.pointee = T.from(uival)
        
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
    let srcdst_mfarray = mfarray.moveaxis(src: axis, dst: lastaxis).conv_order(mforder: .Row)

    var offset = 0
    
    srcdst_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        srcdstptr in
        for _ in 0..<mfarray.storedSize / count{
            wrap_vDSP_sort(count, srcdstptr.baseAddress! + offset, order, vDSP_func)
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
    let srcmfarray = mfarray.moveaxis(src: axis, dst: lastaxis).conv_order(mforder: .Row)
    var retShape = srcmfarray.shape
    
    var offset = 0

    let retSize = shape2size(&retShape)
    let newdata = MfData(size: retSize, mftype: .Int)
    let dstptrF = newdata.data.bindMemory(to: Float.self, capacity: retSize)
    
    srcmfarray.withDataUnsafeMBPtrT(datatype: T.self){
        srcptr in
        
        for _ in 0..<mfarray.storedSize / count{
            var uiarray = Array<UInt>(stride(from: 0, to: UInt(count), by: 1))
            //let srcptr = stride >= 0 ? srcptr.baseAddress! : srcptr.baseAddress! - mfarray.offsetIndex
            wrap_vDSP_argsort(count, srcptr.baseAddress! + offset, &uiarray, order, vDSP_func)
            
            // TODO: refactor
            //convert dataptr(int) to float
            var flarray = uiarray.map{ Float($0) }
            flarray.withUnsafeMutableBufferPointer{
                (dstptrF + offset).moveAssign(from: $0.baseAddress!, count: count)
            }
            
            offset += count
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
    mfarray = check_contiguous(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = MfData(size: mfarray.storedSize, mftype: mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: mfarray.storedSize)
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned mfarray] in
        wrap_vDSP_clip(mfarray.storedSize, $0.baseAddress!, &minval, &maxval, dstptrT, vDSP_func)
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Generate sign by vDSP
/// - Parameters:
///    - mfarray: An input mfarray
///    - vDSP_vminmg_func: vDSP_vminmg function
///    - vDSP_viclip_func: vDSP_viclip function
///    - vForce_copysign_func: vForce_copysign function
/// - Returns: Converted mfarray
internal func sign_by_vDSP<T: MfStorable>(_ mfarray: MfArray, vDSP_vminmg_func: vDSP_vminmg_func<T>, vDSP_viclip_func: vDSP_viclip_func<T>, vForce_copysign_func: vForce_copysign_func<T>) -> MfArray{
    let mfarray = check_contiguous(mfarray)
        
    let size = mfarray.storedSize
    let newdata = MfData(size: mfarray.storedSize, mftype: mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: mfarray.storedSize)
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        wrap_vDSP_sign(size, $0.baseAddress!, dstptrT, vDSP_vminmg_func, vDSP_viclip_func,
            vForce_copysign_func)
    }
    
    let newmfstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

/// Boolean conversion by vDSP
/// - Parameter mfarray: An input mfarray
/// - Returns: Converted mfarray
internal func toBool_by_vDSP(_ mfarray: MfArray) -> MfArray{
    assert(mfarray.storedType == .Float, "Must be bool")
    
    let size = mfarray.storedSize
    let newdata = MfData(size: mfarray.storedSize, mftype: .Bool)
    let dstptrT = newdata.data.bindMemory(to: Float.self, capacity: mfarray.storedSize)
    
    mfarray.withDataUnsafeMBPtrT(datatype: Float.self){
        wrap_vDSP_toBool(size, $0.baseAddress!, dstptrT, vDSP_vminmg, vDSP_viclip)
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Boolean conversion by vDSP
/// - Parameter mfarray: An input mfarray
/// - Returns: Converted mfarray
internal func toIBool_by_vDSP(_ mfarray: MfArray) -> MfArray{
    assert(mfarray.storedType == .Float, "Must be bool")
    
    let size = mfarray.storedSize
    let newdata = MfData(size: mfarray.storedSize, mftype: .Bool)
    let dstptrT = newdata.data.bindMemory(to: Float.self, capacity: mfarray.storedSize)
    
    mfarray.withDataUnsafeMBPtrT(datatype: Float.self){
        wrap_vDSP_toIBool(size, $0.baseAddress!, dstptrT, vDSP_vminmg, vDSP_viclip, vDSP_vsadd, vvfabsf)
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
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
            shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: shapeptr.count)
        }
        
        let newstrides = shape2strides(shapeptr, mforder: .Row)
        stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: shapeptr.count)
        
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
    //let mfarray = check_contiguous(mfarray, .Row)
    
    
    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    var retShape = [true_num] + lastShape
    let retSize = shape2size(&retShape)
    
    let newdata = MfData(size: retSize, mftype: mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: retSize)
    
    indicesT.withDataUnsafeMBPtrT(datatype: T.self){
        //[unowned indicesT](indptr) in
        indptr in
        // note that indices and mfarray is row contiguous
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            srcptr in
            
            for vDSPPrams in OptOffsetParamsSequence(shape: indicesT.shape, bigger_strides: indicesT.strides, smaller_strides: mfarray.strides){
                wrap_vDSP_cmprs(vDSPPrams.blocksize, srcptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, indptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSP_func)
            }
            //vDSP_func(srcptr.baseAddress!, vDSP_Stride(1), indptr.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(indicesT.size))
        }
    }
    
    
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
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
    let newdata = MfData(size: indices.size, mftype: mfarray.mftype)
    let dstptrT = newdata.data.bindMemory(to: T.self, capacity: indices.size)
    let _ = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        srcptr in
        var offsets = (indices.data as! [Int]).map{ UInt(get_positive_index($0, axissize: mfarray.size, axis: 0) * mfarray.strides[0] + 1) }
        wrap_vDSP_gathr(indices.size, srcptr.baseAddress!, &offsets, 1, dstptrT, 1, vDSP_func)
    }
    let newstructure = MfStructure(shape: indices.shape, strides: indices.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
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
