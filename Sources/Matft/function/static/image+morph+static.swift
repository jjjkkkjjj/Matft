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
       Get the structuring element. Same as cv2.getStructuringElement.
       - parameters:
            - shape: The shape of the element
            - ksize: The size (width, height)
            - anchor: (Optional) The anchor (x, y) used for Cross. nil means the center
       - Returns: UInt8 mfarray (shape = (height, width)) whose elements are 0 or 1
    */
    public static func getStructuringElement(shape: MfMorphShape, ksize: (width: Int, height: Int), anchor: (x: Int, y: Int)? = nil) -> MfArray{
        precondition(ksize.width > 0 && ksize.height > 0, "ksize must be positive")
        let mask = structuring_element(shape, width: ksize.width, height: ksize.height, anchor: anchor)
        return floats2image(mask.map{ $0 ? 1 : 0 }, shape: [ksize.height, ksize.width], mftype: .UInt8)
    }

    /**
       Erode the image. Same as cv2.erode with the default border.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - kernel: (Optional) The structuring element (non-zero elements are used). nil means 3x3 rectangle
            - anchor: (Optional) The anchor (x, y) of the kernel. nil means the center
            - iterations: (Optional) The number of times erosion is applied, by default 1
       - Returns: MfArray
    */
    public static func erode(_ src: MfArray, kernel: MfArray? = nil, anchor: (x: Int, y: Int)? = nil, iterations: Int = 1) -> MfArray{
        return morphology(src, kernel: kernel, anchor: anchor, iterations: iterations, isDilate: false)
    }

    /**
       Dilate the image. Same as cv2.dilate with the default border.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - kernel: (Optional) The structuring element (non-zero elements are used). nil means 3x3 rectangle
            - anchor: (Optional) The anchor (x, y) of the kernel. nil means the center
            - iterations: (Optional) The number of times dilation is applied, by default 1
       - Returns: MfArray
    */
    public static func dilate(_ src: MfArray, kernel: MfArray? = nil, anchor: (x: Int, y: Int)? = nil, iterations: Int = 1) -> MfArray{
        return morphology(src, kernel: kernel, anchor: anchor, iterations: iterations, isDilate: true)
    }

    /**
       Apply the advanced morphological transformation. Same as cv2.morphologyEx with the default border.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - op: The morphological operation
            - kernel: The structuring element (non-zero elements are used)
            - anchor: (Optional) The anchor (x, y) of the kernel. nil means the center
            - iterations: (Optional) The number of times erosion and dilation are applied, by default 1
       - Returns: MfArray
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
