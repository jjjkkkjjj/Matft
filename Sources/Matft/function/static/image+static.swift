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
       Convert color space
       - parameters:
            - image: An image mfarray
            - conversion: The conversion type.
            - exclude_alpha: (Optional) Whether to exclude alpha channel, by default true.
       - Returns: MfArray
    */
    public static func color(_ image: MfArray, conversion: MfColorConversion = .RGBA2GRAY, exclude_alpha: Bool = true) -> MfArray{
        unsupport_complex(image)
        unsupport_imagetype(image)
        
        let background: [Float]? = exclude_alpha ? nil : [1, 1, 1]
        
        switch conversion{
        case .RGBA2GRAY:
            return c4toc1_by_vImage(image, pre_bias: [0, 0, 0, 0], coef: [0.299, 0.587, 0.114, 0], post_bias: 0, background: background)
        case .RGBA2RGB:
            return rgba2rgb_image(image, isCopy: true, keepAlpha: false, background: [1, 1, 1])
        case .RGB2RGBA:
            return rgb2rgba_image(image)
        }
    }
    
    /**
       Resize image
       - parameters:
            - image: An image mfarray
            - width: The new width
            - height: The new height
       - Returns: MfArray
    */
    public static func resize(_ image: MfArray, width: Int, height: Int) -> MfArray{
        unsupport_complex(image)
        unsupport_imagetype(image)
        precondition(0 < width && 0 < height, "New size must be positive")
        
        return resize_by_vImage(image, dstWidth: width, dstHeight: height)
    }
    
    /**
       Resize image
       - parameters:
            - image: An image mfarray
            - factor_x: The factor of x
            - factor_y: The factor of y
       - Returns: MfArray
    */
    public static func resize(_ image: MfArray, factor_x: Float, factor_y: Float) -> MfArray{
        precondition(0 < factor_x && 0 < factor_y, "New size must be positive")
        
        let height = Float(image.shape[0])
        let width = Float(image.shape[1])
        
        return resize_by_vImage(image, dstWidth: Int(width*factor_x), dstHeight: Int(height*factor_y))
    }
    
    /**
       Apply affine  transformation
       - parameters:
            - image: An image mfarray
            - matrix: The transform matrix (shape=(2,3))
            - width: The destination width
            - height: The destination height
            - mode: The pixel extrapolation mode
            - borderValue: The border value. Count must be 1 or 4
       - Returns: MfArray
    */
    public static func warpAffine(_ image: MfArray, matrix: MfArray, width: Int, height: Int, mode: MfAffineMode = .ColorFill, borderValue: [Float] = [0]) -> MfArray{
        var borderValue = borderValue
        if borderValue.count == 1{
            borderValue = Array(repeating: borderValue[0], count: 4)
        }
        precondition(borderValue.count == 4, "borderValue must have 1 or 4 element")
        
        return affine_by_vImage(image, dstHeight: height, dstWidth: width, matrix: matrix, mode: mode, borderValue: borderValue)
    }
}


