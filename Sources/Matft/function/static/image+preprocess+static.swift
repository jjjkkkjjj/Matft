//
//  image+preprocess+static.swift
//  Matft
//
//  PIL / transformers compatible preprocessing for vision models
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

extension Matft.image{
    /// The per-channel RGB mean used by OpenAI CLIP. Same as `transformers.image_utils.OPENAI_CLIP_MEAN`.
    public static let OPENAI_CLIP_MEAN: [Double] = [0.48145466, 0.4578275, 0.40821073]
    /// The per-channel RGB standard deviation used by OpenAI CLIP. Same as `transformers.image_utils.OPENAI_CLIP_STD`.
    public static let OPENAI_CLIP_STD: [Double] = [0.26862954, 0.26130258, 0.27577711]
    /// The per-channel RGB mean of ImageNet. Same as `transformers.image_utils.IMAGENET_DEFAULT_MEAN`.
    public static let IMAGENET_DEFAULT_MEAN: [Double] = [0.485, 0.456, 0.406]
    /// The per-channel RGB standard deviation of ImageNet. Same as `transformers.image_utils.IMAGENET_DEFAULT_STD`.
    public static let IMAGENET_DEFAULT_STD: [Double] = [0.229, 0.224, 0.225]
    /// The per-channel mean `[0.5, 0.5, 0.5]`. Same as `transformers.image_utils.IMAGENET_STANDARD_MEAN`.
    public static let IMAGENET_STANDARD_MEAN: [Double] = [0.5, 0.5, 0.5]
    /// The per-channel standard deviation `[0.5, 0.5, 0.5]`. Same as `transformers.image_utils.IMAGENET_STANDARD_STD`.
    public static let IMAGENET_STANDARD_STD: [Double] = [0.5, 0.5, 0.5]

    /**
       Resizes an image in the same way as `PIL.Image.resize`.

       Equivalent to `PIL.Image.resize((width, height), resample)` (Pillow's `libImaging/Resample.c`).
       A UInt8 image is resized with Pillow's 8-bit fixed-point arithmetic, so the result is exactly the same
       pixels as PIL. The other mftypes are resized with floating-point arithmetic like PIL's mode `"F"`.
       The image is not premultiplied by alpha, and any number of channels is accepted.

       To follow `cv2.resize` instead, use `resize(_:width:height:interpolation:)`.

       ```swift
       // rgb: UInt8 (h, w, 3)
       let resized = Matft.image.resize(rgb, width: 224, height: 224, resample: .bicubic) // == PIL.Image.resize(BICUBIC)
       ```

       - Parameters:
            - image: An image mfarray of `(height, width)` or `(height, width, channels)`.
            - width: The destination width.
            - height: The destination height.
            - resample: The resampling filter.
       - Returns: The resized mfarray of `(height, width)` or `(height, width, channels)`. UInt8 stays UInt8,
         Double-stored types keep their mftype, and the other types become Float.
       - Precondition: `image` must be real and 2D or 3D, and `width` and `height` must be positive.
       - Note: Unlike PIL, an RGBA image is not premultiplied by alpha before resampling.
         Convert it to RGB first, as transformers does.
    */
    public static func resize(_ image: MfArray, width: Int, height: Int, resample: MfResample) -> MfArray{
        unsupport_complex(image)
        precondition(image.ndim == 2 || image.ndim == 3, "image must be (h, w) or (h, w, c)")
        precondition(0 < width && 0 < height, "New size must be positive")

        let inH = image.shape[0], inW = image.shape[1]
        let channels = image.ndim == 3 ? image.shape[2] : 1
        let is8bpc = image.mftype == .UInt8
        let src = is8bpc || image.storedType == .Double ? image.to_contiguous(mforder: .Row) : image.astype(.Float)
        let outShape = image.ndim == 3 ? [height, width, channels] : [height, width]
        let size = _ResampleSize(inH: inH, inW: inW, outH: height, outW: width, channels: channels)

        switch src.storedType {
        case .Float:
            let ret = Matft.nums(Float.zero, shape: outShape, mftype: src.mftype)
            src.withUnsafeMutableStartPointer(datatype: Float.self){
                srcptr in
                ret.withUnsafeMutableStartPointer(datatype: Float.self){
                    _pil_resize(srcptr, $0, size, resample: resample, is8bpc: is8bpc)
                }
            }
            return ret
        case .Double:
            let ret = Matft.nums(Double.zero, shape: outShape, mftype: src.mftype)
            src.withUnsafeMutableStartPointer(datatype: Double.self){
                srcptr in
                ret.withUnsafeMutableStartPointer(datatype: Double.self){
                    _pil_resize(srcptr, $0, size, resample: resample, is8bpc: false)
                }
            }
            return ret
        }
    }

