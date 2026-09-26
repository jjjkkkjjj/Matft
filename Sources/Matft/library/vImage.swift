//
//  vImage.swift
//
//
//  Created by Junnosuke Kado on 2022/07/23.
//

import Foundation
#if canImport(Accelerate)
import Accelerate

internal typealias vImage_resize_func = (UnsafePointer<vImage_Buffer>, UnsafePointer<vImage_Buffer>, UnsafeMutableRawPointer?, vImage_Flags) -> vImage_Error

internal typealias vImage_affine_func<T> = (UnsafePointer<vImage_Buffer>, UnsafePointer<vImage_Buffer>, UnsafeMutableRawPointer?, UnsafePointer<vImage_AffineTransform>, UnsafePointer<T>?, vImage_Flags) -> vImage_Error

/// The function applied to a Float image buffer
/// - Parameters:
///   - srcptr: A source pointer
///   - dstptr: A destination pointer
///   - srcHeight: The source height
///   - srcWidth: The source width
///   - dstHeight: The destination height
///   - dstWidth: The destination width
///   - channel: The channel number of the buffer (1: PlanarF, 4: ARGBFFFF)
///   - plane: The channel index of the plane for PlanarF, 0 for ARGBFFFF
internal typealias vImage_buffer_func = (_ srcptr: UnsafeMutableRawPointer, _ dstptr: UnsafeMutableRawPointer, _ srcHeight: Int, _ srcWidth: Int, _ dstHeight: Int, _ dstWidth: Int, _ channel: Int, _ plane: Int) -> Void

@inlinable
internal func vImageAffineWarp_PlanarF_(_ src: UnsafePointer<vImage_Buffer>, _ dest: UnsafePointer<vImage_Buffer>, _ tempBuffer: UnsafeMutableRawPointer!, _ transform: UnsafePointer<vImage_AffineTransform>, _ backColor: UnsafePointer<Pixel_F>?, _ flags: vImage_Flags) -> vImage_Error{
    return vImageAffineWarp_PlanarF(src, dest, tempBuffer, transform, backColor?.pointee ?? 0, flags)
}

/// Wrapper of vImage 4 channel to 1 channel function
/// - Parameters:
///   - srcptr: A  source pointer
///   - dstptr: A destination pointer
///   - height: height
///   - width: width
///   - pre_bias: pre bias array
///   - coef: coefficient array
///   - post_bias;  post bias value
@inline(__always)
internal func wrap_vImage_c4toc1(_ srcptr: UnsafeMutableRawPointer, _ dstptr: UnsafeMutableRawPointer, _ height: Int, _ width: Int, _ pre_bias: inout [Float], _ coef: inout [Float], _ post_bias: Float){
    let bytenum = MemoryLayout<Float>.size // 4
    var src_buffer = vImage_Buffer(data: srcptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: width*4*bytenum)
    var dst_buffer = vImage_Buffer(data: dstptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: width*1*bytenum)

    if #available(macOS 10.11, *) {
        vImageMatrixMultiply_ARGBFFFFToPlanarF(&src_buffer, &dst_buffer, &coef, &pre_bias, post_bias, vImage_Flags(kvImageNoFlags))
    } else {
        fatalError("Couldn't support os version.")
    }
}

/// Wrapper of vImage resize function
/// - Parameters:
///   - srcptr: A  source pointer
///   - srcHeight: height
///   - srcWidth: width
///   - dstptr: A destination pointer
///   - dstHeight: height
///   - dstWidth: width
///   - channel: channel
///   - vImage_func: pvImage resize function
@inline(__always)
internal func wrap_vImage_resize(_ srcptr: UnsafeMutableRawPointer, _ srcHeight: Int, _ srcWidth: Int, _ dstptr: UnsafeMutableRawPointer, _ dstHeight: Int, _ dstWidth: Int, _ channel: Int, vImage_func: vImage_resize_func){
    let bytenum = MemoryLayout<Float>.size // 4
    var src_buffer = vImage_Buffer(data: srcptr, height: vImagePixelCount(srcHeight), width: vImagePixelCount(srcWidth), rowBytes: srcWidth*channel*bytenum)
    var dst_buffer = vImage_Buffer(data: dstptr, height: vImagePixelCount(dstHeight), width: vImagePixelCount(dstWidth), rowBytes: dstWidth*channel*bytenum)

    _ = vImage_func(&src_buffer, &dst_buffer, nil, vImage_Flags(kvImageHighQualityResampling))
}


