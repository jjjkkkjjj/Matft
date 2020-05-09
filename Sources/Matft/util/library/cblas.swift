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

internal func copy_mfarray<T: MfStorable>(_ mfarray: MfArray, dsttmpMfarray: MfArray, cblas_func: cblas_convorder_func<T>) -> MfArray{
    
    
    dsttmpMfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned dsttmpMfarray] (dstptr) in
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            [unowned mfarray] (srcptr) in
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
                let srcptr = cblasPrams.s_stride >= 0 ? srcptr.baseAddress! + cblasPrams.s_offset : srcptr.baseAddress! + (cblasPrams.blocksize - 1) * cblasPrams.s_stride + cblasPrams.s_offset
                let dstptr = cblasPrams.b_stride >= 0 ? dstptr.baseAddress! + cblasPrams.b_offset : dstptr.baseAddress! + (cblasPrams.blocksize - 1) * cblasPrams.b_stride + cblasPrams.b_offset
                copy_unsafeptrT(cblasPrams.blocksize, srcptr, cblasPrams.s_stride, dstptr, cblasPrams.b_stride, cblas_func)
                //print(cblasPrams.blocksize, cblasPrams.b_offset, cblasPrams.b_stride, cblasPrams.s_offset, cblasPrams.s_stride)
            }
        }
    }
    
    return dsttmpMfarray
}

internal func copy_by_cblas<T: MfStorable>(_ mfarray: MfArray, mforder: MfOrder, cblas_func: cblas_convorder_func<T>) -> MfArray{
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.size){_ in}//dummy
    let newstructure = withDummyShapeStridesMBPtr(mfarray.ndim){
            shapeptr, stridesptr in
            mfarray.withShapeUnsafeMBPtr{
            [unowned mfarray] (orig_shapeptr) in
                let newstridesptr = shape2strides(orig_shapeptr, mforder: mforder)
                
                //copy
                shapeptr.baseAddress!.assign(from: orig_shapeptr.baseAddress!, count: mfarray.ndim)
                
                //move
                stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: mfarray.ndim)
                //free
                newstridesptr.deallocate()
            }
        }

    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
    return copy_mfarray(mfarray, dsttmpMfarray: ret, cblas_func: cblas_func)
}

//matrix multiplication
internal typealias cblas_matmul_func<T> = (CBLAS_ORDER, CBLAS_TRANSPOSE, CBLAS_TRANSPOSE, Int32, Int32, Int32, T, UnsafePointer<T>, Int32, UnsafePointer<T>, Int32, T, UnsafeMutablePointer<T>, Int32) -> Void

fileprivate func _run_matmul<T: MfStorable>(_ mforder: MfOrder, _ lrow: Int, _ lcol: Int, _ lptr: UnsafePointer<T>, _ rrow: Int, _ rcol: Int, _ rptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ cblas_func: cblas_matmul_func<T>){
    let M = Int32(lrow)
    let N = Int32(rcol)
    let K = Int32(lcol)
    
    switch mforder {
    case .Column:
        let order = CblasColMajor
        let lda = Int32(lrow)
        let ldb = Int32(rrow)
        let ldc = Int32(lrow)
        cblas_func(order, CblasNoTrans, CblasNoTrans, M, N, K, T.num(1), lptr, lda, rptr, ldb, T.zero, dstptr, ldc)
    case .Row:
        let order = CblasRowMajor
        let lda = Int32(lcol)
        let ldb = Int32(rcol)
        let ldc = Int32(rcol)
        cblas_func(order, CblasNoTrans, CblasNoTrans, M, N, K, T.num(1), lptr, lda, rptr, ldb, T.zero, dstptr, ldc)
    }
}

internal func matmul_by_cblas<T: MfStorable>(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray, cblas_func: cblas_matmul_func<T>) -> MfArray{
    let lshape = lmfarray.shape
    let rshape = rmfarray.shape
    var retshape = lmfarray.shape
    let retndim = retshape.count
    retshape[retndim - 1] = rshape[retndim - 1]
    
    // order
    // must be row major
    let retorder = _matmul_convorder(&lmfarray, &rmfarray)
    
    let newmfstructure = withDummyShapeStridesMBPtr(retndim){
        shapeptr, stridesptr in
        //move
        retshape.withUnsafeMutableBufferPointer{
            shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
        }
        //move
        let newstrides = shape2strides(shapeptr, mforder: retorder)
        stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: retndim)
        //free
        newstrides.deallocate()
    }
    

    let matNum = lshape[retndim - 2] * rshape[retndim - 1]
    let l_matNum = lshape[retndim - 2] * lshape[retndim - 1]
    let r_matNum = rshape[retndim - 2] * rshape[retndim - 1]
    let iterNum = newmfstructure._size / matNum
    
    let newmfdata = withDummyDataMRPtr(lmfarray.mftype, storedSize: newmfstructure._size){
        dstptr in
        var dstptrT = dstptr.bindMemory(to: T.self, capacity: newmfstructure._size)
        lmfarray.withDataUnsafeMBPtrT(datatype: T.self){
            lptr in
            var lptr = lptr.baseAddress!
            rmfarray.withDataUnsafeMBPtrT(datatype: T.self){
                rptr in
                var rptr = rptr.baseAddress!
                
                for _ in 0..<iterNum{
                    _run_matmul(retorder, lshape[retndim - 2], lshape[retndim - 1], lptr, rshape[retndim - 2], rshape[retndim - 1], rptr, dstptrT, cblas_func)
                    
                    lptr += l_matNum
                    rptr += r_matNum
                    dstptrT += matNum
                }
            }
        }
    }
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

fileprivate func _matmul_convorder(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray) -> MfOrder{
    // order
    /*
    // must be close to either row or column major
    var retorder = MfOrder.Row
    if !(lmfarray.mfflags.column_contiguous && rmfarray.mfflags.column_contiguous) || lmfarray.mfflags.row_contiguous && rmfarray.mfflags.row_contiguous{//convert either row or column major
        if lmfarray.mfflags.column_contiguous{
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Column)
            retorder = .Column
        }
        else if lmfarray.mfflags.row_contiguous{
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Row)
            retorder = .Row
        }
        else if rmfarray.mfflags.column_contiguous{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Column)
            retorder = .Column
        }
        else if rmfarray.mfflags.row_contiguous{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Row)
            retorder = .Row
        }
        else{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Row)
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Row)
            retorder = .Row
        }
    }
    else{
        retorder = lmfarray.mfflags.row_contiguous ? .Row : .Column
    }*/
    //must be row major
    let retorder = MfOrder.Row
    if !(lmfarray.mfflags.row_contiguous && rmfarray.mfflags.row_contiguous){//convert row major
        if !rmfarray.mfflags.row_contiguous{
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Row)
        }
        if !lmfarray.mfflags.row_contiguous{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Row)
        }
    }
    return retorder
}
