//
//  index.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

// note that i is index of data
fileprivate func _get_index(i: Int, shapeptr: inout UnsafeMutableBufferPointer<Int>) -> [Int]{
    var ret = Array(repeating: 0, count: shapeptr.count)
    var quotient = i
    let ndim = shapeptr.count
    
    for axis in stride(from: ndim - 1, through: 0, by: -1){
        ret[axis] = quotient % shapeptr[axis]
        quotient = Int(quotient / shapeptr[axis])
    }
    
    return ret
}

internal func get_indices(_ shapeptr: inout UnsafeMutableBufferPointer<Int>) -> [[Int]]{
    var ret: [[Int]] = []
    
    let size = shape2size(shapeptr)
    
    for i in 0..<size{
        ret.append(_get_index(i: i, shapeptr: &shapeptr))
    }
    
    //print(ret)
    
    return ret
}
//recursive function for getting limitted
fileprivate func _recursive_leaveout_indices(shapeptr: inout UnsafeMutableBufferPointer<Int>, axis: Int, ini_num: Int, numbers: inout [Int?]){
    
    let ndim = shapeptr.count
    
    if axis == ndim - 1{
        if shapeptr[axis] < 6{ //not leave out
            for i in 0..<shapeptr[axis]{
                numbers.append(i + ini_num)
            }
        }
        else{ //leave out
            for i in 0..<3{ //first 3 elements
                numbers.append(i + ini_num)
            }
            
            numbers.append(nil) //skip
            
            for i in (shapeptr[axis] - 3)..<shapeptr[axis]{ //last 3 elements
                numbers.append(i + ini_num)
            }
        }
        return
    }
    else{
        let tmparr = create_unsafeMBPtrT(type: Int.self, count: shapeptr.count - (axis + 1))
        memcpy(tmparr.baseAddress!, shapeptr.baseAddress! + axis + 1, MemoryLayout<Int>.stride * tmparr.count)
        let restsize = shape2size(tmparr)
        tmparr.deallocate()
        
        if shapeptr[axis] < 6{ //not leave out
            for i in 0..<shapeptr[axis]{
                _recursive_leaveout_indices(shapeptr: &shapeptr, axis: axis + 1, ini_num: i * restsize + ini_num, numbers: &numbers)
            }
        }
        else{ //leave out
            for i in 0..<3{ //first 3 elements
                _recursive_leaveout_indices(shapeptr: &shapeptr, axis: axis + 1, ini_num: i * restsize + ini_num, numbers: &numbers)
            }
            
            numbers.append(nil) //skip
            
            for i in (shapeptr[axis] - 3)..<shapeptr[axis]{  //last 3 elements
                _recursive_leaveout_indices(shapeptr: &shapeptr, axis: axis + 1, ini_num: i * restsize + ini_num, numbers: &numbers)
            }
        }
    }
}
//nil means skip
internal func get_leaveout_indices(_ shapeptr: inout UnsafeMutableBufferPointer<Int>) -> [[Int]?]{
    var numbers: [Int?] = [] //list of indices of data
    _recursive_leaveout_indices(shapeptr: &shapeptr, axis: 0, ini_num: 0, numbers: &numbers)
    //print(numbers)
    var ret: [[Int]?] = []
    
    for number in numbers{
        if let number = number{
            ret.append(_get_index(i: number, shapeptr: &shapeptr))
        }
        else{ // nil i.e. skip
            ret.append(nil)
        }
    }
    
    return ret
}

