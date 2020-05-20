//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation
import Accelerate

internal func to_Bool(_ mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray{
    
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
