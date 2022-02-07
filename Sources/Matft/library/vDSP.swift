//
//  vDSP.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/05.
//

import Foundation
import Accelerate

public typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

public typealias vDSP_vcmprs_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

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
    wrap_vDSP_convert(mfarray.storedSize, mfarray.mfdata.storedPtr.baseAddress!, 1, newdata.storedPtr.baseAddress!, 1, T.StoredType.vDSP_preop_func)
    
    
    let newmfstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

/*
internal func boolget_by_vDSP<T: MfTypeUsable>(_ src_mfarray: MfArray<T>, _ indices: MfArray<Bool>, _ vDSP_func: vDSP_vcmprs_func<T.StoredType>) -> MfArray<T>{
    
    /*
     Note that returned shape must be (true number in original indices, (mfarray's shape - original indices' shape));
     i.e. returned dim = 1(=true number in original indices) + mfarray's dim - indices' dim
     */
    let true_num = Float.toInt(indices.sum().scalar!)
    let orig_ind_dim = indices.ndim
    
    // broadcast
    let indices = bool_broadcast_to(indices, shape: mfarray.shape)

    // must be row major
    let indicesU: MfArray<U> = check_contiguous(indices.astype(U.self), .Row)
    let mfarray = check_contiguous(mfarray, .Row)
    
    
    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    var retShape = [true_num] + lastShape
    let retSize = shape2size(&retShape)
    
    let newdata = withDummyDataMRPtr(T.self, storedSize: retSize){
        dstptr in
        let dstptrU = dstptr.bindMemory(to: U.self, capacity: retSize)
        
        indicesU.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned indicesU](indptr) in
            // note that indices and mfarray is row contiguous
            mfarray.withDataUnsafeMBPtrT(datatype: U.self){
                srcptr in
                vDSP_func(srcptr.baseAddress!, vDSP_Stride(1), indptr.baseAddress!, vDSP_Stride(1), dstptrU, vDSP_Stride(1), vDSP_Length(indicesU.size))
            }
        }
    }
    
}*/
