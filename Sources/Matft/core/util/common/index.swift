//
//  index.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// Get a positive index from a given index
/// - Parameters:
///   - index: An index. Negative index will be converted into positive one as return value
///   - axissize: The axis size of a given index
///   - axis: An axis
/// - Returns: A positive index
internal func get_positive_index(_ index: Int, axissize: Int, axis: Int) -> Int{
    let ret_index = index >= 0 ? index : index + axissize
    precondition(0 <= ret_index && ret_index < axissize, "\(index) is out of bounds for axis \(axis) with \(axissize)")
    
    return ret_index
}

/// Get a positive index for the insert function from a given index
/// - Parameters:
///   - index: An index. Negative index will be converted into positive one as return value
///   - axissize: The axis size of a given index
///   - axis: An axis
/// - Returns: A positive index
internal func get_positive_index_for_insert(_ index: Int, axissize: Int, axis: Int) -> Int{

    let ret_index: Int
    if index < axissize && index > -axissize - 1{
        ret_index = get_positive_index(index, axissize: axissize, axis: axis)
    }
    else if index == axissize{
        ret_index = index
    }
    else if index == -axissize - 1{
        ret_index = 0
    }
    else{
        preconditionFailure("Invalid index was passed. must not be \(-axissize - 1) <= index(\(index)) <= \(axissize) for axis \(axis)")
    }
    
    return ret_index
}

/// Get a positive axis from a given axis
/// - Parameters:
///   - axis: An axis index. Negative axis will be converted into positive one as return value
///   - ndim: The dimension
/// - Returns: A positive axis
internal func get_positive_axis(_ axis: Int, ndim: Int) -> Int{
    let ret_axis = axis >= 0 ? axis : axis + ndim
    precondition(0 <= ret_axis && ret_axis < ndim, "\(axis) is out of bounds")
    
    return ret_axis
}

/// get a positive axis for expand_dims
/// - Parameters:
///   - axis: An axis index. Negative axis will be converted into positive one as return value
///   - ndim: The dimension
/// - Returns: A positive axis
internal func get_positive_axis_for_expand_dims(_ axis: Int, ndim: Int) -> Int{
    let ret_axis: Int
    if axis < ndim && axis > -ndim - 1{
        ret_axis = get_positive_axis(axis, ndim: ndim)
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

/// Get a positive shape from a given size
/// - Parameters:
///   - shape: A shape array. Negative axis will be converted into positive one as return value
///   - size: The size
/// - Returns: A positive shape array
internal func get_positive_shape(_ shape: [Int], _ size: Int) -> [Int]{
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

/// Get offsets from indices array
/// - Parameters:
///   - mfarray: An input mfarray
///   - indices: An indices mfarray array
/// - Returns:
///   - offsets: Offset values
///   - ind_shape: Indices shape array
///   - ind_size: Indices size
internal func get_offsets_from_indices(_ mfarray: MfArray, _ indices: inout [MfArray]) -> (offsets: [Int], indShape: [Int], indSize: Int){
    var indShape = indices.reduce(indices[0]){ biop_broadcast_to($0, $1).r }.shape
    let indSize = shape2size(&indShape)
    // note that all of mfarraies should have same size thanks to this process
    var offsets = Array(repeating: 0, count: indSize)
    for (axis, inds) in indices.enumerated(){
        precondition(inds.mftype == .Int, "fancy indexing must be Int only, but got \(inds.mftype)")
        let rowInd = inds.broadcast_to(shape: indShape).to_contiguous(mforder: .Row)
        for (i, ind) in (rowInd.data as! [Int]).enumerated(){
            offsets[i] += get_positive_index(ind, axissize: mfarray.shape[axis], axis: axis) * mfarray.strides[axis]
        }
    }
    
    return (offsets, indShape, indSize)
}

/// Broadcasting mfarray for boolean indexing
/// - Parameters:
///   - mfarray: An input boolean mfarray
///   - shape: The destination shape array
/// - Returns: COPIED boolean indices mfarray
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

    for axis in (0..<retndim).reversed(){
        if lshape[axis] == rshape[axis]{
            continue
        }
        else if lshape[axis] == 1{
            lshape[axis] = rshape[axis] // aligned to r
            lstrides[axis] = 0 // broad casted 0
        }
        else if rshape[axis] == 1{
            rshape[axis] = lshape[axis] // aligned to l
            rstrides[axis] = 0 // broad casted 0
        }
        else{
            preconditionFailure("could not be broadcast together with shapes \(l_mfarray.shape) \(r_mfarray.shape)")
        }
    }
    let l_mfstructure = MfStructure(shape: lshape, strides: lstrides)
    let r_mfstructure = MfStructure(shape: rshape, strides: rstrides)
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: l_mfstructure._shape, count: l_mfstructure._ndim)))
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: r_mfstructure._shape, count: r_mfstructure._ndim)))

    l_mfarray = MfArray(base: l_mfarray, mfstructure: l_mfstructure, offset: l_mfarray.offsetIndex)
    r_mfarray = MfArray(base: r_mfarray, mfstructure: r_mfstructure, offset: r_mfarray.offsetIndex)
    
    return (l_mfarray, r_mfarray, rettype)
}


/// Index sequence for a flatten array
internal struct FlattenIndSequence: Sequence{
    let shape: [Int]
    let strides: [Int]
    
    
    /// Initialization
    /// - Parameters:
    ///   - shape: A shape array
    ///   - strides: A strides array
    public init(shape: inout [Int], strides: inout [Int]){
        assert(!shape.isEmpty && !strides.isEmpty, "shape and strides must not be empty")
        assert(shape.count == strides.count, "shape and strides must be samesize")
        
        self.shape = shape
        self.strides = strides
    }
    
    /// Generate an iterator
    /// - Returns: Iterator on index for a flatten array
    func makeIterator() -> FlattenIndSequenceIterator {
        return FlattenIndSequenceIterator(self)
    }
}

/// Iterator on index for a flatten array from a given shape and strides
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


/// Index sequence for a flatten array
/// Note that this sequence is for print function of leave out version
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

/// Iterator on index for a flatten array from a given shape and strides
/// Note that this sequence is for print function of leave out version
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
