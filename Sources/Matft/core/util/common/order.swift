//
//  order.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/06.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal func toSwiftArray(_ mfarray: MfArray) -> [Any]{
    let mfarray = !mfarray.mfstructure.row_contiguous ? mfarray.to_contiguous(mforder: .Row) : mfarray
    
    var shape = mfarray.shape
    var data = mfarray.data
    
    return _get_swiftArray(&data, shape: &shape, axis: 0)
}

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


/// Copy mfarray including structure
/// - Parameter src_mfarray: The source mfarray
/// - Returns: The destination mfarray
@usableFromInline
internal func copy_all_mfarray(_ src_mfarray: MfArray) -> MfArray{
    assert(src_mfarray.mfstructure.row_contiguous || src_mfarray.mfstructure.column_contiguous, "To call copyAll function, passed mfarray must be contiguous")
    
    let newsize = src_mfarray.size
    let newdata = MfData(size: newsize, mftype: src_mfarray.mftype)
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
    case .Double:
        _ = src_mfarray.withUnsafeMutableStartPointer(datatype: Double.self){
            srcptr in
            dst_mfarray.withUnsafeMutableStartPointer(datatype: Double.self){
                dstptr in
                memcpy(dstptr, srcptr, MemoryLayout<Double>.size*newsize)
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
