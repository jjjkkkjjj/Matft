//
//  image+color+static.swift
//
//
//  Color conversion, threshold and histogram functions similar to OpenCV.
//

#if canImport(Accelerate)
import Foundation
import Accelerate

extension Matft.image{

    /**
       Convert color space. Same as cv2.cvtColor.
       Float image is in [0, 1] and UInt8 image is in [0, 255]. For HSV, H is in [0, 360) for Float and [0, 180) for UInt8.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - code: The conversion code
       - Returns: MfArray
    */
    public static func cvtColor(_ src: MfArray, code: MfColorConversion) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)

        switch code{
        case .RGBA2GRAY:
            return c4toc1_by_vImage(src, pre_bias: [0, 0, 0, 0], coef: [0.299, 0.587, 0.114, 0], post_bias: 0)
        case .BGRA2GRAY:
            return c4toc1_by_vImage(src, pre_bias: [0, 0, 0, 0], coef: [0.114, 0.587, 0.299, 0], post_bias: 0)
        case .RGB2GRAY:
            return weighted_sum_image(src, coef: [0.299, 0.587, 0.114])
        case .BGR2GRAY:
            return weighted_sum_image(src, coef: [0.114, 0.587, 0.299])
        case .GRAY2RGB, .GRAY2RGBA:
            let (gray, height, width, channel) = check_and_convert_image_dim(src)
            precondition(channel == 1, "The source must be gray image, but got \(src.shape)")
            let rgb = Matft.concatenate([gray, gray, gray], axis: 2)
            return code == .GRAY2RGB ? rgb : rgb2rgba_image(rgb.reshape([height, width, 3]))
        case .RGBA2RGB:
            return rgba2rgb_image(src, keepAlpha: false, background: [1, 1, 1])
        case .RGB2RGBA:
            return rgb2rgba_image(src)
        case .RGB2BGR, .BGR2RGB:
            precondition(src.ndim == 3 && src.shape[2] == 3, "The source must be (h, w, 3), but got \(src.shape)")
            return src[Matft.all, Matft.all, MfArray([2, 1, 0])].to_contiguous(mforder: .Row)
        case .RGBA2BGRA, .BGRA2RGBA:
            precondition(src.ndim == 3 && src.shape[2] == 4, "The source must be (h, w, 4), but got \(src.shape)")
            return src[Matft.all, Matft.all, MfArray([2, 1, 0, 3])].to_contiguous(mforder: .Row)
        case .RGB2HSV:
            return rgb2hsv_image(src)
        case .HSV2RGB:
            return hsv2rgb_image(src)
        }
    }

    /**
       Apply a fixed-level threshold. Same as cv2.threshold.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - thresh: The threshold value
            - maxval: The value used for Binary and BinaryInv
            - type: The threshold type
            - otsu: (Optional) Whether to determine the threshold by Otsu's method. The source must be 1 channel UInt8 image.
       - Returns: The threshold value used and the thresholded image
    */
    public static func threshold(_ src: MfArray, thresh: Float, maxval: Float, type: MfThresholdType, otsu: Bool = false) -> (retval: Float, dst: MfArray){
        unsupport_complex(src)
        unsupport_imagetype(src)

        var thresh = thresh
        var maxval = maxval
        if otsu{
            precondition(src.mftype == .UInt8 && (src.ndim == 2 || src.shape[2] == 1), "Otsu's method supports 1 channel UInt8 image only")
            thresh = Float(otsu_threshold(histogram(image2floats(src), histSize: 256, lower: 0, upper: 256)))
        }
        let retval = thresh
        if src.mftype == .UInt8{
            thresh = thresh.rounded(.down)
            maxval = maxval.rounded(.toNearestOrEven)
        }

        let x = src.astype(.Float)
        let mask = (x > thresh).astype(.Float)
        let dst: MfArray
        switch type{
        case .Binary:
            dst = mask * maxval
        case .BinaryInv:
            dst = (Float(1) - mask) * maxval
        case .Trunc:
            dst = mask * thresh + (Float(1) - mask) * x
        case .ToZero:
            dst = mask * x
        case .ToZeroInv:
            dst = (Float(1) - mask) * x
        }
        return (retval, convert_image_depth(dst, src.mftype))
    }

    /**
       Calculate a histogram of the channel. Same as cv2.calcHist([src], [channel], None, [histSize], range) with uniform bins.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - channel: (Optional) The channel index, by default 0
            - histSize: The number of bins
            - range: The lower (inclusive) and upper (exclusive) boundaries
       - Returns: The Float histogram (shape = (histSize, 1))
    */
    public static func calcHist(_ src: MfArray, channel: Int = 0, histSize: Int, range: (Float, Float)) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(histSize > 0 && range.0 < range.1, "Invalid histSize or range")
        let (image, _, _, c) = check_and_convert_image_dim(src)
        precondition(0 <= channel && channel < c, "Invalid channel: \(channel)")

        let hist = histogram(image2floats(image[Matft.all, Matft.all, channel]), histSize: histSize, lower: range.0, upper: range.1)
        return floats2image(hist, shape: [histSize, 1], mftype: .Float)
    }

    /**
       Equalize the histogram of gray image. Same as cv2.equalizeHist.
       - parameters:
            - src: A 1 channel UInt8 image mfarray
       - Returns: UInt8 mfarray
    */
    public static func equalizeHist(_ src: MfArray) -> MfArray{
        precondition(src.mftype == .UInt8 && (src.ndim == 2 || (src.ndim == 3 && src.shape[2] == 1)), "equalizeHist supports 1 channel UInt8 image only")
        let values = image2floats(src)
        let hist = histogram(values, histSize: 256, lower: 0, upper: 256)

        var lut = Array(repeating: Float.zero, count: 256)
        let total = Float(values.count)
        if let first = hist.firstIndex(where: { $0 > 0 }){
            if hist[first] == total{
                lut = Array(repeating: Float(first), count: 256)
            }
            else{
                let scale = 255/(total - hist[first])
                var sum: Float = 0
                for i in (first + 1)..<256{
                    sum += hist[i]
                    lut[i] = min(max((sum*scale).rounded(.toNearestOrEven), 0), 255)
                }
            }
        }
        return Matft.image.LUT(src, lut: floats2image(lut, shape: [256], mftype: .UInt8))
    }

    /**
       Look up table transform. Same as cv2.LUT.
       - parameters:
            - src: An UInt8 image mfarray
            - lut: The look up table of 256 elements. The returned mfarray has the lut's mftype.
       - Returns: MfArray
    */
    public static func LUT(_ src: MfArray, lut: MfArray) -> MfArray{
        precondition(src.mftype == .UInt8, "src must be UInt8, but got \(src.mftype)")
        precondition(lut.size == 256, "lut must have 256 elements, but got \(lut.size)")
        unsupport_imagetype(lut)

        let table = image2floats(lut)
        let values = image2floats(src).map{ table[Int($0)] }
        return floats2image(values, shape: src.shape, mftype: lut.mftype)
    }

    /**
       Normalize the norm or value range. Same as cv2.normalize(src, None, alpha, beta, norm_type).
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - alpha: (Optional) The norm value, or the lower boundary of the range for MinMax, by default 1
            - beta: (Optional) The upper boundary of the range for MinMax, by default 0
            - normType: (Optional) The norm type, by default L2
       - Returns: MfArray whose mftype is same as the input
    */
    public static func normalize(_ src: MfArray, alpha: Float = 1, beta: Float = 0, normType: MfNormType = .L2) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)

        let x = src.astype(.Float)
        let scale: Float
        var shift: Float = 0
        switch normType{
        case .MinMax:
            let smin = x.min().scalar(Float.self)!
            let smax = x.max().scalar(Float.self)!
            let (dmin, dmax) = (min(alpha, beta), max(alpha, beta))
            scale = smax - smin > Float.ulpOfOne ? (dmax - dmin)/(smax - smin) : 0
            shift = dmin - smin*scale
        case .Inf, .L1, .L2:
            let norm: Float
            switch normType{
            case .Inf:
                norm = Matft.math.abs(x).max().scalar(Float.self)!
            case .L1:
                norm = Matft.math.abs(x).sum().scalar(Float.self)!
            default:
                norm = sqrt((x*x).sum().scalar(Float.self)!)
            }
            scale = norm > Float.ulpOfOne ? alpha/norm : 0
        }
        return convert_image_depth(x*scale + shift, src.mftype)
    }

    /**
       Scale, calculate absolute values, and convert the result into UInt8. Same as cv2.convertScaleAbs.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - alpha: (Optional) The scale factor, by default 1
            - beta: (Optional) The delta added to the scaled values, by default 0
       - Returns: UInt8 mfarray
    */
    public static func convertScaleAbs(_ src: MfArray, alpha: Float = 1, beta: Float = 0) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        return saturate_ui8_image(Matft.math.abs(src.astype(.Float)*alpha + beta))
    }
}