    /**
       Calculates the resized image size for Qwen2-VL.

       Equivalent to `transformers.models.qwen2_vl.image_processing_qwen2_vl.smart_resize`.
       The returned height and width are divisible by `factor`, the number of pixels is within
       `min_pixels...max_pixels`, and the aspect ratio is kept as much as possible.

       - Parameters:
            - height: The original height.
            - width: The original width.
            - factor: The value both returned sizes are divisible by, by default 28.
            - min_pixels: The minimum number of pixels, by default `56 * 56`.
            - max_pixels: The maximum number of pixels, by default `14 * 14 * 4 * 1280`.
       - Returns: A tuple of the resized height and width.
       - Precondition: The aspect ratio `max(height, width) / min(height, width)` must not exceed 200.
    */
    public static func smart_resize(height: Int, width: Int, factor: Int = 28, min_pixels: Int = 56 * 56, max_pixels: Int = 14 * 14 * 4 * 1280) -> (height: Int, width: Int){
        precondition(Double(Swift.max(height, width)) / Double(Swift.min(height, width)) <= 200, "absolute aspect ratio must be smaller than 200")
        let h = Double(height), w = Double(width), f = Double(factor)
        // Python's round is round half to even
        var h_bar = Int((h / f).rounded(.toNearestOrEven)) * factor
        var w_bar = Int((w / f).rounded(.toNearestOrEven)) * factor
        if h_bar * w_bar > max_pixels{
            let beta = ((h * w) / Double(max_pixels)).squareRoot()
            h_bar = Swift.max(factor, Int((h / beta / f).rounded(.down)) * factor)
            w_bar = Swift.max(factor, Int((w / beta / f).rounded(.down)) * factor)
        }
        else if h_bar * w_bar < min_pixels{
            let beta = (Double(min_pixels) / (h * w)).squareRoot()
            h_bar = Int((h * beta / f).rounded(.up)) * factor
            w_bar = Int((w * beta / f).rounded(.up)) * factor
        }
        return (h_bar, w_bar)
    }

    /**
       Crops the center of an image.

       Equivalent to `transformers.image_transforms.center_crop` for a channel-last image.
       If the image is smaller than the requested size, it is padded with zeros.

       - Parameters:
            - image: An image mfarray of `(height, width)` or `(height, width, channels)`. Any mftype is accepted.
            - height: The height of the cropped image.
            - width: The width of the cropped image.
       - Returns: The cropped row-contiguous mfarray of `(height, width)` or `(height, width, channels)`
         with the same mftype as `image`.
       - Precondition: `image` must be 2D or 3D.
    */
    public static func center_crop(_ image: MfArray, height: Int, width: Int) -> MfArray{
        precondition(image.ndim == 2 || image.ndim == 3, "image must be (h, w) or (h, w, c)")
        func floordiv(_ a: Int, _ b: Int) -> Int{
            return Int((Double(a) / Double(b)).rounded(.down))
        }
        let origH = image.shape[0], origW = image.shape[1]
        var top = floordiv(origH - height, 2)
        var left = floordiv(origW - width, 2)

        var ret = image
        let newH = Swift.max(height, origH), newW = Swift.max(width, origW)
        if top < 0 || left < 0{
            // pad with zeros
            let top_pad = (newH - origH + 1) / 2
            let left_pad = (newW - origW + 1) / 2
            var pad_width = [(top_pad, newH - origH - top_pad), (left_pad, newW - origW - left_pad)]
            if image.ndim == 3{
                pad_width.append((0, 0))
            }
            ret = Matft.pad(image, pad_width: pad_width)
            top += top_pad
            left += left_pad
        }

        var indices: [Any] = [MfSlice(start: Swift.max(0, top), to: Swift.min(newH, top + height)),
                              MfSlice(start: Swift.max(0, left), to: Swift.min(newW, left + width))]
        return ret._get_mfarray(indices: &indices).to_contiguous(mforder: .Row)
    }

