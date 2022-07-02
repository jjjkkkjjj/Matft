//
//  image+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/02.
//

import Foundation
import Accelerate
import CoreGraphics

extension Matft.image{
    
    /**
       Convert mfarray into CGImage
       - parameters:
            - mfarray: An input mfarray
       - Returns: CGImage
    */
    public static func mfarray2cgimage(_ mfarray: MfArray) -> CGImage{
        switch mfarray.storedType{
        case .Float:
            return mfarray2cgimage_by_vDSP(mfarray, vDSP_func: vDSP_vfixu8)
        case .Double:
            return mfarray2cgimage_by_vDSP(mfarray, vDSP_func: vDSP_vfixu8D)
        }
    }
    
    /**
       Convert CGImage into mfarray.
       - parameters:
            - cgimage: An input cgimage
       - Returns: MfArray
    */
    public static func cgimage2mfarray(_ cgimage: CGImage) -> MfArray{
        return cgimage2mfarray_by_vDSP(cgimage, mftype: .UInt8, vDSP_func: vDSP_vfltu8)
    }
}
