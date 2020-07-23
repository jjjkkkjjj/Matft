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

internal func toSwiftArray(_ mfarray: MfArray) -> [Any]{
    let mfarray = !mfarray.mfflags.row_contiguous ? to_row_major(mfarray) : mfarray
    
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
    assert(mfarray.mfflags.row_contiguous || mfarray.mfflags.column_contiguous, "To call copyAll function, passed mfarray must be contiguous")
    let newmfdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.size){
        dstptr in
        mfarray.withDataUnsafeMRPtr{
            [unowned mfarray] in
            dstptr.copyMemory(from: $0, byteCount: mfarray.byteSize)
        }
    }
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    
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
internal func check_biop_contiguous(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ mforder: MfOrder = .Row, convertL: Bool = true) -> (l: MfArray, r: MfArray, biggerL: Bool, retstoredSize: Int){
    let l: MfArray, r: MfArray
    let biggerL: Bool
    let retstoredSize: Int
    if r_mfarray.mfflags.column_contiguous || r_mfarray.mfflags.row_contiguous{
        l = l_mfarray
        r = r_mfarray
        biggerL = false
        retstoredSize = r_mfarray.storedSize
    }
    else if l_mfarray.mfflags.column_contiguous || l_mfarray.mfflags.row_contiguous{
        l = l_mfarray
        r = r_mfarray
        biggerL = true
        retstoredSize = l_mfarray.storedSize
    }
    else{
        if convertL{
            l = Matft.conv_order(l_mfarray, mforder: mforder)
            r = r_mfarray
            biggerL = true
            retstoredSize = l.storedSize
        }
        else{
            l = l_mfarray
            r = Matft.conv_order(r_mfarray, mforder: mforder)
            biggerL = false
            retstoredSize = r.storedSize
        }
    }
    return (l, r, biggerL, retstoredSize)
}