    /**
       Multiplies an image by a scale factor.

       Equivalent to `transformers.image_transforms.rescale` with `dtype=np.float32`:
       the product is computed in Double and returned as Float.

       - Parameters:
            - image: An image mfarray of any shape, e.g. UInt8 in `0...255`.
            - scale: The scale factor, e.g. `1.0 / 255`.
       - Returns: The rescaled Float mfarray with the same shape as `image`.
       - Precondition: `image` must be real.
    */
    public static func rescale(_ image: MfArray, scale: Double) -> MfArray{
        unsupport_complex(image)
        return (image.astype(.Double) * scale).astype(.Float)
    }

    /**
       Normalizes an image with a per-channel mean and standard deviation.

       Equivalent to `transformers.image_transforms.normalize` for a channel-last image:
       `(image - mean) / std` along the last axis.

       - Parameters:
            - image: An image mfarray whose last axis is the channel axis, e.g. `(height, width, channels)`.
            - mean: The mean for each channel, e.g. `OPENAI_CLIP_MEAN`.
            - std: The standard deviation for each channel, e.g. `OPENAI_CLIP_STD`.
       - Returns: The normalized mfarray with the same shape as `image`. It is Double for a Double input and Float otherwise.
       - Precondition: `image` must be real, and `mean` and `std` must have as many elements as the channels.
    */
    public static func normalize_meanstd(_ image: MfArray, mean: [Double], std: [Double]) -> MfArray{
        unsupport_complex(image)
        let channels = image.shape[image.ndim - 1]
        precondition(mean.count == channels && std.count == channels, "mean and std must have \(channels) elements")

        let mftype: MfType = image.mftype == .Double ? .Double : .Float
        let image = image.astype(mftype)
        return (image - MfArray(mean, mftype: mftype)) / MfArray(std, mftype: mftype)
    }

    /**
       Preprocesses an image for CLIP.

       Equivalent to transformers' `CLIPImageProcessor` with the PIL backend: resize the shortest edge to `size`
       with `resize(_:width:height:resample:)`, center crop, rescale and normalize, then transpose to channel-first.

       ```swift
       let rgba = Matft.image.cgimage2mfarray(cgimage, mftype: .UInt8)          // (h, w, 4)
       let rgb = rgba[Matft.all, Matft.all, 0~<3].to_contiguous(mforder: .Row) // (h, w, 3)
       let pixel_values = Matft.image.clip_preprocess(rgb)                      // (1, 3, 224, 224)
       ```

       - Parameters:
            - image: An RGB UInt8 image mfarray of `(height, width, 3)`.
            - size: The length of the shortest edge after resizing, by default 224.
            - crop_height: The height of the center crop, by default 224.
            - crop_width: The width of the center crop, by default 224.
            - resample: The resampling filter, by default `.bicubic`.
            - rescale_factor: The rescale factor, by default `1 / 255`.
            - mean: The per-channel mean for normalization, by default `OPENAI_CLIP_MEAN`.
            - std: The per-channel standard deviation for normalization, by default `OPENAI_CLIP_STD`.
       - Returns: The Float pixel values of shape `(1, channels, crop_height, crop_width)`.
       - Precondition: `image` must be a 3D UInt8 mfarray, e.g. from `cgimage2mfarray(_:mftype:)` with `.UInt8`,
         and `mean` and `std` must have as many elements as its channels.
    */
    public static func clip_preprocess(_ image: MfArray, size: Int = 224, crop_height: Int = 224, crop_width: Int = 224, resample: MfResample = .bicubic, rescale_factor: Double = 1.0 / 255, mean: [Double] = OPENAI_CLIP_MEAN, std: [Double] = OPENAI_CLIP_STD) -> MfArray{
        precondition(image.mftype == .UInt8 && image.ndim == 3, "image must be UInt8 (h, w, c). Use cgimage2mfarray(_:mftype: .UInt8)")

        // transformers.image_transforms.get_resize_output_image_size(default_to_square=False)
        let height = image.shape[0], width = image.shape[1]
        let (short, long) = width <= height ? (width, height) : (height, width)
        let new_long = Int(Double(size * long) / Double(short))
        let (new_h, new_w) = width <= height ? (new_long, size) : (size, new_long)

        var ret = Matft.image.resize(image, width: new_w, height: new_h, resample: resample)
        ret = Matft.image.center_crop(ret, height: crop_height, width: crop_width)
        ret = Matft.image.normalize_meanstd(Matft.image.rescale(ret, scale: rescale_factor), mean: mean, std: std)
        return ret.transpose(axes: [2, 0, 1]).to_contiguous(mforder: .Row).reshape([1, ret.shape[2], crop_height, crop_width])
    }

