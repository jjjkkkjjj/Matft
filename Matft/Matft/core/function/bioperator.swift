//
//  bioperator.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray{
    public static func add(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _binary_operation(l_mfarray, r_mfarray, .add)
    }
}

fileprivate enum BiOp{
    case add
    case sub
    case mul
    case div
    case indot
    case outdot
}

fileprivate func _binary_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ biop: BiOp) -> MfArray{
    //precondition(l_mfarray.mftype == r_mfarray.mftype, "Two mfarray must be same mftype. but two mfarray having unsame mftype will be able to be calclulated in the future")
    
    
    var bigger_mfarray = l_mfarray
    var smaller_mfarray = r_mfarray
    if l_mfarray.storedSize < r_mfarray.storedSize{
        bigger_mfarray = r_mfarray
        smaller_mfarray = l_mfarray
    }
    
    if bigger_mfarray.mftype != smaller_mfarray.mftype{
        smaller_mfarray = smaller_mfarray.astype(bigger_mfarray.mftype)
    }
    
    if bigger_mfarray.shape != smaller_mfarray.shape{ // broadcast to bigger_mfarray
        do{
            smaller_mfarray = try smaller_mfarray.broadcast_to(shape: bigger_mfarray.shape)
        }catch {//conversion error
            fatalError("cannot calculate binary operation due to broadcasting error")
        }
    }
    
    let calctype = bigger_mfarray.mftype
    switch biop {
    case .add:
        switch MfType.storedType(calctype){
        case .Float:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vadd)
        case .Double:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vaddD)
        }
    default:
        fatalError()
        /*
    case .sub:
        
    case .mul:
        
    case .div:
        
    case .indot:
        
    case .outdot:*/
    }
}
