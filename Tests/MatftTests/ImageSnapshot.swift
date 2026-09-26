#if canImport(Accelerate) && canImport(ImageIO)
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@testable import Matft

/// Helpers for image-processing tests with visual check.
///
/// - Input fixtures live in `Tests/MatftTests/files/images/`.
/// - With `MATFT_IMAGE_SNAPSHOT=1`, `save(_:as:)` writes Matft's output to `files/images/matft/<name>.png`.
///   `scripts/image_compare.py` then renders the OpenCV reference and the side-by-side comparison.
/// - Without the env var, `save(_:as:)` does nothing so that a plain `swift test` never touches the repo.
enum ImageSnapshot {
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
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            preconditionFailure("Couldn't create PNG destination: \(url.path)")
        }
        CGImageDestinationAddImage(dest, rendered, nil)
        precondition(CGImageDestinationFinalize(dest), "Couldn't write PNG: \(url.path)")
    }
}
#endif
