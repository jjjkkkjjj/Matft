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
