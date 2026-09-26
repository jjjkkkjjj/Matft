//
//  imageproc.swift
//
//
//  Helpers for OpenCV compatible image processing (kernels, remap and histogram).
//

import Foundation

/// Get the row contiguous values of an image (Float or UInt8) as Float array
/// - Parameters:
///     - image: An image mfarray
/// - Returns: The row contiguous Float array
internal func image2floats(_ image: MfArray) -> [Float]{
    precondition(image.storedType == .Float, "The stored type must be Float, but got \(image.storedType)")
    let image = check_contiguous(image, .Row)
    return image.withUnsafeMutableStartPointer(datatype: Float.self){
        Array(UnsafeBufferPointer(start: $0, count: image.size))
    }
}

/// Create an image mfarray from row contiguous Float array
/// - Parameters:
///     - data: The row contiguous Float array
///     - shape: The shape
///     - mftype: The mftype whose stored type is Float
/// - Returns: The row contiguous mfarray
internal func floats2image(_ data: [Float], shape: [Int], mftype: MfType) -> MfArray{
    let newdata = MfData(size: data.count, mftype: mftype)
    newdata.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptr in
        data.withUnsafeBufferPointer{ dstptr.update(from: $0.baseAddress!, count: data.count) }
    }
    return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: shape, mforder: .Row))
}

/// Convert Float image into the given mftype. UInt8 is rounded and saturated like OpenCV.
/// - Parameters:
///     - image: A Float image mfarray
///     - mftype: The destination mftype (Float or UInt8)
/// - Returns: Converted mfarray
internal func convert_image_depth(_ image: MfArray, _ mftype: MfType) -> MfArray{
    precondition(mftype == .Float || mftype == .UInt8, "ddepth must be Float or UInt8, but got \(mftype)")
    return mftype == .UInt8 ? saturate_ui8_image(image) : image.astype(.Float)
}

/// Pad the kernel so that the anchor is at the center, because vImage uses the center of the kernel as the anchor.
/// - Parameters:
///     - kernel: The row contiguous kernel values
///     - height: The kernel height
///     - width: The kernel width
///     - anchor: The anchor (x, y). nil means the center (width/2, height/2)
///     - pad: The padded value
/// - Returns: The padded kernel whose size is odd
internal func center_kernel<T>(_ kernel: [T], height: Int, width: Int, anchor: (x: Int, y: Int)?, pad: T) -> (kernel: [T], height: Int, width: Int){
    let (ax, ay) = anchor ?? (width/2, height/2)
    precondition(0 <= ax && ax < width && 0 <= ay && ay < height, "anchor must be inside the kernel")
    let rx = max(ax, width - 1 - ax)
    let ry = max(ay, height - 1 - ay)
    let (newWidth, newHeight) = (2*rx + 1, 2*ry + 1)
    if newWidth == width && newHeight == height{
        return (kernel, height, width)
    }

    var ret = Array(repeating: pad, count: newWidth*newHeight)
    for i in 0..<height{
        for j in 0..<width{
            ret[(i + ry - ay)*newWidth + (j + rx - ax)] = kernel[i*width + j]
        }
    }
    return (ret, newHeight, newWidth)
}

/// Same as cv2.getGaussianKernel
/// - Parameters:
///     - ksize: The kernel size (odd)
///     - sigma: The standard deviation. If it's not positive, it's computed from ksize
/// - Returns: The kernel values
internal func gaussian_kernel(ksize: Int, sigma: Double) -> [Float]{
    // the fixed kernels used by OpenCV for small ksize with non-positive sigma
    let small_gaussian_tab: [Int: [Double]] = [
        1: [1],
        3: [0.25, 0.5, 0.25],
        5: [0.0625, 0.25, 0.375, 0.25, 0.0625],
        7: [0.03125, 0.109375, 0.21875, 0.28125, 0.21875, 0.109375, 0.03125]
    ]
    if sigma <= 0, let fixed = small_gaussian_tab[ksize]{
        return fixed.map{ Float($0) }
    }

    let sigmaX = sigma > 0 ? sigma : ((Double(ksize) - 1)*0.5 - 1)*0.3 + 0.8
    let scale2X = -0.5/(sigmaX*sigmaX)
    let ret = (0..<ksize).map{ i -> Double in
        let x = Double(i) - Double(ksize - 1)*0.5
        return exp(scale2X*x*x)
    }
    let sum = ret.reduce(0, +)
    return ret.map{ Float($0/sum) }
}

