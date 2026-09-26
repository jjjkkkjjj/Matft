//
//  image+filter+static.swift
//
//
//  Filtering and edge detection functions similar to OpenCV.
//  Note that the default border type is Replicate, because OpenCV's default (BORDER_REFLECT_101) is not supported by vImage.
//

#if canImport(Accelerate)
import Foundation
import Accelerate

extension Matft.image{

    /**
       Convolves (correlates) an image with a 2D kernel.

       Equivalent to `cv2.filter2D`. As in OpenCV, the kernel is not flipped, i.e. this computes the correlation.
       Each channel of a `(height, width)` or `(height, width, channels)` image is filtered independently,
       and the result is computed in Float.

       - Parameters:
            - src: An image mfarray (UInt8 or Float).
            - ddepth: The destination mftype (UInt8 or Float). `nil` (default) means the same as `src`.
            - kernel: The 2D kernel of shape `(kernel_height, kernel_width)`.
            - anchor: The anchor `(x, y)` inside the kernel. `nil` (default) means the center.
            - delta: The value added to the result, by default 0.
            - borderType: How to extrapolate pixels outside the image, by default `.Replicate`.
              `.Constant` pads with 0.
       - Returns: The filtered mfarray with the same shape as `src`. UInt8 results are rounded and saturated.
       - Precondition: The mftype of `src` must be UInt8 or Float, and `kernel` must be 2D.
       - Note: The default border differs from OpenCV's `BORDER_REFLECT_101`, which vImage does not support.
    */
    public static func filter2D(_ src: MfArray, ddepth: MfType? = nil, kernel: MfArray, anchor: (x: Int, y: Int)? = nil, delta: Float = 0, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(kernel.ndim == 2, "kernel must be 2d, but got \(kernel.shape)")

        let ret = convolve_by_vImage(src, kernel: image2floats(kernel.astype(.Float)), kernelHeight: kernel.shape[0], kernelWidth: kernel.shape[1], anchor: anchor, borderType: borderType)
        return convert_image_depth(delta == 0 ? ret : ret + delta, ddepth ?? src.mftype)
    }

    /**
       Applies a separable linear filter to an image.

       Equivalent to `cv2.sepFilter2D`: each row is filtered with `kernelX`, then each column with `kernelY`.
       Each channel is filtered independently.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - ddepth: The destination mftype (UInt8 or Float). `nil` (default) means the same as `src`.
            - kernelX: The 1D kernel applied along the x (width) axis. Any shape is flattened.
            - kernelY: The 1D kernel applied along the y (height) axis. Any shape is flattened.
            - anchor: The anchor `(x, y)` inside the kernel. `nil` (default) means the center.
            - delta: The value added to the result, by default 0.
            - borderType: How to extrapolate pixels outside the image, by default `.Replicate`.
              `.Constant` pads with 0.
       - Returns: The filtered mfarray with the same shape as `src`. UInt8 results are rounded and saturated.
       - Precondition: The mftype of `src` must be UInt8 or Float.
    */
    public static func sepFilter2D(_ src: MfArray, ddepth: MfType? = nil, kernelX: MfArray, kernelY: MfArray, anchor: (x: Int, y: Int)? = nil, delta: Float = 0, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)