    /**
       Flattens a normalized image into patches for Qwen2-VL.

       Equivalent to the patchify step of transformers' `Qwen2VLImageProcessor` for a single image.
       The image is repeated `temporal_patch_size` times along the temporal axis, so the returned `grid_thw.t` is 1.

       - Parameters:
            - image: A normalized channel-first image mfarray of `(channels, height, width)`. `height` and `width`
              must be divisible by `patch_size * merge_size`.
            - patch_size: The spatial patch size, by default 14.
            - temporal_patch_size: The temporal patch size, by default 2.
            - merge_size: The spatial merge size, by default 2.
       - Returns: A tuple of the Float patches of shape
         `(grid_h * grid_w, channels * temporal_patch_size * patch_size * patch_size)` and the grid size
         `(t: 1, h: height / patch_size, w: width / patch_size)`.
       - Precondition: `image` must be 3D, and its height and width must be divisible by `patch_size * merge_size`.
    */
    public static func qwen2vl_patchify(_ image: MfArray, patch_size: Int = 14, temporal_patch_size: Int = 2, merge_size: Int = 2) -> (pixel_values: MfArray, grid_thw: (t: Int, h: Int, w: Int)){
        precondition(image.ndim == 3, "image must be (c, h, w)")
        let channel = image.shape[0], height = image.shape[1], width = image.shape[2]
        precondition(height % (patch_size * merge_size) == 0 && width % (patch_size * merge_size) == 0, "height and width must be divisible by patch_size * merge_size")
        let grid_h = height / patch_size, grid_w = width / patch_size

        var patches = image.astype(.Float).reshape([channel, grid_h / merge_size, merge_size, patch_size, grid_w / merge_size, merge_size, patch_size])
        // (gh, gw, mh, mw, C, ph, pw)
        patches = patches.transpose(axes: [1, 4, 2, 5, 0, 3, 6])
        // expand temporal_patch_size: (gh, gw, mh, mw, C, T, ph, pw)
        var shape = patches.shape
        shape.insert(temporal_patch_size, at: 5)
        patches = Matft.expand_dims(patches, axis: 5).broadcast_to(shape: shape)

        let pixel_values = patches.to_contiguous(mforder: .Row).reshape([grid_h * grid_w, channel * temporal_patch_size * patch_size * patch_size])
        return (pixel_values, (1, grid_h, grid_w))
    }