/// Wrapper of vImage affine transformation function
/// - Parameters:
///   - srcptr: A  source pointer
///   - srcHeight: height
///   - srcWidth: width
///   - dstptr: A destination pointer
///   - dstHeight: height
///   - dstWidth: width
///   - channel: channel
///   - transform: The transform in vImage's coordinate
///   - backColor: The background color value
///   - flags: Flags
@inline(__always)
internal func wrap_vImage_affine<T>(_ srcptr: UnsafeMutableRawPointer, _ srcHeight: Int, _ srcWidth: Int, _ dstptr: UnsafeMutableRawPointer, _ dstHeight: Int, _ dstWidth: Int, _ channel: Int, _ transform: vImage_AffineTransform, _ backColor: UnsafePointer<T>?, _ flags: Int, vImage_func: vImage_affine_func<T>){
    let bytenum = MemoryLayout<Float>.size // 4
    var src_buffer = vImage_Buffer(data: srcptr, height: vImagePixelCount(srcHeight), width: vImagePixelCount(srcWidth), rowBytes: srcWidth*channel*bytenum)
    var dst_buffer = vImage_Buffer(data: dstptr, height: vImagePixelCount(dstHeight), width: vImagePixelCount(dstWidth), rowBytes: dstWidth*channel*bytenum)
    var transform = transform

    _ = vImage_func(&src_buffer, &dst_buffer, nil, &transform, backColor, vImage_Flags(flags))
}

/// Apply vImage function to an image of any channel number.
///
/// The 4 channel image is processed as a row contiguous ARGBFFFF buffer by `argb_func` if it's given.
/// Otherwise, the image is split into row contiguous planes, and each plane is processed as a PlanarF buffer by `planar_func`.
/// - Parameters:
///   - image: An image mfarray (h, w) or (h, w, c). The mftype must be Float or UInt8
///   - dstHeight: The destination height
///   - dstWidth: The destination width
///   - argb_func: (Optional) The function for ARGBFFFF buffer
///   - planar_func: The function for PlanarF buffer
/// - Returns: The row contiguous image mfarray. The shape is (dstHeight, dstWidth) for 2d input, otherwise (dstHeight, dstWidth, c)
internal func apply_by_vImage(_ image: MfArray, dstHeight: Int, dstWidth: Int, argb_func: vImage_buffer_func?, planar_func: vImage_buffer_func) -> MfArray{
    let is2d = image.ndim == 2
    let (image, srcHeight, srcWidth, channel) = check_and_convert_image_dim(image)
    let dstShape = is2d ? [dstHeight, dstWidth] : [dstHeight, dstWidth, channel]
    let newdata = MfData(uninitializedSize: dstHeight*dstWidth*channel, mftype: image.mftype)

    if channel == 4, let argb_func = argb_func{
        let image = check_contiguous(image, .Row)
        image.withUnsafeMutableStartRawPointer{
            srcptr in
            newdata.withUnsafeMutableStartRawPointer{
                dstptr in
                argb_func(srcptr, dstptr, srcHeight, srcWidth, dstHeight, dstWidth, 4, 0)
            }
        }
        return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: dstShape, mforder: .Row))
    }

    // (h, w, c) -> (c, h, w)
    let planes = image.transpose(axes: [2, 0, 1]).to_contiguous(mforder: .Row)
    let bytenum = MemoryLayout<Float>.size // 4
    planes.withUnsafeMutableStartRawPointer{
        srcptr in
        newdata.withUnsafeMutableStartRawPointer{
            dstptr in
            for i in 0..<channel{
                planar_func(srcptr + i*srcHeight*srcWidth*bytenum, dstptr + i*dstHeight*dstWidth*bytenum, srcHeight, srcWidth, dstHeight, dstWidth, 1, i)
            }
        }
    }

    let ret = MfArray(mfdata: newdata, mfstructure: MfStructure(shape: [channel, dstHeight, dstWidth], mforder: .Row))
    if channel == 1{
        return ret.reshape(dstShape)
    }
    // (c, h, w) -> (h, w, c)
    return ret.transpose(axes: [1, 2, 0]).to_contiguous(mforder: .Row)
}

