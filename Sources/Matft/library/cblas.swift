//
//  cblas.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/07.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate


public typealias cblas_copy_func<T> = (Int32, UnsafePointer<T>, Int32, UnsafeMutablePointer<T>, Int32) -> Void

public typealias cblas_matmul_func<T> = (CBLAS_ORDER, CBLAS_TRANSPOSE, CBLAS_TRANSPOSE, Int32, Int32, Int32, T, UnsafePointer<T>, Int32, UnsafePointer<T>, Int32, T, UnsafeMutablePointer<T>, Int32) -> Void


/// Wrapper of cblas copy function
/// - Parameters:
///   - size: A size to be copied
///   - srcptr: A source pointer
///   - srcStride: A source stride
///   - dstptr: A destination pointer
///   - dstStride: A destination stride
///   - cblas_func: The cblas copy function
@inline(__always)
internal func wrap_cblas_copy<T>(_ size: Int, _ srcptr: UnsafePointer<T>, _ srcStride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dstStride: Int, _ cblas_func: cblas_copy_func<T>){
    cblas_func(Int32(size), srcptr, Int32(srcStride), dstptr, Int32(dstStride))
}

/// Wrapper of cblas matmul function
/// - Parameters:
///   - size: A size
///   - mforder: MfOrder
///   - lptr: A left pointer
///   - lrow: A left row size
///   - lcol: A left column size
///   - rptr: A right pointer
///   - rrow: A right row size
///   - rcol: A right column size
///   - dstptr: A destination pointer
///   - cblas_func: The cblas matmul function
@inline(__always)
internal func wrap_cblas_matmul<T: MfStorable>(_ size: Int, _ mforder: MfOrder, _ lptr: UnsafePointer<T>, _ lrow: Int, _ lcol: Int, _ rptr: UnsafePointer<T>, _ rrow: Int, _ rcol: Int, _ dstptr: UnsafeMutablePointer<T>, _ cblas_func: cblas_matmul_func<T>){
    let M = Int32(lrow)
    let N = Int32(rcol)
    let K = Int32(lcol)
    
    switch mforder {
    case .Column:
        let order = CblasColMajor
        let lda = Int32(lrow)
        let ldb = Int32(rrow)
        let ldc = Int32(lrow)
        cblas_func(order, CblasNoTrans, CblasNoTrans, M, N, K, T.from(1), lptr, lda, rptr, ldb, T.zero, dstptr, ldc)
    case .Row:
        let order = CblasRowMajor
        let lda = Int32(lcol)
        let ldb = Int32(rcol)
        let ldc = Int32(rcol)
        cblas_func(order, CblasNoTrans, CblasNoTrans, M, N, K, T.from(1), lptr, lda, rptr, ldb, T.zero, dstptr, ldc)
    }
}



internal func copy_mfarray<T: MfStorable>(_ mfarray: MfArray, dsttmpMfarray: MfArray, cblas_func: cblas_copy_func<T>) -> MfArray{
    
    
    dsttmpMfarray.withUnsafeMutableStartPointer(datatype: T.self){
        [unowned dsttmpMfarray] (dstptr) in
        mfarray.withUnsafeMutableStartPointer(datatype: T.self){
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
            for cblasPrams in OptOffsetParamsSequence(shape: dsttmpMfarray.shape, bigger_strides: dsttmpMfarray.strides, smaller_strides: mfarray.strides){
                //if negative offset, move proper position
                let srcptr = cblasPrams.s_stride >= 0 ? srcptr + cblasPrams.s_offset : srcptr + (cblasPrams.blocksize - 1) * cblasPrams.s_stride + cblasPrams.s_offset
                let dstptr = cblasPrams.b_stride >= 0 ? dstptr + cblasPrams.b_offset : dstptr + (cblasPrams.blocksize - 1) * cblasPrams.b_stride + cblasPrams.b_offset
                wrap_cblas_copy(cblasPrams.blocksize, srcptr, cblasPrams.s_stride, dstptr, cblasPrams.b_stride, cblas_func)
                //print(cblasPrams.blocksize, cblasPrams.b_offset, cblasPrams.b_stride, cblasPrams.s_offset, cblasPrams.s_stride)
            }
        }
    }
    
    return dsttmpMfarray
}

