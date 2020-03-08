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
    
    let newdata = MfData(dataptr: dstptr, storedSize: mfarray.storedSize, shapeptr: shapeptr, mftype: mfarray.mftype, ndim: mfarray.ndim, mforder: mfarray.mforder, stridesptr: stridesptr)
    return MfArray(mfdata: newdata)
}

//binary operation
internal typealias vDSP_biop_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func biop_unsafePtrT<T>(_ lptr: UnsafePointer<T>, _ lstride: Int, _ rptr: UnsafePointer<T>, _ rstride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_func<T>){
    vDSP_func(lptr, vDSP_Stride(lstride), rptr, vDSP_Stride(rstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_by_vDSP<T: Numeric>(_ bigger_mfarray: MfArray, _ smaller_mfarray: MfArray, vDSP_func: vDSP_biop_func<T>) -> MfArray{
    let dstptr = create_unsafeMPtrT(type: T.self, count: bigger_mfarray.size)
    
    bigger_mfarray.dataptr.bindMemory(to: T.self).withUnsafeBufferPointer{
               lptr in
        smaller_mfarray.dataptr.bindMemory(to: T.self).withUnsafeBufferPointer{
                   rptr in
            for vDSPPrams in OptOffsetParams(bigger_mfarray: bigger_mfarray, smaller_mfarray: smaller_mfarray){
                biop_unsafePtrT(lptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptr + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
            }
        }
        //print(vDSPPrams.l_stride, vDSPPrams.l_offset, vDSPPrams.r_stride, vDSPPrams.r_offset, vDSPPrams.blocksize)
    }
    
    let shapeptr = create_unsafeMPtrT(type: Int.self, count: bigger_mfarray.ndim)
    shapeptr.assign(from: bigger_mfarray.mfdata._shape, count: bigger_mfarray.ndim)
    
    let stridesptr = create_unsafeMPtrT(type: Int.self, count: bigger_mfarray.ndim)
    stridesptr.assign(from: bigger_mfarray.mfdata._strides, count: bigger_mfarray.ndim)
    
    let newdata = MfData(dataptr: dstptr, storedSize: bigger_mfarray.storedSize, shapeptr: shapeptr, mftype: bigger_mfarray.mftype, ndim: bigger_mfarray.ndim, mforder: .Row, stridesptr: stridesptr)
    return MfArray(mfdata: newdata)
}
