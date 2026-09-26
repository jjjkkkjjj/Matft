//
//  image+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/02.
//

#if canImport(Accelerate)
import Foundation
import Accelerate
import CoreGraphics

extension Matft.image{
    
    /**
       Converts an image mfarray into a `CGImage`.

       The input layout is `(height, width)` or `(height, width, 1)` for a grayscale image,
       or `(height, width, 4)` for an RGBA image. 3-channel (RGB) images are not supported;
       append an alpha channel first, e.g. with `cvtColor(_:code:)` and `.RGB2RGBA`.

       - UInt8 values are expected in `0...255` and are written as 8-bit components.
         An RGBA image is written with non-premultiplied alpha.
       - Float values are expected in `0...1` and are written as 32-bit float components.
         An RGBA image is written with premultiplied alpha.

       ```swift
       let rgba = Matft.image.cgimage2mfarray(cgimage, mftype: .UInt8) // (h, w, 4)
       let flipped = rgba[Matft.reverse]
       let newImage = Matft.image.mfarray2cgimage(flipped)
       ```

       - Parameters:
            - mfarray: An image mfarray whose mftype is UInt8 or Float.
       - Returns: A `CGImage` in the device gray or device RGB color space.
       - Precondition: The mftype must be UInt8 or Float, and the channel count must be 1 or 4.
    */
    public static func mfarray2cgimage(_ mfarray: MfArray) -> CGImage{
        unsupport_complex(mfarray)
        unsupport_imagetype(mfarray)
        
        return mfarray2cgimage_by_vDSP(mfarray, vDSP_func: vDSP_vfixu8)
    }
    
    /**
       Converts a `CGImage` into an image mfarray.

       The image is drawn into a CoreGraphics bitmap context, so the result is always row-major:

       - A grayscale (monochrome) image becomes `(height, width)`.
       - Any other color image becomes `(height, width, 4)` in RGBA order. The bitmap context uses
         premultiplied alpha, so the RGB values of semi-transparent pixels are premultiplied by alpha.

       With `.UInt8` the values are in `0...255`; with `.Float` (the default) they are in `0...1`.

       ```swift
       let rgba = Matft.image.cgimage2mfarray(cgimage, mftype: .UInt8)      // (h, w, 4), 0...255
       let rgb = rgba[Matft.all, Matft.all, 0~<3].to_contiguous(mforder: .Row) // (h, w, 3)
       ```

       - Parameters:
            - cgimage: An input `CGImage`.
            - mftype: The mftype of the returned mfarray, `.Float` (default) or `.UInt8`.
       - Returns: The image mfarray.
       - Precondition: `mftype` must be UInt8 or Float.
       - Note: Dimensions of size 1 are squeezed, so a 1-pixel-high or 1-pixel-wide image loses that axis.
    */
    public static func cgimage2mfarray(_ cgimage: CGImage, mftype: MfType = .Float) -> MfArray{
        return cgimage2mfarray_by_vDSP(cgimage, mftype: mftype, vDSP_func: vDSP_vfltu8)
    }
    
    /**
       Converts the color space of an image, with an option to composite alpha onto white.

       This is a thin wrapper of `cvtColor(_:code:)` (equivalent to `cv2.cvtColor`). The only difference
       is `exclude_alpha`: when it is `false` and `conversion` is `.RGBA2GRAY` or `.BGRA2GRAY`, the RGBA image
       is first composited onto a white background using its alpha channel, and then converted to gray.
       For the other conversions `exclude_alpha` is ignored.

       - Parameters:
            - image: An image mfarray (UInt8 in `0...255` or Float in `0...1`) whose layout matches `conversion`.
            - conversion: The conversion code, by default `.RGBA2GRAY`.
            - exclude_alpha: Whether to ignore the alpha channel for gray conversions, by default `true`.
              If `false`, transparent pixels become white.
       - Returns: The converted mfarray with the same mftype as the input.
       - Precondition: The mftype must be UInt8 or Float.
    */
    public static func color(_ image: MfArray, conversion: MfColorConversion = .RGBA2GRAY, exclude_alpha: Bool = true) -> MfArray{
        unsupport_complex(image)
        unsupport_imagetype(image)
        
        // composite on white background before conversion
        let image = (conversion == .RGBA2GRAY || conversion == .BGRA2GRAY) && !exclude_alpha ? rgba2rgb_image(image, keepAlpha: true, background: [1, 1, 1]) : image
        return Matft.image.cvtColor(image, code: conversion)
    }
    
