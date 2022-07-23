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
        unsupport_imagetype(mfarray)
        
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
    
    /**
       Convert RGBA into Gray.
       - parameters:
            - image: An image mfarray
            - exclude_alpha: (Optional) Whether to exclude alpha channel, by default true.
       - Returns: MfArray
    */
    public static func toGray(_ image: MfArray, exclude_alpha: Bool = true) -> MfArray{
        unsupport_complex(image)
        unsupport_imagetype(image)
        
        let background: [Float]? = exclude_alpha ? nil : [1, 1, 1]
        
        return c4toc1_by_vImage(image, pre_bias: [0, 0, 0, 0], coef: [0.299, 0.587, 0.114, 0], post_bias: 0, background: background)
    }
}

/// Check it is real or not. if the mfarray is complex, raise precondition failure.
/// - Parameters:
///     - mfarray: A source mfarray
@inline(__always)
fileprivate func unsupport_imagetype(_ image: MfArray){
    precondition(image.mftype == .UInt8 || image.mftype == .Float, "Supported types are UInt8 or Float only, but got \(image.mftype)")
}
