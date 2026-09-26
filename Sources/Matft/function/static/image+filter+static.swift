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
       Convolve (correlate) the image with the kernel. Same as cv2.filter2D.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - ddepth: (Optional) The destination mftype (UInt8 or Float). nil means same as src
            - kernel: The 2d kernel
            - anchor: (Optional) The anchor (x, y) of the kernel. nil means the center
            - delta: (Optional) The value added to the result
            - borderType: (Optional) The border type, by default Replicate
       - Returns: MfArray
    */
    public static func filter2D(_ src: MfArray, ddepth: MfType? = nil, kernel: MfArray, anchor: (x: Int, y: Int)? = nil, delta: Float = 0, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(kernel.ndim == 2, "kernel must be 2d, but got \(kernel.shape)")

        let ret = convolve_by_vImage(src, kernel: image2floats(kernel.astype(.Float)), kernelHeight: kernel.shape[0], kernelWidth: kernel.shape[1], anchor: anchor, borderType: borderType)
        return convert_image_depth(delta == 0 ? ret : ret + delta, ddepth ?? src.mftype)
    }

    /**
       Apply the separable filter. Same as cv2.sepFilter2D.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - ddepth: (Optional) The destination mftype (UInt8 or Float). nil means same as src
            - kernelX: The kernel along x axis
            - kernelY: The kernel along y axis
            - anchor: (Optional) The anchor (x, y) of the kernel. nil means the center
            - delta: (Optional) The value added to the result
            - borderType: (Optional) The border type, by default Replicate
       - Returns: MfArray
    */
    public static func sepFilter2D(_ src: MfArray, ddepth: MfType? = nil, kernelX: MfArray, kernelY: MfArray, anchor: (x: Int, y: Int)? = nil, delta: Float = 0, borderType: MfBorderType = .Replicate) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)

        let ret = sep_convolve_by_vImage(src, kernelX: image2floats(kernelX.astype(.Float)), kernelY: image2floats(kernelY.astype(.Float)), anchor: anchor, borderType: borderType)
        return convert_image_depth(delta == 0 ? ret : ret + delta, ddepth ?? src.mftype)
    }

    /**
       Blur the image with the box filter. Same as cv2.boxFilter.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - ddepth: (Optional) The destination mftype (UInt8 or Float). nil means same as src
            - ksize: The kernel size (width, height)
            - anchor: (Optional) The anchor (x, y) of the kernel. nil means the center
            - normalize: (Optional) Whether to normalize the kernel by its area, by default true
            - borderType: (Optional) The border type, by default Replicate
       - Returns: MfArray
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
       Blur the image with the normalized box filter. Same as cv2.blur.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - ksize: The kernel size (width, height)
            - anchor: (Optional) The anchor (x, y) of the kernel. nil means the center
            - borderType: (Optional) The border type, by default Replicate
       - Returns: MfArray
    */
    public static func blur(_ src: MfArray, ksize: (width: Int, height: Int), anchor: (x: Int, y: Int)? = nil, borderType: MfBorderType = .Replicate) -> MfArray{
        return Matft.image.boxFilter(src, ksize: ksize, anchor: anchor, normalize: true, borderType: borderType)
    }

    /**
       Get the Gaussian kernel. Same as cv2.getGaussianKernel.
       - parameters:
            - ksize: The kernel size (odd)
            - sigma: The standard deviation. If it's not positive, it's computed from ksize
       - Returns: The Float kernel (shape = (ksize, 1))
    */
    public static func getGaussianKernel(ksize: Int, sigma: Float) -> MfArray{
        precondition(ksize > 0 && ksize % 2 == 1, "ksize must be positive and odd")
        return floats2image(gaussian_kernel(ksize: ksize, sigma: Double(sigma)), shape: [ksize, 1], mftype: .Float)
    }

    /**
       Blur the image with the Gaussian filter. Same as cv2.GaussianBlur.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - ksize: The kernel size (width, height). Each must be positive and odd, or zero to be computed from sigma
            - sigmaX: The standard deviation along x axis
            - sigmaY: (Optional) The standard deviation along y axis. Zero means same as sigmaX
            - borderType: (Optional) The border type, by default Replicate
       - Returns: MfArray
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
       Get the kernels for derivatives. Same as cv2.getDerivKernels.
       - parameters:
            - dx: The derivative order along x axis
            - dy: The derivative order along y axis
            - ksize: The kernel size (1, 3, 5 or 7)
            - normalize: (Optional) Whether to normalize the kernels, by default false
       - Returns: The kernels along x and y axes (shape = (n, 1))
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
       Calculate the derivatives with the Sobel operator. Same as cv2.Sobel.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - ddepth: (Optional) The destination mftype (UInt8 or Float). nil means same as src. Note that UInt8 loses the negative values
            - dx: The derivative order along x axis
            - dy: The derivative order along y axis
            - ksize: (Optional) The kernel size (1, 3, 5 or 7), by default 3
            - scale: (Optional) The scale factor, by default 1
            - delta: (Optional) The value added to the result, by default 0
            - borderType: (Optional) The border type, by default Replicate
       - Returns: MfArray
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
       Calculate the Laplacian. Same as cv2.Laplacian.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - ddepth: (Optional) The destination mftype (UInt8 or Float). nil means same as src. Note that UInt8 loses the negative values
            - ksize: (Optional) The kernel size (1, 3, 5 or 7), by default 1
            - scale: (Optional) The scale factor, by default 1
            - delta: (Optional) The value added to the result, by default 0
            - borderType: (Optional) The border type, by default Replicate
       - Returns: MfArray
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
       Apply the adaptive threshold. Same as cv2.adaptiveThreshold.
       - parameters:
            - src: A 1 channel UInt8 image mfarray
            - maxValue: The value assigned to the pixels satisfying the condition
            - adaptiveMethod: Mean or Gaussian
            - thresholdType: Binary or BinaryInv
            - blockSize: The size of the neighborhood (odd and greater than 1)
            - C: The constant subtracted from the mean
       - Returns: UInt8 mfarray
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
