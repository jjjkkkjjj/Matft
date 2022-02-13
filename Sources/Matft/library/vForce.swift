//
//  vForce.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/08.
//

import Foundation

public typealias vForce_copysign_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

/// Math operation by vDSP
/// - Parameters:
///   - mfarray: An input mfarray
///   - vForce_func: The vForce math function
/// - Returns: The math-operated mfarray
internal func math_vv_by_vForce<T: MfTypeUsable, U: MfTypeUsable>(_ mfarray: MfArray<T>, _ vForce_func: vForce_math_func<U.StoredType>) -> MfArray<U> where T.StoredType == U.StoredType{
    let mfarray = check_contiguous(mfarray)
    var ret_size = Int32(mfarray.size)
    
    let newdata: MfData<U> = MfData(size: mfarray.size)
    vForce_func(newdata.storedPtr.baseAddress!, mfarray.mfdata.storedPtr.baseAddress!, &ret_size)
    
    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