/// Convert 4 channels into 1 channel
/// - Parameters:
///   - image: An image mfarray
///   - pre_bias: pre bias array
///   - coef: coefficient array
///   - post_bias;  post bias value
/// - Returns: 1-channeled image mfarray
internal func c4toc1_by_vImage(_ image: MfArray, pre_bias: [Float], coef: [Float], post_bias: Float) -> MfArray{
    assert(pre_bias.count == 4)
    assert(coef.count == 4)
    var pre_bias = pre_bias
    var coef = coef
    var (image, height, width, channel) = check_and_convert_image_dim(image)

    if (channel == 1){
        return image
    }
    precondition(channel == 4, "must be 3d = (h,w,4)")

    image = check_contiguous(image, .Row)

    let newdata = MfData(uninitializedSize: height*width, mftype: image.mftype)
    newdata.withUnsafeMutableStartRawPointer{
        dstptr in
        image.withUnsafeMutableStartRawPointer{
            srcptr in
            wrap_vImage_c4toc1(srcptr, dstptr, height, width, &pre_bias, &coef, post_bias)
        }
    }

    let newstructure = MfStructure(shape: [height, width], mforder: .Row)
    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)

    return image.mftype == .UInt8 ? saturate_ui8_image(ret) : ret
}



/// Resize image
/// - Parameters:
///   - image: An image mfarray
///   - dstWidth: The destination width
///   - dstHeight: The destination height
/// - Returns: Resized image mfarray
internal func resize_by_vImage(_ image: MfArray, dstWidth: Int, dstHeight: Int) -> MfArray{
    return apply_by_vImage(image, dstHeight: dstHeight, dstWidth: dstWidth, argb_func: {
        srcptr, dstptr, srcHeight, srcWidth, dstHeight, dstWidth, channel, _ in
        wrap_vImage_resize(srcptr, srcHeight, srcWidth, dstptr, dstHeight, dstWidth, channel, vImage_func: vImageScale_ARGBFFFF)
    }, planar_func: {
        srcptr, dstptr, srcHeight, srcWidth, dstHeight, dstWidth, channel, _ in
        wrap_vImage_resize(srcptr, srcHeight, srcWidth, dstptr, dstHeight, dstWidth, channel, vImage_func: vImageScale_PlanarF)
    })
}


/// Convert the affine matrix in OpenCV's coordinate into vImage's one.
///
/// OpenCV's origin is the top-left pixel and its y axis points down, while vImage's origin is the bottom-left pixel and its y axis points up.
/// Let F_h: (x, y) -> (x, (h - 1) - y), the transform in vImage's coordinate is F_dstHeight * M * F_srcHeight.
/// - Parameters:
///   - matrix: The row contiguous Float matrix (shape=(2,3)) in OpenCV's coordinate
///   - srcHeight: The source height
///   - dstHeight: The destination height
/// - Returns: vImage_AffineTransform
internal func cv2vImage_affine_transform(_ matrix: MfArray, srcHeight: Int, dstHeight: Int) -> vImage_AffineTransform{
    let m = matrix.withUnsafeMutableStartPointer(datatype: Float.self){
        Array(UnsafeBufferPointer(start: $0, count: 6))
    }
    let (a, b, tx, c, d, ty) = (m[0], m[1], m[2], m[3], m[4], m[5])
    let hs = Float(srcHeight - 1)
    let hd = Float(dstHeight - 1)
    // vImage_AffineTransform is same as CGAffineTransform: x' = a*x + c*y + tx, y' = b*x + d*y + ty
    return vImage_AffineTransform(a: a, b: -c, c: -b, d: d, tx: tx + b*hs, ty: hd - ty - d*hs)
}

