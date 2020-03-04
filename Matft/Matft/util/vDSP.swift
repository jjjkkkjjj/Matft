//
//  vDSP.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

//converter
internal typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

internal func unsafePtrT2UnsafeMPtrU<T, U>(_ srcptr: UnsafePointer<T>,  _ dstptr: UnsafeMutablePointer<U>, _ vDSP_func: vDSP_convert_func<T, U>, _ count: Int){
    vDSP_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}
internal func preop_by_vDSP<T: Numeric>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    let dstptrT = create_unsafeMPtrT(type: T.self, count: mfarray.storedSize)
    let srcptrT = mfarray.dataptr.bindMemory(to: T.self)
    
    vDSP_func(srcptrT.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
    
    let dstptr = UnsafeMutableRawPointer(dstptrT)
    
    let shapeptr = create_unsafeMPtrT(type: Int.self, count: mfarray.ndim)
    shapeptr.assign(from: mfarray.mfdata._shape, count: mfarray.ndim)
    
    let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfarray.ndim)
    stridesptr.assign(from: mfarray.mfdata._strides, count: mfarray.ndim)
    
    let newdata = MfData(dataptr: dstptr, storedSize: mfarray.storedSize, shapeptr: shapeptr, mftype: mfarray.mftype, ndim: mfarray.ndim, stridesptr: stridesptr)
    return MfArray(mfdata: newdata)
}


//binary operation
internal typealias vDSP_biop_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func biop_unsafePtrT<T>(_ lptr: UnsafePointer<T>, _ lstride: Int, _ rptr: UnsafePointer<T>, _ rstride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_func<T>){
    vDSP_func(lptr, vDSP_Stride(lstride), rptr, vDSP_Stride(rstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_by_vDSP<T: Numeric>(_ bigger_mfarray: MfArray, _ smaller_mfarray: MfArray, vDSP_func: vDSP_biop_func<T>) -> MfArray{
    let dstptr = create_unsafeMPtrT(type: T.self, count: bigger_mfarray.size)
    
    print(bigger_mfarray)
    print(smaller_mfarray)
    
    bigger_mfarray.dataptr.bindMemory(to: T.self).withUnsafeBufferPointer{
               lptr in
        smaller_mfarray.dataptr.bindMemory(to: T.self).withUnsafeBufferPointer{
                   rptr in
            for vDSPPrams in vDSPOptParams(bigger_mfarray: bigger_mfarray, smaller_mfarray: smaller_mfarray){
                biop_unsafePtrT(lptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptr + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
            }
        }
        //print(vDSPPrams.l_stride, vDSPPrams.l_offset, vDSPPrams.r_stride, vDSPPrams.r_offset, vDSPPrams.blocksize)
    }
    
    let shapeptr = create_unsafeMPtrT(type: Int.self, count: bigger_mfarray.ndim)
    shapeptr.assign(from: bigger_mfarray.mfdata._shape, count: bigger_mfarray.ndim)
    
    let stridesptr = create_unsafeMPtrT(type: Int.self, count: bigger_mfarray.ndim)
    stridesptr.assign(from: bigger_mfarray.mfdata._strides, count: bigger_mfarray.ndim)
    
    let newdata = MfData(dataptr: dstptr, storedSize: bigger_mfarray.storedSize, shapeptr: shapeptr, mftype: bigger_mfarray.mftype, ndim: bigger_mfarray.ndim, stridesptr: stridesptr)
    return MfArray(mfdata: newdata)
}

internal struct vDSPOptParams: Sequence{
    let bigger_mfarray: MfArray
    let smaller_mfarray: MfArray
    
    public init(bigger_mfarray: MfArray, smaller_mfarray: MfArray){
        self.bigger_mfarray = bigger_mfarray
        self.smaller_mfarray = smaller_mfarray
    }
    
    func makeIterator() -> vDSPOptParamIterator {
        return vDSPOptParamIterator(optParams: self)
    }
}

internal struct vDSPOptParamIterator: IteratorProtocol{
    let stride: (b: Int, s: Int)
    let blocksize: Int
    let itershapes: [Int]
    let iter_strides: (b: [Int], s: [Int])
    
    var upaxis: Int //indicates which axis will be counted up
    var indicesOfAxes: [Int]
    var offset: (b: Int, s: Int)?
    
    public init(optParams: vDSPOptParams){
        let (axis, blocksize, iterAxes) = _optStrides(shapeptr: optParams.bigger_mfarray.shapeptr, l_strideptr: optParams.bigger_mfarray.stridesptr, r_strideptr: optParams.smaller_mfarray.stridesptr)
        
        self.stride.b = optParams.bigger_mfarray.stridesptr[axis]
        self.stride.s = optParams.smaller_mfarray.stridesptr[axis]
        self.blocksize = blocksize
        
        self.itershapes = iterAxes.map{ optParams.bigger_mfarray.shapeptr[$0] }
        self.iter_strides.b = iterAxes.map{ optParams.bigger_mfarray.stridesptr[$0] }
        self.iter_strides.s = iterAxes.map{ optParams.smaller_mfarray.stridesptr[$0] }
        
        
        if self.itershapes.isEmpty{
            self.upaxis = -1
            self.indicesOfAxes = []
        }
        else{
            self.upaxis = 0
            self.indicesOfAxes = Array(repeating: 0, count: self.itershapes.count)
        }
        self.offset = (0, 0)
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
        var iterAxes: [Int] = []
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
                
                //re-search
                n = 0
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
