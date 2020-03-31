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
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    if !(mfarray.mfflags.column_contiguous || mfarray.mfflags.row_contiguous){//neither row nor column contiguous, close to row major
        mfarray = to_row_major(mfarray)
    }
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            [unowned mfarray] in
            vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

//binary vector to scalar operation
internal typealias vDSP_biop_vs_func<T: MfStorable> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void
fileprivate func _run_biop_vs<T: MfStorable>(_ srcptr: UnsafePointer<T>, _ scalar: T, _ dstptr: UnsafeMutablePointer<T>, _ count: Int, _ vDSP_func: vDSP_biop_vs_func<T>){
    var scalar = scalar
    vDSP_func(srcptr, vDSP_Stride(1), &scalar, dstptr, vDSP_Stride(1), vDSP_Length(count))
}
/*
internal func biop_vs_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_scalar: T, vDSP_func: vDSP_biop_vs_func<T>) -> MfArray{
    
    
}*/
//binary scalar to vector operation
internal typealias vDSP_biop_sv_func<T: MfStorable> = (UnsafePointer<T>, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void
fileprivate func _run_biop_sv<T: MfStorable>(_ scalar: T, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ count: Int, _ vDSP_func: vDSP_biop_sv_func<T>){
    var scalar = scalar
    vDSP_func(&scalar, srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}

//binary vector to vector operation
internal typealias vDSP_biop_vv_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

fileprivate func _run_biop_vv<T: MfStorable>(lptr: UnsafePointer<T>, _ lstride: Int, rptr: UnsafePointer<T>, _ rstride: Int, dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_vv_func<T>){
    vDSP_func(rptr, vDSP_Stride(rstride), lptr, vDSP_Stride(lstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_vv_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_biop_vv_func<T>) -> MfArray{
    let biggerL: Bool // flag whether l is bigger than r
    let retstoredSize: Int
    var l_mfarray = l_mfarray
    //return mfarray must be either row or column major
    if r_mfarray.mfflags.column_contiguous || r_mfarray.mfflags.row_contiguous{
        biggerL = false
        retstoredSize = r_mfarray.storedSize
    }
    else if l_mfarray.mfflags.column_contiguous || l_mfarray.mfflags.row_contiguous{
        biggerL = true
        retstoredSize = l_mfarray.storedSize
    }
    else{
        l_mfarray = Matft.mfarray.conv_order(l_mfarray, mforder: .Row)
        biggerL = true
        retstoredSize = l_mfarray.storedSize
    }
    
    
    let newdata = withDummyDataMRPtr(l_mfarray.mftype, storedSize: retstoredSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: retstoredSize)
        
        l_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            [unowned l_mfarray] (lptr) in
            r_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
                [unowned r_mfarray] (rptr) in
                //print(l_mfarray, r_mfarray)
                //print(l_mfarray.storedSize, r_mfarray.storedSize)
                //print(biggerL)
                if biggerL{// l is bigger
                    for vDSPPrams in OptOffsetParams(bigger_mfarray: l_mfarray, smaller_mfarray: r_mfarray){
                        /*
                        let bptr = bptr.baseAddress! + vDSPPrams.b_offset
                        let sptr = sptr.baseAddress! + vDSPPrams.s_offset
                        dstptrT = dstptrT + vDSPPrams.b_offset*/
                        _run_biop_vv(lptr: lptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr: rptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptr: dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
                        //print(vDSPPrams.blocksize, vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                    }
                }
                else{// r is bigger
                    for vDSPPrams in OptOffsetParams(bigger_mfarray: r_mfarray, smaller_mfarray: l_mfarray){
                        _run_biop_vv(lptr: lptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, rptr: rptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, dstptr: dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
                        //print(vDSPPrams.blocksize, vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                    }
                }
            }
        }
    }

    let newmfstructure = copy_mfstructure(biggerL ? l_mfarray.mfstructure : r_mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
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
        [unowned mfarray] in
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
internal func stats_index_axis_by_vDSP<T: MfStorable>(_ mfarray: MfArray, axis: Int, vDSP_func: vDSP_stats_index_func<T>) -> MfArray{
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
            
            let dstptr = dataptr.bindMemory(to: Float.self, capacity: retsize)
            //convert dataptr(int) to float
            i32array.withUnsafeBufferPointer{
                unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptr, vDSP_vflt32, retsize)
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
        [unowned mfarray] in
        Int(_stats_index_run($0.baseAddress!, vDSP_func: vDSP_func, stride: 1, mfarray.size))
    }
    
    return MfArray([dst])
}


// generate(arange)
/*
internal typealias vDSP_arange_func<T> = (UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

fileprivate func _arange_run<T: MfStorable>(_ startptr: UnsafePointer<T>, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ stride: Int, _ count: Int, _ vDSP_func: vDSP_arange_func<T>){
    vDSP_func(startptr, srcptr, dstptr, vDSP_Stride(stride), vDSP_Length(count))
}

internal func arange_by_vDSP<T: MfStorable>(_ start: T, _ by: T, _ count: Int, _ mftype: MfType, vDSP_func: vDSP_arange_func<T>) -> MfArray{
    let newdata = withDummyDataMRPtr(mftype, storedSize: count){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: count)
        var start = start
        var by = by
        _arange_run(&start, &by, dstptrT, 1, count, vDSP_func)
    }
    
    let newmfstructure = withDummyShapeStridesMBPtr(retShape.count){
        shapeptr, stridesptr in
        retShape.withUnsafeMutableBufferPointer{
            shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: shapeptr.count)
        }
        
        let newstrides = shape2strides(shapeptr, mforder: .Row)
        stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: shapeptr.count)
        
        newstrides.deallocate()
    }
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
*/
