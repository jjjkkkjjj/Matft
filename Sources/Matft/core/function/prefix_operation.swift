//
//  File 2.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation
import Accelerate

extension Matft{
    /**
       Element-wise negativity
       - parameters:
           - mfarray: mfarray
    */
    public static func neg<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        return _prefix_operation(mfarray, .neg)
    }
    
    /**
       Element-wise Not mfarray. Returned mfarray will be bool
       - parameters:
           - mfarray: mfarray
    */
    public static func logical_not<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<Bool>{
        return to_NotBool(mfarray)
    }
}

fileprivate enum PreOp{
    case neg
}

fileprivate func _prefix_operation<T: MfTypable>(_ mfarray: MfArray<T>, _ preop: PreOp) -> MfArray<T>{
    switch preop {
    case .neg:
        switch mfarray.storedType{
        case .Float:
            return preop_by_vDSP(mfarray, vDSP_vneg)
        case .Double:
            return preop_by_vDSP(mfarray, vDSP_vnegD)
        }
    }
}
