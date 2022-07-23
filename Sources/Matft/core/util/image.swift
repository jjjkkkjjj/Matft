//
//  image.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/23.
//

import Foundation

/// Check it is real or not. if the mfarray is complex, raise precondition failure.
/// - Parameters:
///     - mfarray: A source mfarray
@inline(__always)
internal func unsupport_imagetype(_ image: MfArray){
    precondition(image.mftype == .UInt8 || image.mftype == .Float, "Supported types are UInt8 or Float only, but got \(image.mftype)")
}

/// Check a given mfarray's shape and ndim, and convert 3 dim properly.
/// - Parameters:
///     - mfarray: A source mfarray
/// - Returns: Converted mfarray
@inlinable
internal func check_and_convert_image_dim(_ image: MfArray) -> (image: MfArray, height: Int, width: Int, channel: Int){
    precondition(image.mftype == .Float || image.mftype == .UInt8, "mftype must be Float or UInt8, but got \(image.mftype)")
    
    // check condition
    let ret = image.ndim == 2 ? image.expand_dims(axis: 2) : image
    
    precondition(ret.ndim == 3, "Couldn't convert mfarray's shape = \(image.shape) into image. Passed mfarray must be 2d or 3d, but got \(image.ndim)d")
    let shape = ret.shape
    return (ret, shape[0], shape[1], shape[2])
}



/// Convert UInt8 into Float for image.
/// - Parameters:
///     - mfarray: A source mfarray
/// - Returns: Converted mfarray
@inlinable
internal func ui8Xfloat_image(_ image: MfArray) -> MfArray{
    assert(image.mftype == .UInt8)
    return image / Float(255)
}

/// Convert Float into UInt8 for image.
/// - Parameters:
///     - mfarray: A source mfarray
/// - Returns: Converted mfarray
@inlinable
internal func floatXui8_image(_ image: MfArray) -> MfArray{
    assert(image.mftype == .Float)
    return image * Float(255)
}


/// Convert RGBA into RGB
/// - Parameters:
///     - image: An image mfarray
///     - isCopy: Whether to copy or not
///     - keepAlpha: Whether to keep the alpha channel
///     - background: The background array
/// - Returns: Converted mfarray
internal func rgba2rgb_image(_ image: MfArray, isCopy: Bool, keepAlpha: Bool, background: [Float]) -> MfArray{
    assert(background.count == 3)
    let image = isCopy ? image.deepcopy(.Row) : image

    let alpha = image[Matft.all, Matft.all, 3~<4]
    let new = image[Matft.all, Matft.all, 0~<3]*alpha + (1 - alpha) * MfArray(background, mftype: image.mftype)
    
    if keepAlpha{
        image[Matft.all, Matft.all, 0~<3] = new
        return image
    }
    else{
        return new
    }
}

/// Convert RGB into RGBA
/// - Parameters:
///     - image: An image mfarray
/// - Returns: Converted mfarray
internal func rgb2rgba_image(_ image: MfArray) -> MfArray{
    let alpha = Matft.nums(Float(1), shape: [image.shape[0], image.shape[1], 1])
    return Matft.hstack([image, alpha])
}
