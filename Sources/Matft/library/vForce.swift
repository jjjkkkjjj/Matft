//
//  vForce.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/08.
//

import Foundation

public typealias vForce_copysign_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_biop_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

/// Math operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vForce_func: The vForce math function
/// - Returns: The math-operated mfarray
internal func math_by_vForce<T: MfTypeUsable, U: MfTypeUsable>(_ mfarray: MfArray<T>, _ vForce_func: vForce_math_func<U.StoredType>) -> MfArray<U> where T.StoredType == U.StoredType{
    let mfarray = check_contiguous(mfarray)
    var ret_size = Int32(mfarray.size)
    
    let newdata: MfData<U> = MfData(size: mfarray.size)
    vForce_func(newdata.storedPtr.baseAddress!, mfarray.mfdata.storedPtr.baseAddress!, &ret_size)
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Math operation by vDSP
/// - Parameters:
///   - l_mfarray: An input left mfarray
///   - r_mfarray: An input right mfarray
///   - vForce_func: The vForce math function
/// - Returns: The math-operated mfarray
internal func math_biop_by_vForce<T: MfTypeUsable, U: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, _ vForce_func: vForce_math_biop_func<U.StoredType>) -> MfArray<U> where T.StoredType == U.StoredType{
    let l_mfarray = l_mfarray.to_contiguous(mforder: .Row)
    let r_mfarray = r_mfarray.to_contiguous(mforder: .Row)
    var ret_size = Int32(l_mfarray.storedSize)
    
    let newdata: MfData<U> = MfData(size: l_mfarray.storedSize)
    vForce_func(newdata.storedPtr.baseAddress!, l_mfarray.mfdata.storedPtr.baseAddress!, r_mfarray.mfdata.storedPtr.baseAddress!, &ret_size)
    
    let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Calculate the round for all elements
/// - Parameters:
///   - mfarray: An input mfarray
///   - decimals: (Optional) Int, default is 0, which is equivelent to nearest
///   - powval: The power value
/// - Returns: round mfarray
internal func round_by_vForce<T: MfTypeUsable, U: MfTypeUsable>(_ mfarray: MfArray<T>, decimals: Int = 0, powval: U.StoredType) -> MfArray<U> where T.StoredType == U.StoredType{
    
    let mfarray = check_contiguous(mfarray)
    let newdata: MfData<U> = MfData(size: mfarray.storedSize)
    var ret_size = Int32(mfarray.storedSize)
    var powval = powval
    
    let dstptr = newdata.storedPtr.baseAddress!
    mfarray.withUnsafeMutableStartPointer{
        // mfarray * pow
        // nearest(mfarray * pow)
        // nearest(mfarray * pow) / pow
        wrap_vDSP_biopvs(mfarray.storedSize, $0, 1, &powval, dstptr, 1, T.StoredType.vDSP_mulvs_func)
        T.StoredType.vForce_nearest_func(dstptr, dstptr, &ret_size)
        wrap_vDSP_biopvs(mfarray.storedSize, dstptr, 1, &powval, dstptr, 1, T.StoredType.vDSP_divvs_func)
    }
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
