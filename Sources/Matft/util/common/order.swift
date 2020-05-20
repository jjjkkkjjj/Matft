//
//  order.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/06.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal func flatten_array(ptr: UnsafeBufferPointer<Any>, mforder: inout MfOrder) -> (flatten: [Any], shape: [Int]){
    var shape: [Int] = [ptr.count]
    var queue = ptr.compactMap{ $0 }
    
    switch mforder {
    case .Row:
        return (_get_flatten_row_major(queue: &queue, shape: &shape), shape)
    case .Column:
        return (_get_flatten_column_major(queue: &queue, shape: &shape), shape)
    /*case .None:
        fatalError("Select row or column as MfOrder.")*/
    }
}

//row major order
//breadth-first search
fileprivate func _get_flatten_row_major(queue: inout [Any], shape: inout [Int]) -> [Any]{
    precondition(shape.count == 1, "shape must have only one element")
    var cnt = 0 // count up the number that value is extracted from queue for while statement, reset 0 when iteration number reaches size
    var size = queue.count
    var axis = 0//the axis in searching
    
    while queue.count > 0 {
        //get first element
        let elements = queue[0]
        
        if let elements = elements as? [Any]{
            queue += elements
            
            if cnt == 0{ //append next dim
                shape.append(elements.count)
                axis += 1
            }
            else{// check if same dim is or not
                if shape[axis] != elements.count{
                    shape = shape.dropLast()
                }
            }
            cnt += 1
        }
        else{ // value was detected. this means queue in this case becomes flatten array
            break
        }
        //remove first element from array
        let _ = queue.removeFirst()
        
        if cnt == size{//reset count and forward next axis
            cnt = 0
            size *= shape[axis]
        }
    }
    
    return queue
}

//column major order
fileprivate func _get_flatten_column_major(queue: inout [Any], shape: inout [Int]) -> [Any]{
    //precondition(shape.count == 1, "shape must have only one element")
    var cnt = 0 // count up the number that value is extracted from queue for while statement, reset 0 when iteration number reaches size
    //var axis = 0//the axis in searching
    let dim = queue.count // given
    
    var objectFlag = false
    
    var newqueue: [Any] = []
    while queue.count > 0{
        //get first element
        let elements = queue[0]
        
        if var elements = elements as? [Any]{
            if cnt == 0{ //append next dim
                shape.append(elements.count)
                //axis += 1
            }
            else if cnt < dim{// check if same dim is or not
                if shape.last! != elements.count{
                    shape = shape.dropLast()
                    objectFlag = true
                    break
                }
            }
            cnt += 1
            
            newqueue.append(elements.removeFirst())
            if elements.count > 0{
                queue.append(elements)
            }
            
            
        }
        else{ // value was detected. this means queue in this case becomes flatten array
            return queue
        }
        
        let _ = queue.removeFirst()
    }
    
    if !objectFlag{
        //recurrsive
        return _get_flatten_column_major(queue: &newqueue, shape: &shape)
    }
    else{
        return newqueue
    }
}


/*
fileprivate func _recurrsion_flatten(elements: Any, mftype : inout MfType, shape: inout [Int], depth: Int = 1) -> [Any]{
    if let ptr_elements = elements as? UnsafeBufferPointer<Any>{
        
        return ptr_elements.flatMap{
            _recurrsion_flatten(elements: $0, mftype: &mftype, shape: &shape, depth: depth + 1)
        }
    }
    else if let arr_elements = elements as? [Any]{
        if shape.count - 1 < depth{
            shape.append(arr_elements
                .count)
        }
        
        if shape.last! != arr_elements.count{
            shape = shape.dropLast()
        }
        else{
            return arr_elements.withUnsafeBufferPointer{
                _recurrsion_flatten(elements: $0, mftype: &mftype, shape: &shape, depth: depth)
            }
        }
    }
    
    let _mftype = MfType.mftype(value: elements)
    mftype = MfType.priority(mftype, _mftype)
    return [elements]

}*/


 /*
//copy array version
//this implementation was slower 2 times than above function which uses pointer

 extension Sequence {
    private func extract(from value: Any) -> [Any] {
        if let nestedArray = value as? [Any] {
            return nestedArray.flatten()
        }
        return [value]
    }

    func flatten() -> [Any] {
        return flatMap { extract(from: $0) }
    }
}

*/
/**
    - Important: strides must be checked before calling this function
 */
internal func copyAll(_ mfarray: MfArray) -> MfArray{
    precondition(mfarray.mfflags.row_contiguous || mfarray.mfflags.column_contiguous, "To call copyAll function, passed mfarray must be contiguous")
    let newmfdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.size){
        dstptr in
        mfarray.withDataUnsafeMRPtr{
            [unowned mfarray] in
            dstptr.copyMemory(from: $0, byteCount: mfarray.byteSize)
        }
    }
    let newmfstructure = withDummyShapeStridesMPtr(mfarray.ndim){
        (dstshapeptr, dststridesptr) in
        mfarray.withShapeUnsafeMPtr{
            [unowned mfarray] in
            dstshapeptr.assign(from: $0, count: mfarray.ndim)
        }
        mfarray.withStridesUnsafeMPtr{
            [unowned mfarray] in
            dststridesptr.assign(from: $0, count: mfarray.ndim)
        }
    }
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

internal func to_row_major(_ mfarray: MfArray) -> MfArray{
    if mfarray.mfflags.row_contiguous{
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
    if mfarray.mfflags.column_contiguous{
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
internal func check_contiguous(_ mfarray: MfArray, _ mforder: MfOrder = .Row) -> MfArray{
    if mfarray.mfflags.row_contiguous || mfarray.mfflags.column_contiguous{
        return mfarray
    }
    else{
        switch mforder {
        case .Row:
            return to_row_major(mfarray)
        case .Column:
            return to_column_major(mfarray)
        }
    }
}
