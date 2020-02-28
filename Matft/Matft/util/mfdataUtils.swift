//
//  array.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

internal func flatten_array(ptr: UnsafeBufferPointer<Any>, mftype: inout MfType) -> (flatten: [Any], shape: [Int]){
    
    var shape: [Int] = [ptr.count]
    var queue = ptr.compactMap{ $0 }
    
    return (_get_flatten_byBFS(queue: &queue, shape: &shape, mftype: &mftype), shape)
}

//breadth-first search
fileprivate func _get_flatten_byBFS(queue: inout [Any], shape: inout [Int], mftype : inout MfType) -> [Any]{
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

internal func shape2ndim(_ shape: inout [Int]) -> Int{
    return shape.count
}
internal func shape2ndim(_ shapeptr: UnsafeMutableBufferPointer<Int>) -> Int{
    return shapeptr.count
}

internal func shape2size(_ shapeptr: UnsafeMutableBufferPointer<Int>) -> Int{
    return shapeptr.reduce(1, *)
}

internal func shape2strides(_ shapeptr: UnsafeMutableBufferPointer<Int>) -> UnsafeMutableBufferPointer<Int>{
    let stridesptr = create_unsafeMBPtrT(type: Int.self, count: shapeptr.count)
    
    var prevAxisNum = shape2size(shapeptr)
    for index in 0..<shapeptr.count{
        stridesptr[index] = prevAxisNum / shapeptr[index]
        prevAxisNum = stridesptr[index]
    }
    return stridesptr
}

