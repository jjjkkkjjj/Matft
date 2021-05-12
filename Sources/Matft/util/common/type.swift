//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation
import Accelerate

internal func to_Bool(_ mfarray: MfArray) -> MfArray{

    // TODO: use vDSP_vthr?
    switch mfarray.storedType {
    case .Float:
        let ret = toBool_by_vDSP(mfarray, vDSP_vminmg_func: vDSP_vminmg, vDSP_viclip_func: vDSP_viclip, vDSP_convert_func: vDSP_vfixu8)
        return ret
    case .Double:
        let ret = toBool_by_vDSP(mfarray, vDSP_vminmg_func: vDSP_vminmgD, vDSP_viclip_func: vDSP_viclipD, vDSP_convert_func: vDSP_vfixu8D)
        return ret
    }
}
/*
internal func to_Bool_mm_op<U: MfStorable>(l_mfarray: MfArray, r_mfarray: MfArray, op: (U, U) -> Bool) -> MfArray{
    assert(l_mfarray.shape == r_mfarray.shape, "call biop_broadcast_to first!")
    var retShape = l_mfarray.shape
    var i = 0
    let newdata = withDummyDataMRPtr(.Bool, storedSize: l_mfarray.size){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: Float.self, capacity: l_mfarray.size)
        withDataMBPtr_multi(datatype: U.self, l_mfarray, r_mfarray){
            lptr, rptr in
            var val = op(lptr.baseAddress!.pointee, rptr.baseAddress!.pointee) ? Float(1) : Float.zero
            (dstptrT + i).assign(from: &val, count: 1)
            i += 1
        }
    }
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
internal func to_Bool_ms_op<U: MfStorable>(l_mfarray: MfArray, r_scalar: U, op: (U, U) -> Bool) -> MfArray{
    let r_scalar = Float.from(r_scalar)
    let ret = l_mfarray.astype(.Float)
    ret.withDataUnsafeMBPtrT(datatype: Float.self){
        [unowned ret] (dataptr) in
        var newptr = dataptr.map{ $0 > r_scalar ? Float.zero : Float(1) }
        newptr.withUnsafeMutableBufferPointer{
            dataptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: ret.storedSize)
        }
    }
    ret.mfdata._mftype = .Bool
    return ret
}
internal func to_Bool_sm_op<U: MfStorable>(l_scalar: U, r_mfarray: MfArray, op: (U, U) -> Bool) -> MfArray{
    var retShape = r_mfarray.shape
    var i = 0
    let newdata = withDummyDataMRPtr(.Bool, storedSize: r_mfarray.size){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: Float.self, capacity: r_mfarray.size)
        r_mfarray.withContiguousDataUnsafeMPtrT(datatype: U.self){
            rptr in
            var val = op(l_scalar, rptr.pointee) ? Float(1) : Float.zero
            (dstptrT + i).assign(from: &val, count: 1)
            i += 1
        }
    }
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
*/
/**
   - Important: this function creates copy bool mfarray, not view!
 */
internal func bool_broadcast_to(_ mfarray: MfArray, shape: [Int]) -> MfArray{
    assert(mfarray.mftype == .Bool, "must be bool")
    var mfarray = mfarray
    
    let origSize = mfarray.size
    
    let new_ndim = shape.count
    var retShape = shape
    let retSize = shape2size(&retShape)
    
    
    let idim_start = new_ndim  - mfarray.ndim
    
    precondition(idim_start >= 0, "can't broadcast to fewer dimensions")
    
    // broadcast for common part's shape
    let commonShape = Array(shape[0..<mfarray.ndim])
    mfarray = mfarray.broadcast_to(shape: commonShape)
    
    // convert row contiguous
    let rowc_mfarray = check_contiguous(mfarray, .Row)

    if idim_start == 0{
        return rowc_mfarray
    }
    var newerShape = Array(shape[mfarray.ndim..<new_ndim])
    let offset = shape2size(&newerShape)
    
    let newdata = withDummyDataMRPtr(.Bool, storedSize: retSize){
        var dstptrF = $0.bindMemory(to: Float.self, capacity: retSize)
        
        rowc_mfarray.withDataUnsafeMBPtrT(datatype: Float.self){
            srcptr in
            for i in 0..<origSize{
                dstptrF.assign(repeating: (srcptr.baseAddress! + i).pointee, count: offset)
                dstptrF += offset
            }
        }
        
    }
    let newmfstructure = create_mfstructure(&retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

internal func boolean2float(_ mfarray: MfArray) -> MfArray{
    if mfarray.mftype == .Bool{
        mfarray.mfdata._mftype = .Float
    }
    return mfarray
}
