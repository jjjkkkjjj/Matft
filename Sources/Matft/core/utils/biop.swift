//
//  biop.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation


/// Check and convert into a proper contiguous mfarray for a binary operation
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_mfarray: The right mfarray
///   - mforder: An order
///   - convertL: The priority to convert a left mfarray.
/// - Returns:
///   - l: The left mfarray
///   - r: The right mfarray
///   - biggerL: Whether the left mfarray is bigger or not
///   - retsize: The return size after a binary operation
internal func check_biop_contiguous<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, _ mforder: MfOrder = .Row, convertL: Bool = true) -> (l: MfArray<T>, r: MfArray<T>, biggerL: Bool, retsize: Int){
    let l: MfArray<T>, r: MfArray<T>
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



/// Convert 2 mfarray into ones with same structure
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_mfarray: The right mfarray
/// - Returns:
///   - l: The converted left mfarray
///   - r: The converted right mfarray
internal func to_samestructure<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> (l: MfArray<T>, r: MfArray<T>){
    let l: MfArray<T>, r: MfArray<T>
    assert(l_mfarray.size == r_mfarray.size, "must have a same size")
    
    if (l_mfarray.storedSize == r_mfarray.storedSize) && (l_mfarray.strides == r_mfarray.strides){
        // not conversion
        l = l_mfarray
        r = r_mfarray
    }
    else if l_mfarray.mfstructure.column_contiguous ||
        r_mfarray.mfstructure.column_contiguous{
        l = samesize_by_cblas(l_mfarray, cblas_func: T.StoredType.cblas_copy_func, mforder: .Column)
        r = samesize_by_cblas(r_mfarray, cblas_func: T.StoredType.cblas_copy_func, mforder: .Column)
    }
    else{
        l = samesize_by_cblas(l_mfarray, cblas_func: T.StoredType.cblas_copy_func, mforder: .Row)
        r = samesize_by_cblas(r_mfarray, cblas_func: T.StoredType.cblas_copy_func, mforder: .Row)
    }
    
    return (l, r)
}


/// Broadcasting function for a binary operation
/// - Parameters:
///   - l_mfarray: The left mfarray
///   - r_mfarray: The right mfarray
/// - Returns:
///   - l: The left broadcasted mfarray
///   - r: The right broadcasted mfarray
internal func biop_broadcast_to<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> (l: MfArray<T>, r: MfArray<T>){
    var l_mfarray = l_mfarray
    var r_mfarray = r_mfarray
    
    // broadcast
    let retndim: Int
    var l_shape = l_mfarray.shape
    var l_strides = l_mfarray.strides
    var r_shape = r_mfarray.shape
    var r_strides = r_mfarray.strides
    
    // align dimension
    if l_mfarray.ndim < r_mfarray.ndim{ // l has smaller dim
        retndim = r_mfarray.ndim
        l_shape = Array<Int>(repeating: 1, count: r_mfarray.ndim - l_mfarray.ndim) + l_shape // the 1 concatenated elements means broadcastable
        l_strides = Array<Int>(repeating: 0, count: r_mfarray.ndim - l_mfarray.ndim) + l_strides// the 0 concatenated elements means broadcastable
    }
    else if l_mfarray.ndim > r_mfarray.ndim{// r has smaller dim
        retndim = l_mfarray.ndim
        r_shape = Array<Int>(repeating: 1, count: l_mfarray.ndim - r_mfarray.ndim) + r_shape // the 1 concatenated elements means broadcastable
        r_strides = Array<Int>(repeating: 0, count: l_mfarray.ndim - r_mfarray.ndim) + r_strides// the 0 concatenated elements means broadcastable
    }
    else{
        retndim = l_mfarray.ndim
    }
    
    for axis in (0..<retndim).reversed(){
        if l_shape[axis] == r_shape[axis]{
            continue
        }
        else if l_shape[axis] == 1{
            l_shape[axis] = r_shape[axis] // aligned to r
            l_strides[axis] = 0 // broad casted 0
        }
        else if r_shape[axis] == 1{
            r_shape[axis] = l_shape[axis] // aligned to l
            r_strides[axis] = 0 // broad casted 0
        }
        else{
            preconditionFailure("could not be broadcast together with shapes \(l_mfarray.shape) \(r_mfarray.shape)")
        }
    }
    
    let l_mfstructure = MfStructure(shape: l_shape, strides: l_strides)
    let r_mfstructure = MfStructure(shape: r_shape, strides: r_strides)
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: l_mfstructure._shape, count: l_mfstructure._ndim)))
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: r_mfstructure._shape, count: r_mfstructure._ndim)))
    l_mfarray = MfArray(base: l_mfarray, mfstructure: l_mfstructure, offset: l_mfarray.offsetIndex)
    r_mfarray = MfArray(base: r_mfarray, mfstructure: r_mfstructure, offset: r_mfarray.offsetIndex)
    
    return (l_mfarray, r_mfarray)
}
