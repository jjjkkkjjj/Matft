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
    if smaller_mfarray.size == bigger_storedSize{ //transposed
        new = Matft.mfarray.nums_like(num: 0, type: T.self, mfarray: bigger_mfarray)
    }
    else{ // size > bigger stored >= smaller stored
        new = Matft.mfarray.nums(num: 0, type: T.self, shape: bigger_mfarray.shape)
    }
    
    let vdsp_args = vDSP_Args(b_mfarray: bigger_mfarray, b_storedSize: bigger_storedSize, s_mfarray: smaller_mfarray, s_storedSize: smaller_storedSize, n_mfarray: new)
    var start = Date()
    /*
    bigger_mfarray.data.withMemoryRebound(to: Double.self, capacity: bigger_storedSize, { bptr in
        smaller_mfarray.data.withMemoryRebound(to: Double.self, capacity: smaller_storedSize, { sptr in
            new.data.withMemoryRebound(to: Double.self, capacity: new.size, { nptr in
                for args in vdsp_args{
                    //print((new.data + args.n_offset + args.n_stride * (args.blocksize - 1)).pointee)
     
                    //print(args)
                    vDSP_func(bptr + args.b_offset, vDSP_Stride(args.b_stride),
                              sptr + args.s_offset, vDSP_Stride(args.s_stride),
                              nptr + args.n_offset, vDSP_Stride(args.n_stride), vDSP_Length(args.blocksize))
                }
            })
        })
    })
    */
    
    for args in vdsp_args{
        //print((new.data + args.n_offset + args.n_stride * (args.blocksize - 1)).pointee)
        
        //print(args)
        vDSP_func(bigger_mfarray.data + args.b_offset, vDSP_Stride(args.b_stride),
                  smaller_mfarray.data + args.s_offset, vDSP_Stride(args.s_stride),
                  new.data + args.n_offset, vDSP_Stride(args.n_stride), vDSP_Length(args.blocksize))
    }
    var elapsed = Date().timeIntervalSince(start)
    print(elapsed)
    return new
}

fileprivate struct vDSP_Args<T: MfNumeric>: Sequence, IteratorProtocol{
    typealias Element = (b_offset: Int, b_stride: Int, s_offset: Int, s_stride: Int, n_offset: Int, n_stride: Int, blocksize: Int)
    
    public var blocksize: Int
    private var size: Int
    private var calculatedSize: Int
    private var iterNum: Int = 0
    public var b_stride: Int
    public var s_stride: Int
    public var n_stride: Int
    
    // removed strides by index which maximizes blocksize
    private var _b_strides: [Int]
    private var _s_strides: [Int]
    private var _n_strides: [Int]
    // indices for offset
    private var _indices: [[Int]]
    
    private var _n_stridedsize: Int{ // step size every iteration
        return self.blocksize / self.n_stride
    }
    
    init(b_mfarray: MfArray<T>, b_storedSize: Int, s_mfarray: MfArray<T>, s_storedSize: Int, n_mfarray: MfArray<T>) {
        let ndim = n_mfarray.ndim
        /*
        var blocksize_candidates: [Int] = [] // select maximum one
        for i in 0..<ndim{
            let blocks = [b_mfarray.strides[i] != 0 ? b_storedSize / b_mfarray.strides[i] : n_mfarray.size / b_storedSize,//n_mfarray.size, //b_storedSize,
                s_mfarray.strides[i] != 0 ? s_storedSize / s_mfarray.strides[i] : n_mfarray.size / s_storedSize,//n_mfarray.size, //s_storedSize,
                n_mfarray.strides[i] != 0 ? n_mfarray.size / n_mfarray.strides[i] : 1] //bigger, smaller, new
            blocksize_candidates.append(blocks.min()!)
        }*/
        
        self.size = n_mfarray.size
        
        var bst = b_mfarray.strides
        var sst = s_mfarray.strides
        var sh = n_mfarray.shape
        let a = _get_blocksize(b_strides: &bst, b_stroredSize: b_storedSize, s_strides: &sst, s_storedSize: s_storedSize, shape: &sh)
        //print(bst, sst)
        //print(a)
        //self.blocksize = blocksize_candidates.max()!
        //let selectedIndex = blocksize_candidates.firstIndex(of: self.blocksize)!
        self.blocksize = a.blocksize
        let selectedIndex = a.index
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
        
        var _shape = n_mfarray.shape
        _shape.remove(at: selectedIndex)
        self._indices = _get_indices(_shape)

        self.calculatedSize = 0
        
    }
    
    mutating func next() -> (b_offset: Int, b_stride: Int, s_offset: Int, s_stride: Int, n_offset: Int, n_stride: Int, blocksize: Int)? {
        if self.calculatedSize < self.size{
        //if self.iterNum < self._indices.count{
            
            let offsets = self._get_offset()
            
            self.calculatedSize += self.blocksize
            //self.iterNum += 1

            return (offsets.b_offset, self.b_stride, offsets.s_offset, self.s_stride, offsets.n_offset, self.n_stride, self.blocksize)
        }
        else{ //finished
            return nil
        }
    }
    
    private func _get_offset() -> (b_offset: Int, s_offset: Int, n_offset: Int){
        let i = self.calculatedSize / self.blocksize //% self._indices.count
        let indices = self._indices[i]
        //let indices = self._indices[self.iterNum]
        //this line causes slow calculation time....
        return (_inner_product(self._b_strides, indices), _inner_product(self._s_strides, indices), _inner_product(self._n_strides, indices))
        
    }
}

