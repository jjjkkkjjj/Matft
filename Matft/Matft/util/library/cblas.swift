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

internal func copy_unsafeptrT<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ cblas_func: cblas_convorder_func<T>){
    cblas_func(Int32(size), srcptr, Int32(srcStride), dstptr, Int32(dstStride))
}

internal func copy_by_cblas<T: Numeric>(_ mfarray: MfArray, dsttmpMfarray: MfArray, cblas_func: cblas_convorder_func<T>) -> MfArray{
    
    
    dsttmpMfarray.withDataUnsafeMBPtrT(datatype: T.self){
        dstptr in
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            srcptr in
            /*
            var b = [5,6,7,2.0]
            var c = [0,0,0,0.0]
            
            //vDSP_vaddD(&a, vDSP_Stride(1), &b + 3, vDSP_Stride(-1), &c, vDSP_Stride(1), vDSP_Length(4))
            let add = UnsafePointer(b)
            cblas_dcopy(Int32(4), add + 3, Int32(-1), &c, Int32(1))

            print(c)
            //->[6.9532560551673e-310, 6.9532560552309e-310, 1.2516202258872396e-308, 2.0]
            //Cannot copy!!!!
             
            cblas_dcopy(Int32(4), &b, Int32(-1), &c, Int32(1))
            print(c)
            //[2.0, 7.0, 6.0, 5.0]
            //Copied!!!!!!!!!
             
             var b = [5,6,7,2.0]
             var c = [0,0.0]
             
             cblas_dcopy(Int32(c.count), &b + 1, Int32(-1), &c, Int32(1))
             print(c)
             //[7.0, 6.0]!!!!!
            */
            //print(dsttmpMfarray.strides, mfarray.strides)
            for cblasPrams in OptOffsetParams(bigger_mfarray: dsttmpMfarray, smaller_mfarray: mfarray){
                //if negative offset, move proper position
                let srcptr = cblasPrams.s_stride >= 0 ? srcptr.baseAddress! + cblasPrams.s_offset : srcptr.baseAddress! - mfarray.offsetIndex + cblasPrams.s_offset
                let dstptr = cblasPrams.b_stride >= 0 ? dstptr.baseAddress! + cblasPrams.b_offset : dstptr.baseAddress! - dsttmpMfarray.offsetIndex + cblasPrams.b_offset
                copy_unsafeptrT(cblasPrams.blocksize, srcptr, cblasPrams.s_stride, dstptr, cblasPrams.b_stride, cblas_func)
                //print(cblasPrams.blocksize, cblasPrams.b_offset, cblasPrams.b_stride, cblasPrams.s_offset, cblasPrams.s_stride)
            }
        }
    }
    
    return dsttmpMfarray
}



//matrix multiplication
internal typealias cblas_matmul_func<T> = (CBLAS_ORDER, CBLAS_TRANSPOSE, CBLAS_TRANSPOSE, Int32, Int32, Int32, T, UnsafePointer<T>, Int32, UnsafePointer<T>, Int32, T, UnsafeMutablePointer<T>, Int32) -> Void

internal func matmul_by_cblas<T>(_ mforder: MfOrder, _ lrow: Int, _ lcol: Int, _ lptr: UnsafePointer<T>, _ rrow: Int, _ rcol: Int, _ rptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ one: T, _ zero: T, _ cblas_func: cblas_matmul_func<T>){
    let M = Int32(lrow)
    let N = Int32(rcol)
    let K = Int32(lcol)
    
    switch mforder {
    case .Column:
        let order = CblasColMajor
        let lda = Int32(lrow)
        let ldb = Int32(rrow)
        let ldc = Int32(lrow)
        cblas_func(order, CblasNoTrans, CblasNoTrans, M, N, K, one, lptr, lda, rptr, ldb, zero, dstptr, ldc)
    case .Row:
        let order = CblasRowMajor
        let lda = Int32(lcol)
        let ldb = Int32(rcol)
        let ldc = Int32(rcol)
        cblas_func(order, CblasNoTrans, CblasNoTrans, M, N, K, one, lptr, lda, rptr, ldb, zero, dstptr, ldc)
    }
}

