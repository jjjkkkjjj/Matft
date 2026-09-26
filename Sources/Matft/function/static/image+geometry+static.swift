//
//  image+geometry+static.swift
//
//
//  Geometric transformation functions similar to OpenCV.
//

#if canImport(Accelerate)
import Foundation
import Accelerate

extension Matft.image{

    /**
       Flip the image. Same as cv2.flip.
       - parameters:
            - src: An image mfarray
            - flipCode: 0 means flipping around the x axis (vertical), positive means around the y axis (horizontal), and negative means both
       - Returns: The row contiguous mfarray
    */
    public static func flip(_ src: MfArray, flipCode: Int) -> MfArray{
        precondition(src.ndim == 2 || src.ndim == 3, "src must be 2d or 3d, but got \(src.shape)")
        return flip_image(src, vertical: flipCode <= 0, horizontal: flipCode != 0)
    }

    /**
       Rotate the image by 90 degrees multiples. Same as cv2.rotate.
       - parameters:
            - src: An image mfarray
            - rotateCode: The rotation
       - Returns: The row contiguous mfarray
    */
    public static func rotate(_ src: MfArray, rotateCode: MfRotateCode) -> MfArray{
        precondition(src.ndim == 2 || src.ndim == 3, "src must be 2d or 3d, but got \(src.shape)")
        switch rotateCode{
        case .Rotate90Clockwise:
            return flip_image(src.swapaxes(axis1: 0, axis2: 1), vertical: false, horizontal: true)
        case .Rotate180:
            return flip_image(src, vertical: true, horizontal: true)
        case .Rotate90Counterclockwise:
            return flip_image(src.swapaxes(axis1: 0, axis2: 1), vertical: true, horizontal: false)
        }
    }

    /**
       Get the affine matrix of 2d rotation. Same as cv2.getRotationMatrix2D.
       - parameters:
            - center: The center (x, y) of the rotation
            - angle: The rotation angle in degrees. Positive values mean counter-clockwise rotation
            - scale: The isotropic scale factor
       - Returns: The Double affine matrix (shape = (2, 3))
    */
    public static func getRotationMatrix2D(center: (x: Float, y: Float), angle: Float, scale: Float) -> MfArray{
        let rad = Double(angle) * Double.pi / 180
        let alpha = cos(rad) * Double(scale)
        let beta = sin(rad) * Double(scale)
        let (cx, cy) = (Double(center.x), Double(center.y))
        return MfArray([[alpha, beta, (1 - alpha)*cx - beta*cy],
                        [-beta, alpha, beta*cx + (1 - alpha)*cy]] as [[Double]])
    }

    /**
       Calculate the affine transform from 3 pairs of the corresponding points. Same as cv2.getAffineTransform.
       - parameters:
            - src: The source points (shape = (3, 2))
            - dst: The destination points (shape = (3, 2))
       - Returns: The Double affine matrix (shape = (2, 3))
    */
    public static func getAffineTransform(src: MfArray, dst: MfArray) -> MfArray{
        precondition(src.shape == [3, 2] && dst.shape == [3, 2], "src and dst must be (3, 2)")
        let s = image2doubles(src)
        let d = image2doubles(dst)
        // [x y 1] * [a b c]^T = x'
        let A = MfArray((0..<3).map{ [s[2*$0], s[2*$0 + 1], 1] } as [[Double]])
        let b = MfArray((0..<3).map{ [d[2*$0], d[2*$0 + 1]] } as [[Double]])
        let x = try! Matft.linalg.solve(A, b: b)
        return x.T.to_contiguous(mforder: .Row)
    }

    /**
       Calculate the perspective transform from 4 pairs of the corresponding points. Same as cv2.getPerspectiveTransform.
       - parameters:
            - src: The source points (shape = (4, 2))
            - dst: The destination points (shape = (4, 2))
       - Returns: The Double perspective matrix (shape = (3, 3))
    */
    public static func getPerspectiveTransform(src: MfArray, dst: MfArray) -> MfArray{
        precondition(src.shape == [4, 2] && dst.shape == [4, 2], "src and dst must be (4, 2)")
        let s = image2doubles(src)
        let d = image2doubles(dst)
        var A = Array(repeating: Array(repeating: 0.0, count: 8), count: 8)
        var b = Array(repeating: [0.0], count: 8)
        for i in 0..<4{
            let (x, y, u, v) = (s[2*i], s[2*i + 1], d[2*i], d[2*i + 1])
            A[i] = [x, y, 1, 0, 0, 0, -x*u, -y*u]
            A[i + 4] = [0, 0, 0, x, y, 1, -x*v, -y*v]
            b[i] = [u]
            b[i + 4] = [v]
        }
        let h = image2doubles(try! Matft.linalg.solve(MfArray(A), b: MfArray(b)))
        return MfArray((h + [1]) as [Double]).reshape([3, 3])
    }

