//
//  cblas.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
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
internal func wrap_cblas_matmul<T: MfStoredTypeUsable>(_ size: Int, _ mforder: MfOrder, _ lptr: UnsafePointer<T>, _ lrow: Int, _ lcol: Int, _ rptr: UnsafePointer<T>, _ rrow: Int, _ rcol: Int, _ dstptr: UnsafeMutablePointer<T>, _ cblas_func: cblas_matmul_func<T>){
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


/// Copy mfarray by cblas
/// - Parameters:
///   - src_mfarray: The source mfarray
///   - dst_mfarray: The destination mfarray
///   - cblas_func: cblas_copy_function
internal func copy_by_cblas<T: MfTypeUsable>(_ src_mfarray: MfArray<T>, _ dst_mfarray: MfArray<T>, cblas_func: cblas_copy_func<T.StoredType>) -> Void{
    
    let shape = dst_mfarray.shape
    let bigger_strides = dst_mfarray.strides
    let smaller_strides = src_mfarray.strides
    
    dst_mfarray.withUnsafeMutableStartPointer{
        dstptr in
        src_mfarray.withUnsafeMutableStartPointer{
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
internal func contiguous_by_cblas<T: MfTypeUsable>(_ src_mfarray: MfArray<T>, cblas_func: cblas_copy_func<T.StoredType>, mforder: MfOrder) -> MfArray<T>{
        
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
internal func samesize_by_cblas<T: MfTypeUsable>(_ src_mfarray: MfArray<T>, cblas_func: cblas_copy_func<T.StoredType>, mforder: MfOrder) -> MfArray<T>{
    let newsize = src_mfarray.size
    let newdata: MfData<T> = MfData(size: newsize)
    let newstructure = MfStructure(shape: src_mfarray.shape, mforder: mforder)
    let dst_mfarray = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    copy_by_cblas(src_mfarray, dst_mfarray, cblas_func: T.StoredType.cblas_copy_func)
    
    return dst_mfarray
}


/// Stack vertically or horizontally
/// - Parameters:
///   - mfarrays: The mfarray array
///   - ret_shape: The return shape array
///   - mforder: An order. Row major means vstack, Column major means hstack.
/// - Returns: The stacked mfarray
internal func stack_by_cblas<T: MfTypeUsable>(_ mfarrays: [MfArray<T>], ret_shape: [Int], mforder: MfOrder) -> MfArray<T>{
    var ret_shape = ret_shape
    let majorArrays = mfarrays.map{ Matft.to_contiguous($0, mforder: mforder) }
    let ret_size = shape2size(&ret_shape)
    
    let newdata: MfData<T> = MfData(size: ret_size)
    var offset = 0
    for mfarray in majorArrays {
        mfarray.withUnsafeMutableStartPointer{
            wrap_cblas_copy(mfarray.storedSize, $0, 1, newdata.storedPtr.baseAddress! + offset, 1, T.StoredType.cblas_copy_func)
        }
        
        offset += mfarray.storedSize
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: mforder)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Concatenate mfarrays along with a given axis
/// - Parameters:
///   - mfarrays: The mfarray array
///   - ret_shape: The return shape array
///   - axis: An axis index
/// - Returns: The concatenated mfarray
internal func concat_by_cblas<T: MfTypeUsable>(_ mfarrays: [MfArray<T>], ret_shape: [Int], axis: Int) -> MfArray<T>{
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
    
    let majorArrays = mfarrays.map{ Matft.to_contiguous($0, mforder: faster_order) }
    let ret_size = shape2size(&ret_shape)
    
    let newdata: MfData<T> = MfData(size: ret_size)
    var offset = 0
    for sb in 0..<slowerBlockSize{
        for mfarray in majorArrays {
            let concat_size = mfarray.shape[axis]
            mfarray.withUnsafeMutableStartPointer{
                wrap_cblas_copy(fasterBlockSize*concat_size, $0 + sb*fasterBlockSize*concat_size, 1, newdata.storedPtr.baseAddress! + offset, 1, T.StoredType.cblas_copy_func)
            }
            
            offset += fasterBlockSize*concat_size
        }
    }
    let newstructure = MfStructure(shape: ret_shape, mforder: faster_order)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}


/// Getter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray. Must be more than 2d
///   - indices: An input Interger indices array
///   - cblas_func: cblas_copy_func
/// - Returns: The mfarray
internal func fancyndget_by_cblas<T: MfTypeUsable, U: MfInterger>(_ mfarray: MfArray<T>, _ indices: MfArray<U>, cblas_func: cblas_copy_func<T.StoredType>) -> MfArray<T>{
    // fancy indexing
    // note that if not assignment, returned copy value not view.
    assert(mfarray.ndim > 1, "must be more than 2d!")
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
    var work_shape = Array(mfarray.shape.suffix(from: 1))
    var ret_shape = indices.shape + work_shape
    let ret_size = shape2size(&ret_shape)
    
    let indices = indices.astype(newtype: Int.self, mforder: .Row)
    let mfarray = check_contiguous(mfarray, .Row)
    
    let work_size = shape2size(&work_shape)
    
    let newdata: MfData<T> = MfData(size: ret_size)
    
    let offsets = indices.data.map{ get_positive_index($0, axissize: mfarray.shape[0], axis: 0) * mfarray.strides[0] }
    
    var dstptr = newdata.storedPtr.baseAddress!
    mfarray.withUnsafeMutableStartPointer{
        for offset in offsets{
            wrap_cblas_copy(work_size, $0 + offset, 1, dstptr, 1, cblas_func)
            dstptr += work_size
        }
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
    
}

/// Getter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray. Must be more than 2d
///   - indices: An input Interger indices array
///   - cblas_func: cblas_copy_func
/// - Returns: The mfarray
internal func fancygetall_by_cblas<T: MfTypeUsable, U: MfInterger>(_ mfarray: MfArray<T>, _ indices: inout [MfArray<U>], cblas_func: cblas_copy_func<T.StoredType>) -> MfArray<T>{
    assert(indices.count >= 2)
    precondition(indices.count <= mfarray.ndim, "too many indices for array: array is \(mfarray.ndim)-dimensional, but \(indices.count) were indexed")
    
    let mfarray = check_contiguous(mfarray, .Row)
    
    let (offsets, ind_shape, _) = get_offsets_from_indices(mfarray, &indices)
    
    var work_shape = Array(mfarray.shape.suffix(from: indices.count))
    var ret_shape = ind_shape + work_shape
    let ret_size = shape2size(&ret_shape)
    let work_size = work_shape.count > 0 ? shape2size(&work_shape) : 1
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
    
    let newdata: MfData<T> = MfData(size: ret_size)
    var dstptr = newdata.storedPtr.baseAddress!
    
    mfarray.withUnsafeMutableStartPointer{
        for offset in offsets{
            wrap_cblas_copy(work_size, $0 + offset, 1, dstptr, 1, cblas_func)
            dstptr += work_size
        }
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

/// Setter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray.
///   - indices: An input Interger indices mfarray
///   - cblas_func: cblas_copy_func
internal func fancyset_by_cblas<T: MfTypeUsable, U: MfInterger>(_ mfarray: MfArray<T>, _ indices: MfArray<U>, _ assigned_array: MfArray<T>, _ cblas_func: cblas_copy_func<T.StoredType>){

    var work_shape = Array(mfarray.shape.suffix(from: 1))
    let work_size = shape2size(&work_shape)
    let ret_shape = indices.shape + work_shape
    
    let indices = indices.astype(newtype: Int.self, mforder: .Row)
    let assigned_array = check_contiguous(assigned_array.broadcast_to(shape: ret_shape), .Row)
    
    let offsets = indices.data.map{ get_positive_index($0, axissize: mfarray.shape[0], axis: 0) * mfarray.strides[0] }
    
    if mfarray.ndim == 1{
        assigned_array.withUnsafeMutableStartPointer{
            srcptr in
            mfarray.withUnsafeMutableStartPointer{
                dstptr in
                for (i, offset) in offsets.enumerated(){
                    (dstptr + offset).assign(from: srcptr + i, count: 1)
                }
            }
        }
    }
    else{
        let work_mfarray_strides = Array(mfarray.strides.suffix(from: 1))
        let work_assigned_mfarray_strides = Array(assigned_array.strides.suffix(from: indices.ndim))
        
        assigned_array.withUnsafeMutableStartPointer{
            srcptr in
            mfarray.withUnsafeMutableStartPointer{
                dstptr in
                for cblasParams in OptOffsetParamsSequence(shape: work_shape, bigger_strides: work_assigned_mfarray_strides, smaller_strides: work_mfarray_strides){
                    for (i, offset) in offsets.enumerated(){
                        wrap_cblas_copy(cblasParams.blocksize, srcptr + i*work_size + cblasParams.b_offset, cblasParams.b_stride, dstptr + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }
            }
        }
    }

}

/// Setter function for the fancy indexing on a given Interger indices.
/// - Parameters:
///   - mfarray: An inpu mfarray.
///   - indices: An input Interger indices mfarray array
///   - cblas_func: cblas_copy_func
internal func fancysetall_by_cblas<T: MfTypeUsable, U: MfInterger>(_ mfarray: MfArray<T>, _ indices: inout [MfArray<U>], _ assigned_array: MfArray<T>, _ cblas_func: cblas_copy_func<T.StoredType>){
    // check proper indices
    assert(indices.count >= 2)
    precondition(indices.count <= mfarray.ndim, "too many indices for array: array is \(mfarray.ndim)-dimensional, but \(indices.count) were indexed")

    let (offsets, ind_shape, _) = get_offsets_from_indices(mfarray, &indices)
    
    var work_shape = Array(mfarray.shape.suffix(from: indices.count))
    let ret_shape = ind_shape + work_shape
    let work_size = work_shape.count > 0 ? shape2size(&work_shape) : 1
    
    let assigned_array = check_contiguous(assigned_array.broadcast_to(shape: ret_shape), .Row)
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

    if work_shape.count == 0{// indices.count == mfarray.ndim
        assigned_array.withUnsafeMutableStartPointer{
            srcptr in
            mfarray.withUnsafeMutableStartPointer{
                dstptr in
                for (i, offset) in offsets.enumerated(){
                    (dstptr + offset).assign(from: srcptr + i, count: 1)
                }
            }
        }
    }
    else{
        let work_mfarray_strides = Array(mfarray.strides.suffix(from: indices.count))
        let work_sssigned_mfarray_strides = Array(assigned_array.strides.suffix(work_shape.count))
        assigned_array.withUnsafeMutableStartPointer{
            srcptr in
            mfarray.withUnsafeMutableStartPointer{
                dstptr in
                for cblasParams in OptOffsetParamsSequence(shape: work_shape, bigger_strides: work_sssigned_mfarray_strides, smaller_strides: work_mfarray_strides){
                    for (i, offset) in offsets.enumerated(){
                        wrap_cblas_copy(cblasParams.blocksize, srcptr + i*work_size + cblasParams.b_offset, cblasParams.b_stride, dstptr + offset + cblasParams.s_offset, cblasParams.s_stride, cblas_func)
                    }
                }
            }
        }
        
    }
    
}

internal func matmul_by_cblas<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, cblas_func: cblas_matmul_func<T.StoredType>) -> MfArray<T>{
    let l_shape = l_mfarray.shape
    let r_shape = r_mfarray.shape
    var ret_shape = l_mfarray.shape
    let ret_ndim = ret_shape.count
    ret_shape[ret_ndim - 1] = r_shape[ret_ndim - 1]
    let ret_size = shape2size(&ret_shape)
    // order
    // must be row major
    let (l_mfarray, r_mfarray, ret_order) = check_matmul_contiguous(l_mfarray, r_mfarray)

    let matNum = l_shape[ret_ndim - 2] * r_shape[ret_ndim - 1]
    let l_matNum = l_shape[ret_ndim - 2] * l_shape[ret_ndim - 1]
    let r_matNum = r_shape[ret_ndim - 2] * r_shape[ret_ndim - 1]
    let iterNum = ret_size / matNum
    
    let newdata: MfData<T> = MfData(size: ret_size)
    let dstptr = newdata.storedPtr.baseAddress!
    l_mfarray.withUnsafeMutableStartPointer{
        lptr in
        r_mfarray.withUnsafeMutableStartPointer{
            rptr in
            for i in 0..<iterNum{
                wrap_cblas_matmul(matNum, ret_order, lptr + i*l_matNum, l_shape[ret_ndim - 2], l_shape[ret_ndim - 1], rptr + i*r_matNum, r_shape[ret_ndim - 2], r_shape[ret_ndim - 1], dstptr + i*matNum, cblas_func)
            }
        }
    }
 
    let newstructure = MfStructure(shape: ret_shape, mforder: ret_order)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
