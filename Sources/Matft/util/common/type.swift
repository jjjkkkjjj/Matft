//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation
import Accelerate

internal func to_Bool<T: MfTypable>(_ mfarray: MfArray<T>, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray<Bool>{
    
    let ret = mfarray.astype(Float.self)
    let retsize = ret.size
    let newmfdata = withDummyDataMRPtr(Bool.self, storedSize: retsize){
        (dataptr) in
        
        let dataptrF = dataptr.bindMemory(to: Float.self, capacity: retsize)
        ret.withDataUnsafeMBPtrT(datatype: Float.self){
            srcptr in
            // TODO: use vDSP_vthr?
            var newptr = srcptr.map{ abs($0) <= thresholdF ? Float.zero : Float(1) }
            newptr.withUnsafeMutableBufferPointer{
                dataptrF.moveAssign(from: $0.baseAddress!, count: retsize)
            }
        }
        
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

internal func to_NotBool<T: MfTypable>(_ mfarray: MfArray<T>, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray<Bool>{
    
    let ret = mfarray.astype(Float.self)
    let retsize = ret.size
    let newmfdata = withDummyDataMRPtr(Bool.self, storedSize: retsize){
        (dataptr) in
        
        let dataptrF = dataptr.bindMemory(to: Float.self, capacity: retsize)
        ret.withDataUnsafeMBPtrT(datatype: Float.self){
            srcptr in
            // TODO: use vDSP_vthr?
            var newptr = srcptr.map{ abs($0) > thresholdF ? Float.zero : Float(1) }
            newptr.withUnsafeMutableBufferPointer{
                dataptrF.moveAssign(from: $0.baseAddress!, count: retsize)
            }
        }
        
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    
    return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
}

/**
   - Important: this function creates copy bool mfarray, not view!
 */
internal func bool_broadcast_to(_ mfarray: MfArray<Bool>, shape: [Int]) -> MfArray<Bool>{
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
    
    let newdata = withDummyDataMRPtr(Bool.self, storedSize: retSize){
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