    /**
       Resizes an image to the given width and height.

       Equivalent to `cv2.resize`. The input layout is `(height, width)` or `(height, width, channels)`
       and the output layout is `(height, width)` or `(height, width, channels)` respectively,
       with the same mftype as the input.

       - `.Lanczos` (default) uses vImage's high quality resampling. It is not the same as `cv2.INTER_LANCZOS4`.
       - `.Linear` and `.Nearest` follow `cv2.INTER_LINEAR` and `cv2.INTER_NEAREST` (pixel-center sampling,
         edges replicated). UInt8 results are rounded and saturated.

       To reproduce `PIL.Image.resize` exactly, use `resize(_:width:height:resample:)` instead.

       ```swift
       let small = Matft.image.resize(image, width: 300, height: 150, interpolation: .Linear)
       ```

       - Parameters:
            - image: An image mfarray (UInt8 or Float).
            - width: The destination width.
            - height: The destination height.
            - interpolation: The interpolation, by default `.Lanczos`.
       - Returns: The resized mfarray.
       - Precondition: The mftype must be UInt8 or Float, and `width` and `height` must be positive.
    */
    public static func resize(_ image: MfArray, width: Int, height: Int, interpolation: MfInterpolation = .Lanczos) -> MfArray{
        unsupport_complex(image)
        unsupport_imagetype(image)
        precondition(0 < width && 0 < height, "New size must be positive")

        switch interpolation{
        case .Lanczos:
            return resize_by_vImage(image, dstWidth: width, dstHeight: height)
        case .Linear, .Nearest:
            return resize_by_remap(image, dstWidth: width, dstHeight: height, interpolation: interpolation)
        }
    }

    /**
       Resizes an image by scale factors.

       Equivalent to `cv2.resize` with `dsize=None, fx=factor_x, fy=factor_y`. The destination size is
       `Int(width * factor_x)` by `Int(height * factor_y)`, i.e. truncated toward zero (OpenCV rounds it).
       See `resize(_:width:height:interpolation:)` for the details.

       - Parameters:
            - image: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - factor_x: The scale factor along the horizontal (width) axis.
            - factor_y: The scale factor along the vertical (height) axis.
            - interpolation: The interpolation, by default `.Lanczos`.
       - Returns: The resized mfarray with the same mftype as the input.
       - Precondition: Both factors must be positive and the resulting size must be at least 1 pixel.
    */
    public static func resize(_ image: MfArray, factor_x: Float, factor_y: Float, interpolation: MfInterpolation = .Lanczos) -> MfArray{
        precondition(0 < factor_x && 0 < factor_y, "New size must be positive")

        let height = Float(image.shape[0])
        let width = Float(image.shape[1])

        return Matft.image.resize(image, width: Int(width*factor_x), height: Int(height*factor_y), interpolation: interpolation)
    }
    
    /**
       Applies an affine transformation to an image.

       Equivalent to `cv2.warpAffine`: `dst(x', y') = src(x, y)` where `(x', y') = matrix * (x, y, 1)`.
       The origin is the top-left pixel and the y axis points down, as in OpenCV, so a matrix from
       `getRotationMatrix2D(center:angle:scale:)` or `getAffineTransform(src:dst:)` can be passed directly.

       The input layout is `(height, width)` or `(height, width, channels)`, and the output has the same
       number of channels and mftype. The transformation is computed by vImage, so the interpolation differs
       slightly from OpenCV's `INTER_LINEAR`, especially along the edges.

       - Parameters:
            - image: An image mfarray (UInt8 or Float).
            - matrix: The `(2, 3)` affine matrix mapping source coordinates into destination coordinates.
            - width: The destination width.
            - height: The destination height.
            - mode: How to fill the pixels mapped from outside the source, by default `.ColorFill` (fill with
              `borderValue`). `.EdgeExtend` is vImage's edge extension, so it may differ from `cv2.BORDER_REPLICATE`.
            - borderValue: The fill value for `.ColorFill`, by default `[0]`. Pass one value for all channels
              or 4 values (one per channel).
       - Returns: The transformed mfarray of `(height, width)` or `(height, width, channels)`.
       - Precondition: The mftype must be UInt8 or Float, `matrix` must be `(2, 3)`, the size must be positive,
         and `borderValue` must have 1 or 4 elements.
       - Note: Since v0.3.3 the matrix has the same meaning as OpenCV's one. Earlier versions swapped the
         off-diagonal elements and used a bottom-left origin.
    */
    public static func warpAffine(_ image: MfArray, matrix: MfArray, width: Int, height: Int, mode: MfAffineMode = .ColorFill, borderValue: [Float] = [0]) -> MfArray{
        var borderValue = borderValue
        if borderValue.count == 1{
            borderValue = Array(repeating: borderValue[0], count: 4)
        }
        precondition(borderValue.count == 4, "borderValue must have 1 or 4 element")
        unsupport_complex(image)
        unsupport_imagetype(image)
        precondition(0 < width && 0 < height, "New size must be positive")

        return affine_by_vImage(image, dstHeight: height, dstWidth: width, matrix: matrix, mode: mode, borderValue: borderValue)
    }
}


#endif
