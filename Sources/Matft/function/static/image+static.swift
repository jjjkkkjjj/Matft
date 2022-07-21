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
        unsupport_complex(mfarray)
        return mfarray2cgimage_by_vDSP(mfarray, vDSP_func: vDSP_vfixu8)
    }
    
    /**
       Convert CGImage into mfarray.
       - parameters:
            - cgimage: An input cgimage
            - mftype: (Optional) mftype, by default float. Note, mftype must be UInt8 or Float only.
       - Returns: MfArray
    */
    public static func cgimage2mfarray(_ cgimage: CGImage, mftype: MfType = .Float) -> MfArray{
        return cgimage2mfarray_by_vDSP(cgimage, mftype: mftype, vDSP_func: vDSP_vfltu8)
    }
}