/// Apply affine  transformation
/// - Parameters:
///     - image: An image mfarray
///     - matrix: The transform matrix (shape=(2,3)) in OpenCV's coordinate
///     - width: The destination width
///     - height: The destination height
///     - mode: The pixel extrapolation mode
///     - borderValue: The border value. Count must be 4
/// - Returns: Affine transformed image mfarray
internal func affine_by_vImage(_ image: MfArray, dstHeight: Int, dstWidth: Int, matrix: MfArray, mode: MfAffineMode, borderValue: [Float]) -> MfArray{
    precondition(matrix.shape == [2, 3], "matrix's shape must be [2, 3], but got \(matrix.shape)")

    let matrix = check_contiguous(matrix.astype(.Float), .Row)
    let transform = cv2vImage_affine_transform(matrix, srcHeight: image.shape[0], dstHeight: dstHeight)

    let flags: Int
    switch mode{
    case .ColorFill:
        flags = kvImageBackgroundColorFill
    case .EdgeExtend:
        flags = kvImageEdgeExtend
    }

    return borderValue.withUnsafeBufferPointer{
        borderptr in
        apply_by_vImage(image, dstHeight: dstHeight, dstWidth: dstWidth, argb_func: {
            srcptr, dstptr, srcHeight, srcWidth, dstHeight, dstWidth, channel, _ in
            wrap_vImage_affine(srcptr, srcHeight, srcWidth, dstptr, dstHeight, dstWidth, channel, transform, borderptr.baseAddress!, flags, vImage_func: vImageAffineWarp_ARGBFFFF)
        }, planar_func: {
            srcptr, dstptr, srcHeight, srcWidth, dstHeight, dstWidth, channel, plane in
            // each plane is filled by the border value of its channel
            wrap_vImage_affine(srcptr, srcHeight, srcWidth, dstptr, dstHeight, dstWidth, channel, transform, borderptr.baseAddress! + plane, flags, vImage_func: vImageAffineWarp_PlanarF_)
        })
    }
}

/// Wrapper of vImage convolution function (correlation like cv2.filter2D)
/// - Parameters:
///   - srcptr: A  source pointer
///   - dstptr: A destination pointer
///   - height: height
///   - width: width
///   - kernel: The row contiguous kernel whose size is odd
///   - kernelHeight: The kernel height
///   - kernelWidth: The kernel width
///   - borderType: The border type
@inline(__always)
internal func wrap_vImage_convolve(_ srcptr: UnsafeMutableRawPointer, _ dstptr: UnsafeMutableRawPointer, _ height: Int, _ width: Int, _ kernel: UnsafePointer<Float>, _ kernelHeight: Int, _ kernelWidth: Int, _ borderType: MfBorderType){
    let bytenum = MemoryLayout<Float>.size // 4
    var src_buffer = vImage_Buffer(data: srcptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: width*bytenum)
    var dst_buffer = vImage_Buffer(data: dstptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: width*bytenum)
    let flags = borderType == .Constant ? kvImageBackgroundColorFill : kvImageEdgeExtend

    _ = vImageConvolve_PlanarF(&src_buffer, &dst_buffer, nil, 0, 0, kernel, UInt32(kernelHeight), UInt32(kernelWidth), 0, vImage_Flags(flags))
}

/// Convolve (correlate) the image with the kernel for each channel
/// - Parameters:
///   - image: An image mfarray (Float or UInt8)
///   - kernel: The row contiguous kernel
///   - kernelHeight: The kernel height
///   - kernelWidth: The kernel width
///   - anchor: The anchor (x, y). nil means the center
///   - borderType: The border type
/// - Returns: The Float image mfarray. Note that UInt8 image is not saturated
internal func convolve_by_vImage(_ image: MfArray, kernel: [Float], kernelHeight: Int, kernelWidth: Int, anchor: (x: Int, y: Int)? = nil, borderType: MfBorderType) -> MfArray{
    let (kernel, kernelHeight, kernelWidth) = center_kernel(kernel, height: kernelHeight, width: kernelWidth, anchor: anchor, pad: Float.zero)

    return kernel.withUnsafeBufferPointer{
        kernelptr in
        apply_by_vImage(image.astype(.Float), dstHeight: image.shape[0], dstWidth: image.shape[1], argb_func: nil, planar_func: {
            srcptr, dstptr, height, width, _, _, _, _ in
            wrap_vImage_convolve(srcptr, dstptr, height, width, kernelptr.baseAddress!, kernelHeight, kernelWidth, borderType)
        })
    }
}

