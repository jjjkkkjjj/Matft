//
//  vDSP.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

internal func unsafePtrT2UnsafeMPtrU<T, U>(_ srcptr: UnsafePointer<T>,  _ dstptr: UnsafeMutablePointer<U>, _ vDSP_func: vDSP_convert_func<T, U>, _ count: Int){
    vDSP_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}

internal typealias vDSP_biop_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func biop_unsafePtrT<T>(_ lptr: UnsafePointer<T>, _ lstride: Int, _ rptr: UnsafePointer<T>, _ rstride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_func<T>){
    vDSP_func(lptr, vDSP_Stride(lstride), rptr, vDSP_Stride(rstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_by_vDSP<T>(l_mfarray: MfArray, r_mfarray: MfArray, vDSP_func: vDSP_biop_func<T>) -> MfArray{
    let dstptr = create_unsafeMRBPtr(type: T.self, count: l_mfarray.size)
    
    for vDSPPrams in vDSPOptParams(l_mfarray: l_mfarray, r_mfarray: r_mfarray){
        l_mfarray.dataptr.bindMemory(to: T.self).withUnsafeBufferPointer{
            lptr in
            r_mfarray.dataptr.bindMemory(to: T.self).withUnsafeBufferPointer{
                rptr in
                var p = dstptr.bindMemory(to: T.self)
                    p.withUnsafeMutableBufferPointer{
                    
                    biop_unsafePtrT(lptr.baseAddress! + vDSPPrams.l_offset, vDSPPrams.l_stride, rptr.baseAddress! + vDSPPrams.r_offset, vDSPPrams.r_stride, $0.baseAddress! + vDSPPrams.l_offset, vDSPPrams.l_stride, vDSPPrams.blocksize, vDSP_func)
                }
                
            }
        }
    }
    
    let shapeptr = create_unsafeMBPtrT(type: Int.self, count: l_mfarray.ndim)
    
    let stridesptr = create_unsafeMBPtrT(type: Int.self, count: l_mfarray.ndim)
    for axis in 0..<l_mfarray.ndim{
        shapeptr[axis] = l_mfarray.shapeptr[axis]
        stridesptr[axis] = l_mfarray.stridesptr[axis]
    }
    
    let newdata = MfData(dataptr: dstptr, storedSize: l_mfarray.storedSize, shapeptr: l_mfarray.shapeptr, mftype: l_mfarray.mftype, stridesptr: l_mfarray.stridesptr)
    return MfArray(newdata)
}

internal struct vDSPOptParams: Sequence{
    let l_mfarray: MfArray
    let r_mfarray: MfArray
    
    public init(l_mfarray: MfArray, r_mfarray: MfArray){
        self.l_mfarray = l_mfarray
        self.r_mfarray = r_mfarray
    }
    
    func makeIterator() -> vDSPOptParamIterator {
        return vDSPOptParamIterator(optParams: self)
    }
}

internal struct vDSPOptParamIterator: IteratorProtocol{
    let optParams: vDSPOptParams
    let axis: Int
    let blocksize: Int
    let itershapes: [Int]
    let iterL_strides: [Int]
    let iterR_strides: [Int]
    var shapeIter: CombinationIterator
    
    public init(optParams: vDSPOptParams){
        let (axis, blocksize, iterAxes) = _optStrides(shapeptr: optParams.l_mfarray.shapeptr, l_strideptr: optParams.l_mfarray.stridesptr, r_strideptr: optParams.r_mfarray.stridesptr)
        self.axis = axis
        self.blocksize = blocksize
        self.optParams = optParams
        
        self.itershapes = iterAxes.map{ optParams.l_mfarray.shapeptr[$0] }
        self.iterL_strides = iterAxes.map{ optParams.l_mfarray.stridesptr[$0] }
        self.iterR_strides = iterAxes.map{ optParams.l_mfarray.stridesptr[$0] }
        
        var shapecombo = itershapes.flatMap{
            [Array(0..<$0)]
        } as [Any]
        self.shapeIter = Combination(&shapecombo).makeIterator()
    }
    
    mutating func next() -> (l_offset: Int, l_stride: Int, r_offset: Int, r_stride: Int, blocksize: Int)? {
        guard let indices = self.shapeIter.next() else{
            return nil
        }
        
        var l_offset = 0, r_offset = 0
        for axis in 0..<indices.count{
            let index = indices[axis]
            l_offset += self.iterL_strides[axis] * index
            r_offset += self.iterR_strides[axis] * index
        }
        
        return (l_offset, self.optParams.l_mfarray.stridesptr[self.axis], r_offset, self.optParams.r_mfarray.stridesptr[self.axis], self.blocksize)
    }
}

/*
 * search maximum and common contiguous stride between two mfarray
 * @return
 *      axis        : index of strides given for vDSP
 *      blocksize   : maximum size calculated once by vDSP
 *      iterAxes    : indices of non-contiguous strides
 */
fileprivate func _optStrides(shapeptr: UnsafeMutableBufferPointer<Int>, l_strideptr: UnsafeMutableBufferPointer<Int>, r_strideptr: UnsafeMutableBufferPointer<Int>) -> (axis: Int, blocksize: Int, iterAxes: [Int]){
    var optaxis = 0, optBlockSize = -1
    
    let ndim = shapeptr.count
    var optiterAxes: [Int] = Array(0..<ndim)
    
    // search optimimal strides
    for axis in 0..<ndim{
        var l_strides = Array(l_strideptr) as [Int?]
        var r_strides = Array(r_strideptr) as [Int?]
        l_strides[axis] = nil//flag for skip
        r_strides[axis] = nil
        
        var n = 0
        var blockSize = shapeptr[axis]
        var iterAxes: [Int] = Array(0..<ndim)
        iterAxes.removeFirst(axis)
        while n < ndim{
            guard let lst = l_strides[n], let rst = r_strides[n] else {//skip
                n += 1
                continue
            }
            
            if (lst == l_strideptr[axis] * shapeptr[axis]) && (rst == r_strideptr[axis] * shapeptr[axis]){//
                l_strides[n] = nil//set flag as already checked
                r_strides[n] = nil
                
                //update blocksize
                blockSize *= shapeptr[n]
                
                //set axes to search
                iterAxes.removeFirst(n)
                
                //re-search
                n = 0
            }
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
