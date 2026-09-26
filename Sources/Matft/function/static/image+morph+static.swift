//
//  image+morph+static.swift
//
//
//  Morphological functions similar to OpenCV.
//

#if canImport(Accelerate)
import Foundation
import Accelerate

extension Matft.image{

    /**
       Returns a structuring element of the given shape for morphological operations.

       Equivalent to `cv2.getStructuringElement`.

       - Parameters:
            - shape: The shape of the element (`.Rect`, `.Cross` or `.Ellipse`).
            - ksize: The size `(width, height)` of the element.
            - anchor: The anchor `(x, y)` inside the element. It only affects `.Cross`.
              `nil` (default) means the center.
       - Returns: The UInt8 mfarray of shape `(height, width)` whose elements are 0 or 1.
       - Precondition: `ksize` must be positive.
    */
    public static func getStructuringElement(shape: MfMorphShape, ksize: (width: Int, height: Int), anchor: (x: Int, y: Int)? = nil) -> MfArray{
        precondition(ksize.width > 0 && ksize.height > 0, "ksize must be positive")
        let mask = structuring_element(shape, width: ksize.width, height: ksize.height, anchor: anchor)
        return floats2image(mask.map{ $0 ? 1 : 0 }, shape: [ksize.height, ksize.width], mftype: .UInt8)
    }

    /**
       Erodes an image with a structuring element (local minimum).

       Equivalent to `cv2.erode` with the default border, i.e. pixels outside the image are ignored.
       Each channel of a `(height, width)` or `(height, width, channels)` image is processed independently.

       - Parameters:
            - src: An image mfarray (UInt8 or Float).
            - kernel: The 2D structuring element whose non-zero elements are used, e.g. from
              `getStructuringElement(shape:ksize:anchor:)`. `nil` (default) means a 3x3 rectangle.
            - anchor: The anchor `(x, y)` inside the kernel. `nil` (default) means the center.
            - iterations: The number of times erosion is applied, by default 1.
       - Returns: The eroded mfarray with the same shape and mftype as `src`.
       - Precondition: The mftype of `src` must be UInt8 or Float, `kernel` must be 2D, and `iterations` must be non-negative.
    */
    public static func erode(_ src: MfArray, kernel: MfArray? = nil, anchor: (x: Int, y: Int)? = nil, iterations: Int = 1) -> MfArray{
        return morphology(src, kernel: kernel, anchor: anchor, iterations: iterations, isDilate: false)
    }

    /**
       Dilates an image with a structuring element (local maximum).

       Equivalent to `cv2.dilate` with the default border, i.e. pixels outside the image are ignored.
       Each channel of a `(height, width)` or `(height, width, channels)` image is processed independently.

       - Parameters:
            - src: An image mfarray (UInt8 or Float).
            - kernel: The 2D structuring element whose non-zero elements are used, e.g. from
              `getStructuringElement(shape:ksize:anchor:)`. `nil` (default) means a 3x3 rectangle.
            - anchor: The anchor `(x, y)` inside the kernel. `nil` (default) means the center.
            - iterations: The number of times dilation is applied, by default 1.
       - Returns: The dilated mfarray with the same shape and mftype as `src`.
       - Precondition: The mftype of `src` must be UInt8 or Float, `kernel` must be 2D, and `iterations` must be non-negative.
    */
    public static func dilate(_ src: MfArray, kernel: MfArray? = nil, anchor: (x: Int, y: Int)? = nil, iterations: Int = 1) -> MfArray{
        return morphology(src, kernel: kernel, anchor: anchor, iterations: iterations, isDilate: true)
    }

    /**
       Performs an advanced morphological transformation.

       Equivalent to `cv2.morphologyEx` with the default border. The operations are composed of
       `erode(_:kernel:anchor:iterations:)` and `dilate(_:kernel:anchor:iterations:)`:
       `.Open` is dilate(erode), `.Close` is erode(dilate), `.Gradient` is dilate - erode,
       `.TopHat` is src - open and `.BlackHat` is close - src.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - op: The morphological operation.
            - kernel: The 2D structuring element whose non-zero elements are used.
            - anchor: The anchor `(x, y)` inside the kernel. `nil` (default) means the center.
            - iterations: The number of times erosion and dilation are applied, by default 1.
       - Returns: The transformed mfarray with the same shape and mftype as `src`. UInt8 differences are saturated at 0.
       - Precondition: The mftype of `src` must be UInt8 or Float, and `kernel` must be 2D.
    */
    public static func morphologyEx(_ src: MfArray, op: MfMorphOp, kernel: MfArray, anchor: (x: Int, y: Int)? = nil, iterations: Int = 1) -> MfArray{
        func erode(_ x: MfArray) -> MfArray{
            return Matft.image.erode(x, kernel: kernel, anchor: anchor, iterations: iterations)
        }
        func dilate(_ x: MfArray) -> MfArray{
            return Matft.image.dilate(x, kernel: kernel, anchor: anchor, iterations: iterations)
        }
        func sub(_ l: MfArray, _ r: MfArray) -> MfArray{
            return convert_image_depth(l.astype(.Float) - r.astype(.Float), src.mftype)
        }

        switch op{
        case .Erode:
            return erode(src)
        case .Dilate:
            return dilate(src)
        case .Open:
            return dilate(erode(src))
        case .Close:
            return erode(dilate(src))
        case .Gradient:
            return sub(dilate(src), erode(src))
        case .TopHat:
            return sub(src, dilate(erode(src)))
        case .BlackHat:
            return sub(erode(dilate(src)), src)
        }
    }

    private static func morphology(_ src: MfArray, kernel: MfArray?, anchor: (x: Int, y: Int)?, iterations: Int, isDilate: Bool) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(iterations >= 0, "iterations must be non-negative")

        let kernel = kernel ?? Matft.nums(Float(1), shape: [3, 3])
        precondition(kernel.ndim == 2, "kernel must be 2d, but got \(kernel.shape)")
        let mask = image2floats(kernel.astype(.Float)).map{ $0 != 0 }

        var ret = src
        for _ in 0..<iterations{
            ret = morphology_by_vImage(ret, mask: mask, maskHeight: kernel.shape[0], maskWidth: kernel.shape[1], anchor: anchor, isDilate: isDilate)
        }
        return ret
    }
}
#endif