    /**
       Preprocesses an image for Qwen2-VL.

       Equivalent to transformers' `Qwen2VLImageProcessor` with the PIL backend for a single image:
       `smart_resize(height:width:factor:min_pixels:max_pixels:)`, `resize(_:width:height:resample:)`,
       rescale, normalize and `qwen2vl_patchify(_:patch_size:temporal_patch_size:merge_size:)`.

       ```swift
       let (patches, grid_thw) = Matft.image.qwen2vl_preprocess(rgb) // rgb: UInt8 (h, w, 3)
       ```

       - Parameters:
            - image: An RGB UInt8 image mfarray of `(height, width, 3)`.
            - min_pixels: The minimum number of pixels after resizing, by default `56 * 56`.
            - max_pixels: The maximum number of pixels after resizing, by default `28 * 28 * 1280`.
            - patch_size: The spatial patch size, by default 14.
            - temporal_patch_size: The temporal patch size, by default 2.
            - merge_size: The spatial merge size, by default 2.
            - resample: The resampling filter, by default `.bicubic`.
            - rescale_factor: The rescale factor, by default `1 / 255`.
            - mean: The per-channel mean for normalization, by default `OPENAI_CLIP_MEAN`.
            - std: The per-channel standard deviation for normalization, by default `OPENAI_CLIP_STD`.
       - Returns: A tuple of the Float patches of shape
         `(grid_h * grid_w, channels * temporal_patch_size * patch_size * patch_size)` and the grid size `grid_thw`.
       - Precondition: `image` must be a 3D UInt8 mfarray, and `mean` and `std` must have as many elements as its channels.
    */
    public static func qwen2vl_preprocess(_ image: MfArray, min_pixels: Int = 56 * 56, max_pixels: Int = 28 * 28 * 1280, patch_size: Int = 14, temporal_patch_size: Int = 2, merge_size: Int = 2, resample: MfResample = .bicubic, rescale_factor: Double = 1.0 / 255, mean: [Double] = OPENAI_CLIP_MEAN, std: [Double] = OPENAI_CLIP_STD) -> (pixel_values: MfArray, grid_thw: (t: Int, h: Int, w: Int)){
        precondition(image.mftype == .UInt8 && image.ndim == 3, "image must be UInt8 (h, w, c). Use cgimage2mfarray(_:mftype: .UInt8)")

        let (h, w) = Matft.image.smart_resize(height: image.shape[0], width: image.shape[1], factor: patch_size * merge_size, min_pixels: min_pixels, max_pixels: max_pixels)
        var ret = Matft.image.resize(image, width: w, height: h, resample: resample)
        ret = Matft.image.normalize_meanstd(Matft.image.rescale(ret, scale: rescale_factor), mean: mean, std: std)
        return Matft.image.qwen2vl_patchify(ret.transpose(axes: [2, 0, 1]), patch_size: patch_size, temporal_patch_size: temporal_patch_size, merge_size: merge_size)
    }
}

// MARK: - PIL resample (libImaging/Resample.c and Geometry.c of Pillow)

fileprivate struct _ResampleSize{
    let inH: Int, inW: Int, outH: Int, outW: Int, channels: Int
}

/// The filter function and its support
fileprivate func _pil_filter(_ resample: MfResample) -> (filter: (Double) -> Double, support: Double){
    func sinc(_ x: Double) -> Double{
        if x == 0{
            return 1
        }
        let x = x * Double.pi
        return sin(x) / x
    }
    switch resample {
    case .nearest:
        preconditionFailure("nearest doesn't use the filter")
    case .bilinear:
        return ({
            let x = abs($0)
            return x < 1 ? 1 - x : 0
        }, 1)
    case .bicubic:
        return ({
            let a = -0.5
            let x = abs($0)
            if x < 1{
                return ((a + 2) * x - (a + 3)) * x * x + 1
            }
            if x < 2{
                return (((x - 5) * x + 8) * x - 4) * a
            }
            return 0
        }, 2)
    case .lanczos:
        return ({ -3 <= $0 && $0 < 3 ? sinc($0) * sinc($0 / 3) : 0 }, 3)
    }
}

/// Same as `precompute_coeffs` in Resample.c. Returns the bounds (xmin, count) and the normalized coefficients (ksize per output pixel)
fileprivate func _pil_precompute_coeffs(inSize: Int, outSize: Int, resample: MfResample) -> (bounds: [(Int, Int)], kk: [Double], ksize: Int){
    let (filter, filterSupport) = _pil_filter(resample)
    let scale = Double(inSize) / Double(outSize)
    let filterscale = Swift.max(scale, 1)
    let support = filterSupport * filterscale
    let ksize = Int(support.rounded(.up)) * 2 + 1
    let inv_filterscale = 1 / filterscale

    var bounds: [(Int, Int)] = []
    var kk = [Double](repeating: 0, count: outSize * ksize)
    for xx in 0..<outSize{
        let center = (Double(xx) + 0.5) * scale
        // (int) cast of C truncates toward zero
        let xmin = Swift.max(Int(center - support + 0.5), 0)
        let xmax = Swift.min(Int(center + support + 0.5), inSize) - xmin
        var ww = 0.0
        for x in 0..<xmax{
            let w = filter((Double(x + xmin) - center + 0.5) * inv_filterscale)
            kk[xx * ksize + x] = w
            ww += w
        }
        if ww != 0{
            for x in 0..<xmax{
                kk[xx * ksize + x] /= ww
            }
        }
        bounds.append((xmin, xmax))
    }
    return (bounds, kk, ksize)
}

