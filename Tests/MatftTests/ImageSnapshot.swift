#if canImport(Accelerate) && canImport(ImageIO)
import Foundation
import XCTest
import CoreGraphics
import ImageIO

@testable import Matft

/// Helpers for image-processing tests with visual check.
///
/// - Input fixtures live in `Tests/MatftTests/files/images/`.
/// - With `MATFT_IMAGE_SNAPSHOT=1`, `save(_:as:)` writes Matft's output to `files/images/matft/<name>.png`.
///   `scripts/image_compare.py` then renders the OpenCV reference and the side-by-side comparison.
/// - Without the env var, `save(_:as:)` does nothing so that a plain `swift test` never touches the repo.
/// - `check(_:as:)` always compares the output with the committed reference `files/images/opencv/<name>.png`
///   by the tolerance of `tolerances[name]`, and then calls `save(_:as:)` for the visual check.
enum ImageSnapshot {
    /// The allowed difference from the reference in 8-bit values. `nil` is not checked
    struct Tolerance {
        var maxAbs: Int?
        var meanAbs: Double?
        var minPSNR: Double?

        /// Identical to the reference
        static let exact = Tolerance(maxAbs: 0, meanAbs: 0, minPSNR: nil)
        /// Rounding errors only
        static func rounding(_ maxAbs: Int) -> Tolerance {
            return Tolerance(maxAbs: maxAbs, meanAbs: 0.2, minPSNR: nil)
        }
        /// Different interpolations (vImage vs OpenCV). The difference is along the edges
        static func interpolation(meanAbs: Double, minPSNR: Double) -> Tolerance {
            return Tolerance(maxAbs: nil, meanAbs: meanAbs, minPSNR: minPSNR)
        }
    }

    /// The tolerance of each case. The measured values (`scripts/image_compare.py`) are in the comments.
    /// A case must be registered here and in `CASES` of `scripts/image_compare.py`
    static let tolerances: [String: Tolerance] = [
        // vImage Lanczos vs cv2 LANCZOS4: max 25, mean 0.748, 43.6dB
        "resize_300x150": .interpolation(meanAbs: 1.0, minPSNR: 42),
        // max 23, mean 1.000, 42.3dB
        "resize_gray_300x150": .interpolation(meanAbs: 1.3, minPSNR: 41),
        "resize_colmajor_300x150": .interpolation(meanAbs: 1.0, minPSNR: 42),
        "warpAffine_translate": .exact,
        // vImage vs cv2 INTER_LINEAR along the rotated edges: max 82, mean 2.406, 33.0dB
        "warpAffine_rotate30_colorFill": .interpolation(meanAbs: 3.0, minPSNR: 32),
        // max 134, mean 2.803, 30.2dB (vImage's edge extension differs from BORDER_REPLICATE outside the source)
        "warpAffine_rotate30_edgeExtend": .interpolation(meanAbs: 3.5, minPSNR: 29),
        // max 127, mean 2.860, 30.2dB
        "warpAffine_getRotationMatrix2D_45": .interpolation(meanAbs: 3.5, minPSNR: 29),
        "color_rgba2gray": .rounding(1),
        // mean 0.128
        "color_rgba2gray_alpha_white": .rounding(1),
        "color_rgba2rgb_uint8": .exact,
        "cvtColor_rgba2bgra": .exact,
        "cvtColor_rgb2hsv_h": .rounding(1),
        "threshold_binary_127": .exact,
        "threshold_otsu": .exact,
        "equalizeHist": .exact,
        "LUT_gamma05": .exact,
        "filter2D_sharpen": .exact,
        "blur_5x5": .exact,
        "GaussianBlur_k9": .rounding(1),
        "Sobel_dx": .rounding(2),
        // a few pixels differ by 8 because of the Float rounding before convertScaleAbs
        "Laplacian_k3": .rounding(8),
        "adaptiveThreshold_mean": .exact,
        "adaptiveThreshold_gaussian_inv": .exact,
        "erode_rect5": .exact,
        "dilate_ellipse7": .exact,
        "morphologyEx_open_ellipse5": .exact,
        "morphologyEx_gradient_cross3": .rounding(1),
        "flip_horizontal": .exact,
        "rotate_90cw": .exact,
        "warpPerspective": .rounding(1),
        // max 1, mean 0.149, 56.4dB
        "resize_linear_300x150": .rounding(1),
        "resize_nearest_100x60": .exact,
        // PIL references
        "resize_pil_bicubic_100x60": .exact,
        "resize_pil_bicubic_300x400": .exact,
        "Canny_100_200": .exact,
        "Canny_50_150_L2": .exact,
    ]