        let ret = sep_convolve_by_vImage(src, kernelX: image2floats(kernelX.astype(.Float)), kernelY: image2floats(kernelY.astype(.Float)), anchor: anchor, borderType: borderType)
        return convert_image_depth(delta == 0 ? ret : ret + delta, ddepth ?? src.mftype)
    }

    /**
       Blurs an image with a box filter.

       Equivalent to `cv2.boxFilter`. With `normalize` the result is the mean over the `ksize` window.
       For a normalized UInt8 result, halves are rounded up as OpenCV does (e.g. 32.5 becomes 33).

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - ddepth: The destination mftype (UInt8 or Float). `nil` (default) means the same as `src`.
            - ksize: The kernel size `(width, height)`.
            - anchor: The anchor `(x, y)` inside the kernel. `nil` (default) means the center.
            - normalize: Whether to divide by the kernel area, by default `true`. If `false`, the result is the sum.
            - borderType: How to extrapolate pixels outside the image, by default `.Replicate`.
              `.Constant` pads with 0.
       - Returns: The filtered mfarray with the same shape as `src`.
       - Precondition: The mftype of `src` must be UInt8 or Float, and `ksize` must be positive.
    */
    public static func boxFilter(_ src: MfArray, ddepth: MfType? = nil, ksize: (width: Int, height: Int), anchor: (x: Int, y: Int)? = nil, normalize: Bool = true, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(ksize.width > 0 && ksize.height > 0, "ksize must be positive")

        let kernelX = Array(repeating: normalize ? 1/Float(ksize.width) : 1, count: ksize.width)
        let kernelY = Array(repeating: normalize ? 1/Float(ksize.height) : 1, count: ksize.height)
        let ret = sep_convolve_by_vImage(src, kernelX: kernelX, kernelY: kernelY, anchor: anchor, borderType: borderType)
        let depth = ddepth ?? src.mftype
        if depth == .UInt8 && normalize{
            // OpenCV's UInt8 box filter rounds halves up (e.g. 32.5 -> 33), unlike saturate_cast (half to even).
            // The exact mean is a multiple of 1/(w*h), so a quarter of it absorbs the Float error without reaching another value
            let eps = 0.25 / Float(ksize.width * ksize.height)
            return convert_image_depth(Matft.math.floor(ret + (0.5 + eps)), depth)
        }
        return convert_image_depth(ret, depth)
    }

    /**
       Blurs an image with a normalized box filter.

       Equivalent to `cv2.blur`. Same as `boxFilter(_:ddepth:ksize:anchor:normalize:borderType:)` with `normalize: true`.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - ksize: The kernel size `(width, height)`.
            - anchor: The anchor `(x, y)` inside the kernel. `nil` (default) means the center.
            - borderType: How to extrapolate pixels outside the image, by default `.Replicate`.
              `.Constant` pads with 0.
       - Returns: The blurred mfarray with the same shape and mftype as `src`.
       - Precondition: The mftype of `src` must be UInt8 or Float, and `ksize` must be positive.
    */
    public static func blur(_ src: MfArray, ksize: (width: Int, height: Int), anchor: (x: Int, y: Int)? = nil, borderType: MfBorderType = .Replicate) -> MfArray{
        return Matft.image.boxFilter(src, ksize: ksize, anchor: anchor, normalize: true, borderType: borderType)
    }

    /**
       Returns the 1D Gaussian filter coefficients.

       Equivalent to `cv2.getGaussianKernel` with `ktype=CV_32F`. The coefficients sum to 1.
       For a non-positive `sigma`, it is computed as `0.3 * ((ksize - 1) * 0.5 - 1) + 0.8`, and the
       fixed OpenCV kernels are used for `ksize` of 1, 3, 5, 7 and 9.

       - Parameters:
            - ksize: The kernel size. It must be positive and odd.
            - sigma: The standard deviation. If it is not positive, it is computed from `ksize`.
       - Returns: The Float kernel of shape `(ksize, 1)`.
       - Precondition: `ksize` must be positive and odd.
    */
    public static func getGaussianKernel(ksize: Int, sigma: Float) -> MfArray{
        precondition(ksize > 0 && ksize % 2 == 1, "ksize must be positive and odd")
        return floats2image(gaussian_kernel(ksize: ksize, sigma: Double(sigma)), shape: [ksize, 1], mftype: .Float)
    }

    /**
       Blurs an image with a Gaussian filter.

       Equivalent to `cv2.GaussianBlur`. The filter is applied separably with `getGaussianKernel(ksize:sigma:)`
       along each axis. Each channel is filtered independently.

       ```swift
       let blurred = Matft.image.GaussianBlur(image, ksize: (9, 9), sigmaX: 0)
       ```

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - ksize: The kernel size `(width, height)`. Each must be positive and odd, or 0 to be computed
              from the sigma (as OpenCV: about 3 sigma for UInt8 and 4 sigma for Float on each side).
            - sigmaX: The standard deviation along the x axis. If it is not positive, it is computed from `ksize.width`.
            - sigmaY: The standard deviation along the y axis, by default 0 which means the same as `sigmaX`.
            - borderType: How to extrapolate pixels outside the image, by default `.Replicate`.
              `.Constant` pads with 0.
       - Returns: The blurred mfarray with the same shape and mftype as `src`. UInt8 results are rounded and saturated.
       - Precondition: The mftype of `src` must be UInt8 or Float, and the resulting kernel size must be positive and odd.
    */
    public static func GaussianBlur(_ src: MfArray, ksize: (width: Int, height: Int), sigmaX: Float, sigmaY: Float = 0, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)

        let sigmaY = sigmaY <= 0 ? sigmaX : sigmaY
        func computedSize(_ ksize: Int, _ sigma: Float) -> Int{
            if ksize > 0 || sigma <= 0{
                return ksize
            }
            return Int((sigma*(src.mftype == .UInt8 ? 3 : 4)*2 + 1).rounded(.toNearestOrEven)) | 1
        }
        let (kw, kh) = (computedSize(ksize.width, sigmaX), computedSize(ksize.height, sigmaY))
        precondition(kw > 0 && kw % 2 == 1 && kh > 0 && kh % 2 == 1, "ksize must be positive and odd")

        let ret = sep_convolve_by_vImage(src, kernelX: gaussian_kernel(ksize: kw, sigma: Double(sigmaX)), kernelY: gaussian_kernel(ksize: kh, sigma: Double(sigmaY)), borderType: borderType)
        return convert_image_depth(ret, src.mftype)
    }

    /**
       Returns the separable filter coefficients for image derivatives.

       Equivalent to `cv2.getDerivKernels` with `ktype=CV_32F`. The kernels are the Sobel kernels;
       if `ksize` is 1 and the order is positive, a 3-tap kernel is returned as in OpenCV.

       - Parameters:
            - dx: The derivative order along the x axis.
            - dy: The derivative order along the y axis.
            - ksize: The aperture size. It must be odd and in `1...31`.
            - normalize: Whether to scale the kernels so that they give the normalized derivatives, by default `false`.
       - Returns: A tuple of the Float kernels along the x axis (`kx`) and the y axis (`ky`), each of shape `(n, 1)`.
       - Precondition: `ksize` must be odd and in `1...31`, and each order must be less than the (effective) kernel size.
    */
    public static func getDerivKernels(dx: Int, dy: Int, ksize: Int, normalize: Bool = false) -> (kx: MfArray, ky: MfArray){
        precondition(ksize % 2 == 1 && ksize > 0 && ksize <= 31, "ksize must be positive and odd")
        func kernel(_ order: Int) -> MfArray{
            var k = sobel_kernel(ksize: ksize, order: order)
            if normalize{
                let scale = 1/Float(1 << (k.count - order - 1))
                k = k.map{ $0*scale }
            }
            return floats2image(k, shape: [k.count, 1], mftype: .Float)
        }
        return (kernel(dx), kernel(dy))
    }

    /**
       Calculates image derivatives with the extended Sobel operator.

       Equivalent to `cv2.Sobel`. Each channel is processed independently.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - ddepth: The destination mftype (UInt8 or Float). `nil` (default) means the same as `src`.
              Note that UInt8 saturates the negative values to 0, so pass `.Float` to keep them.
            - dx: The derivative order along the x axis.
            - dy: The derivative order along the y axis.
            - ksize: The kernel size (1, 3, 5 or 7), by default 3. `cv2.FILTER_SCHARR` is not supported.
            - scale: The scale factor applied to the derivatives, by default 1.
            - delta: The value added to the result, by default 0.
            - borderType: How to extrapolate pixels outside the image, by default `.Replicate`.
              `.Constant` pads with 0.
       - Returns: The derivative mfarray with the same shape as `src`.
       - Precondition: The mftype of `src` must be UInt8 or Float, `dx` and `dy` must be non-negative with
         `dx + dy > 0`, and `ksize` must be 1, 3, 5 or 7.
    */
    public static func Sobel(_ src: MfArray, ddepth: MfType? = nil, dx: Int, dy: Int, ksize: Int = 3, scale: Float = 1, delta: Float = 0, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(dx >= 0 && dy >= 0 && dx + dy > 0, "dx and dy must be non-negative and dx + dy > 0")
        precondition([1, 3, 5, 7].contains(ksize), "ksize must be 1, 3, 5 or 7")

        let ret = sep_convolve_by_vImage(src, kernelX: sobel_kernel(ksize: ksize, order: dx), kernelY: sobel_kernel(ksize: ksize, order: dy), borderType: borderType)
        return convert_image_depth(scale == 1 && delta == 0 ? ret : ret*scale + delta, ddepth ?? src.mftype)
    }

    /**
       Calculates the Laplacian of an image.

       Equivalent to `cv2.Laplacian`. For `ksize` 1 the kernel is `[[0, 1, 0], [1, -4, 1], [0, 1, 0]]`,
       for 3 it is `[[2, 0, 2], [0, -8, 0], [2, 0, 2]]`, and for 5 and 7 it is the sum of the second
       Sobel derivatives along x and y.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - ddepth: The destination mftype (UInt8 or Float). `nil` (default) means the same as `src`.
              Note that UInt8 saturates the negative values to 0, so pass `.Float` to keep them.
            - ksize: The aperture size (1, 3, 5 or 7), by default 1.
            - scale: The scale factor applied to the Laplacian, by default 1.
            - delta: The value added to the result, by default 0.
            - borderType: How to extrapolate pixels outside the image, by default `.Replicate`.
              `.Constant` pads with 0.
       - Returns: The Laplacian mfarray with the same shape as `src`.
       - Precondition: The mftype of `src` must be UInt8 or Float, and `ksize` must be 1, 3, 5 or 7.
    */
    public static func Laplacian(_ src: MfArray, ddepth: MfType? = nil, ksize: Int = 1, scale: Float = 1, delta: Float = 0, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition([1, 3, 5, 7].contains(ksize), "ksize must be 1, 3, 5 or 7")

        let ret: MfArray
        switch ksize{
        case 1:
            ret = convolve_by_vImage(src, kernel: [0, 1, 0, 1, -4, 1, 0, 1, 0], kernelHeight: 3, kernelWidth: 3, borderType: borderType)
        case 3:
            ret = convolve_by_vImage(src, kernel: [2, 0, 2, 0, -8, 0, 2, 0, 2], kernelHeight: 3, kernelWidth: 3, borderType: borderType)
        default:
            let d2x = sep_convolve_by_vImage(src, kernelX: sobel_kernel(ksize: ksize, order: 2), kernelY: sobel_kernel(ksize: ksize, order: 0), borderType: borderType)
            let d2y = sep_convolve_by_vImage(src, kernelX: sobel_kernel(ksize: ksize, order: 0), kernelY: sobel_kernel(ksize: ksize, order: 2), borderType: borderType)
            ret = d2x + d2y
        }
        return convert_image_depth(scale == 1 && delta == 0 ? ret : ret*scale + delta, ddepth ?? src.mftype)
    }

    /**
       Applies an adaptive threshold to a grayscale image.

       Equivalent to `cv2.adaptiveThreshold`. The threshold of each pixel is the mean (`.Mean`) or the
       Gaussian-weighted mean (`.Gaussian`) of its `blockSize` x `blockSize` neighborhood minus `C`.
       The neighborhood is computed with the `.Replicate` border.

       - Parameters:
            - src: A 1-channel UInt8 image mfarray of `(height, width)` or `(height, width, 1)`.
            - maxValue: The value assigned to the pixels satisfying the condition. It is rounded and saturated into `0...255`.
            - adaptiveMethod: `.Mean` or `.Gaussian`.
            - thresholdType: `.Binary` or `.BinaryInv`.
            - blockSize: The size of the neighborhood. It must be odd and greater than 1.
            - C: The constant subtracted from the (weighted) mean.
       - Returns: The UInt8 mfarray with the same shape as `src`.
       - Precondition: `src` must be a 1-channel UInt8 image, `thresholdType` must be `.Binary` or `.BinaryInv`,
         and `blockSize` must be odd and greater than 1.
    */
    public static func adaptiveThreshold(_ src: MfArray, maxValue: Float, adaptiveMethod: MfAdaptiveMethod, thresholdType: MfThresholdType, blockSize: Int, C: Float) -> MfArray{
        precondition(src.mftype == .UInt8 && (src.ndim == 2 || (src.ndim == 3 && src.shape[2] == 1)), "adaptiveThreshold supports 1 channel UInt8 image only")
        precondition(thresholdType == .Binary || thresholdType == .BinaryInv, "thresholdType must be Binary or BinaryInv")
        precondition(blockSize % 2 == 1 && blockSize > 1, "blockSize must be odd and greater than 1")

        let mean: MfArray
        switch adaptiveMethod{
        case .Mean:
            mean = Matft.image.boxFilter(src, ksize: (blockSize, blockSize), borderType: .Replicate)
        case .Gaussian:
            mean = Matft.image.GaussianBlur(src, ksize: (blockSize, blockSize), sigmaX: 0, borderType: .Replicate)
        }

        // same as OpenCV: src - mean > -ceil(C) for Binary, src - mean <= -floor(C) for BinaryInv
        let imaxval = min(max(maxValue.rounded(.toNearestOrEven), 0), 255)
        let diff = src.astype(.Float) - mean.astype(.Float)
        let mask: MfArray
        if thresholdType == .Binary{
            mask = (diff > -C.rounded(.up)).astype(.Float)
        }
        else{
            mask = (diff <= -C.rounded(.down)).astype(.Float)
        }
        return convert_image_depth(mask * imaxval, .UInt8)
    }
}
#endif