fileprivate let _PRECISION_BITS: Int32 = 32 - 8 - 2

/// Same as `normalize_coeffs_8bpc` in Resample.c
fileprivate func _pil_normalize_coeffs_8bpc(_ kk: [Double]) -> [Int32]{
    let one = Double(1 << _PRECISION_BITS)
    return kk.map{ $0 < 0 ? Int32(-0.5 + $0 * one) : Int32(0.5 + $0 * one) }
}

/// One pass of the separable convolution.
/// The source is regarded as `lines` lines of pixels, and each pixel has `channels` contiguous values.
/// The output pixel `xx` of a line is the weighted sum of the source pixels `bounds[xx].0 ..< bounds[xx].0 + bounds[xx].1`.
/// - Parameters:
///   - srcLineStride / dstLineStride: The strides between lines
///   - srcPixelStride / dstPixelStride: The strides between pixels in a line
fileprivate struct _PassLayout{
    let lines: Int
    let srcLineStride: Int, srcPixelStride: Int
    let dstLineStride: Int, dstPixelStride: Int
    let outLen: Int
    let channels: Int
}

/// 8bpc pass with PIL's fixed-point arithmetic. src and dst are integer pixels (0...255)
fileprivate func _pil_pass_8bpc(src: UnsafePointer<Int32>, dst: UnsafeMutablePointer<Int32>, _ layout: _PassLayout, bounds: [(Int, Int)], kk: [Double], ksize: Int){
    let kk8 = _pil_normalize_coeffs_8bpc(kk)
    let initial: Int32 = 1 << (_PRECISION_BITS - 1)
    let C = layout.channels
    let stride = layout.srcPixelStride

    // clip8
    func clip<V: SIMD>(_ ss: V) -> V where V.Scalar == Int32{
        return (ss &>> _PRECISION_BITS).clamped(lowerBound: .zero, upperBound: V(repeating: 255))
    }

    kk8.withUnsafeBufferPointer{
        kkptr in
        for line in 0..<layout.lines{
            let srcLine = src + line * layout.srcLineStride
            let dstLine = dst + line * layout.dstLineStride
            for xx in 0..<layout.outLen{
                let (xmin, xmax) = bounds[xx]
                let k = kkptr.baseAddress! + xx * ksize
                let p = srcLine + xmin * stride
                let out = dstLine + xx * layout.dstPixelStride

                if C <= 4{
                    // a few channels (horizontal pass): accumulate all the channels of a pixel at once in a SIMD register
                    var ss = SIMD4<Int32>(repeating: initial)
                    switch C {
                    case 1:
                        var s1 = initial
                        for x in 0..<xmax{
                            s1 = s1 &+ p[x * stride] &* k[x]
                        }
                        ss[0] = s1
                    case 3:
                        for x in 0..<xmax{
                            let q = p + x * stride
                            ss &+= SIMD4(q[0], q[1], q[2], 0) &* k[x]
                        }
                    case 4:
                        for x in 0..<xmax{
                            ss &+= UnsafeRawPointer(p + x * stride).loadUnaligned(as: SIMD4<Int32>.self) &* k[x]
                        }
                    default:
                        for x in 0..<xmax{
                            let q = p + x * stride
                            var v = SIMD4<Int32>.zero
                            for c in 0..<C{
                                v[c] = q[c]
                            }
                            ss &+= v &* k[x]
                        }
                    }
                    let clipped = clip(ss)
                    for c in 0..<C{
                        out[c] = clipped[c]
                    }
                    continue
                }

                // many channels (vertical pass): accumulate 8 channels at once in a SIMD register
                var c = 0
                while c + 8 <= C{
                    var ss = SIMD8<Int32>(repeating: initial)
                    for x in 0..<xmax{
                        ss &+= UnsafeRawPointer(p + x * stride + c).loadUnaligned(as: SIMD8<Int32>.self) &* k[x]
                    }
                    UnsafeMutableRawPointer(out + c).storeBytes(of: clip(ss), as: SIMD8<Int32>.self)
                    c += 8
                }
                while c < C{
                    var ss = initial
                    for x in 0..<xmax{
                        ss = ss &+ p[x * stride + c] &* k[x]
                    }
                    out[c] = Swift.min(Swift.max(ss >> _PRECISION_BITS, 0), 255)
                    c += 1
                }
            }
        }
    }
}

