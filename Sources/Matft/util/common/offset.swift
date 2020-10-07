//
//  offset.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/07.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

internal struct OptOffsetParams_mfarray: Sequence{
    let bigger_mfarray: MfArray
    let smaller_mfarray: MfArray
    
    public init(bigger_mfarray: MfArray, smaller_mfarray: MfArray){
        self.bigger_mfarray = bigger_mfarray
        self.smaller_mfarray = smaller_mfarray
    }
    
    func makeIterator() -> OptOffsetParamIterator {
        return OptOffsetParamIterator(optParams: self)
    }
}

internal struct OptOffsetParams_raw: Sequence{
    let shape: [Int]
    let strides: (b: [Int], s: [Int])
    
    public init(shape: [Int], bigger_strides: [Int], smaller_strides: [Int]){
        self.shape = shape
        self.strides.b = bigger_strides
        self.strides.s = smaller_strides
    }
    
    func makeIterator() -> OptOffsetParamIterator {
        return OptOffsetParamIterator(optParams: self)
    }
}

internal struct OptOffsetParamIterator: IteratorProtocol{
    let stride: (b: Int, s: Int)
    let blocksize: Int
    let itershapes: [Int]
    let iter_strides: (b: [Int], s: [Int])
    
    var upaxis: Int //indicates which axis will be counted up
    var indicesOfAxes: [Int]
    var offset: (b: Int, s: Int)? = (0, 0)
    
    public init(optParams: OptOffsetParams_mfarray){
        var shape = optParams.bigger_mfarray.shape
        var b_strides = optParams.bigger_mfarray.strides
        var s_strides = optParams.smaller_mfarray.strides
        
        let (axis, blocksize, iterAxes) =
        
            _optStrides(shape: &shape, l_strides: &b_strides, r_strides: &s_strides)
        
        
        self.stride.b = b_strides[axis]
        self.stride.s = s_strides[axis]
        self.blocksize = blocksize
        
        self.itershapes = iterAxes.map{ shape[$0] }
        self.iter_strides.b = iterAxes.map{ b_strides[$0] }
        self.iter_strides.s = iterAxes.map{ s_strides[$0] }
        
        
        if self.itershapes.isEmpty{
            self.upaxis = -1
            self.indicesOfAxes = []
        }
        else{
            self.upaxis = 0
            self.indicesOfAxes = Array(repeating: 0, count: self.itershapes.count)
        }
    }
    
    public init(optParams: OptOffsetParams_raw){
        var shape = optParams.shape
        var b_strides = optParams.strides.b
        var s_strides = optParams.strides.s
        
        let (axis, blocksize, iterAxes) =
        
            _optStrides(shape: &shape, l_strides: &b_strides, r_strides: &s_strides)
        
        
        self.stride.b = b_strides[axis]
        self.stride.s = s_strides[axis]
        self.blocksize = blocksize
        
        self.itershapes = iterAxes.map{ shape[$0] }
        self.iter_strides.b = iterAxes.map{ b_strides[$0] }
        self.iter_strides.s = iterAxes.map{ s_strides[$0] }
        
        
        if self.itershapes.isEmpty{
            self.upaxis = -1
            self.indicesOfAxes = []
        }
        else{
            self.upaxis = 0
            self.indicesOfAxes = Array(repeating: 0, count: self.itershapes.count)
        }
    }
    
    mutating func next() -> (b_offset: Int, b_stride: Int, s_offset: Int, s_stride: Int, blocksize: Int)? {
        if self.indicesOfAxes.isEmpty{//offset (0, 0) must be returned even if itershapes doesn't exist
            
            self.indicesOfAxes = [-1] //dummy
            return (self.offset!.b, self.stride.b, self.offset!.s, self.stride.s, self.blocksize)
        }
        
        if self.upaxis < 0{
            return nil
        }

        for axis in 0..<self.indicesOfAxes.count{
            if self.indicesOfAxes[axis] < self.itershapes[axis] - 1{
                self.indicesOfAxes[axis] += 1
                self.upaxis = axis
                
                self.offset!.b += self.iter_strides.b[axis]
                self.offset!.s += self.iter_strides.s[axis]
                
                return (self.offset!.b, self.stride.b, self.offset!.s, self.stride.s, self.blocksize)
            }
            else if self.upaxis < self.itershapes.count{// next axis
                self.indicesOfAxes[axis] = 0

                // reset offset
                self.offset!.b -= self.iter_strides.b[axis]*(self.itershapes[axis] - 1)
                self.offset!.s -= self.iter_strides.s[axis]*(self.itershapes[axis] - 1)
            }
            else{
                return nil
            }
        }
        
        //last all indices are 0
        self.upaxis = -1
        return (self.offset!.b, self.stride.b, self.offset!.s, self.stride.s, self.blocksize)
    }
}

/*
 * search maximum and common contiguous stride between two mfarray
 * @return
 *      axis        : index of strides given for vDSP
 *      blocksize   : maximum size calculated once by vDSP
 *      iterAxes    : indices of non-contiguous strides
 */
fileprivate func _optStrides(shape: inout [Int], l_strides: inout [Int], r_strides: inout [Int]) -> (axis: Int, blocksize: Int, iterAxes: [Int]){
    var optaxis = 0, optBlockSize = -1
    
    let ndim = shape.count
    var optiterAxes: [Int] = Array(0..<ndim)
    
    // search optimimal strides
    for axis in 0..<ndim{
        var lsts = Array(l_strides) as [Int?]
        var rsts = Array(r_strides) as [Int?]
        lsts[axis] = nil//flag for skip
        rsts[axis] = nil
        
        var n = 0
        var last_contiguous_axis = axis
        var blockSize = shape[axis]
        var iterAxes: [Int] = []
        while n < ndim{
            guard let lst = lsts[n], let rst = rsts[n] else {//skip
                n += 1
                continue
            }
            
            if (lst == l_strides[last_contiguous_axis] * shape[last_contiguous_axis]) && (rst == r_strides[last_contiguous_axis] * shape[last_contiguous_axis]){//
                lsts[n] = nil//set flag as already checked
                rsts[n] = nil
                
                //update blocksize
                blockSize *= shape[n]
                
                //update last_contiguous_axis
                last_contiguous_axis = n
                
                //re-search
                n = 0
                iterAxes = []
                
                continue
            }
            
            //set axes to search
            iterAxes.append(n)
            n += 1
        }
        
        //check if it is maximum blocksize or not
        if blockSize > optBlockSize{
            optBlockSize = blockSize
            optaxis = axis
            optiterAxes = iterAxes
        }
    }
    
    return (optaxis, optBlockSize, optiterAxes)
}
/* future work?
 
 // optContiguousDims must not be 0, positive value means row contiguous, negative value means column contiguous
 , optContiguousDims = 1
 */

