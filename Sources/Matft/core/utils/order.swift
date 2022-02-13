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
@usableFromInline
internal func check_contiguous<T: MfTypeUsable>(_ mfarray: MfArray<T>, _ mforder: MfOrder? = .Row) -> MfArray<T>{
    if ((mfarray.mfstructure.row_contiguous || mfarray.mfstructure.column_contiguous) && mforder == nil) ||
        (mfarray.mfstructure.row_contiguous && mforder == .Row) || (mfarray.mfstructure.column_contiguous && mforder == .Column){
        return mfarray
    }
    else{
        return Matft.to_contiguous(mfarray, mforder: mforder ?? .Row)
    }
}

/// Whether to contain reverse or not
/// - Returns: The boolean whether to contain reverse or not
@usableFromInline
internal func isReverse<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> Bool{
    return mfarray.strides.contains{ $0 < 0 }
}


/// Get a swift array
/// - Parameter mfarray: An input mfarray
/// - Returns: A swift array
@usableFromInline
internal func toSwiftArray<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> [Any]{
    let mfarray = !mfarray.mfstructure.row_contiguous ? Matft.to_contiguous(mfarray, mforder: .Row) : mfarray
    
    var shape = mfarray.shape
    var data: [Any] = mfarray.data
    
    return _get_swiftArray(&data, shape: &shape, axis: 0)
}


/// Get a swift array. This function is recursive one
/// - Parameters:
///   - data: An input and output data array
///   - shape: A shape array
///   - axis: The current axis
/// - Returns: A swift array
fileprivate func _get_swiftArray(_ data: inout [Any], shape: inout [Int], axis: Int) -> [Any]{
    let dim = shape[axis]
    let ndim = shape.count
    let size = data.count
    let offset = size / dim // note that this division must be divisible
    
    var ret: [Any] = []
    for i in 0..<dim{
        var slicedArray = Array(data[i*offset..<(i+1)*offset])
        if axis + 1 < ndim{
            ret += [_get_swiftArray(&slicedArray, shape: &shape, axis: axis + 1)]
        }
        else{
            ret += slicedArray
        }
    }
    return ret
}