/// Weighted sum of 3 channels, e.g., RGB to gray
/// - Parameters:
///     - image: An image mfarray (h, w, 3)
///     - coef: The coefficients
/// - Returns: The gray image mfarray (h, w)
fileprivate func weighted_sum_image(_ image: MfArray, coef: [Float]) -> MfArray{
    precondition(image.ndim == 3 && image.shape[2] == 3, "The source must be (h, w, 3), but got \(image.shape)")
    let x = image.astype(.Float)
    let gray = x[Matft.all, Matft.all, 0]*coef[0] + x[Matft.all, Matft.all, 1]*coef[1] + x[Matft.all, Matft.all, 2]*coef[2]
    return convert_image_depth(gray, image.mftype)
}

/// Convert RGB into HSV like cv2.COLOR_RGB2HSV
/// - Parameters:
///     - image: An image mfarray (h, w, 3)
/// - Returns: The HSV image mfarray
fileprivate func rgb2hsv_image(_ image: MfArray) -> MfArray{
    precondition(image.ndim == 3 && image.shape[2] == 3, "The source must be (h, w, 3), but got \(image.shape)")
    let isUInt8 = image.mftype == .UInt8
    let scale: Float = isUInt8 ? 1/255 : 1
    var values = image2floats(image)

    for i in stride(from: 0, to: values.count, by: 3){
        let (r, g, b) = (values[i]*scale, values[i + 1]*scale, values[i + 2]*scale)
        let v = max(r, g, b)
        let vmin = min(r, g, b)
        var diff = v - vmin
        let s = diff/(abs(v) + Float.ulpOfOne)
        diff = 60/(diff + Float.ulpOfOne)
        var h: Float
        if v == r{
            h = (g - b)*diff
        }
        else if v == g{
            h = (b - r)*diff + 120
        }
        else{
            h = (r - g)*diff + 240
        }
        if h < 0{
            h += 360
        }

        if isUInt8{
            var h8 = (h/2).rounded(.toNearestOrEven)
            if h8 >= 180{
                h8 -= 180
            }
            (values[i], values[i + 1], values[i + 2]) = (h8, (s*255).rounded(.toNearestOrEven), (v*255).rounded(.toNearestOrEven))
        }
        else{
            (values[i], values[i + 1], values[i + 2]) = (h, s, v)
        }
    }
    return floats2image(values, shape: image.shape, mftype: image.mftype)
}