/// Convert the stored values (Float) of UInt8 image into Int32 pixels
fileprivate func _pil_float2int32(_ src: UnsafePointer<Float>, _ dst: UnsafeMutablePointer<Int32>, count: Int){
    #if canImport(Accelerate)
    vDSP_vfix32(src, 1, dst, 1, vDSP_Length(count))
    #else
    for i in 0..<count{
        dst[i] = Int32(src[i])
    }
    #endif
}

/// Convert Int32 pixels into the stored values (Float) of UInt8 image
fileprivate func _pil_int322float(_ src: UnsafePointer<Int32>, _ dst: UnsafeMutablePointer<Float>, count: Int){
    #if canImport(Accelerate)
    vDSP_vflt32(src, 1, dst, 1, vDSP_Length(count))
    #else
    for i in 0..<count{
        dst[i] = Float(src[i])
    }
    #endif
}

/// Floating point pass like PIL's mode "F". The accumulation is done in Double and stored as T
fileprivate func _pil_pass_float<T: BinaryFloatingPoint>(src: UnsafePointer<T>, dst: UnsafeMutablePointer<T>, _ layout: _PassLayout, bounds: [(Int, Int)], kk: [Double], ksize: Int){
    let C = layout.channels
    let acc = UnsafeMutablePointer<Double>.allocate(capacity: C)
    defer { acc.deallocate() }

    kk.withUnsafeBufferPointer{
        kkptr in
        for line in 0..<layout.lines{
            let srcLine = src + line * layout.srcLineStride
            let dstLine = dst + line * layout.dstLineStride
            for xx in 0..<layout.outLen{
                let (xmin, xmax) = bounds[xx]
                let k = kkptr.baseAddress! + xx * ksize
                if C <= 4{
                    // a few channels (horizontal pass): accumulate each channel in a register
                    let p = srcLine + xmin * layout.srcPixelStride
                    let out = dstLine + xx * layout.dstPixelStride
                    for c in 0..<C{
                        var ss = 0.0
                        for x in 0..<xmax{
                            ss += Double(p[x * layout.srcPixelStride + c]) * k[x]
                        }
                        out[c] = T(ss)
                    }
                    continue
                }
                // many channels (vertical pass): accumulate row by row to access the memory contiguously
                acc.initialize(repeating: 0, count: C)
                for x in 0..<xmax{
                    let w = k[x]
                    let p = srcLine + (x + xmin) * layout.srcPixelStride
                    for c in 0..<C{
                        acc[c] += Double(p[c]) * w
                    }
                }
                let out = dstLine + xx * layout.dstPixelStride
                for c in 0..<C{
                    out[c] = T(acc[c])
                }
            }
        }
    }
}