/// Same as getSobelKernel in OpenCV
/// - Parameters:
///     - ksize: The kernel size (1, 3, 5 or 7)
///     - order: The derivative order
/// - Returns: The kernel values
internal func sobel_kernel(ksize: Int, order: Int) -> [Float]{
    let ksize = (ksize == 1 && order > 0) ? 3 : ksize
    precondition(order < ksize, "The derivative order must be less than ksize")
    if ksize == 1{
        return [1]
    }
    if ksize == 3{
        switch order{
        case 0:
            return [1, 2, 1]
        case 1:
            return [-1, 0, 1]
        default:
            return [1, -2, 1]
        }
    }

    var ker = Array(repeating: 0, count: ksize + 1)
    ker[0] = 1
    for _ in 0..<(ksize - order - 1){
        var oldval = ker[0]
        for j in 1...ksize{
            let newval = ker[j] + ker[j - 1]
            ker[j - 1] = oldval
            oldval = newval
        }
    }
    for _ in 0..<order{
        var oldval = -ker[0]
        for j in 1...ksize{
            let newval = ker[j - 1] - ker[j]
            ker[j - 1] = oldval
            oldval = newval
        }
    }
    return ker.prefix(ksize).map{ Float($0) }
}

/// Same as cv2.getStructuringElement
/// - Parameters:
///     - shape: The shape
///     - width: The width
///     - height: The height
///     - anchor: The anchor (x, y) for cross. nil means the center
/// - Returns: The row contiguous mask
internal func structuring_element(_ shape: MfMorphShape, width: Int, height: Int, anchor: (x: Int, y: Int)?) -> [Bool]{
    let (ax, ay) = anchor ?? (width/2, height/2)
    var ret = Array(repeating: false, count: width*height)
    let r = height/2
    let c = width/2
    let inv_r2 = r > 0 ? 1/Double(r*r) : 0

    for i in 0..<height{
        var (j1, j2) = (0, 0)
        switch shape{
        case .Rect:
            (j1, j2) = (0, width)
        case .Cross:
            (j1, j2) = i == ay ? (0, width) : (ax, ax + 1)
        case .Ellipse:
            let dy = i - r
            if abs(dy) <= r{
                let dx = Int((Double(c)*sqrt(Double(r*r - dy*dy)*inv_r2)).rounded(.toNearestOrEven))
                j1 = max(c - dx, 0)
                j2 = min(c + dx + 1, width)
            }
        }
        for j in j1..<max(j1, j2){
            ret[i*width + j] = true
        }
    }
    return ret
}

/// Remap the image like cv2.remap
/// - Parameters:
///     - image: An image mfarray (Float or UInt8)
///     - mapx: The x coordinates of the source for each destination pixel (row contiguous, count = dstHeight*dstWidth)
///     - mapy: The y coordinates of the source for each destination pixel
///     - dstHeight: The destination height
///     - dstWidth: The destination width
///     - interpolation: Nearest or Linear
///     - borderType: The border type
///     - borderValue: The border value for each channel
///     - quantize: Whether to quantize the coordinates into 1/32 pixel like cv2.remap
/// - Returns: The row contiguous remapped image
internal func remap_image(_ image: MfArray, mapx: [Float], mapy: [Float], dstHeight: Int, dstWidth: Int, interpolation: MfInterpolation, borderType: MfBorderType, borderValue: [Float], quantize: Bool) -> MfArray{
    let is2d = image.ndim == 2
    let (image, height, width, channel) = check_and_convert_image_dim(image)
    precondition(mapx.count == dstHeight*dstWidth && mapy.count == dstHeight*dstWidth, "Invalid map size")
    precondition(interpolation != .Lanczos, "Lanczos is not supported")
    let src = image2floats(image)
    var dst = Array(repeating: Float.zero, count: dstHeight*dstWidth*channel)
    let border = (0..<channel).map{ $0 < borderValue.count ? borderValue[$0] : (borderValue.last ?? 0) }

    @inline(__always)
    func pixel(_ y: Int, _ x: Int, _ c: Int) -> Float{
        if 0 <= y && y < height && 0 <= x && x < width{
            return src[(y*width + x)*channel + c]
        }
        switch borderType{
        case .Constant:
            return border[c]
        case .Replicate:
            return src[(min(max(y, 0), height - 1)*width + min(max(x, 0), width - 1))*channel + c]
        }
    }

    for i in 0..<dstHeight*dstWidth{
        let (x, y) = (mapx[i], mapy[i])
        if interpolation == .Nearest{
            let sx = Int(x.rounded(.toNearestOrEven))
            let sy = Int(y.rounded(.toNearestOrEven))
            for c in 0..<channel{
                dst[i*channel + c] = pixel(sy, sx, c)
            }
            continue
        }

        var (sx, sy) = (Int(x.rounded(.down)), Int(y.rounded(.down)))
        var (fx, fy) = (x - Float(sx), y - Float(sy))
        if quantize{
            let X = Int((x*32).rounded(.toNearestOrEven))
            let Y = Int((y*32).rounded(.toNearestOrEven))
            sx = X >> 5
            sy = Y >> 5
            fx = Float(X & 31)/32
            fy = Float(Y & 31)/32
        }
        for c in 0..<channel{
            let top = pixel(sy, sx, c)*(1 - fx) + pixel(sy, sx + 1, c)*fx
            let bottom = pixel(sy + 1, sx, c)*(1 - fx) + pixel(sy + 1, sx + 1, c)*fx
            dst[i*channel + c] = top*(1 - fy) + bottom*fy
        }
    }

    let ret = floats2image(dst, shape: is2d ? [dstHeight, dstWidth] : [dstHeight, dstWidth, channel], mftype: .Float)
    return convert_image_depth(ret, image.mftype)
}

