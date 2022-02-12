//
//  cblas.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation
import Accelerate


public typealias cblas_copy_func<T> = (Int32, UnsafePointer<T>, Int32, UnsafeMutablePointer<T>, Int32) -> Void



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
        wrap_cblas_copy(mfarray.storedSize, mfarray.mfdata.storedPtr.baseAddress!, 1, newdata.storedPtr.baseAddress! + offset, 1, T.StoredType.cblas_copy_func)
        offset += mfarray.storedSize
    }
    
    let newstructure = MfStructure(shape: ret_shape, mforder: mforder)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