    /**
       Apply the perspective transformation. Same as cv2.warpPerspective.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - M: The perspective matrix (shape = (3, 3)) mapping the source coordinate into the destination one
            - dsize: The destination size (width, height)
            - interpolation: (Optional) Linear or Nearest, by default Linear
            - borderMode: (Optional) The border type, by default Constant
            - borderValue: (Optional) The border value. The count must be 1 or the channel number
       - Returns: MfArray
    */
    public static func warpPerspective(_ src: MfArray, M: MfArray, dsize: (width: Int, height: Int), interpolation: MfInterpolation = .Linear, borderMode: MfBorderType = .Constant, borderValue: [Float] = [0]) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(M.shape == [3, 3], "M must be (3, 3), but got \(M.shape)")
        precondition(dsize.width > 0 && dsize.height > 0, "dsize must be positive")

        // inverse map: dst -> src
        let m = image2doubles(try! Matft.linalg.inv(M.astype(.Double)))
        var mapx = Array(repeating: Float.zero, count: dsize.width*dsize.height)
        var mapy = mapx
        for y in 0..<dsize.height{
            for x in 0..<dsize.width{
                let (dx, dy) = (Double(x), Double(y))
                var w = m[6]*dx + m[7]*dy + m[8]
                w = w != 0 ? 1/w : 0
                mapx[y*dsize.width + x] = Float((m[0]*dx + m[1]*dy + m[2])*w)
                mapy[y*dsize.width + x] = Float((m[3]*dx + m[4]*dy + m[5])*w)
            }
        }
        return remap_image(src, mapx: mapx, mapy: mapy, dstHeight: dsize.height, dstWidth: dsize.width, interpolation: interpolation, borderType: borderMode, borderValue: borderValue)
    }

    /**
       Remap the image. Same as cv2.remap with Float maps.
       - parameters:
            - src: An image mfarray (UInt8 or Float)
            - map1: The x coordinates of the source (shape = (h, w))
            - map2: The y coordinates of the source (shape = (h, w))
            - interpolation: Linear or Nearest
            - borderMode: (Optional) The border type, by default Constant
            - borderValue: (Optional) The border value. The count must be 1 or the channel number
       - Returns: MfArray (shape = (h, w) or (h, w, c))
    */
    public static func remap(_ src: MfArray, map1: MfArray, map2: MfArray, interpolation: MfInterpolation, borderMode: MfBorderType = .Constant, borderValue: [Float] = [0]) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(map1.ndim == 2 && map1.shape == map2.shape, "map1 and map2 must be 2d and have same shape")

        return remap_image(src, mapx: image2floats(map1.astype(.Float)), mapy: image2floats(map2.astype(.Float)), dstHeight: map1.shape[0], dstWidth: map1.shape[1], interpolation: interpolation, borderType: borderMode, borderValue: borderValue)
    }

    /**
       Find edges by the Canny algorithm. Same as cv2.Canny.
       - parameters:
            - image: A 1 channel UInt8 image mfarray
            - threshold1: The first threshold for the hysteresis
            - threshold2: The second threshold for the hysteresis
            - apertureSize: (Optional) The aperture size of Sobel operator (3, 5 or 7), by default 3
            - L2gradient: (Optional) Whether to use L2 norm of the gradient, by default false (L1 norm)
       - Returns: UInt8 mfarray whose edges are 255
    */
    public static func Canny(_ image: MfArray, threshold1: Float, threshold2: Float, apertureSize: Int = 3, L2gradient: Bool = false) -> MfArray{
        precondition(image.mftype == .UInt8 && (image.ndim == 2 || (image.ndim == 3 && image.shape[2] == 1)), "Canny supports 1 channel UInt8 image only")
        precondition([3, 5, 7].contains(apertureSize), "apertureSize must be 3, 5 or 7")
        let (height, width) = (image.shape[0], image.shape[1])

        let dx = image2floats(Matft.image.Sobel(image, ddepth: .Float, dx: 1, dy: 0, ksize: apertureSize, borderType: .Replicate))
        let dy = image2floats(Matft.image.Sobel(image, ddepth: .Float, dx: 0, dy: 1, ksize: apertureSize, borderType: .Replicate))
        let edges = canny_edges(dx: dx, dy: dy, height: height, width: width, threshold1: Double(threshold1), threshold2: Double(threshold2), L2gradient: L2gradient)
        return floats2image(edges, shape: image.shape, mftype: .UInt8)
    }
}

