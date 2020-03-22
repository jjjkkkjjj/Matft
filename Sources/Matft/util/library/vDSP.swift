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

internal func unsafePtrT2UnsafeMPtrU<T: MfTypable, U: MfTypable>(_ srcptr: UnsafePointer<T>,  _ dstptr: UnsafeMutablePointer<U>, _ vDSP_func: vDSP_convert_func<T, U>, _ count: Int){
    vDSP_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}
internal func preop_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    return MfArray(mfdata: newdata, mfstructure: mfarray.mfstructure)
}

//binary operation
internal typealias vDSP_biop_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func biop_unsafePtrT<T: MfStorable>(lptr: UnsafePointer<T>, _ lstride: Int, rptr: UnsafePointer<T>, _ rstride: Int, dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_func<T>){
    vDSP_func(lptr, vDSP_Stride(lstride), rptr, vDSP_Stride(rstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_by_vDSP<T: MfStorable>(_ bigger_mfarray: MfArray, _ smaller_mfarray: MfArray, vDSP_func: vDSP_biop_func<T>) -> MfArray{
    
    let newdata = withDummyDataMRPtr(bigger_mfarray.mftype, storedSize: bigger_mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: bigger_mfarray.storedSize)
        
        bigger_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            bptr in
            smaller_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
                sptr in
                //print(bigger_mfarray, smaller_mfarray)
                //print(bigger_mfarray.storedSize, smaller_mfarray.storedSize)
                for vDSPPrams in OptOffsetParams(bigger_mfarray: bigger_mfarray, smaller_mfarray: smaller_mfarray){
                    /*
                    let bptr = bptr.baseAddress! + vDSPPrams.b_offset
                    let sptr = sptr.baseAddress! + vDSPPrams.s_offset
                    dstptrT = dstptrT + vDSPPrams.b_offset*/
                    biop_unsafePtrT(lptr: bptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr: sptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptr: dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
                    //print(vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                }
            }
        }
    }
    
    return MfArray(mfdata: newdata, mfstructure: bigger_mfarray.mfstructure)
}

//get stats for mfarray
internal typealias vDSP_stats_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Length) -> Void
fileprivate func _stats_run<T: MfStorable>(_ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, vDSP_func: vDSP_stats_func<T>, stride: Int, _ count: Int){
    
    vDSP_func(srcptr, vDSP_Stride(stride), dstptr, vDSP_Length(count))
}

// for along given axis
internal func stats_axis_by_vDSP<T: MfStorable>(_ mfarray: MfArray, axis: Int, vDSP_func: vDSP_stats_func<T>) -> MfArray{
    var retShape = mfarray.shape
    let count = retShape.remove(at: axis)
    var retStrides = mfarray.strides
    //remove and get stride at given axis
    let stride = retStrides.remove(at: axis)
    
    
    let retndim = retShape.count

    let ret = withDummy(mftype: mfarray.mftype, storedSize: mfarray.storedSize, ndim: retndim){
        dataptr, shapeptr, stridesptr in

        //move
        shapeptr.baseAddress!.moveAssign(from: &retShape, count: retndim)
        
        //move
        stridesptr.baseAddress!.moveAssign(from: &retStrides, count: retndim)
        
        
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            srcptr in
            var dstptr = dataptr.bindMemory(to: T.self, capacity: shape2size(shapeptr))
            for flat in FlattenIndSequence(shapeptr: shapeptr, stridesptr: stridesptr){
                _stats_run(srcptr.baseAddress! + flat.flattenIndex, dstptr, vDSP_func: vDSP_func, stride: stride, count)
                dstptr += 1
                //print(flat.flattenIndex, flat.indices)
            }
        }
        
        //row major order because FlattenIndSequence count up for row major
        let newstridesptr = shape2strides(shapeptr, mforder: .Row)
        //move
        stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: retndim)
        //free
        newstridesptr.deallocate()
    }

    return ret
}

// for all elements
internal func stats_all_by_vDSP<T: MfStorable>(_ mfarray: MfArray, vDSP_func: vDSP_stats_func<T>) -> MfArray{
    var dst = T.zero
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        _stats_run($0.baseAddress!, &dst, vDSP_func: vDSP_func, stride: 1, mfarray.size)
    }
    
    return MfArray([dst], mftype: mfarray.mftype)
}


internal typealias vDSP_stats_index_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length) -> Void

fileprivate func _stats_index_run<T: MfStorable>(_ srcptr: UnsafePointer<T>, vDSP_func: vDSP_stats_index_func<T>, stride: Int32, _ count: Int) -> Int32{
    var ret = vDSP_Length(0)
    var tmpdst = T.zero
    vDSP_func(srcptr, vDSP_Stride(stride), &tmpdst, &ret, vDSP_Length(count))

    return Int32(ret)
}

//for along given axis
internal func stats_index_axis_by_vDSP<T: MfStorable>(_ mfarray: MfArray, axis: Int, vDSP_func: vDSP_stats_index_func<T>, vDSP_conv_func: vDSP_convert_func<Int32, T>) -> MfArray{
    var retShape = mfarray.shape
    let count = retShape.remove(at: axis)
    var retStrides = mfarray.strides
    //remove and get stride at given axis
    let stride = Int32(retStrides.remove(at: axis))
    
    
    let retndim = retShape.count

    let ret = withDummy(mftype: MfType.Int, storedSize: mfarray.storedSize, ndim: retndim){
        dataptr, shapeptr, stridesptr in

        //move
        shapeptr.baseAddress!.moveAssign(from: &retShape, count: retndim)
        
        //move
        stridesptr.baseAddress!.moveAssign(from: &retStrides, count: retndim)
        
        let retsize = shape2size(shapeptr)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            srcptr in

            var i32array = Array<Int32>(repeating: 0, count: retsize)
            //let srcptr = stride >= 0 ? srcptr.baseAddress! : srcptr.baseAddress! - mfarray.offsetIndex
            let srcptr = srcptr.baseAddress!
            for (i, flat) in FlattenIndSequence(shapeptr: shapeptr, stridesptr: stridesptr).enumerated(){
                i32array[i] = _stats_index_run(srcptr + flat.flattenIndex, vDSP_func: vDSP_func, stride: stride, count) / stride
                //print(flat.flattenIndex, flat.indices)
            }
            
            let dstptr = dataptr.bindMemory(to: T.self, capacity: retsize)
            //convert dataptr(int) to float
            i32array.withUnsafeBufferPointer{
                unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptr, vDSP_conv_func, retsize)
            }
            
        }
        
        
        //row major order because FlattenIndSequence count up for row major
        let newstridesptr = shape2strides(shapeptr, mforder: .Row)
        //move
        stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: retndim)
        //free
        newstridesptr.deallocate()
    }

    return ret
}

// for all elements
internal func stats_index_all_by_vDSP<T: MfStorable>(_ mfarray: MfArray, vDSP_func: vDSP_stats_index_func<T>) -> MfArray{

    let dst = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        Int(_stats_index_run($0.baseAddress!, vDSP_func: vDSP_func, stride: 1, mfarray.size))
    }
    
    return MfArray([dst])
}