/// Copy mfarray by cblas
/// - Parameters:
///   - src_mfarray: The source mfarray
///   - dst_mfarray: The destination mfarray
///   - cblas_func: cblas_copy_function
internal func copy_by_cblas<T: MfStorable>(_ src_mfarray: MfArray, _ dst_mfarray: MfArray, cblas_func: cblas_copy_func<T>) -> Void{
    
    let shape = dst_mfarray.shape
    let bigger_strides = dst_mfarray.strides
    let smaller_strides = src_mfarray.strides
    
    dst_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
        dstptr in
        src_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
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
            for cblasPrams in OptOffsetParamsSequence(shape: shape, bigger_strides: bigger_strides, smaller_strides: smaller_strides){
                //if negative offset, move proper position
                let srcptr = cblasPrams.s_stride >= 0 ? srcptr + cblasPrams.s_offset : srcptr + (cblasPrams.blocksize - 1) * cblasPrams.s_stride + cblasPrams.s_offset
                let dstptr = cblasPrams.b_stride >= 0 ? dstptr + cblasPrams.b_offset : dstptr + (cblasPrams.blocksize - 1) * cblasPrams.b_stride + cblasPrams.b_offset
                wrap_cblas_copy(cblasPrams.blocksize, srcptr, cblasPrams.s_stride, dstptr, cblasPrams.b_stride, cblas_func)
                //print(cblasPrams.blocksize, cblasPrams.b_offset, cblasPrams.b_stride, cblasPrams.s_offset, cblasPrams.s_stride)
            }
        }
    }
    
    return
}

/// Convert contiguous mfarray
/// - Parameters:
///   - src_mfarray: The source mfarray
///   - cblas_func: cblas_copy_function
///   - mforder: The order
/// - Returns: Contiguous mfarray
internal func contiguous_by_cblas<T: MfStorable>(_ src_mfarray: MfArray, cblas_func: cblas_copy_func<T>, mforder: MfOrder) -> MfArray{
        
    switch mforder {
    case .Row:
        if src_mfarray.mfstructure.row_contiguous{
            return copy_all_mfarray(src_mfarray)
        }
    case .Column:
        if src_mfarray.mfstructure.column_contiguous{
            return copy_all_mfarray(src_mfarray)
        }
    }
    
    return samesize_by_cblas(src_mfarray, cblas_func: cblas_func, mforder: mforder)
}

/// Convert mfarray with same size as an internal stored data size
/// - Parameters:
///   - src_mfarray: The source mfarray
///   - cblas_func: cblas_copy_func
///   - mforder: An order
/// - Returns: The destination mfarray with same size as an internal stored data size
internal func samesize_by_cblas<T: MfStorable>(_ src_mfarray: MfArray, cblas_func: cblas_copy_func<T>, mforder: MfOrder) -> MfArray{
    let newsize = src_mfarray.size
    let newdata: MfData = MfData(size: newsize, mftype: src_mfarray.mftype)
    let newstructure = MfStructure(shape: src_mfarray.shape, mforder: mforder)
    let dst_mfarray = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    copy_by_cblas(src_mfarray, dst_mfarray, cblas_func: cblas_func)
    
    return dst_mfarray
}

internal func shift_by_cblas<T: MfStorable>(_ mfarray: MfArray, shift: Int, axis: Int? = nil, _ cblas_func: cblas_copy_func<T>) -> MfArray{
    
    var offset: Int
    var size: Int
    if let axis = axis, mfarray.ndim > 1 {
        let pos_axis = get_positive_axis(axis, ndim: mfarray.ndim)
        
        offset = shift
        size = mfarray.shape[pos_axis]
    }
    else{
        offset = shift
        size = mfarray.size
    }
    
    // compress shift into -size <= shift < size
    // and then get positive shift value
    let sign = offset >= 0 ? 1 : -1
    offset = sign*(abs(offset) % size)
    offset = offset >= 0 ? offset : offset + size
    
    assert(0 <= offset && offset < size)
    // offset is shifted value to right along axis
    offset = size - offset
    
    let src_mfarray: MfArray
    if let axis = axis, mfarray.ndim > 1 {
        src_mfarray = check_contiguous(mfarray.swapaxes(axis1: axis, axis2: 0), .Row)
        var restShape = Array(mfarray.shape.suffix(mfarray.ndim-1))
        let restSize = shape2size(&restShape)
        
        // update offset along all flatten array
        size = src_mfarray.size
        offset *= restSize
    }
    else{
        src_mfarray = check_contiguous(mfarray, .Row)
    }
    
    let newdata = MfData(size: src_mfarray.storedSize, mftype: src_mfarray.mftype)
    
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        src_mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            srcptrT in
            // copy shift*size~ value first
            if size-offset > 0{
                wrap_cblas_copy(size-offset, srcptrT + offset, 1, dstptrT, 1, cblas_func)
            }
            // copy remain (0~shift)
            if offset > 0{
                wrap_cblas_copy(offset, srcptrT, 1, dstptrT + size - offset, 1, cblas_func)
            }
        }
    }
    
    let newstructure = MfStructure(shape: src_mfarray.shape, strides: src_mfarray.strides)
    
    if let axis = axis, mfarray.ndim > 1 {
        return MfArray(mfdata: newdata, mfstructure: newstructure).swapaxes(axis1: 0, axis2: axis)
    }
    else{
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
}

