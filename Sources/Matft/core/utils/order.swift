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


/// Return contiguous mfarray. If passed mfarray is arleady contiguous, return one directly
/// - Parameters:
///   - mfarray: An input mfarray
///   - mforder: An order
/// - Returns: A contiguous mfarray
internal func check_contiguous<T: MfTypeUsable>(_ mfarray: MfArray<T>, _ mforder: MfOrder? = nil) -> MfArray<T>{
    if ((mfarray.mfstructure.row_contiguous || mfarray.mfstructure.column_contiguous) && mforder == nil) ||
        (mfarray.mfstructure.row_contiguous && mforder == .Row) || (mfarray.mfstructure.column_contiguous && mforder == .Column){
        return mfarray
    }
    else{
        return Matft.to_contiguous(mfarray, mforder: mforder ?? .Row)
    }
}
