//
//  vImage.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/23.
//

import Foundation
import Accelerate

internal typealias vImage_resize_func = (UnsafePointer<vImage_Buffer>, UnsafePointer<vImage_Buffer>, UnsafeMutableRawPointer?, vImage_Flags) -> vImage_Error

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


/// Convert 4 channels into 1 channel
/// - Parameters:
///   - image: An image mfarray
///   - pre_bias: pre bias array
///   - coef: coefficient array
///   - post_bias;  post bias value
///   - background: background array, if it's nill, exclude alpha channel.
/// - Returns: 1-channeled image mfarray
internal func c4toc1_by_vImage(_ image: MfArray, pre_bias: [Float], coef: [Float], post_bias: Float, background: [Float]?) -> MfArray{
    assert(pre_bias.count == 4)
    assert(coef.count == 4)
    var pre_bias = pre_bias
    var coef = coef
    var (image, height, width, channel) = check_and_convert_image_dim(image)
    
    if (channel == 1){
        return image
    }
    precondition(channel == 4, "must be 3d = (h,w,4)")
    
    if let background = background {
        assert(background.count == 3)
        let alpha = image[Matft.all, Matft.all, 3~<4]
        image[Matft.all, Matft.all, 0~<3] = image[Matft.all, Matft.all, 0~<3]*alpha + (1 - alpha) * MfArray(background, mftype: image.mftype)
        //image.swapaxes(axis1: -1, axis2: 0)[0~<3] = (image[Matft.all, Matft.all, 0~<3]*alpha + (1 - alpha) * MfArray([1, 1, 1], mftype: image.mftype)).swapaxes(axis1: -1, axis2: 0)
    }
    
    image = check_contiguous(image, .Row)
    
    let newdata = MfData(size: height*width, mftype: image.mftype)
    newdata.withUnsafeMutableStartRawPointer{
        dstptr in
        image.withUnsafeMutableStartRawPointer{
            srcptr in
            wrap_vImage_c4toc1(srcptr, dstptr, height, width, &pre_bias, &coef, post_bias)
        }
    }
    
    let newstructure = MfStructure(shape: [height, width], mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}



/// Resize image
/// - Parameters:
///   - image: An image mfarray
///   - dstWidth: The dstination width
///   - dstHeight: The destination height
/// - Returns: Resized image mfarray
internal func resize_by_vImage(_ image: MfArray, dstWidth: Int, dstHeight: Int) -> MfArray{
    var (image, srcHeight, srcWidth, channel) = check_and_convert_image_dim(image)
    
    let newdata = MfData(size: dstWidth*dstHeight*channel, mftype: image.mftype)
    let newstructure: MfStructure
    let dstShape = [dstHeight, dstWidth, channel]
    
    if channel == 1{// gray
        image = check_contiguous(image, .Column)
        
        image.withUnsafeMutableStartRawPointer{
            srcptr in
            newdata.withUnsafeMutableStartRawPointer{
                dstptr in
                wrap_vImage_resize(srcptr, srcHeight, srcWidth, dstptr, dstHeight, dstWidth, 1, vImage_func: vImageScale_PlanarF)
            }
        }
        newstructure = MfStructure(shape: dstShape, mforder: .Column)
    }
    else if channel == 4{ // RGBA
        image = check_contiguous(image)
        
        if image.mfstructure.row_contiguous{
            image.withUnsafeMutableStartRawPointer{
                srcptr in
                newdata.withUnsafeMutableStartRawPointer{
                    dstptr in
                    wrap_vImage_resize(srcptr, srcHeight, srcWidth, dstptr, dstHeight, dstWidth, 4, vImage_func: vImageScale_ARGBFFFF)
                }
            }
            
            newstructure = MfStructure(shape: dstShape, mforder: .Row)
        }
        else{ // column contiguous
            image.withUnsafeMutableStartRawPointer{
                srcptr in
                newdata.withUnsafeMutableStartRawPointer{
                    dstptr in
                    for i in 0..<4{
                        wrap_vImage_resize(srcptr + i*srcWidth*srcHeight*4, srcHeight, srcWidth, dstptr + i*dstWidth*dstHeight*4, dstHeight, dstWidth, 1, vImage_func: vImageScale_PlanarF)
                    }
                }
            }
            
            newstructure = MfStructure(shape: dstShape, mforder: .Column)
        }
    }
    else{
        preconditionFailure("Unsupport shape: \(image.shape)")
    }
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
