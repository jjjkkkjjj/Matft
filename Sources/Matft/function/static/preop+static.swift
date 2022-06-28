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
    public static func neg(_ mfarray: MfArray) -> MfArray{
        return _prefix_operation(mfarray, .neg)
    }
    
    /**
       Element-wise Not mfarray. Returned mfarray will be bool
       - parameters:
           - mfarray: mfarray
    */
    public static func logical_not(_ mfarray: MfArray) -> MfArray{
        var ret = to_Bool(mfarray)// copy and convert to bool
        ret = Matft.math.abs(ret - 1) // force cast to Float
        ret.mfdata._mftype = .Bool
        return ret
    }
}

fileprivate enum PreOp{
    case neg
}

fileprivate func _prefix_operation(_ mfarray: MfArray, _ preop: PreOp) -> MfArray{
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