/// Convert HSV into RGB like cv2.COLOR_HSV2RGB
/// - Parameters:
///     - image: An HSV image mfarray (h, w, 3)
/// - Returns: The RGB image mfarray
fileprivate func hsv2rgb_image(_ image: MfArray) -> MfArray{
    precondition(image.ndim == 3 && image.shape[2] == 3, "The source must be (h, w, 3), but got \(image.shape)")
    let isUInt8 = image.mftype == .UInt8
    // (b, g, r) indices of (v, p, q, t) for each sector
    let sector_data = [[1, 3, 0], [1, 0, 2], [3, 0, 1], [0, 2, 1], [0, 1, 3], [2, 1, 0]]
    var values = image2floats(image)

    for i in stride(from: 0, to: values.count, by: 3){
        var h = isUInt8 ? values[i]*2 : values[i]
        let s = isUInt8 ? values[i + 1]/255 : values[i + 1]
        let v = isUInt8 ? values[i + 2]/255 : values[i + 2]

        h *= 6/360
        while h < 0{
            h += 6
        }
        while h >= 6{
            h -= 6
        }
        var sector = Int(h.rounded(.down))
        h -= Float(sector)
        if sector < 0 || sector >= 6{
            sector = 0
            h = 0
        }
        let tab = [v, v*(1 - s), v*(1 - s*h), v*(1 - s*(1 - h))]
        let (b, g, r) = (tab[sector_data[sector][0]], tab[sector_data[sector][1]], tab[sector_data[sector][2]])

        if isUInt8{
            (values[i], values[i + 1], values[i + 2]) = ((r*255).rounded(.toNearestOrEven), (g*255).rounded(.toNearestOrEven), (b*255).rounded(.toNearestOrEven))
        }
        else{
            (values[i], values[i + 1], values[i + 2]) = (r, g, b)
        }
    }
    return floats2image(values, shape: image.shape, mftype: image.mftype)
}
#endif