/// Flip the image by the reversed slices
/// - Parameters:
///     - image: An image mfarray
///     - vertical: Whether to flip upside down
///     - horizontal: Whether to flip left and right
/// - Returns: The row contiguous mfarray
fileprivate func flip_image(_ image: MfArray, vertical: Bool, horizontal: Bool) -> MfArray{
    let rows = vertical ? ~<<-1 : MfSlice()
    let cols = horizontal ? ~<<-1 : MfSlice()
    return image[rows, cols].to_contiguous(mforder: .Row)
}

/// Get the row contiguous values as Double array
/// - Parameters:
///     - mfarray: A mfarray
/// - Returns: The row contiguous Double array
fileprivate func image2doubles(_ mfarray: MfArray) -> [Double]{
    let mfarray = check_contiguous(mfarray.astype(.Double), .Row)
    return mfarray.withUnsafeMutableStartPointer(datatype: Double.self){
        Array(UnsafeBufferPointer(start: $0, count: mfarray.size))
    }
}

/// Same as Canny algorithm of OpenCV: non-maximum suppression and hysteresis
/// - Parameters:
///     - dx: The row contiguous derivatives along x axis
///     - dy: The row contiguous derivatives along y axis
///     - height: The height
///     - width: The width
///     - threshold1: The first threshold
///     - threshold2: The second threshold
///     - L2gradient: Whether to use L2 norm
/// - Returns: The row contiguous edges (0 or 255)
fileprivate func canny_edges(dx: [Float], dy: [Float], height: Int, width: Int, threshold1: Double, threshold2: Double, L2gradient: Bool) -> [Float]{
    var low = min(threshold1, threshold2)
    var high = max(threshold1, threshold2)
    if L2gradient{
        low = min(32767, low)
        high = min(32767, high)
        if low > 0{
            low *= low
        }
        if high > 0{
            high *= high
        }
    }
    let lowInt = Int(low.rounded(.down))
    let highInt = Int(high.rounded(.down))

    // magnitude with zero padding
    let pw = width + 2
    var mag = Array(repeating: 0, count: (height + 2)*pw)
    for y in 0..<height{
        for x in 0..<width{
            let (gx, gy) = (Int(dx[y*width + x]), Int(dy[y*width + x]))
            mag[(y + 1)*pw + x + 1] = L2gradient ? gx*gx + gy*gy : abs(gx) + abs(gy)
        }
    }

    // 0: may be edge, 1: not edge, 2: edge
    var map = Array(repeating: UInt8(1), count: (height + 2)*pw)
    var stack: [Int] = []
    let TG22 = 0.4142135623730950488016887242097
    for y in 0..<height{
        for x in 0..<width{
            let i = (y + 1)*pw + x + 1
            let m = mag[i]
            if m <= lowInt{
                continue
            }
            let (xs, ys) = (Int(dx[y*width + x]), Int(dy[y*width + x]))
            let (ax, ay) = (Double(abs(xs)), Double(abs(ys)))
            let tg22x = ax*TG22

            var isMax = false
            if ay < tg22x{
                isMax = m > mag[i - 1] && m >= mag[i + 1]
            }
            else{
                let tg67x = tg22x + ax*2
                if ay > tg67x{
                    isMax = m > mag[i - pw] && m >= mag[i + pw]
                }
                else{
                    let s = (xs ^ ys) < 0 ? -1 : 1
                    isMax = m > mag[i - pw - s] && m > mag[i + pw + s]
                }
            }
            if isMax{
                if m > highInt{
                    map[i] = 2
                    stack.append(i)
                }
                else{
                    map[i] = 0
                }
            }
        }
    }

    // hysteresis
    let neighbors = [-pw - 1, -pw, -pw + 1, -1, 1, pw - 1, pw, pw + 1]
    while let i = stack.popLast(){
        for n in neighbors where map[i + n] == 0{
            map[i + n] = 2
            stack.append(i + n)
        }
    }

    var ret = Array(repeating: Float.zero, count: height*width)
    for y in 0..<height{
        for x in 0..<width where map[(y + 1)*pw + x + 1] == 2{
            ret[y*width + x] = 255
        }
    }
    return ret
}
#endif
