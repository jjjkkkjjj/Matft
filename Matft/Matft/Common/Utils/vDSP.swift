//
//  vDSP.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/26.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation
import Accelerate

typealias vDSP_infix_func = (UnsafePointer<Double>, vDSP_Stride, UnsafePointer<Double>, vDSP_Stride, UnsafeMutablePointer<Double>, vDSP_Stride, vDSP_Length) -> Void

internal func vDSP_infix<T: MfNumeric>(_ left: MfArray<T>, _ right: MfArray<T>, _ vDSP_func: vDSP_infix_func) -> MfArray<T>{
    precondition(left.shape == right.shape, "left and rght must have same shape, shortly be broadcasted")
    if left.strides == right.strides{ //same order
        let new = Matft.mfarray.nums(num: 0, type: T.self, shape: left.shape)
        vDSP_func(left.data, vDSP_Stride(1), right.data, vDSP_Stride(1), new.data, vDSP_Stride(1), vDSP_Length(left.size))
        return new
    }

    // calculate which mfarray has bigger storedSize
    var smaller_storedSize = _get_storedSize(mfarray: left)
    var bigger_storedSize = _get_storedSize(mfarray: right)
    
    var smaller_mfarray = left
    var bigger_mfarray = right
    
    if bigger_storedSize < smaller_storedSize{
        swap(&smaller_storedSize, &bigger_storedSize)
        swap(&smaller_mfarray, &bigger_mfarray)
    }
    
    let new : MfArray<T>
    if smaller_mfarray.size == bigger_storedSize{
        new = Matft.mfarray.nums_like(num: 0, type: T.self, mfarray: bigger_mfarray)
        /*
        if smaller_storedSize == bigger_storedSize{ //squared mfarray (not broad casted and same )
            let blocksize = smaller_mfarray.shape[0]
            let bigger_stride = vDSP_Stride(bigger_mfarray.strides.min()!)
            let smaller_stride = vDSP_Stride(smaller_mfarray.strides.max()!)
            
            new = Matft.mfarray.nums(num: 0, type: T.self, shape: bigger_mfarray.shape)
            
            for i in 0..<blocksize{
                //let bigger_offset = (i * blocksize >= blocksize) ? 0 : i * blocksize
                vDSP_func(bigger_mfarray.data + i * blocksize, bigger_stride, smaller_mfarray.data + i, smaller_stride, new.data + blocksize * i, vDSP_Stride(1), vDSP_Length(blocksize))
            }
            return new
        }
        else{ //size = bigger stored > smaller stored
            new = Matft.mfarray.nums_like(num: 0, type: T.self, mfarray: bigger_mfarray)
        }*/
    }
    else{ // size > bigger stored >= smaller stored
        new = Matft.mfarray.nums(num: 0, type: T.self, shape: bigger_mfarray.shape)
    }
    
    
    
    
    return new
    
    /*
    let IA = vDSP_Stride(left_stride)
    let IB = vDSP_Stride(right_stride)
    let IC = vDSP_Stride(out_stride)
    let N = vDSP_Length(dim_shape)
    
    switch vDSP_function {
    case vDSP_op.infix.add:
        vDSP_vaddD(left_data, IA, right_data, IB, out_data, IC, N)
    case vDSP_op.infix.sub:
        vDSP_vsubD(left_data, IA, right_data, IB, out_data, IC, N)
    case vDSP_op.infix.mul:
        vDSP_vmulD(left_data, IA, right_data, IB, out_data, IC, N)
    case vDSP_op.infix.div:
        vDSP_vdivD(left_data, IA, right_data, IB, out_data, IC, N)
    }*/
}
/*
internal func vDSP_prefix(vDSP_function: vDSP_op.prefix, _ data: UnsafePointer<Double>, _ stride: Int, _ out_data: UnsafeMutablePointer<Double>, _ out_stride: Int, _ size: Int){
    let IA = vDSP_Stride(stride)
    let IC = vDSP_Stride(out_stride)
    let N = vDSP_Length(size)
    
    switch vDSP_function {
    case vDSP_op.prefix.neg:
        vDSP_vnegD(data, IA, out_data, IC, N)
    }
}


*/
fileprivate func _get_offset<T>(bigger_mfarray: MfArray<T>, bigger_storedsize: Int, smaller_mfarray: MfArray<T>, smaller_storedsize: Int) -> (b_offsets: [Int], b_stride: Int, s_offsets: [Int], s_stride: Int, blocksize: Int){
    
    var blocksizes: [Int] = []
    var b_strides = bigger_mfarray.strides
    var s_strides = smaller_mfarray.strides
    
    for (b_stride, s_stride) in zip(b_strides, s_strides){
        let _blocksize = max(bigger_storedsize / b_stride, smaller_storedsize / s_stride)
        
        if b_stride * s_stride == 0{
            blocksizes.append(min(_blocksize, bigger_storedsize / smaller_storedsize))
        }
        else if b_stride == 0 && s_stride == 0{
            blocksizes.append(bigger_mfarray.size + 1)//not selected
        }
        else{
            blocksizes.append(_blocksize)
        }
    }
    
    let blocksize = blocksizes.min()!
    let minIndex = blocksizes.firstIndex(of: blocksize)!
    
    let b_remain_strides = b_strides.remove(at: minIndex)
    let s_remain_strides = s_strides.remove(at: minIndex)
    
    var bigger_offsets = [0]
    var smaller_offsets = [0]
    for _ in 1..<(bigger_storedsize / blocksize){
        //bigger_offsets.append(<#T##newElement: Int##Int#>)
    }
    
    return (bigger_offsets, bigger_mfarray.strides[minIndex], smaller_offsets, smaller_mfarray.strides[minIndex], blocksize)
}

