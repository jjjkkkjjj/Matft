//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/11.
//

import Foundation

internal func get_axis(_ axis: Int, ndim: Int) -> Int{
    let ret_axis = axis >= 0 ? axis : axis + ndim
    precondition(0 <= ret_axis && ret_axis < ndim, "\(axis) is out of bounds")
    
    return ret_axis
}

internal func get_axis_for_expand_dims(_ axis: Int, ndim: Int) -> Int{
    let ret_axis: Int
    if axis < ndim && axis > -ndim - 1{
        ret_axis = get_axis(axis, ndim: ndim)
    }
    else if axis == ndim{
        ret_axis = axis
    }
    else if axis == -ndim - 1{
        ret_axis = 0
    }
    else{
        preconditionFailure("Invalid axis was passed. must not be -mfarray.ndim - 1 <= axis <= mfarray.ndim")
    }
    
    return ret_axis
}

internal func get_index(_ index: Int, dim: Int, axis: Int) -> Int{
    let ret_index = index >= 0 ? index : index + dim
    precondition(0 <= ret_index && ret_index < dim, "\(index) is out of bounds for axis \(axis) with \(dim)")
    
    return ret_index
}

internal func get_shape(_ shape: [Int], _ size: Int) -> [Int]{
    let restsize = shape.filter{ $0 != -1 }.reduce(1, *)
    return shape.map{
        if $0 != -1{
            return $0
        }
        else{
            return size / restsize
        }
    }
}

internal func biop_broadcast_to(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> (l: MfArray, r: MfArray, t: MfType){
    var l_mfarray = l_mfarray
    var r_mfarray = r_mfarray
    /*
    if l_mfarray.storedSize < r_mfarray.storedSize{
        l_mfarray = r_mfarray
        r_mfarray = l_mfarray
    }*/
    
    let rettype = MfType.priority(l_mfarray.mftype, r_mfarray.mftype)
    if l_mfarray.mftype != rettype{
        l_mfarray = l_mfarray.astype(rettype)
    }
    else if r_mfarray.mftype != rettype{
        r_mfarray = r_mfarray.astype(rettype)
    }
    
    if l_mfarray.size > r_mfarray.size{
        r_mfarray = r_mfarray.broadcast_to(shape: l_mfarray.shape)
    }
    else if r_mfarray.size > l_mfarray.size{
        l_mfarray = l_mfarray.broadcast_to(shape: r_mfarray.shape)
    }
    // below condition has same size implicitly
    // below condition cannot be deprecated into above condition because l.size > r.size & l.ndim < r.ndim is possible
    else if l_mfarray.ndim > r_mfarray.ndim{
        r_mfarray = r_mfarray.broadcast_to(shape: l_mfarray.shape)
    }
    else if r_mfarray.ndim > l_mfarray.ndim{
        l_mfarray = l_mfarray.broadcast_to(shape: r_mfarray.shape)
    }
    
    return (l_mfarray, r_mfarray, rettype)
}