    /// Compare `image` with the committed reference `files/images/opencv/<name>.png` by `tolerances[name]`, then `save(_:as:)` it
    /// - Parameters:
    ///     - image: An image mfarray (Float in [0, 1] or UInt8, shape = (h, w) or (h, w, 1 or 4))
    ///     - name: The case name
    static func check(_ image: MfArray, as name: String, file: StaticString = #filePath, line: UInt = #line) {
        defer { save(image, as: name) }
        guard let tolerance = tolerances[name] else {
            XCTFail("No tolerance for \(name). Add it to ImageSnapshot.tolerances", file: file, line: line)
            return
        }
        let reference = Matft.image.cgimage2mfarray(loadFixture("opencv/\(name).png"), mftype: .UInt8)
        // same as `to_uint8` of scripts/image_compare.py
        var actual = image.mftype == .Float ? Matft.math.round(image * Float(255)) : image.astype(.Float)
        actual = actual.clip(min: Float(0), max: Float(255))
        if actual.ndim == 3 && actual.shape[2] == 1 {
            actual = actual.reshape([actual.shape[0], actual.shape[1]])
        }
        XCTAssertEqual(actual.shape, reference.shape, "\(name): shape mismatch", file: file, line: line)
        guard actual.shape == reference.shape else { return }

        let diff = rowValues(Matft.math.abs(actual - reference.astype(.Float)))
        let maxAbs = Int(diff.max() ?? 0)
        let meanAbs = diff.reduce(0, +) / Double(diff.count)
        let mse = diff.reduce(0){ $0 + $1 * $1 } / Double(diff.count)
        let psnr = mse == 0 ? Double.infinity : 10 * log10(255 * 255 / mse)
        let measured = "max|diff|=\(maxAbs) mean|diff|=\(meanAbs) PSNR=\(psnr)dB"
        if let limit = tolerance.maxAbs {
            XCTAssertLessThanOrEqual(maxAbs, limit, "\(name): \(measured)", file: file, line: line)
        }
        if let limit = tolerance.meanAbs {
            XCTAssertLessThanOrEqual(meanAbs, limit, "\(name): \(measured)", file: file, line: line)
        }
        if let limit = tolerance.minPSNR {
            XCTAssertGreaterThanOrEqual(psnr, limit, "\(name): \(measured)", file: file, line: line)
        }
    }

    static let imagesDir: URL = URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .appendingPathComponent("files")
        .appendingPathComponent("images")

    static var isEnabled: Bool {
        return ProcessInfo.processInfo.environment["MATFT_IMAGE_SNAPSHOT"] == "1"
    }

    /// Load an input fixture as CGImage.
    static func loadFixture(_ filename: String = "rena.png") -> CGImage {
        let url = imagesDir.appendingPathComponent(filename)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            preconditionFailure("Couldn't load image fixture: \(url.path)")
        }
        return image
    }

    /// Save Matft's output image as 8-bit PNG (gray or RGBA) when snapshot is enabled.
    /// - Parameters:
    ///     - image: An image mfarray (Float in [0, 1] or UInt8, shape = (h, w) or (h, w, 1 or 4))
    ///     - name: The case name. Must match a key of `CASES` in `scripts/image_compare.py`
    static func save(_ image: MfArray, as name: String) {
        guard isEnabled else { return }

        let cgimage = Matft.image.mfarray2cgimage(image)
        let isGray = cgimage.colorSpace?.model == .monochrome
        let colorSpace = isGray ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB()
        let alphaInfo: CGImageAlphaInfo = isGray ? .none : .premultipliedLast
        // Redraw into an 8-bit context so that Float images are also written as ordinary 8-bit PNG.
        guard let context = CGContext(data: nil, width: cgimage.width, height: cgimage.height,
                                      bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue) else {
            preconditionFailure("Couldn't create CGContext for \(name)")
        }
        context.draw(cgimage, in: CGRect(x: 0, y: 0, width: cgimage.width, height: cgimage.height))
        guard let rendered = context.makeImage() else {
            preconditionFailure("Couldn't render \(name)")
        }

        let dir = imagesDir.appendingPathComponent("matft")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).png")
        // "public.png" is UTType.png.identifier, which needs iOS 14
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            preconditionFailure("Couldn't create PNG destination: \(url.path)")
        }
        CGImageDestinationAddImage(dest, rendered, nil)
        precondition(CGImageDestinationFinalize(dest), "Couldn't write PNG: \(url.path)")
    }
}
#endif
