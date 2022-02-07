//
//  optparams.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation


/// Optimal offset and stride parameters sequence for vDSP and cblas
internal struct OptOffsetParamsSequence: Sequence{
    let shape: [Int]
    let strides: (b: [Int], s: [Int])
    
    
    /// Initialization
    /// - Parameters:
    ///   - shape: An input shape array
    ///   - bigger_strides: The strides of **larger stored size** mfarray
    ///   - smaller_strides: The strides of **smaller stored size** mfarray
    public init(shape: [Int], bigger_strides: [Int], smaller_strides: [Int]){
        self.shape = shape
        self.strides.b = bigger_strides
        self.strides.s = smaller_strides
    }
    
    
    /// Generate an Iterator
    /// - Returns: Iterator on optimal offset parameters for vDSP and cblas
    func makeIterator() -> OptOffsetParamIterator {
        return OptOffsetParamIterator(optParams: self)
    }
}


/// Iterator on optimal offset parameters for vDSP and cblas
internal struct OptOffsetParamIterator: IteratorProtocol{
    let stride: (b: Int, s: Int)
    let blocksize: Int
    let itershapes: [Int]
    let iter_strides: (b: [Int], s: [Int])
    
    var upaxis: Int //indicates which axis will be counted up
    var indicesOfAxes: [Int]
    var offset: (b: Int, s: Int)? = (0, 0)
    
    
    /// Initialization
    /// - Parameter optParams: Optimal offset and stride parameters sequence
    public init(optParams: OptOffsetParamsSequence){
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


/// Search maximum and common contiguous stride between two mfarray
/// - Parameters:
///   - shape: An input shape array
///   - l_strides: The left mfarray's strides array
///   - r_strides: The right mfarray's strides array
/// - Returns:
///   - axis: index of strides given for vDSP
///   - blocksize: maximum size calculated once by vDSP or cblas
///   - iterAxes: indices of non-contiguous strides
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
