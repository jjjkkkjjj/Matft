//
//  order.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/06.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal func flatten_array(ptr: UnsafeBufferPointer<Any>, mftype: inout MfType, mforder: inout MfOrder) -> (flatten: [Any], shape: [Int]){
    var shape: [Int] = [ptr.count]
    var queue = ptr.compactMap{ $0 }
    
    switch mforder {
    case .Row:
        return (_get_flatten_row_major(queue: &queue, shape: &shape, mftype: &mftype), shape)
    case .Column:
        return (_get_flatten_column_major(queue: &queue, shape: &shape, mftype: &mftype), shape)
    /*case .None:
        fatalError("Select row or column as MfOrder.")*/
    }
}

//row major order
//breadth-first search
fileprivate func _get_flatten_row_major(queue: inout [Any], shape: inout [Int], mftype : inout MfType) -> [Any]{
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
                    mftype = .Object
                }
            }
            cnt += 1
        }
        else{ // value was detected. this means queue in this case becomes flatten array
            let _mftype = MfType.mftype(value: elements)
            mftype = MfType.priority(mftype, _mftype)
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
fileprivate func _get_flatten_column_major(queue: inout [Any], shape: inout [Int], mftype: inout MfType) -> [Any]{
    //precondition(shape.count == 1, "shape must have only one element")
    var cnt = 0 // count up the number that value is extracted from queue for while statement, reset 0 when iteration number reaches size
    //var axis = 0//the axis in searching
    let dim = queue.count // given
    
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
                    mftype = .Object
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
            let _mftype = MfType.mftype(value: elements)
            mftype = MfType.priority(mftype, _mftype)
            return queue
        }
        
        let _ = queue.removeFirst()
    }
    
    if mftype != .Object{
        //recurrsive
        return _get_flatten_column_major(queue: &newqueue, shape: &shape, mftype: &mftype)
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


internal func to_row_major(_ mfarray: MfArray) -> MfArray{
    if mfarray.mfflags.row_contiguous{
        return mfarray.deepcopy()
    }
    
    
    let newstructure = withDummyShapeStridesMBPtr(mfarray.ndim){
            shapeptr, stridesptr in
            mfarray.withShapeUnsafeMBPtr{
            orig_shapeptr in
                let newstridesptr = shape2strides(orig_shapeptr, mforder: .Row)
                
                //copy
                shapeptr.baseAddress!.assign(from: orig_shapeptr.baseAddress!, count: mfarray.ndim)
                
                //move
                stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: mfarray.ndim)
            }
        }

    let ret = mfarray.deepcopy()
    ret.mfstructure = newstructure
    switch mfarray.storedType {
    case .Float:
        return convorder_by_cblas(mfarray, dsttmpMfarray: ret, cblas_func: cblas_scopy)
    case .Double:
        return convorder_by_cblas(mfarray, dsttmpMfarray: ret, cblas_func: cblas_dcopy)
    }
    
}

internal func to_column_major(_ mfarray: MfArray) -> MfArray{
    if mfarray.mfflags.column_contiguous{
        return mfarray.deepcopy()
    }
    
    let newstructure = withDummyShapeStridesMBPtr(mfarray.ndim){
        shapeptr, stridesptr in
        mfarray.withShapeUnsafeMBPtr{
        orig_shapeptr in
            let newstridesptr = shape2strides(orig_shapeptr, mforder: .Column)
            
            //copy
            shapeptr.baseAddress!.assign(from: orig_shapeptr.baseAddress!, count: mfarray.ndim)
            
            //move
            stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: mfarray.ndim)
        }
    }
    
    let ret = mfarray.deepcopy()
    ret.mfstructure = newstructure
    switch mfarray.storedType {
    case .Float:
        return convorder_by_cblas(mfarray, dsttmpMfarray: ret, cblas_func: cblas_scopy)
    case .Double:
        return convorder_by_cblas(mfarray, dsttmpMfarray: ret, cblas_func: cblas_dcopy)
    }
}

