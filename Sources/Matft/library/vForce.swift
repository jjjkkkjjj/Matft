//
//  vecLib.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate

public typealias vForce_copysign_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_biop_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

/// Math operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vForce_func: The vForce math function
/// - Returns: The math-operated mfarray
internal func math_by_vForce<T: MfStorable>(_ mfarray: MfArray, _ vForce_func: vForce_math_func<T>) -> MfArray{
    let mfarray = check_contiguous(mfarray)
    var ret_size = Int32(mfarray.size)
    
    let newdata = MfData(size: mfarray.size, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            vForce_func(dstptrT, $0, &ret_size)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Math operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vForce_func: The vForce math function
/// - Returns: The math-operated mfarray
internal func mathf_by_vForce<T: MfStorable>(_ mfarray: MfArray, _ vForce_func: vForce_math_func<T>) -> MfArray{
    var mfarray = mfarray
    mfarray = check_contiguous(mfarray)
    
    let newdata = MfData(size: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            var storedSize = Int32(mfarray.storedSize)
            vForce_func(dstptrT, $0, &storedSize)
        }
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Math operation by vDSP
/// - Parameters:
///   - l_mfarray: An input left mfarray
///   - r_mfarray: An input right mfarray
///   - vForce_func: The vForce math function
/// - Returns: The math-operated mfarray
internal func math_biop_by_vForce<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ vForce_func: vForce_math_biop_func<T>) -> MfArray{
    let l_mfarray = l_mfarray.to_contiguous(mforder: .Row)
    let r_mfarray = r_mfarray.to_contiguous(mforder: .Row)
    
    var storedSize = Int32(l_mfarray.storedSize)
    let newdata = MfData(size: l_mfarray.storedSize, mftype: l_mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        l_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            lptr in
            r_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                rptr in
                vForce_func(dstptrT, lptr, rptr, &storedSize)
            }
        }
    }

    let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
#else
// MARK: - WASI Fallback Implementations for vForce

public typealias vForce_copysign_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_biop_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

// MARK: - vForce Math Functions (Float)

@inline(__always)
internal func vvsqrtf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = sqrtf(src[i])
    }
}

@inline(__always)
internal func vvrsqrtf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = 1.0 / sqrtf(src[i])
    }
}

@inline(__always)
internal func vvlogf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = logf(src[i])
    }
}

@inline(__always)
internal func vvlog2f(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = log2f(src[i])
    }
}

@inline(__always)
internal func vvlog10f(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = log10f(src[i])
    }
}

@inline(__always)
internal func vvexpf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = expf(src[i])
    }
}

@inline(__always)
internal func vvexp2f(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = exp2f(src[i])
    }
}

@inline(__always)
internal func vvexpm1f(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = expm1f(src[i])
    }
}

@inline(__always)
internal func vvpowf(_ dst: UnsafeMutablePointer<Float>, _ base: UnsafePointer<Float>, _ exp: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = powf(base[i], exp[i])
    }
}

@inline(__always)
internal func vvsinf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = sinf(src[i])
    }
}

@inline(__always)
internal func vvcosf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = cosf(src[i])
    }
}

@inline(__always)
internal func vvtanf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = tanf(src[i])
    }
}

@inline(__always)
internal func vvasinf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = asinf(src[i])
    }
}

@inline(__always)
internal func vvacosf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = acosf(src[i])
    }
}

@inline(__always)
internal func vvatanf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = atanf(src[i])
    }
}

@inline(__always)
internal func vvsinhf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = sinhf(src[i])
    }
}

@inline(__always)
internal func vvcoshf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = coshf(src[i])
    }
}

@inline(__always)
internal func vvtanhf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = tanhf(src[i])
    }
}

@inline(__always)
internal func vvasinhf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = asinhf(src[i])
    }
}

@inline(__always)
internal func vvacoshf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = acoshf(src[i])
    }
}

@inline(__always)
internal func vvatanhf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = atanhf(src[i])
    }
}

@inline(__always)
internal func vvfloorf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = floorf(src[i])
    }
}

@inline(__always)
internal func vvceilf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = ceilf(src[i])
    }
}

@inline(__always)
internal func vvfabsf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = fabsf(src[i])
    }
}

@inline(__always)
internal func vvintf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = truncf(src[i])
    }
}

@inline(__always)
internal func vvnintf(_ dst: UnsafeMutablePointer<Float>, _ src: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = roundf(src[i])
    }
}

