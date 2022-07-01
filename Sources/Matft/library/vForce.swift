//
//  vecLib.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
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