fileprivate func _get_blocksize(b_strides: inout [Int], b_stroredSize: Int, s_strides: inout [Int], s_storedSize: Int, shape: inout [Int]) -> (blocksize: Int, index: Int){
    let ndim = shape.count
    
    var blocksizes_mul = shape // maximum blocksize for each axis
    var blocksizes_div = shape
    
    var axis = 0
    blocksizes_div[axis] = shape[axis]
    while axis < ndim - 1 {
       // var axis_mul = axis
        var axis_div = axis
        var blocksize_div = shape[axis]
        
        _check_recursive_nextDiv(axis: &axis_div, blocksize: &blocksize_div, b_strides: &b_strides, s_strides: &s_strides, shape: &shape)
        
        var tmp = 1
        for ax in stride(from: axis_div, through: axis, by: -1){
            tmp *= shape[ax]
            blocksizes_div[ax] = tmp
        }
        
        axis += (axis_div - axis + 1)
    }
    
    axis = ndim - 1
    blocksizes_mul[axis] = shape[axis]
    while axis >= 0 {
        var axis_mul = axis
        var blocksize_mul = shape[axis]
        
        _check_recursive_prevDiv(axis: &axis_mul, blocksize: &blocksize_mul, b_strides: &b_strides, s_strides: &s_strides, shape: &shape)
        
        var tmp = 1
        for ax in stride(from: axis_mul, through: axis, by: 1){
            tmp *= shape[ax]
            blocksizes_mul[ax] = tmp
        }
        
        axis += (axis_mul - axis - 1)
    }
    
    //print(blocksizes_mul, blocksizes_div)
    let ret_mul = blocksizes_mul.max()!
    let ret_div = blocksizes_div.max()!
    
    if ret_mul > ret_div{
        return (ret_mul, blocksizes_mul.firstIndex(of: ret_mul)!)
    }
    else{
        return (ret_div, blocksizes_div.firstIndex(of: ret_div)!)
    }
}

fileprivate func _check_recursive_nextDiv(axis: inout Int, blocksize: inout Int, b_strides: inout [Int], s_strides: inout [Int], shape: inout [Int]){
    if axis == shape.count - 1{
        return
    }
    
    let b_ret = (b_strides[axis] == b_strides[axis + 1] / shape[axis + 1])
    let s_ret = (s_strides[axis] == s_strides[axis + 1] / shape[axis + 1])
    
    if b_ret && s_ret{
        axis += 1
        blocksize *= shape[axis]
        _check_recursive_nextDiv(axis: &axis, blocksize: &blocksize, b_strides: &b_strides, s_strides: &s_strides, shape: &shape)
    }
    else{
        return
    }
}

fileprivate func _check_recursive_prevDiv(axis: inout Int, blocksize: inout Int, b_strides: inout [Int], s_strides: inout [Int], shape: inout [Int]){
    if axis == 0{
        return
    }
    
    let b_ret = (b_strides[axis - 1] == b_strides[axis] * shape[axis])
    let s_ret = (s_strides[axis - 1] == s_strides[axis] * shape[axis])
    
    if b_ret && s_ret{
        axis += -1
        blocksize *= shape[axis]
        _check_recursive_prevDiv(axis: &axis, blocksize: &blocksize, b_strides: &b_strides, s_strides: &s_strides, shape: &shape)
    }
    else{
        return
    }
}
