//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation
import Accelerate

internal func to_Bool(_ mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray{
    //convert float and contiguous
    let ret = mfarray.astype(.Float)
    // TODO: use vDSP_vthr?
    switch ret.storedType {
    case .Float:
        ret.withDataUnsafeMBPtrT(datatype: Float.self){
            [unowned ret] (dataptr) in
            var newptr = dataptr.map{ abs($0) <= thresholdF ? Float.zero : Float(1) }
            newptr.withUnsafeMutableBufferPointer{
                dataptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: ret.storedSize)
            }
        }
    case .Double:
        fatalError("Bug was occurred. Bool's storedType is not double.")
    }
    
    ret.mfdata._mftype = .Bool
    return ret
}

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
