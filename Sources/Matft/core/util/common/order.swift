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
    let mfarray = !mfarray.mfstructure.row_contiguous ? to_row_major(mfarray) : mfarray
    
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

/**
    - Important: strides must be checked before calling this function
 */
internal func copyAll(_ mfarray: MfArray) -> MfArray{
    assert(mfarray.mfstructure.row_contiguous || mfarray.mfstructure.column_contiguous, "To call copyAll function, passed mfarray must be contiguous")
    let newmfdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.size){
        dstptr in
        mfarray.withDataUnsafeMRPtr{
            [unowned mfarray] in
            dstptr.copyMemory(from: $0, byteCount: mfarray.byteSize)
        }
    }
    let newmfstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

internal func to_row_major(_ mfarray: MfArray) -> MfArray{
    if mfarray.mfstructure.row_contiguous{
        return copyAll(mfarray)
    }
    
    switch mfarray.storedType {
    case .Float:
        return copy_by_cblas(mfarray, mforder: .Row, cblas_func: cblas_scopy)
    case .Double:
        return copy_by_cblas(mfarray, mforder: .Row, cblas_func: cblas_dcopy)
    }
    
}

internal func to_column_major(_ mfarray: MfArray) -> MfArray{
    if mfarray.mfstructure.column_contiguous{
        return copyAll(mfarray)
    }
    
    switch mfarray.storedType {
    case .Float:
        return copy_by_cblas(mfarray, mforder: .Column, cblas_func: cblas_scopy)
    case .Double:
        return copy_by_cblas(mfarray, mforder: .Column, cblas_func: cblas_dcopy)
    }
}

/**
 Return contiguous mfarray. If passed mfarray is arleady contiguous, return one directly
 */
internal func check_contiguous(_ mfarray: MfArray, _ mforder: MfOrder? = nil) -> MfArray{
    if ((mfarray.mfstructure.row_contiguous || mfarray.mfstructure.column_contiguous) && mforder == nil) ||
        (mfarray.mfstructure.row_contiguous && mforder == .Row) || (mfarray.mfstructure.column_contiguous && mforder == .Column){
        return mfarray
    }
    else{
        switch mforder {
        case .Row, nil:
            return to_row_major(mfarray)
        case .Column:
            return to_column_major(mfarray)
        }
    }
}
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
            l = Matft.conv_order(l_mfarray, mforder: mforder)
            r = r_mfarray
            biggerL = true
            retsize = l.size
        }
        else{
            l = l_mfarray
            r = Matft.conv_order(r_mfarray, mforder: mforder)
            biggerL = false
            retsize = r.size
        }
    }
    return (l, r, biggerL, retsize)
}
