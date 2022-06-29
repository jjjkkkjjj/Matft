//
//  index.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

// note that i is index of data
fileprivate func _get_index(i: Int, shape: inout [Int]) -> [Int]{
    var ret = Array(repeating: 0, count: shape.count)
    var quotient = i
    let ndim = shape.count
    
    for axis in stride(from: ndim - 1, through: 0, by: -1){
        ret[axis] = quotient % shape[axis]
        quotient = Int(quotient / shape[axis])
    }
    
    return ret
}

internal func get_indices(_ shape: inout [Int]) -> [[Int]]{
    var ret: [[Int]] = []
    
    let size = shape2size(&shape)
    
    for i in 0..<size{
        ret.append(_get_index(i: i, shape: &shape))
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

        let restsize = shape2size(&shape)
        
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
internal func get_leaveout_indices(_ shape: inout [Int]) -> [[Int]?]{
    var numbers: [Int?] = [] //list of indices of data
    _recursive_leaveout_indices(shape: &shape, axis: 0, ini_num: 0, numbers: &numbers)
    //print(numbers)
    var ret: [[Int]?] = []
    
    for number in numbers{
        if let number = number{
            ret.append(_get_index(i: number, shape: &shape))
        }
        else{ // nil i.e. skip
            ret.append(nil)
        }
    }
    
    return ret
}

internal struct FlattenIndSequence: Sequence{
    let shape: [Int]
    let strides: [Int]
    
    public init(shape: inout [Int], strides: inout [Int]){
        assert(!shape.isEmpty && !strides.isEmpty, "shape and strides must not be empty")
        assert(shape.count == strides.count, "shape and strides must be samesize")
        
        self.shape = shape
        self.strides = strides
    }
    
    func makeIterator() -> FlattenIndSequenceIterator {
        return FlattenIndSequenceIterator(self)
    }
}

// return index for flatten array from shape and strides
internal struct FlattenIndSequenceIterator: IteratorProtocol{
    private let flattenIndSeq: FlattenIndSequence
    public var strides: [Int]{
        return self.flattenIndSeq.strides
    }
    public var shape: [Int]{
        return self.flattenIndSeq.shape
    }
    
    public var indicesOfAxes: [Int]
    public var flattenIndex: Int = 0
    public var upaxis: Int = -1 //indicates which axis will be counted up
    
    public init(_ flattenIndSeq: FlattenIndSequence){
        self.flattenIndSeq = flattenIndSeq
        
        self.indicesOfAxes = Array(repeating: 0, count: flattenIndSeq.shape.count)
        self.flattenIndex = 0
        self.upaxis = -1
    }
    
    mutating func next() -> (flattenIndex: Int, indices: [Int])? {
        if self.upaxis == -1{// flattenIndex = 0, indicesOfAxes = [0,...,0] must be returned
            self.upaxis = self.shape.count - 1
            return (self.flattenIndex, self.indicesOfAxes)
        }
        
        for axis in (0..<self.indicesOfAxes.count).reversed(){
            if self.indicesOfAxes[axis] < self.shape[axis] - 1{
                self.indicesOfAxes[axis] += 1
                self.upaxis = axis
                
                self.flattenIndex += self.strides[axis]
                
                return (self.flattenIndex, self.indicesOfAxes)
            }
            else{// next axis
                self.indicesOfAxes[axis] = 0

                // reset flattenIndex
                self.flattenIndex -= self.strides[axis]*(self.shape[axis] - 1)
            }
        }
        
        return nil
        
    }
}


internal struct FlattenLOIndSequence: Sequence{
    let shape: [Int]
    let strides: [Int]
    let storedSize: Int
    
    public init(storedSize: Int, shape: inout [Int], strides: inout [Int]){
        assert(!shape.isEmpty && !strides.isEmpty, "shape and strides must not be empty")
        assert(shape.count == strides.count, "shape and strides must be samesize")
        
        self.shape = shape
        self.strides = strides
        self.storedSize = storedSize
    }
    
    func makeIterator() -> FlattenLOIndSequenceIterator {
        return FlattenLOIndSequenceIterator(self)
    }
}

// return index for flatten array from shape and strides
internal struct FlattenLOIndSequenceIterator: IteratorProtocol{
    private let flattenLOIndSeq: FlattenLOIndSequence
    public var strides: [Int]{
        return self.flattenLOIndSeq.strides
    }
    public var shape: [Int]{
        return self.flattenLOIndSeq.shape
    }
    public var storedSize: Int{
        return self.flattenLOIndSeq.storedSize
    }
    
    public var indicesOfAxes: [Int]
    public var flattenIndex: Int = 0
    public var isUpAxis: Bool  = true//indicates which axis will be counted up
    
    public init(_ flattenLOIndSeq: FlattenLOIndSequence){
        self.flattenLOIndSeq = flattenLOIndSeq
        
        self.indicesOfAxes = Array(repeating: 0, count: flattenLOIndSeq.shape.count)
        self.flattenIndex = 0
        self.isUpAxis = true
    }
    
    //return (nil nil) indicates skip
    mutating func next() -> (flattenIndex: Int?, indices: [Int]?)? {
        if self.isUpAxis{// flattenIndex = 0, indicesOfAxes = [0,...,0] must be returned
            self.isUpAxis = false
            return (self.flattenIndex, self.indicesOfAxes)
        }
        
    
        
        for axis in (0..<self.indicesOfAxes.count).reversed(){
            
            if self.indicesOfAxes[axis] < self.shape[axis] - 1{
                
                if self.indicesOfAxes[axis] < 2 || self.indicesOfAxes[axis] >= self.shape[axis] - 4{ //0<=index<3 and dim-3-1<=index<dim
                    self.indicesOfAxes[axis] += 1
                    
                    self.isUpAxis = false
                    
                    self.flattenIndex += self.strides[axis]
                    
                    return (self.flattenIndex, self.indicesOfAxes)
                }
                else{// skip
                    let skipnum = self.shape[axis] - 6
                    
                    if axis == self.indicesOfAxes.count - 1{// last axis
                        self.indicesOfAxes[axis] += skipnum
                        self.flattenIndex += self.strides[axis] * skipnum
                        
                        self.isUpAxis = false
                    }
                    else{
                        self.indicesOfAxes[axis] += skipnum + 1
                        self.flattenIndex += self.strides[axis] * (skipnum + 1)
                        
                        self.isUpAxis = true // once return (nil, nil) (i.e. skip) and then re-start printing
                    }
                    return (nil, nil)
                }
            }
            else{// next axis, i.e. self.indicesOfAxes[axis] == self.shape[axis] - 1
                if axis >= 3 && axis < self.indicesOfAxes.count - 3{
                    for _axis in (0..<self.indicesOfAxes.count - 3).reversed(){//shape[_axis] padding for each indicesAxes
                        self.indicesOfAxes[_axis] = self.shape[_axis] - 1
                    }
                    
                    self.isUpAxis = false
                    
                    return (nil, nil)
                }
                
                self.indicesOfAxes[axis] = 0

                // reset flattenIndex
                self.flattenIndex -= self.strides[axis]*(self.shape[axis] - 1)
            }
        }
        
        return nil
        
    }
}


/*
internal struct Combination: Sequence{
    var a: [Any]
    public init (_ a: inout [Any]){
        self.a = a
    }
    
    func makeIterator() -> CombinationIterator {
        return CombinationIterator(self.a)
    }
}

internal struct CombinationIterator: IteratorProtocol{
    var a: [Any]
    var indices: [Int]
    var iternum = 0
    
    public init(_ a: [Any]){
        self.a = a
        self.indices = Array(repeating: 0, count: a.count)
    }
    
    mutating func next() -> [Int]? {
        if self.iternum == 0{
            self.iternum += 1
            
            return self.indices
        }
        else{
            self.iternum += 1
            
            var next = self.a.count - 1
            
            if (next < 0){
                return nil
            }
            
            guard let a = self.a[next] as? [Int] else {
                return nil
            }
            
            while (next >= 0 && self.indices[next] + 1 >= a.count){
                next -= 1
            }
            
            if (next < 0){
                return nil
            }
            
            self.indices[next] += 1
            for i in next + 1..<self.a.count{
                self.indices[i] = 0
            }
            
            return self.indices
        }
    }
}
*/
