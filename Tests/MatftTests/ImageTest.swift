#if canImport(Accelerate) && canImport(ImageIO)
import XCTest

@testable import Matft

final class ImageTest: XCTestCase {

    /// max(|a - b|) as Float
    private func maxAbsDiff(_ a: MfArray, _ b: MfArray) -> Float {
        return Matft.math.abs(a.astype(.Float) - b.astype(.Float)).max().scalar(Float.self)!
    }

    /// rena.png as Float RGBA in [0, 1], shape=(225, 225, 4)
    private func loadRena(_ mftype: MfType = .Float) -> MfArray {
        return Matft.image.cgimage2mfarray(ImageSnapshot.loadFixture(), mftype: mftype)
    }

    /// Replace the alpha channel with a horizontal ramp: alpha[y, x] = x / (w - 1)
    private func withAlphaRamp(_ image: MfArray) -> MfArray {
        let image = image.deepcopy(.Row)
        let (h, w) = (image.shape[0], image.shape[1])
        var ramp = Matft.arange(start: 0, to: w, by: 1, mftype: .Float) / Float(w - 1)
        if image.mftype == .UInt8 {
            ramp = Matft.math.round(ramp * Float(255)).astype(.UInt8)
        }
        image[Matft.all, Matft.all, 3] = Matft.broadcast_to(ramp, shape: [h, w])
        return image
    }

    /// Black gray image (h, w) with a bright 7x7 square centered at (x, y)
    private func squareImage(h: Int, w: Int, x: Int, y: Int) -> MfArray {
        let image = Matft.nums(Float(0), shape: [h, w])
        image[(y - 3)~<(y + 4), (x - 3)~<(x + 4)] = MfArray([Float(1)])
        return image
    }

    /// Same formula as cv2.getRotationMatrix2D
    private func rotationMatrix(cx: Float, cy: Float, angle: Float) -> MfArray {
        let rad = angle * Float.pi / 180
        let (a, b) = (cos(rad), sin(rad))
        return MfArray([[a, b, (1 - a) * cx - b * cy],
                        [-b, a, b * cx + (1 - a) * cy]], mftype: .Float)
    }

    // MARK: - resize

    func test_resize() {
        let image = loadRena()
        let ret = Matft.image.resize(image, width: 300, height: 150)

        XCTAssertEqual(ret.shape, [150, 300, 4])
        XCTAssertEqual(ret.mftype, .Float)
        // The fixture is opaque, so resized alpha stays 1
        XCTAssertLessThan(maxAbsDiff(ret[Matft.all, Matft.all, 3], Matft.nums(Float(1), shape: [150, 300])), 1e-3)

        ImageSnapshot.save(ret, as: "resize_300x150")
    }

    func test_resize_gray() {
        let image = loadRena()
        let gray = Matft.image.color(image, conversion: .RGBA2GRAY)
        let ret = Matft.image.resize(gray, width: 300, height: 150)

        XCTAssertEqual(ret.shape, [150, 300])
        XCTAssertEqual(ret.mftype, .Float)
        // resize and gray conversion are both linear, so they commute
        let expected = Matft.image.color(Matft.image.resize(image, width: 300, height: 150), conversion: .RGBA2GRAY)
        XCTAssertLessThan(maxAbsDiff(ret, expected), 1e-3)

        ImageSnapshot.save(ret, as: "resize_gray_300x150")
    }

    func test_resize_colmajor() {
        let image = loadRena()
        let colmajor = image.to_contiguous(mforder: .Column)
        let ret = Matft.image.resize(colmajor, width: 300, height: 150)

        XCTAssertEqual(ret.shape, [150, 300, 4])
        XCTAssertLessThan(maxAbsDiff(ret, Matft.image.resize(image, width: 300, height: 150)), 1e-5)

        // non-square and non-contiguous (sliced view) input
        let sliced = image[20~<220, 40~<160]
        XCTAssertLessThan(maxAbsDiff(Matft.image.resize(sliced, width: 90, height: 170),
                                     Matft.image.resize(sliced.deepcopy(.Row), width: 90, height: 170)), 1e-5)

        ImageSnapshot.save(ret, as: "resize_colmajor_300x150")
    }

    // MARK: - warpAffine

    func test_warpAffine_translate() {
        let image = loadRena()
        let matrix = MfArray([[1, 0, 20],
                              [0, 1, 10]] as [[Float]])
        let ret = Matft.image.warpAffine(image, matrix: matrix, width: 225, height: 225)

        XCTAssertEqual(ret.shape, [225, 225, 4])
        // cv2: dst[y + 10, x + 20] = src[y, x]
        XCTAssertLessThan(maxAbsDiff(ret[10~<225, 20~<225], image[0~<215, 0~<205]), 1e-3)
        XCTAssertLessThan(ret[0~<10].max().scalar(Float.self)!, 1e-3)
        XCTAssertLessThan(ret[Matft.all, 0~<20].max().scalar(Float.self)!, 1e-3)

        ImageSnapshot.save(ret, as: "warpAffine_translate")
    }