fileprivate struct vdsp_args<T: MfNumeric>: IteratorProtocol{
    typealias Element = (b_offset: Int, b_stride: Int, s_offset: Int, s_stride: Int, n_offset: Int, n_stride: Int, blocksize: Int)
    
    public var blocksize: Int
    private var size: Int
    private var calculatedSize: Int
    public var b_stride: Int
    public var s_stride: Int
    public var n_stride: Int
    
    // removed strides by index which maximizes blocksize
    private var _b_strides: [Int]
    private var _s_strides: [Int]
    private var _n_strides: [Int]
    
    private var _n_stridedsize: Int{ // step size every iteration
        return self.blocksize / self.n_stride
    }
    
    init(b_mfarray: MfArray<T>, b_storedSize: Int, s_mfarray: MfArray<T>, s_storedSize: Int, n_mfarray: MfArray<T>) {
        let ndim = n_mfarray.ndim
        
        var blocksize_candidates: [Int] = [] // select maximum one
        for i in 0..<ndim{
            let blocks = [b_storedSize / b_mfarray.strides[i],
                          s_storedSize / s_mfarray.strides[i],
                          n_mfarray.size / n_mfarray.strides[i]] //bigger, smaller, new
            blocksize_candidates.append(blocks.min()!)
        }
        
        self.blocksize = blocksize_candidates.max()!
        self.size = n_mfarray.size
        
        let selectedIndex = blocksize_candidates.firstIndex(of: self.blocksize)!
        self.b_stride = b_mfarray.strides[selectedIndex]
        self.s_stride = s_mfarray.strides[selectedIndex]
        self.n_stride = n_mfarray.strides[selectedIndex]
        
        //copy strides respectively
        self._b_strides = b_mfarray.strides
        self._s_strides = s_mfarray.strides
        self._n_strides = n_mfarray.strides
        
        //remove selected index
        self._b_strides.remove(at: selectedIndex)
        self._s_strides.remove(at: selectedIndex)
        self._n_strides.remove(at: selectedIndex)
        
        self.calculatedSize = 0
    }
    
    mutating func next() -> (b_offset: Int, b_stride: Int, s_offset: Int, s_stride: Int, n_offset: Int, n_stride: Int, blocksize: Int)? {
        if self.calculatedSize == 0{
            self.calculatedSize += self.blocksize
            return (0, self.b_stride, 0, self.s_stride, 0, self.n_stride, self.blocksize)
        }
        
        if self.calculatedSize < self.size{
            for i in stride(from: self._n_strides.count - 1, through: 0, by: -1){ //search n_strides corresponds to (blocksize / n_stride )
                if self._n_stridedsize == self.calculatedSize{
                    
                }
            }
            
            //if above
            
            self.calculatedSize += self.blocksize
            
        }
        else{ //finished
            return nil
        }
    }
}
