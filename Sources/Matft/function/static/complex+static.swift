//
//  complex+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/18.
//

import Foundation
import Accelerate

extension Matft.complex{
    
    /**
       Return the angle of the complex argument
       - parameters:
           - mfarray:  mfarray
    */
    public static func angle(_ mfarray: MfArray) -> MfArray{
        let src_mfarray: MfArray
        if mfarray.isReal{
            src_mfarray = mfarray.to_complex(false)
        }
        else{
            src_mfarray = mfarray
        }
        
        switch src_mfarray.storedType{
        case .Float:
            let ret = zvphas_by_vDSP(src_mfarray, vDSP_zvphas)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = zvphas_by_vDSP(src_mfarray, vDSP_zvphasD)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    
    
}
