//
//  cblas.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/07.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

//convert order
internal typealias cblas_convorder_func<T> = (Int32, UnsafePointer<T>, Int32, UnsafeMutablePointer<T>, Int32) -> Void

internal func convorder<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ cblas_func: cblas_convorder_func<T>){
    cblas_func(Int32(size), srcptr, Int32(srcStride), dstptr, Int32(dstStride))
}

internal func convorder_by_cblas<T: Numeric>(_ mfarray: MfArray, dsttmpMfarray: MfArray, cblas_func: cblas_convorder_func<T>) -> MfArray{
    
    let dstptr = create_unsafeMPtrT(type: T.self, count: mfarray.size)
    
    mfarray.dataptr.bindMemory(to: T.self).withUnsafeBufferPointer{
               lptr in
        for cblasPrams in OptOffsetParams(bigger_mfarray: dsttmpMfarray, smaller_mfarray: mfarray){
            convorder(cblasPrams.blocksize, lptr.baseAddress! + cblasPrams.s_offset, cblasPrams.s_stride, dstptr + cblasPrams.b_offset, cblasPrams.b_stride, cblas_func)
        }
    }
    
    dsttmpMfarray.mfdata._data.moveInitializeMemory(as: T.self, from: dstptr, count: mfarray.size)
    return dsttmpMfarray
}
