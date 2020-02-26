//
//  Index.swift
//  Matft
//
//  Created by Junnosuke Kado on 2019/12/09.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

// note that i is index of data
fileprivate func _get_index(i: Int, shape: inout [Int]) -> [Int]{
    var res = shape
    var quotient = i
    let ndim = shape.count
    
    for axis in stride(from: ndim - 1, through: 0, by: -1){
        res[axis] = quotient % shape[axis]
        quotient = Int(quotient / shape[axis])
    }
    
    return res
}

internal func _get_indices(_ shape: [Int]) -> [[Int]]{
    var ret: [[Int]] = []
    
    let size = _shape2size(shape)
    var _shape = shape
    
    for i in 0..<size{
        ret.append(_get_index(i: i, shape: &_shape))
    }
    
    //print(ret)
    
    return ret
}
//recursive function for getting limitted
fileprivate func _recursive_leaveout_indices(shape: inout [Int], axis: Int, ini_num: Int, numbers: inout [Int?]){
    
    let ndim = shape.count
    
    if axis == ndim - 1{
        if shape[axis] < 6{ //not leave out
            for i in 0..<shape[axis]{
                numbers.append(i + ini_num)
            }
        }
        else{ //leave out
            for i in 0..<3{ //first 3 elements
                numbers.append(i + ini_num)
            }
            
            numbers.append(nil) //skip
            
            for i in (shape[axis] - 3)..<shape[axis]{ //last 3 elements
                numbers.append(i + ini_num)
            }
        }
        return
    }
    else{
        let restsize = _shape2size(Array(shape[(axis + 1)..<ndim]))
        if shape[axis] < 6{ //not leave out
            for i in 0..<shape[axis]{
                _recursive_leaveout_indices(shape: &shape, axis: axis + 1, ini_num: i * restsize + ini_num, numbers: &numbers)
            }
        }
        else{ //leave out
            for i in 0..<3{ //first 3 elements
                _recursive_leaveout_indices(shape: &shape, axis: axis + 1, ini_num: i * restsize + ini_num, numbers: &numbers)
            }
            
            numbers.append(nil) //skip
            
            for i in (shape[axis] - 3)..<shape[axis]{  //last 3 elements
                _recursive_leaveout_indices(shape: &shape, axis: axis + 1, ini_num: i * restsize + ini_num, numbers: &numbers)
            }
        }
    }
}
//nil means skip
internal func _get_leaveout_indices(_ shape: [Int]) -> [[Int]?]{
    var numbers: [Int?] = [] //list of indices of data
    var _shape = shape
    _recursive_leaveout_indices(shape: &_shape, axis: 0, ini_num: 0, numbers: &numbers)
    //print(numbers)
    var ret: [[Int]?] = []
    
    for number in numbers{
        if let number = number{
            ret.append(_get_index(i: number, shape: &_shape))
        }
        else{ // nil i.e. skip
            ret.append(nil)
        }
    }
    
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

/*
 internal struct Indices: Sequence, IteratorProtocol{
 typealias Element = [Int]
 
 init() {
 
 }
 
 mutating func next() -> [Int]? {
 <#code#>
 }
 }
 */