/// Stack vertically or horizontally
/// - Parameters:
///   - mfarrays: The mfarray array
///   - ret_shape: The return shape array
///   - ret_mftype: The return mftype
///   - mforder: An order. Row major means vstack, Column major means hstack.
///   - cblas_func: cblas_copy function
/// - Returns: The stacked mfarray
internal func stack_by_cblas<T: MfStorable>(_ mfarrays: [MfArray], ret_shape: [Int], ret_mftype: MfType, mforder: MfOrder, _ cblas_func: cblas_copy_func<T>) -> MfArray{
    assert(mfarrays.count > 0)

    var ret_shape = ret_shape
    let majorArrays = mfarrays.map{ $0.astype(ret_mftype, mforder: mforder) }
    let ret_size = shape2size(&ret_shape)
    
    let newdata: MfData = MfData(size: ret_size, mftype: ret_mftype)

    var offset = 0
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        for mfarray in majorArrays {
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                wrap_cblas_copy(mfarray.storedSize, $0, 1, dstptrT + offset, 1, cblas_func)
            }
            
            offset += mfarray.storedSize
        }
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: mforder)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Concatenate mfarrays along with a given axis
/// - Parameters:
///   - mfarrays: The mfarray array
///   - ret_shape: The return shape array
///   - ret_mftype: The return mftype
///   - axis: An axis index
///   - cblas_func: cblas_copy function
/// - Returns: The concatenated mfarray
internal func concat_by_cblas<T: MfStorable>(_ mfarrays: [MfArray], ret_shape: [Int], ret_mftype: MfType, axis: Int, _ cblas_func: cblas_copy_func<T>) -> MfArray{
    var ret_shape = ret_shape
    var column_shape = ret_shape // the left side shape splited by axis, must have more than one elements
    column_shape.removeSubrange(axis..<ret_shape.count)
    let column_size = shape2size(&column_shape)
    var row_shape = ret_shape// the right side shape splited by axis, must have more than one elements
    row_shape.removeSubrange(0...axis)
    let row_size = shape2size(&row_shape)
    
    let faster_order = row_size >= column_size ? MfOrder.Row : MfOrder.Column
    let fasterBlockSize = row_size >= column_size ? row_size : column_size
    let slowerBlockSize = row_size >= column_size ? column_size : row_size
    
    let majorArrays = mfarrays.map{ Matft.astype($0, mftype: ret_mftype, mforder: faster_order) }
    let ret_size = shape2size(&ret_shape)
    
    let newdata = MfData(size: ret_size, mftype: ret_mftype)
    var offset = 0
    
    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        for sb in 0..<slowerBlockSize{
            for mfarray in majorArrays {
                let concat_size = mfarray.shape[axis]
                mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                    wrap_cblas_copy(fasterBlockSize*concat_size, $0 + sb*fasterBlockSize*concat_size, 1, dstptrT + offset, 1, cblas_func)
                }
                
                offset += fasterBlockSize*concat_size
            }
        }
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: faster_order)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Multiply mfarray
/// - Parameters:
///   - lmfarray: The left mfarray
///   - rmfarray: The right mfarray
///   - cblas_func: cblas_matmul function
/// - Returns: The multiplied mfarray
internal func matmul_by_cblas<T: MfStorable>(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray, cblas_func: cblas_matmul_func<T>) -> MfArray{
    let lshape = lmfarray.shape
    let rshape = rmfarray.shape
    var retshape = lmfarray.shape
    let retndim = retshape.count
    retshape[retndim - 1] = rshape[retndim - 1]
    
    // order
    // must be row major
    let retorder = check_matmul_contiguous(&lmfarray, &rmfarray)
    
    let newstructure = MfStructure(shape: retshape, mforder: retorder)
    let newsize = shape2size(&retshape)
    
    let matNum = lshape[retndim - 2] * rshape[retndim - 1]
    let l_matNum = lshape[retndim - 2] * lshape[retndim - 1]
    let r_matNum = rshape[retndim - 2] * rshape[retndim - 1]
    let iterNum = newsize / matNum
    
    let newdata = MfData(size: newsize, mftype: lmfarray.mftype)

    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        var dstptrT = dstptrT
        lmfarray.withUnsafeMutableStartPointer(datatype: T.self){
            lptr in
            var lptr = lptr
            rmfarray.withUnsafeMutableStartPointer(datatype: T.self){
                rptr in
                var rptr = rptr
                
                for _ in 0..<iterNum{
                    wrap_cblas_matmul(matNum, retorder, lptr, lshape[retndim - 2], lshape[retndim - 1], rptr, rshape[retndim - 2], rshape[retndim - 1], dstptrT, cblas_func)
                    
                    lptr += l_matNum
                    rptr += r_matNum
                    dstptrT += matNum
                }
            }
        }
    }
    
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Getter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray. Must be more than 2d
///   - indices: An input Interger indices array
///   - cblas_func: cblas_copy_func
/// - Returns: The mfarray
internal func fancyndget_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ cblas_func: cblas_copy_func<T>) -> MfArray{
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
    
    if mfarray.isReal{
        let newdata = MfData(size: retSize, mftype: mfarray.mftype)

        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            var dstptrT = dstptrT
            let _ = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                [unowned mfarray](srcptr) in
                
                let offsets = (indices.data as! [Int]).map{ get_positive_index($0, axissize: mfarray.shape[0], axis: 0) * mfarray.strides[0] }
                for offset in offsets{
                    wrap_cblas_copy(workSize, srcptr + offset, 1, dstptrT, 1, cblas_func)
                    dstptrT += workSize
                }
            }
        }
        
        let newstructure = MfStructure(shape: retShape, mforder: .Row)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    else{
        let newdata = MfData(size: retSize, mftype: mfarray.mftype, complex: true)

        newdata.withUnsafeMutablevDSPPointer(datatype: T.vDSPType.self){
            dstptrT in
            var dstptrTr = dstptrT.pointee.realp as! UnsafeMutablePointer<T>
            var dstptrTi = dstptrT.pointee.imagp as! UnsafeMutablePointer<T>
            let _ = mfarray.withUnsafeMutablevDSPPointer(datatype: T.vDSPType.self){
                [unowned mfarray](srcptr) in
                let srcptrr = srcptr.pointee.realp as! UnsafeMutablePointer<T>
                let srcptri = srcptr.pointee.imagp as! UnsafeMutablePointer<T>
                
                let offsets = (indices.data as! [Int]).map{ get_positive_index($0, axissize: mfarray.shape[0], axis: 0) * mfarray.strides[0] }
                for offset in offsets{
                    wrap_cblas_copy(workSize, srcptrr + offset, 1, dstptrTr, 1, cblas_func)
                    dstptrTr += workSize
                    
                    wrap_cblas_copy(workSize, srcptri + offset, 1, dstptrTi, 1, cblas_func)
                    dstptrTi += workSize
                }
            }
        }
        
        let newstructure = MfStructure(shape: retShape, mforder: .Row)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}



