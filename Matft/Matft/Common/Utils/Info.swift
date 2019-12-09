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
