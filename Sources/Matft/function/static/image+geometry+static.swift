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
       Flips an image around the vertical axis, the horizontal axis, or both.

       Equivalent to `cv2.flip`.

       - Parameters:
            - src: An image mfarray of `(height, width)` or `(height, width, channels)`. Any mftype is accepted.
            - flipCode: 0 flips vertically (around the x axis), a positive value flips horizontally
              (around the y axis), and a negative value flips both.
       - Returns: The flipped row-contiguous mfarray with the same shape and mftype as `src`.
       - Precondition: `src` must be 2D or 3D.
    */
    public static func flip(_ src: MfArray, flipCode: Int) -> MfArray{
        precondition(src.ndim == 2 || src.ndim == 3, "src must be 2d or 3d, but got \(src.shape)")
        let axes = flipCode == 0 ? [0] : (flipCode > 0 ? [1] : [0, 1])
        return Matft.flip(src, axes: axes).to_contiguous(mforder: .Row)
    }

    /**
       Rotates an image by a multiple of 90 degrees.

       Equivalent to `cv2.rotate`.

       - Parameters:
            - src: An image mfarray of `(height, width)` or `(height, width, channels)`. Any mftype is accepted.
            - rotateCode: The rotation.
       - Returns: The rotated row-contiguous mfarray. The height and width are swapped for 90-degree rotations.
       - Precondition: `src` must be 2D or 3D.
    */
    public static func rotate(_ src: MfArray, rotateCode: MfRotateCode) -> MfArray{
        precondition(src.ndim == 2 || src.ndim == 3, "src must be 2d or 3d, but got \(src.shape)")
        switch rotateCode{
        case .Rotate90Clockwise:
            return Matft.flip(src.swapaxes(axis1: 0, axis2: 1), axis: 1).to_contiguous(mforder: .Row)
        case .Rotate180:
            return Matft.flip(src, axes: [0, 1]).to_contiguous(mforder: .Row)
        case .Rotate90Counterclockwise:
            return Matft.flip(src.swapaxes(axis1: 0, axis2: 1), axis: 0).to_contiguous(mforder: .Row)
        }
    }

    /**
       Calculates the affine matrix of a 2D rotation with scaling.

       Equivalent to `cv2.getRotationMatrix2D`. The result can be passed to
       `warpAffine(_:matrix:width:height:mode:borderValue:)`.

       ```swift
       let M = Matft.image.getRotationMatrix2D(center: (Float(w) / 2, Float(h) / 2), angle: 45, scale: 1)
       let rotated = Matft.image.warpAffine(image, matrix: M, width: w, height: h)
       ```

       - Parameters:
            - center: The center `(x, y)` of the rotation in the source image.
            - angle: The rotation angle in degrees. Positive values mean counter-clockwise rotation
              (the origin is the top-left corner).
            - scale: The isotropic scale factor.
       - Returns: The Double affine matrix of shape `(2, 3)`.
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
       Calculates the affine transform from three pairs of corresponding points.

       Equivalent to `cv2.getAffineTransform`.

       - Parameters:
            - src: The source points `(x, y)` of shape `(3, 2)`.
            - dst: The destination points `(x, y)` of shape `(3, 2)`.
       - Returns: The Double affine matrix of shape `(2, 3)` mapping `src` into `dst`.
       - Precondition: `src` and `dst` must be `(3, 2)`. The points must not be collinear.
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
       Calculates the perspective transform from four pairs of corresponding points.

       Equivalent to `cv2.getPerspectiveTransform`.

       - Parameters:
            - src: The source points `(x, y)` of shape `(4, 2)`.
            - dst: The destination points `(x, y)` of shape `(4, 2)`.
       - Returns: The Double perspective matrix of shape `(3, 3)` whose last element is 1.
       - Precondition: `src` and `dst` must be `(4, 2)`, and no three points may be collinear.
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
       Applies a perspective transformation to an image.

       Equivalent to `cv2.warpPerspective` (without `WARP_INVERSE_MAP`). Each destination pixel is sampled
       from the source at the inverse-mapped position, as `remap(_:map1:map2:interpolation:borderMode:borderValue:)` does.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - M: The `(3, 3)` perspective matrix mapping source coordinates into destination coordinates.
            - dsize: The destination size `(width, height)`.
            - interpolation: `.Linear` (default) or `.Nearest`. `.Lanczos` is not supported.
            - borderMode: How to fill the pixels mapped from outside the source, by default `.Constant`.
            - borderValue: The fill value for `.Constant`, by default `[0]`. Pass one value, or one value per channel;
              missing channels use the last value.
       - Returns: The transformed mfarray of `(dsize.height, dsize.width)` or `(dsize.height, dsize.width, channels)`
         with the same mftype as `src`. UInt8 results are rounded and saturated.
       - Precondition: The mftype of `src` must be UInt8 or Float, `M` must be `(3, 3)` and invertible,
         and `dsize` must be positive.
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
       Remaps an image with per-pixel source coordinates.

       Equivalent to `cv2.remap` with two Float maps: `dst(y, x) = src(map2(y, x), map1(y, x))`.

       - Parameters:
            - src: An image mfarray (UInt8 or Float) of `(height, width)` or `(height, width, channels)`.
            - map1: The source x coordinates of shape `(h, w)`.
            - map2: The source y coordinates of shape `(h, w)`.
            - interpolation: `.Linear` or `.Nearest`. `.Lanczos` is not supported.
            - borderMode: How to fill the pixels mapped from outside the source, by default `.Constant`.
            - borderValue: The fill value for `.Constant`, by default `[0]`. Pass one value, or one value per channel;
              missing channels use the last value.
       - Returns: The remapped mfarray of `(h, w)` or `(h, w, channels)` with the same mftype as `src`.
         UInt8 results are rounded and saturated.
       - Precondition: The mftype of `src` must be UInt8 or Float, `map1` and `map2` must be 2D with the same shape,
         and `interpolation` must not be `.Lanczos`.
    */
    public static func remap(_ src: MfArray, map1: MfArray, map2: MfArray, interpolation: MfInterpolation, borderMode: MfBorderType = .Constant, borderValue: [Float] = [0]) -> MfArray{
        unsupport_complex(src)
        unsupport_imagetype(src)
        precondition(map1.ndim == 2 && map1.shape == map2.shape, "map1 and map2 must be 2d and have same shape")

        return remap_image(src, mapx: image2floats(map1.astype(.Float)), mapy: image2floats(map2.astype(.Float)), dstHeight: map1.shape[0], dstWidth: map1.shape[1], interpolation: interpolation, borderType: borderMode, borderValue: borderValue)
    }

    /**
       Finds edges in a grayscale image with the Canny algorithm.

       Equivalent to `cv2.Canny`. The gradients are computed by `Sobel(_:ddepth:dx:dy:ksize:scale:delta:borderType:)`
       with the `.Replicate` border, followed by non-maximum suppression and hysteresis thresholding.

       - Parameters:
            - image: A 1-channel UInt8 image mfarray of `(height, width)` or `(height, width, 1)`.
            - threshold1: One threshold for the hysteresis. The smaller of the two is the lower threshold.
            - threshold2: The other threshold for the hysteresis. The larger of the two is the upper threshold.
            - apertureSize: The aperture size of the Sobel operator (3, 5 or 7), by default 3.
            - L2gradient: Whether to use the L2 norm of the gradient, by default `false` (L1 norm).
       - Returns: The UInt8 edge map with the same shape as `image`, where edges are 255 and the others are 0.
       - Precondition: `image` must be a 1-channel UInt8 image, and `apertureSize` must be 3, 5 or 7.
    */
    public static func Canny(_ image: MfArray, threshold1: Float, threshold2: Float, apertureSize: Int = 3, L2gradient: Bool = false) -> MfArray{
        precondition(image.mftype == .UInt8 && (image.ndim == 2 || (image.ndim == 3 && image.shape[2] == 1)), "Canny supports 1 channel UInt8 image only")
        precondition([3, 5, 7].contains(apertureSize), "apertureSize must be 3, 5 or 7")
        let (height, width) = (image.shape[0], image.shape[1])

        var dx = image2floats(Matft.image.Sobel(image, ddepth: .Float, dx: 1, dy: 0, ksize: apertureSize, borderType: .Replicate))
        var dy = image2floats(Matft.image.Sobel(image, ddepth: .Float, dx: 0, dy: 1, ksize: apertureSize, borderType: .Replicate))
        var (threshold1, threshold2) = (Double(threshold1), Double(threshold2))
        if apertureSize == 7{
            // OpenCV scales the 7x7 derivatives by 1/16 (rounded into Int16) and the thresholds too
            dx = dx.map{ ($0 / 16).rounded(.toNearestOrEven) }
            dy = dy.map{ ($0 / 16).rounded(.toNearestOrEven) }
            threshold1 /= 16
            threshold2 /= 16
        }
        let edges = canny_edges(dx: dx, dy: dy, height: height, width: width, threshold1: threshold1, threshold2: threshold2, L2gradient: L2gradient)
        return floats2image(edges, shape: image.shape, mftype: .UInt8)
    }
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
