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
            for cblasPrams in OptOffsetParams_mfarray(bigger_mfarray: dsttmpMfarray, smaller_mfarray: mfarray){
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
    let newdata = MfData(size: mfarray.size, mftype: mfarray.mftype)
    let newstructure = MfStructure(shape: mfarray.shape, mforder: mforder)

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
    
    let newstructure = MfStructure(shape: retshape, mforder: retorder)
    let newsize = shape2size(&retshape)
    
    let matNum = lshape[retndim - 2] * rshape[retndim - 1]
    let l_matNum = lshape[retndim - 2] * lshape[retndim - 1]
    let r_matNum = rshape[retndim - 2] * rshape[retndim - 1]
    let iterNum = newsize / matNum
    
    let newdata = MfData(size: newsize, mftype: lmfarray.mftype)
    var dstptrT = newdata.data.bindMemory(to: T.self, capacity: newsize)
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
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

fileprivate func _matmul_convorder(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray) -> MfOrder{
    // order
    /*
    // must be close to either row or column major
    var retorder = MfOrder.Row
    if !(lmfarray.mfstructure.column_contiguous && rmfarray.mfstructure.column_contiguous) || lmfarray.mfstructure.row_contiguous && rmfarray.mfstructure.row_contiguous{//convert either row or column major
        if lmfarray.mfstructure.column_contiguous{
            rmfarray = Matft.conv_order(rmfarray, mforder: .Column)
            retorder = .Column
        }
        else if lmfarray.mfstructure.row_contiguous{
            rmfarray = Matft.conv_order(rmfarray, mforder: .Row)
            retorder = .Row
        }
        else if rmfarray.mfstructure.column_contiguous{
            lmfarray = Matft.conv_order(lmfarray, mforder: .Column)
            retorder = .Column
        }
        else if rmfarray.mfstructure.row_contiguous{
            lmfarray = Matft.conv_order(lmfarray, mforder: .Row)
            retorder = .Row
        }
        else{
            lmfarray = Matft.conv_order(lmfarray, mforder: .Row)
            rmfarray = Matft.conv_order(rmfarray, mforder: .Row)
            retorder = .Row
        }
    }
    else{
        retorder = lmfarray.mfstructure.row_contiguous ? .Row : .Column
    }*/
    //must be row major
    let retorder = MfOrder.Row
    if !(lmfarray.mfstructure.row_contiguous && rmfarray.mfstructure.row_contiguous){//convert row major
        if !rmfarray.mfstructure.row_contiguous{
            rmfarray = Matft.conv_order(rmfarray, mforder: .Row)
        }
        if !lmfarray.mfstructure.row_contiguous{
            lmfarray = Matft.conv_order(lmfarray, mforder: .Row)
        }
    }
    return retorder
}


internal func fancyndgetcol_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ cblas_func: cblas_convorder_func<T>) -> MfArray{
    assert(indices.mftype == .Int, "must be int")
    assert(mfarray.ndim > 1, "must be more than 2d")
    // fancy indexing
    // note that if not assignment, returned copy value not view.
    /*
     >>> a = np.arange(9).reshape(3,3)
     >>> a
     array([[0, 1, 2],
            [3, 4, 5],
            [6, 7, 8]])
     >>> a[[1,2],[2,2]].base
     None
     */
    // boolean indexing
    // note that if not assignment, returned copy value not view.
    /*
     a = np.arange(5)
     >>> a[a==1]
     array([1])
     >>> a[a==1].base
     None
     */
    /*
     var a = [0.0, 2.0, 3.0, 1.0]
     var c = [0.0, 0, 0]
     var bb: [UInt] = [1, 1, 3]
     vDSP_vgathrD(&a, &bb, vDSP_Stride(1), &c, vDSP_Stride(1), vDSP_Length(c.count))
     print(c)
     //[0.0, 0.0, 3.0]
     */
    var workShape = Array(mfarray.shape.suffix(from: 1))
    var retShape = indices.shape + workShape
    let retSize = shape2size(&retShape)
    
    let indices = check_contiguous(indices, .Row)
    let mfarray = check_contiguous(mfarray, .Row)
    
    let workSize = shape2size(&workShape)
    
    let newdata = MfData(size: retSize, mftype: mfarray.mftype)
    var dstptrT = newdata.data.bindMemory(to: T.self, capacity: retSize)
    let _ = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned mfarray](srcptr) in
        
        let offsets = (indices.data as! [Int]).map{ get_positive_index($0, axissize: mfarray.shape[0], axis: 0) * mfarray.strides[0] }
        for offset in offsets{
            copy_unsafeptrT(workSize, srcptr.baseAddress! + offset, 1, dstptrT, 1, cblas_func)
            dstptrT += workSize
        }
    }
    
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func fancygetall_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: inout [MfArray], _ cblas_func: cblas_convorder_func<T>) -> MfArray{
    // check proper indices
    assert(indices.count >= 2)
    precondition(indices.count <= mfarray.ndim, "too many indices for array: array is \(mfarray.ndim)-dimensional, but \(indices.count) were indexed")
    
    let mfarray = check_contiguous(mfarray, .Row)
    
    let (offsets, indShape, _) = get_offsets_from_indices(mfarray, &indices)
    
    var workShape = Array(mfarray.shape.suffix(from: indices.count))
    var retShape = indShape + workShape
    let retSize = shape2size(&retShape)
    let workSize = workShape.count > 0 ? shape2size(&workShape) : 1
    /*
     >>> a = np.arange(27).reshape(3,3,3)
     >>> a[[[-2,1,0]], [[0,1,0]]]
     array([[[ 9, 10, 11],
             [12, 13, 14],
             [ 0,  1,  2]]])
     >>> a[-2,0]
     array([ 9, 10, 11])
     >>> a[1,1]
     array([12, 13, 14])
     >>> a[0,0]
     array([0, 1, 2])
     */
    
    let newdata = MfData(size: retSize, mftype: mfarray.mftype)
    var dstptrT = newdata.data.bindMemory(to: T.self, capacity: retSize)
    let _ = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        srcptr in
        
        for offset in offsets{
            copy_unsafeptrT(workSize, srcptr.baseAddress! + offset, 1, dstptrT, 1, cblas_func)
            dstptrT += workSize
        }
    }
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