/// Getter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray. Must be more than 2d
///   - indices: An input Interger indices array
///   - cblas_func: cblas_copy_func
/// - Returns: The mfarray
internal func fancygetall_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: inout [MfArray], _ cblas_func: cblas_copy_func<T>) -> MfArray{
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
    
    if mfarray.isReal{
        let newdata = MfData(size: retSize, mftype: mfarray.mftype)
        newdata.withUnsafeMutableStartPointer(datatype: T.self){
            dstptrT in
            var dstptrT = dstptrT
            let _ = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                srcptr in
                
                for offset in offsets{
                    wrap_cblas_copy(workSize, srcptr + offset, 1, dstptrT, 1, cblas_func)
                    dstptrT += workSize
                }
            }
        }
        
        let newstructure = MfStructure(shape: retShape, mforder: .Row)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    else{
        let newdata = MfData(size: retSize, mftype: mfarray.mftype, complex: true)

        newdata.withUnsafeMutablevDSPPointer(datatype: T.vDSPType.self){
            dstptrT in
            var dstptrTr = dstptrT.pointee.realp as! UnsafeMutablePointer<T>
            var dstptrTi = dstptrT.pointee.imagp as! UnsafeMutablePointer<T>
            let _ = mfarray.withUnsafeMutablevDSPPointer(datatype: T.vDSPType.self){
                srcptr in
                let srcptrr = srcptr.pointee.realp as! UnsafeMutablePointer<T>
                let srcptri = srcptr.pointee.imagp as! UnsafeMutablePointer<T>
                
                for offset in offsets{
                    wrap_cblas_copy(workSize, srcptrr + offset, 1, dstptrTr, 1, cblas_func)
                    dstptrTr += workSize
                    
                    wrap_cblas_copy(workSize, srcptri + offset, 1, dstptrTi, 1, cblas_func)
                    dstptrTi += workSize
                }
            }
        }
        
        let newstructure = MfStructure(shape: retShape, mforder: .Row)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}

/// Setter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray.
///   - indices: An input Interger indices mfarray
///   - assignedMfarray: The assigned mfarray
///   - cblas_func: cblas_copy_func
internal func fancyset_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, _ assignedMfarray: MfArray, _ cblas_func: cblas_copy_func<T>) -> Void{
    assert(indices.mftype == .Int, "must be int")
    
    var workShape = Array(mfarray.shape.suffix(from: 1))
    let workSize = shape2size(&workShape)
    let retShape = indices.shape + workShape
    
    let indices = check_contiguous(indices, .Row)
    let assignedMfarray = check_contiguous(assignedMfarray.broadcast_to(shape: retShape), .Row).astype(mfarray.mftype)
    
    let offsets = (indices.data as! [Int]).map{ get_positive_index($0, axissize: mfarray.shape[0], axis: 0) * mfarray.strides[0] }
    
    if mfarray.ndim == 1{

        let _ = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            dstptr in
            let _ = assignedMfarray.withUnsafeMutableStartPointer(datatype: T.self){
                srcptr in
                for (i, offset) in offsets.enumerated(){
                    (dstptr + offset).assign(from: srcptr + i, count: 1)
                }
            }
        }
    }
    else{
        let _ = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned mfarray](dstptr) in
            let _ = assignedMfarray.withUnsafeMutableStartPointer(datatype: T.self){
                [unowned assignedMfarray](srcptr) in
                
                let workMfarrayStrides = Array(mfarray.strides.suffix(from: 1))
                let workAssignedMfarrayStrides = Array(assignedMfarray.strides.suffix(from: indices.ndim))
                for cblasParams in OptOffsetParamsSequence(shape: workShape, bigger_strides: workAssignedMfarrayStrides, smaller_strides: workMfarrayStrides){
                    for (i, offset) in offsets.enumerated(){
                        wrap_cblas_copy(cblasParams.blocksize, srcptr + i*workSize + cblasParams.b_offset, cblasParams.b_stride, dstptr + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }
                /*
                for (i, offset) in offsets.enumerated(){
                    for cblasParams in OptOffsetParams_raw(shape: workShape, bigger_strides: Array(assignedMfarray.strides.suffix(from: indices.ndim)), smaller_strides: workMfarrayStrides){

                        wrap_cblas_copy(cblasParams.blocksize, srcptr.baseAddress! + i*workSize + cblasParams.b_offset, cblasParams.b_stride, dstptr.baseAddress! + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }*/
            }
            
        }
    }

}

