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
       Converts the color space of an image.

       Equivalent to `cv2.cvtColor`. Float images are in `0...1` and UInt8 images are in `0...255`;
       the output has the same mftype as the input, and UInt8 results are rounded and saturated.

       | Code | Input layout | Output layout |
       | --- | --- | --- |
       | `.RGBA2GRAY`, `.BGRA2GRAY` | `(h, w, 4)` | `(h, w)` |
       | `.RGB2GRAY`, `.BGR2GRAY` | `(h, w, 3)` | `(h, w)` |
       | `.GRAY2RGB` / `.GRAY2RGBA` | `(h, w)` or `(h, w, 1)` | `(h, w, 3)` / `(h, w, 4)` |
       | `.RGBA2RGB` | `(h, w, 4)` | `(h, w, 3)` |
       | `.RGB2RGBA` | `(h, w, 3)` | `(h, w, 4)` with opaque alpha |
       | `.RGB2BGR`, `.BGR2RGB` | `(h, w, 3)` | `(h, w, 3)` |
       | `.RGBA2BGRA`, `.BGRA2RGBA` | `(h, w, 4)` | `(h, w, 4)` |
       | `.RGB2HSV`, `.HSV2RGB` | `(h, w, 3)` | `(h, w, 3)` |

       Gray conversions use the weights `0.299 R + 0.587 G + 0.114 B` as OpenCV does.
       For HSV, H is in `0..<360` for Float and in `0..<180` for UInt8 (as OpenCV), and S and V use
       the same range as the input.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) whose layout matches `code`.
            - code: The conversion code.
       - Returns: The converted mfarray with the same mftype as `src`.
       - Precondition: The mftype must be UInt8 or Float, and the channel count must match `code`.
       - Note: Unlike `cv2.COLOR_RGBA2RGB`, which just drops the alpha channel, `.RGBA2RGB` composites
         the image onto a white background using the alpha channel. `.RGBA2GRAY` and `.BGRA2GRAY` ignore alpha,
         and return a 1-channel input without conversion (as `(h, w, 1)`).
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
       Applies a fixed-level threshold to each element.

       Equivalent to `cv2.threshold`. The comparison is `src > thresh`; see `MfThresholdType` for the formula of each type.
       For a UInt8 image, `thresh` is floored and `maxval` is rounded before thresholding, as OpenCV does.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of any number of channels.
            - thresh: The threshold value. Ignored when `otsu` is `true`.
            - maxval: The value assigned by `.Binary` and `.BinaryInv`.
            - type: The threshold type.
            - otsu: Whether to determine the threshold by Otsu's method (`cv2.THRESH_OTSU`), by default `false`.
       - Returns: A tuple of the threshold actually used (`retval`) and the thresholded image (`dst`)
         with the same shape and mftype as `src`.
       - Precondition: The mftype must be UInt8 or Float. With `otsu`, `src` must be a 1-channel UInt8 image.
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
       Calculates the histogram of one channel.

       Equivalent to `cv2.calcHist([src], [channel], None, [histSize], [range.0, range.1])` with uniform bins.
       Values outside `range.0..<range.1` are not counted.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - channel: The channel index, by default 0.
            - histSize: The number of bins.
            - range: The lower (inclusive) and upper (exclusive) boundaries of the bins.
       - Returns: The Float histogram of shape `(histSize, 1)`.
       - Precondition: `histSize` must be positive, `range.0 < range.1`, and `channel` must be a valid index.
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
       Equalizes the histogram of a grayscale image.

       Equivalent to `cv2.equalizeHist`.

       - Parameters:
            - src: A 1-channel UInt8 image mfarray of `(height, width)` or `(height, width, 1)`.
       - Returns: The equalized UInt8 mfarray with the same shape as `src`.
       - Precondition: `src` must be a 1-channel UInt8 image.
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
       Transforms each element with a look-up table.

       Equivalent to `cv2.LUT` with a single-channel table: `dst[i] = lut[src[i]]`.

       - Parameters:
            - src: A UInt8 mfarray of any shape.
            - lut: A look-up table of 256 elements (UInt8 or Float).
       - Returns: The transformed mfarray with the same shape as `src` and the same mftype as `lut`.
       - Precondition: `src` must be UInt8, and `lut` must be UInt8 or Float with 256 elements.
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
       Normalizes the norm or the value range of an image.

       Equivalent to `cv2.normalize(src, None, alpha, beta, norm_type)` without a mask.
       The norm or range is computed over all elements (all channels together).

       - For `.MinMax`, the values are linearly mapped into `min(alpha, beta)...max(alpha, beta)`.
       - For `.Inf`, `.L1` and `.L2`, the values are scaled so that the norm becomes `alpha`.

       For the transformers-style `(x - mean) / std` normalization, use `normalize_meanstd(_:mean:std:)`.

       - Parameters:
            - src: An image mfarray (UInt8 or Float).
            - alpha: The target norm, or one boundary of the range for `.MinMax`, by default 1.
            - beta: The other boundary of the range for `.MinMax`, by default 0. Ignored for the other norms.
            - normType: The norm type, by default `.L2`.
       - Returns: The normalized mfarray with the same shape and mftype as `src`. UInt8 results are rounded and saturated.
       - Precondition: The mftype must be UInt8 or Float.
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
       Scales an image, takes the absolute values and converts the result into UInt8.

       Equivalent to `cv2.convertScaleAbs`: `dst = saturate(|src * alpha + beta|)`.

       - Parameters:
            - src: An image mfarray (UInt8 or Float).
            - alpha: The scale factor, by default 1.
            - beta: The delta added to the scaled values, by default 0.
       - Returns: The UInt8 mfarray with the same shape as `src`, rounded and saturated into `0...255`.
       - Precondition: The mftype must be UInt8 or Float.
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