@inline(__always)
internal func vvcopysignf(_ dst: UnsafeMutablePointer<Float>, _ mag: UnsafePointer<Float>, _ sign: UnsafePointer<Float>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = copysignf(mag[i], sign[i])
    }
}

// MARK: - vForce Math Functions (Double)

@inline(__always)
internal func vvsqrt(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = sqrt(src[i])
    }
}

@inline(__always)
internal func vvrsqrt(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = 1.0 / sqrt(src[i])
    }
}

@inline(__always)
internal func vvlog(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = log(src[i])
    }
}

@inline(__always)
internal func vvlog2(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = log2(src[i])
    }
}

@inline(__always)
internal func vvlog10(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = log10(src[i])
    }
}

@inline(__always)
internal func vvexp(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = exp(src[i])
    }
}

@inline(__always)
internal func vvexp2(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = exp2(src[i])
    }
}

@inline(__always)
internal func vvexpm1(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = expm1(src[i])
    }
}

@inline(__always)
internal func vvpow(_ dst: UnsafeMutablePointer<Double>, _ base: UnsafePointer<Double>, _ exp: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = pow(base[i], exp[i])
    }
}

@inline(__always)
internal func vvsin(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = sin(src[i])
    }
}

@inline(__always)
internal func vvcos(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = cos(src[i])
    }
}

@inline(__always)
internal func vvtan(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = tan(src[i])
    }
}

@inline(__always)
internal func vvasin(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = asin(src[i])
    }
}

@inline(__always)
internal func vvacos(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = acos(src[i])
    }
}

@inline(__always)
internal func vvatan(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = atan(src[i])
    }
}

@inline(__always)
internal func vvsinh(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = sinh(src[i])
    }
}

@inline(__always)
internal func vvcosh(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = cosh(src[i])
    }
}

@inline(__always)
internal func vvtanh(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = tanh(src[i])
    }
}

@inline(__always)
internal func vvasinh(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = asinh(src[i])
    }
}

@inline(__always)
internal func vvacosh(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = acosh(src[i])
    }
}

@inline(__always)
internal func vvatanh(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = atanh(src[i])
    }
}

@inline(__always)
internal func vvfloor(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = floor(src[i])
    }
}

@inline(__always)
internal func vvceil(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = ceil(src[i])
    }
}

@inline(__always)
internal func vvfabs(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = fabs(src[i])
    }
}

@inline(__always)
internal func vvint(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = trunc(src[i])
    }
}

@inline(__always)
internal func vvnint(_ dst: UnsafeMutablePointer<Double>, _ src: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = round(src[i])
    }
}

@inline(__always)
internal func vvcopysign(_ dst: UnsafeMutablePointer<Double>, _ mag: UnsafePointer<Double>, _ sign: UnsafePointer<Double>, _ count: UnsafePointer<Int32>) {
    let n = Int(count.pointee)
    for i in 0..<n {
        dst[i] = copysign(mag[i], sign[i])
    }
}

// MARK: - vForce High-Level Functions for WASI

internal func math_by_vForce<T: MfStorable>(_ mfarray: MfArray, _ vForce_func: vForce_math_func<T>) -> MfArray{
    let mfarray = check_contiguous(mfarray)
    var ret_size = Int32(mfarray.size)

    let newdata = MfData(size: mfarray.size, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            vForce_func(dstptrT, $0, &ret_size)
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)

    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func mathf_by_vForce<T: MfStorable>(_ mfarray: MfArray, _ vForce_func: vForce_math_func<T>) -> MfArray{
    var mfarray = mfarray
    mfarray = check_contiguous(mfarray)

    let newdata = MfData(size: mfarray.storedSize, mftype: mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray] in
            var storedSize = Int32(mfarray.storedSize)
            vForce_func(dstptrT, $0, &storedSize)
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func math_biop_by_vForce<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ vForce_func: vForce_math_biop_func<T>) -> MfArray{
    let l_mfarray = l_mfarray.to_contiguous(mforder: .Row)
    let r_mfarray = r_mfarray.to_contiguous(mforder: .Row)

    var storedSize = Int32(l_mfarray.storedSize)
    let newdata = MfData(size: l_mfarray.storedSize, mftype: l_mfarray.mftype)
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        l_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            lptr in
            r_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                rptr in
                vForce_func(dstptrT, lptr, rptr, &storedSize)
            }
        }
    }

    let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

#endif // canImport(Accelerate)