/// Same as `ImagingResample` (and `ImagingScaleAffine` for nearest) of Pillow. src and dst are row major (h, w, c)
fileprivate func _pil_resize<T: BinaryFloatingPoint>(_ src: UnsafeMutablePointer<T>, _ dst: UnsafeMutablePointer<T>, _ size: _ResampleSize, resample: MfResample, is8bpc: Bool){
    let C = size.channels

    if size.inH == size.outH && size.inW == size.outW{
        dst.update(from: src, count: size.inH * size.inW * C)
        return
    }

    if resample == .nearest{
        // The positions are accumulated as Pillow does
        let a0 = Double(size.inW) / Double(size.outW)
        let a4 = Double(size.inH) / Double(size.outH)
        var xintab: [Int] = []
        var xo = a0 * 0.5
        for _ in 0..<size.outW{
            xintab.append(xo < 0 ? -1 : Int(xo))
            xo += a0
        }
        var yo = a4 * 0.5
        for y in 0..<size.outH{
            let yi = yo < 0 ? -1 : Int(yo)
            for x in 0..<size.outW{
                (dst + (y * size.outW + x) * C).update(from: src + (yi * size.inW + xintab[x]) * C, count: C)
            }
            yo += a4
        }
        return
    }

    let need_horizontal = size.outW != size.inW
    let need_vertical = size.outH != size.inH

    var vert = _pil_precompute_coeffs(inSize: size.inH, outSize: size.outH, resample: resample)
    // First and last used rows in the source image
    let ybox_first = vert.bounds[0].0
    let ybox_last = vert.bounds[size.outH - 1].0 + vert.bounds[size.outH - 1].1

    // The layout of the horizontal pass: rows of pixels
    func horizontalLayout(rows: Int) -> _PassLayout{
        return _PassLayout(lines: rows, srcLineStride: size.inW * C, srcPixelStride: C, dstLineStride: size.outW * C, dstPixelStride: C, outLen: size.outW, channels: C)
    }
    // The layout of the vertical pass: one line of rows, whose "channels" are all the values of a row
    func verticalLayout(width: Int) -> _PassLayout{
        return _PassLayout(lines: 1, srcLineStride: 0, srcPixelStride: width * C, dstLineStride: 0, dstPixelStride: width * C, outLen: size.outH, channels: width * C)
    }
    let horiz = need_horizontal ? _pil_precompute_coeffs(inSize: size.inW, outSize: size.outW, resample: resample) : nil
    let tempRows = ybox_last - ybox_first
    if need_horizontal{
        // Shift bounds for vertical pass
        vert.bounds = vert.bounds.map{ ($0.0 - ybox_first, $0.1) }
    }

    if is8bpc{
        // PIL's 8bpc passes. The intermediate image is also rounded to 8bit. UInt8 is stored as Float
        precondition(T.self == Float.self, "UInt8 must be stored as Float")
        let count = size.inH * size.inW * C
        let src8 = UnsafeMutablePointer<Int32>.allocate(capacity: count)
        defer { src8.deallocate() }
        _pil_float2int32(UnsafeRawPointer(src).assumingMemoryBound(to: Float.self), src8, count: count)
        let dst8 = UnsafeMutablePointer<Int32>.allocate(capacity: size.outH * size.outW * C)
        defer { dst8.deallocate() }

        if let horiz = horiz{
            let temp = UnsafeMutablePointer<Int32>.allocate(capacity: tempRows * size.outW * C)
            defer { temp.deallocate() }
            _pil_pass_8bpc(src: src8 + ybox_first * size.inW * C, dst: need_vertical ? temp : dst8, horizontalLayout(rows: tempRows), bounds: horiz.bounds, kk: horiz.kk, ksize: horiz.ksize)
            if need_vertical{
                _pil_pass_8bpc(src: temp, dst: dst8, verticalLayout(width: size.outW), bounds: vert.bounds, kk: vert.kk, ksize: vert.ksize)
            }
        }
        else{
            _pil_pass_8bpc(src: src8, dst: dst8, verticalLayout(width: size.inW), bounds: vert.bounds, kk: vert.kk, ksize: vert.ksize)
        }
        _pil_int322float(dst8, UnsafeMutableRawPointer(dst).assumingMemoryBound(to: Float.self), count: size.outH * size.outW * C)
    }
    else{
        if let horiz = horiz{
            let temp = UnsafeMutablePointer<T>.allocate(capacity: tempRows * size.outW * C)
            defer { temp.deallocate() }
            _pil_pass_float(src: src + ybox_first * size.inW * C, dst: need_vertical ? temp : dst, horizontalLayout(rows: tempRows), bounds: horiz.bounds, kk: horiz.kk, ksize: horiz.ksize)
            if need_vertical{
                _pil_pass_float(src: temp, dst: dst, verticalLayout(width: size.outW), bounds: vert.bounds, kk: vert.kk, ksize: vert.ksize)
            }
        }
        else{
            _pil_pass_float(src: src, dst: dst, verticalLayout(width: size.inW), bounds: vert.bounds, kk: vert.kk, ksize: vert.ksize)
        }
    }
}
