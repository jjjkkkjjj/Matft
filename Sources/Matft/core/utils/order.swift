//
//  order.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation

/// Copy mfarray including structure
/// - Parameter src_mfarray: The source mfarray
/// - Returns: The destination mfarray
@usableFromInline
internal func copy_all_mfarray<T: MfTypeUsable>(_ src_mfarray: MfArray<T>) -> MfArray<T>{
    assert(src_mfarray.mfstructure.row_contiguous || src_mfarray.mfstructure.column_contiguous, "To call copyAll function, passed mfarray must be contiguous")
    
    let newsize = src_mfarray.size
    let newdata: MfData<T> = MfData(size: newsize)
    let newstructure = MfStructure(shape: src_mfarray.shape, strides: src_mfarray.strides)
    let dst_mfarray = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    _ = src_mfarray.withUnsafeMutableStartPointer{
        srcptr in
        dst_mfarray.withUnsafeMutableStartPointer{
            dstptr in
            memcpy(dstptr, srcptr, MemoryLayout<T.StoredType>.size*newsize)
        }
    }
    
    return dst_mfarray
}