/// Setter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray.
///   - indices: An input Interger indices mfarray array
///   - assignedMfarray: The assigned mfarray
///   - cblas_func: cblas_copy_func
internal func fancysetall_by_cblas<T: MfStorable>(_ mfarray: MfArray, _ indices: inout [MfArray], _ assignedMfarray: MfArray, _ cblas_func: cblas_copy_func<T>) -> Void{
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
    let _ = mfarray.withUnsafeMutableStartPointer(datatype: T.self){
        [unowned mfarray](dstptr) in
        let _ = assignedMfarray.withUnsafeMutableStartPointer(datatype: T.self){
            [unowned assignedMfarray](srcptr) in
            if workShape.count == 0{// indices.count == mfarray.ndim
                for (i, offset) in offsets.enumerated(){
                    (dstptr + offset).assign(from: srcptr + i, count: 1)
                }
            }
            else{
                let workMfarrayStrides = Array(mfarray.strides.suffix(from: indices.count))
                let workAssignedMfarrayStrides = Array(assignedMfarray.strides.suffix(workShape.count))
                for cblasParams in OptOffsetParamsSequence(shape: workShape, bigger_strides: workAssignedMfarrayStrides, smaller_strides: workMfarrayStrides){
                    for (i, offset) in offsets.enumerated(){
                        wrap_cblas_copy(cblasParams.blocksize, srcptr + i*workSize + cblasParams.b_offset, cblasParams.b_stride, dstptr + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }
            }
            
        }
    }
    
}