/// Convolve (correlate) the image with the separable kernel for each channel
/// - Parameters:
///   - image: An image mfarray (Float or UInt8)
///   - kernelX: The kernel along x axis
///   - kernelY: The kernel along y axis
///   - anchor: The anchor (x, y). nil means the center
///   - borderType: The border type
/// - Returns: The Float image mfarray. Note that UInt8 image is not saturated
internal func sep_convolve_by_vImage(_ image: MfArray, kernelX: [Float], kernelY: [Float], anchor: (x: Int, y: Int)? = nil, borderType: MfBorderType) -> MfArray{
    let ret = convolve_by_vImage(image, kernel: kernelX, kernelHeight: 1, kernelWidth: kernelX.count, anchor: anchor.map{ ($0.x, 0) }, borderType: borderType)
    return convolve_by_vImage(ret, kernel: kernelY, kernelHeight: kernelY.count, kernelWidth: 1, anchor: anchor.map{ (0, $0.y) }, borderType: borderType)
}

/// Apply erode (min) or dilate (max) filter with the mask for each channel.
/// The pixels outside the image are ignored like OpenCV's default border value.
/// - Parameters:
///   - image: An image mfarray (Float or UInt8)
///   - mask: The row contiguous mask of the structuring element
///   - maskHeight: The mask height
///   - maskWidth: The mask width
///   - anchor: The anchor (x, y). nil means the center
///   - isDilate: Dilate or erode
/// - Returns: The image mfarray whose mftype is same as the input
internal func morphology_by_vImage(_ image: MfArray, mask: [Bool], maskHeight: Int, maskWidth: Int, anchor: (x: Int, y: Int)?, isDilate: Bool) -> MfArray{
    let (mask, kh, kw) = center_kernel(mask, height: maskHeight, width: maskWidth, anchor: anchor, pad: false)
    let bytenum = MemoryLayout<Float>.size // 4

    // vImageErode/Dilate_PlanarF compute min/max(src - kernel) + kernel[center], so the excluded elements are +-inf and the center must be included.
    let excluded: Float = isDilate ? Float.infinity : -Float.infinity
    let kernel = mask.map{ $0 ? Float.zero : excluded }
    let isRect = mask.allSatisfy{ $0 }
    let centerIncluded = mask[(kh/2)*kw + kw/2]

    let ret = kernel.withUnsafeBufferPointer{
        kernelptr in
        apply_by_vImage(image, dstHeight: image.shape[0], dstWidth: image.shape[1], argb_func: nil, planar_func: {
            srcptr, dstptr, height, width, _, _, _, _ in
            var src_buffer = vImage_Buffer(data: srcptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: width*bytenum)
            var dst_buffer = vImage_Buffer(data: dstptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: width*bytenum)

            if isRect{
                let flags = vImage_Flags(kvImageEdgeExtend)
                _ = isDilate ? vImageMax_PlanarF(&src_buffer, &dst_buffer, nil, 0, 0, vImagePixelCount(kh), vImagePixelCount(kw), flags) : vImageMin_PlanarF(&src_buffer, &dst_buffer, nil, 0, 0, vImagePixelCount(kh), vImagePixelCount(kw), flags)
            }
            else if centerIncluded{
                let flags = vImage_Flags(kvImageNoFlags)
                _ = isDilate ? vImageDilate_PlanarF(&src_buffer, &dst_buffer, 0, 0, kernelptr.baseAddress!, vImagePixelCount(kh), vImagePixelCount(kw), flags) : vImageErode_PlanarF(&src_buffer, &dst_buffer, 0, 0, kernelptr.baseAddress!, vImagePixelCount(kh), vImagePixelCount(kw), flags)
            }
            else{
                morph_by_loop(srcptr.assumingMemoryBound(to: Float.self), dstptr.assumingMemoryBound(to: Float.self), height: height, width: width, mask: mask, kh: kh, kw: kw, isDilate: isDilate)
            }
        })
    }
    return ret
}
#endif
