//
//  utils_mfarray.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/06.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

internal func anyArray2data_C<T>(array: [Any], type: T.Type) -> MfArrayInfo<T>{
    switch type {
    case is Int.Type:
        var data: [Double] = []
        let shape = search_mfarrayInfo_recursion_Int(array: array, type: Int.self, data: &data)
        //print(data)
        //print(shape)
        
        return MfArrayInfo(data: data, type: type, shape: shape, order: MfArrayType.MfOrder.C)
        
    case is Float.Type:
        var data: [Double] = []
        let shape = search_mfarrayInfo_recursion_FloatingPoint(array: array, type: Float.self, data: &data)
        //print(data)
        //print(shape)
        
        return MfArrayInfo(data: data, type: type, shape: shape, order: MfArrayType.MfOrder.C)
        
    case is Double.Type:
        var data: [Double] = []
        let shape = search_mfarrayInfo_recursion_FloatingPoint(array: array, type: Double.self, data: &data)
        //print(data)
        //print(shape)
        
        return MfArrayInfo(data: data, type: type, shape: shape, order: MfArrayType.MfOrder.C)
    default:
        fatalError("Unsupported type \(type) was passed")
    }
}

internal func search_mfarrayInfo_recursion_FloatingPoint<T: BinaryFloatingPoint>(array: [Any], type: T.Type, data: inout [Double]) -> [Int]{
    var elementShapes: [[Int]] = []
    
    if let array = array as? [T]{
        data += array.map{ Double($0) }
        return [array.count]
    }
    else{
        for element in array{
            if let element = element as? [T]{
                data += element.map{ Double($0) }
                elementShapes.append([element.count])
            }
            else if let element = element as? [Any]{
                let elementShape_ = search_mfarrayInfo_recursion_FloatingPoint(array: element, type: T.self, data: &data)
                elementShapes.append(elementShape_)
            }
            else{
                fatalError("Element type was unsame")
            }
        }
    }
    //check elementShapes
    let orderSet = NSOrderedSet(array: elementShapes)
    let uniqueValues = orderSet.array as! [[Int]]
    
    precondition(uniqueValues.count == 1, "MfArray doesn't support uneven array, check input array")
    
    return [array.count] + uniqueValues[0]
}
internal func search_mfarrayInfo_recursion_Int<T: BinaryInteger>(array: [Any], type: T.Type, data: inout [Double]) -> [Int]{
    var elementShapes: [[Int]] = []
    
    if let array = array as? [T]{
        data += array.map{ Double($0) }
        return [array.count]
    }
    else{
        for element in array{
            if let element = element as? [T]{
                data += element.map{ Double($0) }
                elementShapes.append([element.count])
            }
            else if let element = element as? [Any]{
                let elementShape_ = search_mfarrayInfo_recursion_Int(array: element, type: T.self, data: &data)
                elementShapes.append(elementShape_)
            }
            else{
                fatalError("Element type was unsame")
            }
        }
    }
    //check elementShapes
    let orderSet = NSOrderedSet(array: elementShapes)
    let uniqueValues = orderSet.array as! [[Int]]
    
    precondition(uniqueValues.count == 1, "MfArray doesn't support uneven array, check input array")
    
    return [array.count] + uniqueValues[0]
}

internal func _shape2size(_ shape: [Int]) -> Int{
    var _size = 1
    for dim in shape{
        _size *= dim
    }
    return _size
}

internal func _shape2strides(_ shape: [Int], _ size: Int) -> [Int]{
    var strides: [Int] = []
    var prevAxisNum = size
    for index in 0..<shape.count{
        strides.append(prevAxisNum / shape[index])
        prevAxisNum = strides[index]
    }
    return strides
}

internal func _shape2ndim(_ shape: [Int]) -> Int{
    return shape.count
}
/*
 * Check whether the given array is stored contiguously
 * in memory. And update the passed in ap flags appropriately.
 *
 * The traditional rule is that for an array to be flagged as C contiguous,
 * the following must hold:
 *
 * strides[-1] == itemsize
 * strides[i] == shape[i+1] * strides[i + 1]
 *
 * And for an array to be flagged as F contiguous, the obvious reversal:
 *
 * strides[0] == itemsize
 * strides[i] == shape[i - 1] * strides[i - 1]
 */