/// Calculate the histogram like cv2.calcHist with uniform bins
/// - Parameters:
///     - values: The values
///     - histSize: The number of bins
///     - lower: The lower bound (inclusive)
///     - upper: The upper bound (exclusive)
/// - Returns: The histogram
internal func histogram(_ values: [Float], histSize: Int, lower: Float, upper: Float) -> [Float]{
    var hist = Array(repeating: Float.zero, count: histSize)
    let a = Double(histSize)/Double(upper - lower)
    for v in values where lower <= v && v < upper{
        let idx = Int((Double(v - lower)*a).rounded(.down))
        if 0 <= idx && idx < histSize{
            hist[idx] += 1
        }
    }
    return hist
}

/// Same as getThreshVal_Otsu_8u in OpenCV
/// - Parameters:
///     - hist: The histogram of 256 bins
/// - Returns: The threshold value
internal func otsu_threshold(_ hist: [Float]) -> Int{
    let scale = 1/Double(hist.reduce(0, +))
    var mu = 0.0
    for i in 0..<hist.count{
        mu += Double(i)*Double(hist[i])
    }
    mu *= scale

    var (mu1, q1) = (0.0, 0.0)
    var (max_sigma, max_val) = (0.0, 0)
    let eps = Double(Float.ulpOfOne)
    for i in 0..<hist.count{
        let p_i = Double(hist[i])*scale
        mu1 *= q1
        q1 += p_i
        let q2 = 1 - q1
        if min(q1, q2) < eps || max(q1, q2) > 1 - eps{
            continue
        }
        mu1 = (mu1 + Double(i)*p_i)/q1
        let mu2 = (mu - q1*mu1)/q2
        let sigma = q1*q2*(mu1 - mu2)*(mu1 - mu2)
        if sigma > max_sigma{
            max_sigma = sigma
            max_val = i
        }
    }
    return max_val
}

/// Apply min (erode) or max (dilate) filter with the mask by loop. This is the fallback of vImage whose kernel center must be included.
/// The pixels outside the image are ignored like OpenCV's default border value.
/// - Parameters:
///     - src: The row contiguous plane
///     - height: The height
///     - width: The width
///     - mask: The row contiguous odd size mask
///     - kh: The mask height
///     - kw: The mask width
///     - isDilate: Dilate (max) or erode (min)
/// - Returns: The row contiguous plane
internal func morph_by_loop(_ src: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Float>, height: Int, width: Int, mask: [Bool], kh: Int, kw: Int, isDilate: Bool){
    let (cy, cx) = (kh/2, kw/2)
    let offsets = (0..<kh*kw).filter{ mask[$0] }.map{ ($0/kw - cy, $0%kw - cx) }
    for y in 0..<height{
        for x in 0..<width{
            var val: Float = isDilate ? -Float.greatestFiniteMagnitude : Float.greatestFiniteMagnitude
            for (dy, dx) in offsets{
                let (yy, xx) = (y + dy, x + dx)
                if 0 <= yy && yy < height && 0 <= xx && xx < width{
                    val = isDilate ? max(val, src[yy*width + xx]) : min(val, src[yy*width + xx])
                }
            }
            dst[y*width + x] = val
        }
    }
}