    func test_warpAffine_rotate() {
        // cv2.getRotationMatrix2D((112, 112), 30, 1) maps (x, y) = (150, 112) to (144.9, 93.0) (counterclockwise)
        let matrix = rotationMatrix(cx: 112, cy: 112, angle: 30)
        let square = squareImage(h: 225, w: 225, x: 150, y: 112)

        for input in [square, square.to_contiguous(mforder: .Column)] {
            let ret = Matft.image.warpAffine(input, matrix: matrix, width: 225, height: 225)
            XCTAssertEqual(ret.shape, [225, 225])
            XCTAssertGreaterThan(ret.item(indices: [93, 145], type: Float.self), 0.9)
            // clockwise rotation (b and c swapped) would move the square to (144.9, 131.0)
            XCTAssertLessThan(ret.item(indices: [131, 145], type: Float.self), 0.1)
        }

        // RGBA: color fill and edge extend
        let image = loadRena()
        let fill = Matft.image.warpAffine(image, matrix: matrix, width: 225, height: 225, mode: .ColorFill, borderValue: [0, 0, 0, 1])
        XCTAssertEqual(fill.shape, [225, 225, 4])
        // center is fixed (up to the smoothing of vImage resampling)
        XCTAssertLessThan(maxAbsDiff(fill[112, 112], image[112, 112]), 5e-2)
        // corners are out of the source
        XCTAssertLessThan(maxAbsDiff(fill[0, 0], MfArray([0, 0, 0, 1] as [Float])), 1e-3)
        ImageSnapshot.save(fill, as: "warpAffine_rotate30_colorFill")

        let edge = Matft.image.warpAffine(image, matrix: matrix, width: 225, height: 225, mode: .EdgeExtend)
        XCTAssertLessThan(maxAbsDiff(edge[112, 112], image[112, 112]), 5e-2)
        ImageSnapshot.save(edge, as: "warpAffine_rotate30_edgeExtend")
    }

    // MARK: - color

    func test_color_rgba2gray() {
        let image = loadRena()
        let ret = Matft.image.color(image, conversion: .RGBA2GRAY)
        XCTAssertEqual(ret.shape, [225, 225])
        XCTAssertEqual(ret.mftype, .Float)
        ImageSnapshot.save(ret, as: "color_rgba2gray")

        // UInt8 gray is rounded like cv2
        let ret8 = Matft.image.color(loadRena(.UInt8), conversion: .RGBA2GRAY)
        XCTAssertEqual(ret8.mftype, .UInt8)
        XCTAssertEqual(maxAbsDiff(ret8, Matft.math.round(ret8.astype(.Float))), 0)
        XCTAssertLessThanOrEqual(maxAbsDiff(ret8, ret * Float(255)), 1)
    }

    func test_color_exclude_alpha() {
        // rgb = (0.2, 0.4, 0.6), alpha = 0.5
        let pixel = MfArray([[[0.2, 0.4, 0.6, 0.5]]] as [[[Float]]])
        // exclude alpha: 0.299*0.2 + 0.587*0.4 + 0.114*0.6
        let excluded = Matft.image.color(pixel, conversion: .RGBA2GRAY, exclude_alpha: true)
        XCTAssertEqual(excluded.item(indices: [0, 0], type: Float.self), 0.363, accuracy: 1e-4)
        // composite on white: rgb*0.5 + 0.5 = (0.6, 0.7, 0.8) -> 0.299*0.6 + 0.587*0.7 + 0.114*0.8
        let composited = Matft.image.color(pixel, conversion: .RGBA2GRAY, exclude_alpha: false)
        XCTAssertEqual(composited.item(indices: [0, 0], type: Float.self), 0.6815, accuracy: 1e-4)
        // input is not modified
        XCTAssertEqual(pixel, MfArray([[[0.2, 0.4, 0.6, 0.5]]] as [[[Float]]]))

        let image = withAlphaRamp(loadRena())
        ImageSnapshot.save(Matft.image.color(image, conversion: .RGBA2GRAY, exclude_alpha: false), as: "color_rgba2gray_alpha_white")
    }

    func test_color_rgba2rgb_uint8() {
        // rgb = (51, 102, 153), alpha = 128
        // np.rint(rgb * (128/255) + 255 * (1 - 128/255)) = (153, 178, 204)
        let pixel = MfArray([[[51, 102, 153, 128]]] as [[[UInt8]]])
        let ret = Matft.image.color(pixel, conversion: .RGBA2RGB)
        XCTAssertEqual(ret.mftype, .UInt8)
        XCTAssertEqual(ret, MfArray([[[153, 178, 204]]] as [[[UInt8]]]))

        let image8 = withAlphaRamp(loadRena(.UInt8))
        let rgb8 = Matft.image.color(image8, conversion: .RGBA2RGB)
        XCTAssertEqual(rgb8.mftype, .UInt8)
        XCTAssertEqual(rgb8.shape, [225, 225, 3])
        XCTAssertLessThanOrEqual(rgb8.max().scalar(UInt8.self)!, 255)
        let rgbF = Matft.image.color(image8.astype(.Float) / Float(255), conversion: .RGBA2RGB)
        XCTAssertLessThanOrEqual(maxAbsDiff(rgb8, rgbF * Float(255)), 1)

        // RGB2RGBA: alpha = 255 for UInt8
        let rgba8 = Matft.image.color(rgb8, conversion: .RGB2RGBA)
        XCTAssertEqual(rgba8.mftype, .UInt8)
        XCTAssertEqual(rgba8.shape, [225, 225, 4])
        XCTAssertEqual(rgba8[Matft.all, Matft.all, 3].min().scalar(UInt8.self)!, 255)

        ImageSnapshot.save(rgba8, as: "color_rgba2rgb_uint8")
    }
}
#endif
