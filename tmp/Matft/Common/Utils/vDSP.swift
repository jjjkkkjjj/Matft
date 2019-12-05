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
    
    if smaller_storedSize == bigger_storedSize{ //squared mfarray
        let blocksize = smaller_mfarray.shape[0]
        let bigger_stride = vDSP_Stride(bigger_mfarray.strides.min()!)
        let smaller_stride = vDSP_Stride(smaller_mfarray.strides.max()!)
        
        let new = Matft.mfarray.nums(num: 0, type: T.self, shape: bigger_mfarray.shape)

        for i in 0..<blocksize{
            //let bigger_offset = (i * blocksize >= blocksize) ? 0 : i * blocksize
            vDSP_func(bigger_mfarray.data + i * blocksize, bigger_stride, smaller_mfarray.data + i, smaller_stride, new.data + blocksize * i, vDSP_Stride(1), vDSP_Length(blocksize))
        }
        return new
    }
    
    if smaller_storedSize == 1{ //mfarray + number
        let new = Matft.mfarray.nums_like(num: 0, type: T.self, mfarray: bigger_mfarray)
        vDSP_func(bigger_mfarray.data, vDSP_Stride(1), smaller_mfarray.data, vDSP_Stride(0), new.data, vDSP_Stride(1), vDSP_Length(bigger_storedSize))
        return new
    }
    else{
        for (b_stride, s_stride) in zip(bigger_mfarray.strides, smaller_mfarray.strides){
            
        }
        
        let new = Matft.mfarray.nums_like(num: 0, type: T.self, mfarray: bigger_mfarray)
        
        return new
    }
    
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
fileprivate func _get_offset_from_different_stride<T>(bigger_mfarray: MfArray<T>, bigger_storedsize: Int, smaller_mfarray: MfArray<T>, smaller_storedsize: Int) -> (b_offsets: [Int], b_stride: Int, s_offsets: [Int], s_stride: Int, blocksize: Int){
    
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
        bigger_offsets.append(<#T##newElement: Int##Int#>)
    }
    
    return (bigger_offsets, bigger_mfarray.strides[minIndex], smaller_offsets, smaller_mfarray.strides[minIndex], blocksize)
}

fileprivate func _check_lrstride(left_stride: [Int], right_stride: [Int]){
    

}
