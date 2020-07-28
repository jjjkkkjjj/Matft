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
// same above
fileprivate func _run_preop<T: MfTypable, U: MfTypable>(_ srcptr: UnsafePointer<T>,  _ dstptr: UnsafeMutablePointer<U>, _ count: Int, _ vDSP_func: vDSP_convert_func<T, U>){
    vDSP_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}
internal func preop_by_vDSP<T: MfTypable, U: MfStorable, V: MfTypable>(_ mfarray: MfArray<T>, _ vDSP_func: vDSP_convert_func<U, U>) -> MfArray<V>{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_contiguous(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = withDummyDataMRPtr(V.self, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: U.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned mfarray] in
            _run_preop($0.baseAddress!, dstptrT, mfarray.storedSize, vDSP_func)
            //vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
// same above
internal func math_by_vDSP<T: MfTypable, U: MfStorable, V: MfTypable>(_ mfarray: MfArray<T>, _ vDSP_func: vDSP_convert_func<U, U>) -> MfArray<V>{
    return preop_by_vDSP(mfarray, vDSP_func)
}

//binary vector to scalar operation
internal typealias vDSP_biop_vs_func<T: MfStorable> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void
fileprivate func _run_biop_vs<T: MfStorable>(_ srcptr: UnsafePointer<T>, _ scalar: T, _ dstptr: UnsafeMutablePointer<T>, _ count: Int, _ vDSP_func: vDSP_biop_vs_func<T>){
    var scalar = scalar
    vDSP_func(srcptr, vDSP_Stride(1), &scalar, dstptr, vDSP_Stride(1), vDSP_Length(count))
}

internal func biop_vs_by_vDSP<T: MfTypable, U: MfStorable>(_ l_mfarray: MfArray<T>, _ r_scalar: U, _ vDSP_func: vDSP_biop_vs_func<U>) -> MfArray<T>{
    var mfarray = l_mfarray

    mfarray = check_contiguous(mfarray)
    
    let newdata = withDummyDataMRPtr(T.self, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: U.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned mfarray] in
            _run_biop_vs($0.baseAddress!, r_scalar, dstptrT, mfarray.storedSize, vDSP_func)
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

//binary scalar to vector operation
internal typealias vDSP_biop_sv_func<T: MfStorable> = (UnsafePointer<T>, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void
fileprivate func _run_biop_sv<T: MfStorable>(_ scalar: T, _ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, _ count: Int, _ vDSP_func: vDSP_biop_sv_func<T>){
    var scalar = scalar
    vDSP_func(&scalar, srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}

internal func biop_sv_by_vDSP<T: MfTypable, U: MfStorable>(_ l_scalar: U, _ r_mfarray: MfArray<T>, _ vDSP_func: vDSP_biop_sv_func<U>) -> MfArray<T>{
    var mfarray = r_mfarray

    mfarray = check_contiguous(mfarray)
    
    
    let newdata = withDummyDataMRPtr(T.self, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: U.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned mfarray] in
            _run_biop_sv(l_scalar, $0.baseAddress!, dstptrT, mfarray.storedSize, vDSP_func)
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

//binary vector to vector operation
internal typealias vDSP_biop_vv_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

fileprivate func _run_biop_vv<T: MfStorable>(lptr: UnsafePointer<T>, _ lstride: Int, rptr: UnsafePointer<T>, _ rstride: Int, dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_vv_func<T>){
    vDSP_func(rptr, vDSP_Stride(rstride), lptr, vDSP_Stride(lstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_vv_by_vDSP<T: MfTypable, U: MfStorable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, vDSP_func: vDSP_biop_vv_func<U>) -> MfArray<T>{
    // biggerL: flag whether l is bigger than r
    //return mfarray must be either row or column major
    let (l_mfarray, r_mfarray, biggerL, retstoredSize) = check_biop_contiguous(l_mfarray, r_mfarray, .Row, convertL: true)
    
    
    let newdata = withDummyDataMRPtr(T.self, storedSize: retstoredSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: U.self, capacity: retstoredSize)
        
        l_mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned l_mfarray] (lptr) in
            r_mfarray.withDataUnsafeMBPtrT(datatype: U.self){
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
fileprivate func _run_stats<T: MfStorable>(_ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, vDSP_func: vDSP_stats_func<T>, stride: Int, _ count: Int){
    
    vDSP_func(srcptr, vDSP_Stride(stride), dstptr, vDSP_Length(count))
}

// for along given axis
internal func stats_axis_by_vDSP<T: MfTypable, U: MfStorable, V: MfTypable>(_ mfarray: MfArray<T>, axis: Int, vDSP_func: vDSP_stats_func<U>) -> MfArray<V>{
    let mfarray = check_contiguous(mfarray)

    var retShape = mfarray.shape
    let count = retShape.remove(at: axis)
    var retStrides = mfarray.strides
    //remove and get stride at given axis
    let stride = retStrides.remove(at: axis)
    
    let retSize = shape2size(&retShape)
    let newmfdata = withDummyDataMRPtr(V.self, storedSize: retSize){
        dstptr in
        var dstptrU = dstptr.bindMemory(to: U.self, capacity: retSize)
        
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            srcptr in
            for flat in FlattenIndSequence(shape: &retShape, strides: &retStrides){
                _run_stats(srcptr.baseAddress! + flat.flattenIndex, dstptrU, vDSP_func: vDSP_func, stride: stride, count)
                dstptrU += 1
                //print(flat.flattenIndex, flat.indices)
            }
        }
    }
    
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)

    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

// for all elements
internal func stats_all_by_vDSP<T: MfTypable, U: MfStorable, V: MfTypable>(_ mfarray: MfArray<T>, vDSP_func: vDSP_stats_func<U>) -> MfArray<V>{
    let mfarray = check_contiguous(mfarray)

    var retShape = [1]
    let newmfdata = withDummyDataMRPtr(V.self, storedSize: 1){
        dstptr in
        let dstptrU = dstptr.bindMemory(to: U.self, capacity: 1)
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned mfarray](srcptr) in
            _run_stats(srcptr.baseAddress!, dstptrU, vDSP_func: vDSP_func, stride: 1, mfarray.size)
        }
    }
    
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}


internal typealias vDSP_stats_index_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length) -> Void

fileprivate func _run_stats_index<T: MfStorable>(_ srcptr: UnsafePointer<T>, vDSP_func: vDSP_stats_index_func<T>, stride: Int32, _ count: Int) -> Int32{
    var ret = vDSP_Length(0)
    var tmpdst = T.zero
    vDSP_func(srcptr, vDSP_Stride(stride), &tmpdst, &ret, vDSP_Length(count))

    return Int32(ret)
}

//for along given axis
internal func stats_index_axis_by_vDSP<T: MfTypable, U: MfStorable>(_ mfarray: MfArray<T>, axis: Int, vDSP_func: vDSP_stats_index_func<U>) -> MfArray<Int>{
    let mfarray = check_contiguous(mfarray)
    
    var retShape = mfarray.shape
    let count = retShape.remove(at: axis)
    var retStrides = mfarray.strides
    //remove and get stride at given axis
    let stride = Int32(retStrides.remove(at: axis))
    
    
    let retSize = shape2size(&retShape)
    let newmfdata = withDummyDataMRPtr(Int.self, storedSize: retSize){
        dstptr in
        let dstptrF = dstptr.bindMemory(to: Float.self, capacity: retSize)
        
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            srcptr in
            var i32array = Array<Int32>(repeating: 0, count: retSize)
            //let srcptr = stride >= 0 ? srcptr.baseAddress! : srcptr.baseAddress! - mfarray.offsetIndex
            let srcptr = srcptr.baseAddress!
            for (i, flat) in FlattenIndSequence(shape: &retShape, strides: &retStrides).enumerated(){
                i32array[i] = _run_stats_index(srcptr + flat.flattenIndex, vDSP_func: vDSP_func, stride: stride, count) / stride
                //print(flat.flattenIndex, flat.indices)
            }
            
            //convert dataptr(int) to float
            i32array.withUnsafeBufferPointer{
                unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptrF, vDSP_vflt32, retSize)
            }
        }
    }
    
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)

    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

// for all elements
internal func stats_index_all_by_vDSP<T: MfTypable, U: MfStorable>(_ mfarray: MfArray<T>, vDSP_func: vDSP_stats_index_func<U>) -> MfArray<Int>{
    let mfarray = check_contiguous(mfarray)
    
    let dst = mfarray.withDataUnsafeMBPtrT(datatype: U.self){
        [unowned mfarray] in
        Int(_run_stats_index($0.baseAddress!, vDSP_func: vDSP_func, stride: 1, mfarray.size))
    }
    
    return MfArray([dst])
}


// sort
internal typealias vDSP_sort_func<T> = (UnsafeMutablePointer<T>, vDSP_Length, Int32) -> Void
fileprivate func _run_sort<T: MfStorable>(_ srcdstptr: UnsafeMutablePointer<T>, count: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_func<T>){
    let order = Int32(order.rawValue)
    vDSP_func(srcdstptr, vDSP_Length(count), order)
}

internal func sort_by_vDSP<T: MfTypable, U: MfStorable>(_ mfarray: MfArray<T>, _ axis: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_func<U>) -> MfArray<T>{
    let retndim = mfarray.ndim
    let count = mfarray.shape[axis]
    
    let lastaxis = retndim - 1
    // move lastaxis and given axis and align order
    let srcdst_mfarray = mfarray.moveaxis(src: axis, dst: lastaxis).conv_order(mforder: .Row)

    var offset = 0
    
    srcdst_mfarray.withDataUnsafeMBPtrT(datatype: U.self){
        srcdstptr in
        for _ in 0..<mfarray.storedSize / count{
            _run_sort(srcdstptr.baseAddress! + offset, count: count, order, vDSP_func)
            offset += count
        }
    }
    
    // re-move axis and lastaxis
    return srcdst_mfarray.moveaxis(src: lastaxis, dst: axis)
}

internal typealias vDSP_sort_index_func<T> = (UnsafePointer<T>, UnsafeMutablePointer<vDSP_Length>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length, Int32) -> Void
fileprivate func _run_sort_index<T: MfStorable>(_ srcptr: UnsafeMutablePointer<T>, dstptr: UnsafeMutablePointer<UInt>, count: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_index_func<T>){
    let order = Int32(order.rawValue)
    var tmp = Array<vDSP_Length>(repeating: 0, count: count)
    vDSP_func(srcptr, dstptr, &tmp, vDSP_Length(count), order)
}

internal func sort_index_by_vDSP<T: MfTypable, U: MfStorable>(_ mfarray: MfArray<T>, _ axis: Int, _ order: MfSortOrder, _ vDSP_func: vDSP_sort_index_func<U>) -> MfArray<Int>{

    let count = mfarray.shape[axis]
    
    let lastaxis = mfarray.ndim - 1
    // move lastaxis and given axis and align order
    let srcmfarray = mfarray.moveaxis(src: axis, dst: lastaxis).conv_order(mforder: .Row)
    var retShape = srcmfarray.shape
    
    var offset = 0

    let retSize = shape2size(&retShape)
    let newmfdata = withDummyDataMRPtr(Int.self, storedSize: retSize){
        dstptr in
        let dstptrF = dstptr.bindMemory(to: Float.self, capacity: retSize)
        
        srcmfarray.withDataUnsafeMBPtrT(datatype: U.self){
            srcptr in
            
            for _ in 0..<mfarray.storedSize / count{
                var uiarray = Array<UInt>(stride(from: 0, to: UInt(count), by: 1))
                //let srcptr = stride >= 0 ? srcptr.baseAddress! : srcptr.baseAddress! - mfarray.offsetIndex
                
                _run_sort_index(srcptr.baseAddress! + offset, dstptr: &uiarray, count: count, order, vDSP_func)
                
                // TODO: refactor
                //convert dataptr(int) to float
                var flarray = uiarray.map{ Float($0) }
                flarray.withUnsafeMutableBufferPointer{
                    (dstptrF + offset).moveAssign(from: $0.baseAddress!, count: count)
                }
                
                offset += count
            }
            
        }
    }
    
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)
    
    let ret = MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
    
    // re-move axis and lastaxis
    return ret.moveaxis(src: lastaxis, dst: axis)
    
}

internal typealias vDSP_clip_func<T: MfStorable> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length, UnsafeMutablePointer<vDSP_Length>, UnsafeMutablePointer<vDSP_Length>) -> Void
fileprivate func _run_clip<T: MfStorable>(_ srcptr: UnsafePointer<T>, dstptr: UnsafeMutablePointer<T>, count: Int, _ min: T, _ max: T, _ vDSP_func: vDSP_clip_func<T>){
    var min = min
    var max = max
    
    var mincount = vDSP_Length(0)
    var maxcount = vDSP_Length(0)
    
    vDSP_func(srcptr, vDSP_Stride(1), &min, &max, dstptr, vDSP_Stride(1), vDSP_Length(count), &mincount, &maxcount)
}
internal func clip_by_vDSP<T: MfTypable, U: MfStorable>(_ mfarray: MfArray<T>, _ min: U, _ max: U, _ vDSP_func: vDSP_clip_func<U>) -> MfArray<T>{
    //return mfarray must be either row or column major
    var mfarray = mfarray
    //print(mfarray)
    mfarray = check_contiguous(mfarray)
    //print(mfarray)
    //print(mfarray.strides)
    
    let newdata = withDummyDataMRPtr(T.self, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrU = dstptr.bindMemory(to: U.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned mfarray] in
            _run_clip($0.baseAddress!, dstptr: dstptrU, count: mfarray.storedSize, min, max, vDSP_func)
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
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

internal typealias vDSP_vcmprs_func<T: MfStorable> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func boolget_by_vDSP<T: MfTypable, U:MfStorable>(_ mfarray: MfArray<T>, _ indices: MfArray<Bool>, _ vDSP_func: vDSP_vcmprs_func<U>) -> MfArray<T>{
    /*
     Note that returned shape must be (true number in original indices, (mfarray's shape - original indices' shape));
     i.e. returned dim = 1(=true number in original indices) + mfarray's dim - indices' dim
     */
    let true_num = Float.toInt(indices.sum().scalar!)
    let orig_ind_dim = indices.ndim
    
    // broadcast
    let indices = bool_broadcast_to(indices, shape: mfarray.shape)

    // must be row major
    let indicesU: MfArray<U> = check_contiguous(indices.astype(U.self), .Row)
    let mfarray = check_contiguous(mfarray, .Row)
    
    
    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    var retShape = [true_num] + lastShape
    let retSize = shape2size(&retShape)
    
    let newdata = withDummyDataMRPtr(T.self, storedSize: retSize){
        dstptr in
        let dstptrU = dstptr.bindMemory(to: U.self, capacity: retSize)
        
        indicesU.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned indicesU](indptr) in
            // note that indices and mfarray is row contiguous
            mfarray.withDataUnsafeMBPtrT(datatype: U.self){
                srcptr in
                vDSP_func(srcptr.baseAddress!, vDSP_Stride(1), indptr.baseAddress!, vDSP_Stride(1), dstptrU, vDSP_Stride(1), vDSP_Length(indicesU.size))
            }
        }
    }
    
    
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