internal func _check_contiguous(shape: [Int], strides: [Int]) -> (C_CONTIGUOUS: Bool, F_CONTIGUOUS: Bool){
    var sd = 1
    
    //check c contiguous
    var is_c_contig = true
    for i in stride(from: shape.count - 1, through: 0, by: -1){
        let dim = shape[i]
        if dim == 0{
            return (true, true)
        }
        if dim != 1{
            if strides[i] != sd{
                is_c_contig = false
            }
            sd *= dim
        }
    }

    sd = 1
    //check f contiguous
    for i in 0..<shape.count{
        let dim = shape[i]
        if dim != 1{
            if strides[i] != sd{
                return (is_c_contig, false)
            }
            sd *= dim
        }
    }
    return (is_c_contig, true)
}

internal func _check_broadcastable_and_get_broadcastedMfArray<T>(_ a: MfArray<T>, _ b: MfArray<T>) -> (a_: MfArray<T>, b_: MfArray<T>){
    var mindim_array = a
    var grdim_array = b
    var mina = true //means a has smaller dimension than b
    if a.ndim > b.ndim{
        mindim_array = b
        grdim_array = a
        mina = false
    }
    
    var mindim_newShape: [Int] = Array<Int>(repeating: 0, count: grdim_array.ndim)
    var grdim_newShape: [Int] = Array<Int>(repeating: 0, count: grdim_array.ndim)
    
    for i in 0..<mindim_array.ndim{
        //get dim of shape from back
        let mindim_shape = mindim_array.shape[mindim_array.ndim - 1 - i]
        let grdim_shape = grdim_array.shape[grdim_array.ndim - 1 - i]
        
        let index = grdim_array.ndim - 1 - i
        if mindim_shape == grdim_shape{//when the shapes' size are same, continue
            mindim_newShape[index] = mindim_shape
            grdim_newShape[index] = mindim_shape
            continue
        }
        else{
            if mindim_shape == 1{
                mindim_newShape[index] = grdim_shape
                grdim_newShape[index] = grdim_shape
            }else if grdim_shape == 1{
                mindim_newShape[index] = mindim_shape
                grdim_newShape[index] = mindim_shape
            }
            else{//cannot broadcast
                fatalError("operands could not be broadcast together with shapes \(a.shape) \(b.shape)")
            }
        }
    }
    
    for i in mindim_array.ndim..<grdim_array.ndim{
        let index = grdim_array.ndim - 1 - i
        mindim_newShape[index] = grdim_array.shape[index]
        grdim_newShape[index] = grdim_array.shape[index]
    }
    
    mindim_array = mindim_array.broadcast_to(shape: mindim_newShape)
    grdim_array = grdim_array.broadcast_to(shape: grdim_newShape)
    if mina{
        return (mindim_array, grdim_array)
    }
    else{
        return (grdim_array, mindim_array)
    }
}

internal func _get_storedSize<T>(mfarray: MfArray<T>) -> Int{
    // check stordsize
    var _base = mfarray.base
    var _storedSize = mfarray.size
    while _base != nil {
        _storedSize = _base!.size
        _base = _base!.base
    }
    return _storedSize
}

internal func _get_indices(_ shape: [Int]) -> [[Int]]{
    var ret: [[Int]] = []
    
    let size = _shape2size(shape)
    
    for i in 0..<size{
        var res = shape
        
        let ndim = shape.count
        
        var tmp = i
        for axis in stride(from: ndim - 1, through: 0, by: -1){
            res[axis] = tmp % shape[axis]
            tmp = Int(tmp / shape[axis])
        }
        
        ret.append(res)
    }
    
    //print(ret)
    
    return ret
}

internal func _inner_product<T: MfNumeric>(_ left: [T], _ right: [T]) -> T{
    precondition(left.count == right.count, "cannot calculate inner product due to unsame dim")
    var ret = T.zero
    
    for (l, r) in zip(left, right){
        ret += l * r
    }
    return ret
}
