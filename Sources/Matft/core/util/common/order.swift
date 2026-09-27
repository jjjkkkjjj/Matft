//
//  order.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/06.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// Copy mfarray including structure
/// - Parameter src_mfarray: The source mfarray
/// - Returns: The destination mfarray
@usableFromInline
internal func copy_all_mfarray(_ src_mfarray: MfArray) -> MfArray{
    assert(src_mfarray.mfstructure.row_contiguous || src_mfarray.mfstructure.column_contiguous, "To call copyAll function, passed mfarray must be contiguous")
    
    let newsize = src_mfarray.size
    let newdata = MfData(uninitializedSize: newsize, mftype: src_mfarray.mftype, complex: src_mfarray.isComplex)
    let newstructure = MfStructure(shape: src_mfarray.shape, strides: src_mfarray.strides)
    let dst_mfarray = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    switch src_mfarray.storedType{
    case .Float:
        _ = src_mfarray.withUnsafeMutableStartPointer(datatype: Float.self){
            srcptr in
            dst_mfarray.withUnsafeMutableStartPointer(datatype: Float.self){
                dstptr in
                memcpy(dstptr, srcptr, MemoryLayout<Float>.size*newsize)
            }
        }
        if src_mfarray.isComplex{
            _ = src_mfarray.withUnsafeMutableStartImagPointer(datatype: Float.self){
                srcptr in
                dst_mfarray.withUnsafeMutableStartImagPointer(datatype: Float.self){
                    dstptr in
                    memcpy(dstptr!, srcptr!, MemoryLayout<Float>.size*newsize)
                }
            }
        }
    case .Double:
        _ = src_mfarray.withUnsafeMutableStartPointer(datatype: Double.self){
            srcptr in
            dst_mfarray.withUnsafeMutableStartPointer(datatype: Double.self){
                dstptr in
                memcpy(dstptr, srcptr, MemoryLayout<Double>.size*newsize)
            }
        }
        if src_mfarray.isComplex{
            _ = src_mfarray.withUnsafeMutableStartImagPointer(datatype: Double.self){
                srcptr in
                dst_mfarray.withUnsafeMutableStartImagPointer(datatype: Double.self){
                    dstptr in
                    memcpy(dstptr!, srcptr!, MemoryLayout<Double>.size*newsize)
                }
            }
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
internal func check_contiguous(_ mfarray: MfArray, _ mforder: MfOrder? = nil) -> MfArray{
    if ((mfarray.mfstructure.row_contiguous || mfarray.mfstructure.column_contiguous) && mforder == nil) ||
        (mfarray.mfstructure.row_contiguous && mforder == .Row) || (mfarray.mfstructure.column_contiguous && mforder == .Column){
        return mfarray
    }
    else{
        switch mforder {
        case .Row, nil:
            return mfarray.to_contiguous(mforder: .Row)
        case .Column:
            return mfarray.to_contiguous(mforder: .Column)
        }
    }
}

/// Return the mfarray itself when its elements occupy the whole stored data exactly once,
/// i.e. row/column contiguous or any axis permutation of them (e.g. `a.transpose(axes: [0,2,1])`). Otherwise return a row contiguous copy.
///
/// - Important: Use this only for element-wise kernels that process `storedSize` elements linearly
///   and create the result with the same shape and strides. The other kernels must use `check_contiguous`.
internal func check_dense(_ mfarray: MfArray) -> MfArray{
    // A view (e.g. `a[1~<2]`) shares the base's stored data, so `storedSize` elements from its offset would run past the end
    if mfarray.offsetIndex == 0 && mfarray.size == mfarray.storedSize &&
        (mfarray.mfstructure.row_contiguous || mfarray.mfstructure.column_contiguous || _is_dense_permutation(shape: mfarray.shape, strides: mfarray.strides)){
        return mfarray
    }
    return mfarray.to_contiguous(mforder: .Row)
}

/// Make two mfarrays of the same shape dense in the same layout, so that their elements can be processed linearly together.
/// Arrays already in the same dense layout are not copied.
/// - Returns: The mfarrays. `size` elements from each start pointer correspond one by one
internal func check_same_dense_layout(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> (l: MfArray, r: MfArray){
    assert(l_mfarray.shape == r_mfarray.shape, "call biop_broadcast_to first!")
    let l = check_dense(l_mfarray)
    let r = check_dense(r_mfarray)
    if l.strides == r.strides{
        return (l, r)
    }
    return (check_contiguous(l, .Row), check_contiguous(r, .Row))
}

/// Convert mftype for internal use. Unlike `astype`, which always copies, it returns a view when only the type label changes
/// (e.g. Int -> Float, both stored as Float). The returned mfarray must not be written.
/// - Parameters:
///   - mfarray: An input mfarray
///   - mftype: The new mftype
/// - Returns: The mfarray of the given mftype
internal func astype_or_view(_ mfarray: MfArray, _ mftype: MfType) -> MfArray{
    if mfarray.mftype == mftype{
        return mfarray
    }
    // Bool needs the values to be converted into 1/0
    guard mftype != .Bool && MfType.storedType(mftype) == mfarray.storedType else{
        return mfarray.astype(mftype)
    }
    let ret = MfArray(base: mfarray, mfstructure: mfarray.mfstructure, offset: mfarray.offsetIndex)
    ret.mfdata.mftype = mftype
    return ret
}

/// Whether the strides are a permutation of contiguous strides without gaps
fileprivate func _is_dense_permutation(shape: [Int], strides: [Int]) -> Bool{
    let axes = (0..<shape.count).filter{ shape[$0] != 1 }.sorted{ strides[$0] < strides[$1] }
    var expected = 1
    for axis in axes{
        if strides[axis] != expected{
            return false
        }
        expected *= shape[axis]
    }
    return true
}

@usableFromInline
internal func check_biop_contiguous(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ mforder: MfOrder = .Row, convertL: Bool = true) -> (l: MfArray, r: MfArray, biggerL: Bool, retsize: Int){
    let l: MfArray, r: MfArray
    let biggerL: Bool
    let retsize: Int
    if r_mfarray.mfstructure.column_contiguous || r_mfarray.mfstructure.row_contiguous{
        l = l_mfarray
        r = r_mfarray
        biggerL = false
        retsize = r_mfarray.size
    }
    else if l_mfarray.mfstructure.column_contiguous || l_mfarray.mfstructure.row_contiguous{
        l = l_mfarray
        r = r_mfarray
        biggerL = true
        retsize = l_mfarray.size
    }
    else{
        if convertL{
            l = Matft.to_contiguous(l_mfarray, mforder: mforder)
            r = r_mfarray
            biggerL = true
            retsize = l.size
        }
        else{
            l = l_mfarray
            r = Matft.to_contiguous(r_mfarray, mforder: mforder)
            biggerL = false
            retsize = r.size
        }
    }
    return (l, r, biggerL, retsize)
}

/// Get a best order for matrix mulplication
/// - Parameters:
///   - l_mfarray: An left mfarray
///   - r_mfarray: An right mfarray
/// - Returns:
///   - l_mfarray: Contiguous left mfarray
///   - r_mfarray: Contiguous right mfarray
///   - mforder: Best order
@usableFromInline
internal func check_matmul_contiguous(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray) -> MfOrder{
    // order
    /*
    // must be close to either row or column major
    var retorder = MfOrder.Row
    if !(lmfarray.mfstructure.column_contiguous && rmfarray.mfstructure.column_contiguous) || lmfarray.mfstructure.row_contiguous && rmfarray.mfstructure.row_contiguous{//convert either row or column major
        if lmfarray.mfstructure.column_contiguous{
            rmfarray = Matft.to_contiguous(rmfarray, mforder: .Column)
            retorder = .Column
        }
        else if lmfarray.mfstructure.row_contiguous{
            rmfarray = Matft.to_contiguous(rmfarray, mforder: .Row)
            retorder = .Row
        }
        else if rmfarray.mfstructure.column_contiguous{
            lmfarray = Matft.to_contiguous(lmfarray, mforder: .Column)
            retorder = .Column
        }
        else if rmfarray.mfstructure.row_contiguous{
            lmfarray = Matft.to_contiguous(lmfarray, mforder: .Row)
            retorder = .Row
        }
        else{
            lmfarray = Matft.to_contiguous(lmfarray, mforder: .Row)
            rmfarray = Matft.to_contiguous(rmfarray, mforder: .Row)
            retorder = .Row
        }
    }
    else{
        retorder = lmfarray.mfstructure.row_contiguous ? .Row : .Column
    }*/
    //must be row major
    let retorder = MfOrder.Row
    if !(lmfarray.mfstructure.row_contiguous && rmfarray.mfstructure.row_contiguous){//convert row major
        if !rmfarray.mfstructure.row_contiguous{
            rmfarray = Matft.to_contiguous(rmfarray, mforder: .Row)
        }
        if !lmfarray.mfstructure.row_contiguous{
            lmfarray = Matft.to_contiguous(lmfarray, mforder: .Row)
        }
    }
    return retorder
}

/// Whether to contain reverse or not
/// - Returns: The boolean whether to contain reverse or not
internal func isReverse(_ strides: inout [Int]) -> Bool{
    return strides.contains{ $0 < 0 }
}

/// Get a swift array
/// - Parameter mfarray: An input mfarray
/// - Returns: A swift array
@usableFromInline
internal func toSwiftArray(_ mfarray: MfArray) -> [Any]{
    // mfarray has no base
    let mfarray = mfarray.deepcopy(.Row)
    
    var shape = mfarray.shape
    var data = mfarray.data
    
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
    let offset = dim == 0 ? 0 : size / dim // note that this division must be divisible
    
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
