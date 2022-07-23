//
//  vImage.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/23.
//

import Foundation
import Accelerate


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
    
    var image = image.ndim == 2 ? image.expand_dims(axis: 2) : image
    if (image.ndim == 3 && image.shape[2] == 1){
        return image
    }
    
    precondition(image.ndim == 3 && image.shape[2] == 4, "must be 3d = (h,w,4)")
    
    if let background = background {
        assert(background.count == 3)
        let alpha = image[Matft.all, Matft.all, 3~<4]
        // TODO: Support the below subscription
        //image[Matft.all, Matft.all, 0~<3] = image[Matft.all, Matft.all, 0~<3]*alpha + (1 - alpha) * MfArray(background, mftype: image.mftype)
        image.swapaxes(axis1: -1, axis2: 0)[0~<3] = (image[Matft.all, Matft.all, 0~<3]*alpha + (1 - alpha) * MfArray([1, 1, 1], mftype: image.mftype)).swapaxes(axis1: -1, axis2: 0)
    }
    
    image = check_contiguous(image, .Row)
    
    let height = image.shape[0]
    let width = image.shape[1]
    
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
