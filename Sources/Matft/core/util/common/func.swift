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
        preconditionFailure("Invalid axis was passed. must not be \(-ndim - 1) <= axis(\(axis)) <= \(ndim)")
    }
    
    return ret_axis
}

internal func get_index(_ index: Int, dim: Int, axis: Int) -> Int{
    let ret_index = index >= 0 ? index : index + dim
    precondition(0 <= ret_index && ret_index < dim, "\(index) is out of bounds for axis \(axis) with \(dim)")
    
    return ret_index
}

internal func get_index_for_insert(_ index: Int, dim: Int, axis: Int) -> Int{

    let ret_index: Int
    if index < dim && index > -dim - 1{
        ret_index = get_index(index, dim: dim, axis: axis)
    }
    else if index == dim{
        ret_index = index
    }
    else if index == -dim - 1{
        ret_index = 0
    }
    else{
        preconditionFailure("Invalid index was passed. must not be \(-dim - 1) <= index(\(index)) <= \(dim) for axis \(axis)")
    }
    
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
    
    // convert type
    let rettype = MfType.priority(l_mfarray.mftype, r_mfarray.mftype)
    if l_mfarray.mftype != rettype{
        l_mfarray = l_mfarray.astype(rettype)
    }
    else if r_mfarray.mftype != rettype{
        r_mfarray = r_mfarray.astype(rettype)
    }
    
    // broadcast
    let retndim: Int
    var lshape = l_mfarray.shape
    var lstrides = l_mfarray.strides
    var rshape = r_mfarray.shape
    var rstrides = r_mfarray.strides
    
    // align dimension
    if l_mfarray.ndim < r_mfarray.ndim{ // l has smaller dim
        retndim = r_mfarray.ndim
        lshape = Array<Int>(repeating: 1, count: r_mfarray.ndim - l_mfarray.ndim) + lshape // the 1 concatenated elements means broadcastable
        lstrides = Array<Int>(repeating: 0, count: r_mfarray.ndim - l_mfarray.ndim) + lstrides// the 0 concatenated elements means broadcastable
    }
    else if l_mfarray.ndim > r_mfarray.ndim{// r has smaller dim
        retndim = l_mfarray.ndim
        rshape = Array<Int>(repeating: 1, count: l_mfarray.ndim - r_mfarray.ndim) + rshape // the 1 concatenated elements means broadcastable
        rstrides = Array<Int>(repeating: 0, count: l_mfarray.ndim - r_mfarray.ndim) + rstrides// the 0 concatenated elements means broadcastable
    }
    else{
        retndim = l_mfarray.ndim
    }

    let (l_mfstructure, r_mfstructure) = withDummy2ShapeStridesMBPtr(retndim){
        
        l_shapeptr, l_stridesptr, r_shapeptr, r_stridesptr in
        //move
        lshape.withUnsafeMutableBufferPointer{
            l_shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
        }
        lstrides.withUnsafeMutableBufferPointer{
            l_stridesptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
        }
        rshape.withUnsafeMutableBufferPointer{
            r_shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
        }
        rstrides.withUnsafeMutableBufferPointer{
            r_stridesptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
        }
        
        
        for axis in (0..<retndim).reversed(){
            if l_shapeptr[axis] == r_shapeptr[axis]{
                continue
            }
            else if l_shapeptr[axis] == 1{
                l_shapeptr[axis] = r_shapeptr[axis] // aligned to r
                l_stridesptr[axis] = 0 // broad casted 0
            }
            else if r_shapeptr[axis] == 1{
                r_shapeptr[axis] = l_shapeptr[axis] // aligned to l
                r_stridesptr[axis] = 0 // broad casted 0
            }
            else{
                preconditionFailure("could not be broadcast together with shapes \(l_mfarray.shape) \(r_mfarray.shape)")
            }
        }
    }
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: l_mfstructure._shape, count: l_mfstructure._ndim)))
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: r_mfstructure._shape, count: r_mfstructure._ndim)))

    l_mfarray = MfArray(base: l_mfarray, mfstructure: l_mfstructure, offset: l_mfarray.offsetIndex)
    r_mfarray = MfArray(base: r_mfarray, mfstructure: r_mfstructure, offset: r_mfarray.offsetIndex)
    
    return (l_mfarray, r_mfarray, rettype)
}