internal func fancysetcol_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ assignedMfarray: MfArray, _ cblas_func: cblas_convorder_func<T>) -> Void{
    assert(indices.mftype == .Int, "must be int")
    
    var workShape = Array(mfarray.shape.suffix(from: 1))
    let workSize = shape2size(&workShape)
    let retShape = indices.shape + workShape
    
    let indices = check_contiguous(indices, .Row)
    let assignedMfarray = check_contiguous(assignedMfarray.broadcast_to(shape: retShape), .Row).astype(mfarray.mftype)
    
    let offsets = (indices.data as! [Int]).map{ get_positive_index($0, axissize: mfarray.shape[0], axis: 0) * mfarray.strides[0] }
    
    if mfarray.ndim == 1{

        let _ = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            dstptr in
            let _ = assignedMfarray.withDataUnsafeMBPtrT(datatype: T.self){
                srcptr in
                for (i, offset) in offsets.enumerated(){
                    (dstptr.baseAddress! + offset).assign(from: srcptr.baseAddress! + i, count: 1)
                }
            }
        }
    }
    else{
        let _ = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            [unowned mfarray](dstptr) in
            let _ = assignedMfarray.withDataUnsafeMBPtrT(datatype: T.self){
                [unowned assignedMfarray](srcptr) in
                
                let workMfarrayStrides = Array(mfarray.strides.suffix(from: 1))
                let workAssignedMfarrayStrides = Array(assignedMfarray.strides.suffix(from: indices.ndim))
                for cblasParams in OptOffsetParams_raw(shape: workShape, bigger_strides: workAssignedMfarrayStrides, smaller_strides: workMfarrayStrides){
                    for (i, offset) in offsets.enumerated(){
                        copy_unsafeptrT(cblasParams.blocksize, srcptr.baseAddress! + i*workSize + cblasParams.b_offset, cblasParams.b_stride, dstptr.baseAddress! + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }
                /*
                for (i, offset) in offsets.enumerated(){
                    for cblasParams in OptOffsetParams_raw(shape: workShape, bigger_strides: Array(assignedMfarray.strides.suffix(from: indices.ndim)), smaller_strides: workMfarrayStrides){

                        copy_unsafeptrT(cblasParams.blocksize, srcptr.baseAddress! + i*workSize + cblasParams.b_offset, cblasParams.b_stride, dstptr.baseAddress! + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }*/
            }
            
        }
    }

}


internal func fancysetall_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: inout [MfArray], _ assignedMfarray: MfArray, _ cblas_func: cblas_convorder_func<T>) -> Void{
    // check proper indices
    assert(indices.count >= 2)
    precondition(indices.count <= mfarray.ndim, "too many indices for array: array is \(mfarray.ndim)-dimensional, but \(indices.count) were indexed")

    let (offsets, indShape, _) = get_offsets_from_indices(mfarray, &indices)
    
    var workShape = Array(mfarray.shape.suffix(from: indices.count))
    let retShape = indShape + workShape
    let workSize = workShape.count > 0 ? shape2size(&workShape) : 1
    
    let assignedMfarray = check_contiguous(assignedMfarray.broadcast_to(shape: retShape), .Row).astype(mfarray.mftype)
    /*
     >>> a = np.arange(27).reshape(3,3,3)
     >>> a[[[-2,1,0]], [[0,1,0]]]
     array([[[ 9, 10, 11],
             [12, 13, 14],
             [ 0,  1,  2]]])
     >>> a[-2,0]
     array([ 9, 10, 11])
     >>> a[1,1]
     array([12, 13, 14])
     >>> a[0,0]
     array([0, 1, 2])
     */
    let _ = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        [unowned mfarray](dstptr) in
        let _ = assignedMfarray.withDataUnsafeMBPtrT(datatype: T.self){
            [unowned assignedMfarray](srcptr) in
            if workShape.count == 0{// indices.count == mfarray.ndim
                for (i, offset) in offsets.enumerated(){
                    (dstptr.baseAddress! + offset).assign(from: srcptr.baseAddress! + i, count: 1)
                }
            }
            else{
                let workMfarrayStrides = Array(mfarray.strides.suffix(from: indices.count))
                let workAssignedMfarrayStrides = Array(assignedMfarray.strides.suffix(workShape.count))
                for cblasParams in OptOffsetParams_raw(shape: workShape, bigger_strides: workAssignedMfarrayStrides, smaller_strides: workMfarrayStrides){
                    for (i, offset) in offsets.enumerated(){
                        copy_unsafeptrT(cblasParams.blocksize, srcptr.baseAddress! + i*workSize + cblasParams.b_offset, cblasParams.b_stride, dstptr.baseAddress! + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }
            }
            
        }
    }
    
}
