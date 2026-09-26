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

        ImageSnapshot.check(ret, as: "resize_300x150")
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

        ImageSnapshot.check(ret, as: "resize_gray_300x150")
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

        ImageSnapshot.check(ret, as: "resize_colmajor_300x150")
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

        ImageSnapshot.check(ret, as: "warpAffine_translate")
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
        ImageSnapshot.check(fill, as: "warpAffine_rotate30_colorFill")

        let edge = Matft.image.warpAffine(image, matrix: matrix, width: 225, height: 225, mode: .EdgeExtend)
        XCTAssertLessThan(maxAbsDiff(edge[112, 112], image[112, 112]), 5e-2)
        ImageSnapshot.check(edge, as: "warpAffine_rotate30_edgeExtend")
    }

    // MARK: - color

    func test_color_rgba2gray() {
        let image = loadRena()
        let ret = Matft.image.color(image, conversion: .RGBA2GRAY)
        XCTAssertEqual(ret.shape, [225, 225])
        XCTAssertEqual(ret.mftype, .Float)
        ImageSnapshot.check(ret, as: "color_rgba2gray")

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
        ImageSnapshot.check(Matft.image.color(image, conversion: .RGBA2GRAY, exclude_alpha: false), as: "color_rgba2gray_alpha_white")
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

        ImageSnapshot.check(rgba8, as: "color_rgba2rgb_uint8")
    }

    // MARK: - cvtColor

    /// rena.png as UInt8 RGB, shape=(225, 225, 3)
    private func loadRenaRGB8() -> MfArray {
        return Matft.image.cvtColor(loadRena(.UInt8), code: .RGBA2RGB)
    }

    /// rena.png as UInt8 gray (cv2.COLOR_RGBA2GRAY), shape=(225, 225)
    private func loadRenaGray8() -> MfArray {
        return Matft.image.cvtColor(loadRena(.UInt8), code: .RGBA2GRAY)
    }

    // px = np.array([[[255,0,0],[0,255,0],[0,0,255],[10,20,30]],[[200,100,50],[0,0,0],[255,255,255],[128,64,200]]], np.uint8)
    private let pixels8 = MfArray([[[255, 0, 0], [0, 255, 0], [0, 0, 255], [10, 20, 30]],
                                   [[200, 100, 50], [0, 0, 0], [255, 255, 255], [128, 64, 200]]] as [[[UInt8]]])

    func test_cvtColor_gray() {
        // cv2.cvtColor(px, cv2.COLOR_RGB2GRAY), cv2.cvtColor(px, cv2.COLOR_BGR2GRAY)
        XCTAssertEqual(Matft.image.cvtColor(pixels8, code: .RGB2GRAY), MfArray([[76, 150, 29, 18], [124, 0, 255, 99]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.cvtColor(pixels8, code: .BGR2GRAY), MfArray([[29, 150, 76, 22], [96, 0, 255, 112]] as [[UInt8]]))

        let gray = MfArray([[0, 128], [255, 64]] as [[UInt8]])
        let rgb = Matft.image.cvtColor(gray, code: .GRAY2RGB)
        XCTAssertEqual(rgb.shape, [2, 2, 3])
        XCTAssertEqual(rgb[1, 0], MfArray([255, 255, 255] as [UInt8]))
        let rgba = Matft.image.cvtColor(gray, code: .GRAY2RGBA)
        XCTAssertEqual(rgba[0, 1], MfArray([128, 128, 128, 255] as [UInt8]))
    }

    func test_cvtColor_swap() {
        let bgr = Matft.image.cvtColor(pixels8, code: .RGB2BGR)
        XCTAssertEqual(bgr[1, 0], MfArray([50, 100, 200] as [UInt8]))
        XCTAssertEqual(Matft.image.cvtColor(bgr, code: .BGR2RGB), pixels8)

        let rgba = loadRena(.UInt8)
        let bgra = Matft.image.cvtColor(rgba, code: .RGBA2BGRA)
        XCTAssertEqual(bgra[Matft.all, Matft.all, 0], rgba[Matft.all, Matft.all, 2])
        XCTAssertEqual(Matft.image.cvtColor(bgra, code: .BGRA2RGBA), rgba)
        ImageSnapshot.check(bgra, as: "cvtColor_rgba2bgra")
    }

    func test_cvtColor_hsv() {
        // cv2.cvtColor(px, cv2.COLOR_RGB2HSV)
        let hsv8 = Matft.image.cvtColor(pixels8, code: .RGB2HSV)
        XCTAssertEqual(hsv8, MfArray([[[0, 255, 255], [60, 255, 255], [120, 255, 255], [105, 170, 30]],
                                      [[10, 191, 200], [0, 0, 0], [0, 0, 255], [134, 173, 200]]] as [[[UInt8]]]))
        // cv2.cvtColor(cv2.cvtColor(px, cv2.COLOR_RGB2HSV), cv2.COLOR_HSV2RGB) == px
        XCTAssertEqual(Matft.image.cvtColor(hsv8, code: .HSV2RGB), pixels8)

        // cv2.cvtColor(px.astype(np.float32)/255, cv2.COLOR_RGB2HSV)
        let hsvF = Matft.image.cvtColor(pixels8.astype(.Float) / Float(255), code: .RGB2HSV)
        let expected = MfArray([[[0.0, 1.0, 1.0], [120.0, 1.0, 1.0], [240.0, 1.0, 1.0], [210.0, 0.666666, 0.117647]],
                                [[20.0, 0.75, 0.784314], [0.0, 0.0, 0.0], [0.0, 0.0, 1.0], [268.235291, 0.68, 0.784314]]] as [[[Float]]])
        XCTAssertLessThan(maxAbsDiff(hsvF, expected), 1e-4)
        XCTAssertLessThan(maxAbsDiff(Matft.image.cvtColor(hsvF, code: .HSV2RGB) * Float(255), pixels8), 1e-3)

        let hsv = Matft.image.cvtColor(loadRenaRGB8(), code: .RGB2HSV)
        ImageSnapshot.check(hsv[Matft.all, Matft.all, 0], as: "cvtColor_rgb2hsv_h")
    }

    // MARK: - threshold

    func test_threshold() {
        let gray = MfArray([[0, 50, 100], [150, 200, 250]] as [[UInt8]])
        // cv2.threshold(g, 127.5, 200, type)
        let expected: [(MfThresholdType, [[UInt8]])] = [
            (.Binary, [[0, 0, 0], [200, 200, 200]]),
            (.BinaryInv, [[200, 200, 200], [0, 0, 0]]),
            (.Trunc, [[0, 50, 100], [127, 127, 127]]),
            (.ToZero, [[0, 0, 0], [150, 200, 250]]),
            (.ToZeroInv, [[0, 50, 100], [0, 0, 0]]),
        ]
        for (type, value) in expected {
            let (retval, dst) = Matft.image.threshold(gray, thresh: 127.5, maxval: 200, type: type)
            XCTAssertEqual(retval, 127.5)
            XCTAssertEqual(dst, MfArray(value), "\(type)")
        }

        // Float
        let grayF = gray.astype(.Float) / Float(255)
        let (_, dstF) = Matft.image.threshold(grayF, thresh: 0.5, maxval: 1, type: .Binary)
        XCTAssertEqual(dstF, MfArray([[0, 0, 0], [1, 1, 1]] as [[Float]]))

        let (_, rena) = Matft.image.threshold(loadRenaGray8(), thresh: 127, maxval: 255, type: .Binary)
        XCTAssertEqual(rena.mftype, .UInt8)
        ImageSnapshot.check(rena, as: "threshold_binary_127")
    }

    func test_threshold_otsu() {
        // cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[0] == 116
        let (retval, dst) = Matft.image.threshold(loadRenaGray8(), thresh: 0, maxval: 255, type: .Binary, otsu: true)
        XCTAssertEqual(retval, 116)
        ImageSnapshot.check(dst, as: "threshold_otsu")
    }

    // MARK: - histogram

    func test_calcHist() {
        // cv2.calcHist([gray], [0], None, [8], [0, 256]).ravel()
        let hist = Matft.image.calcHist(loadRenaGray8(), histSize: 8, range: (0, 256))
        XCTAssertEqual(hist.shape, [8, 1])
        XCTAssertEqual(hist, MfArray([444, 7561, 6264, 10728, 14288, 6808, 4399, 133] as [Float]).reshape([8, 1]))

        // channel of RGBA
        let histR = Matft.image.calcHist(loadRena(.UInt8), channel: 0, histSize: 256, range: (0, 256))
        XCTAssertEqual(histR.sum().scalar(Float.self)!, 225 * 225)
    }

    func test_equalizeHist() {
        // cv2.equalizeHist(g)
        let gray = MfArray([[0, 50, 100], [150, 200, 250]] as [[UInt8]])
        XCTAssertEqual(Matft.image.equalizeHist(gray), MfArray([[0, 51, 102], [153, 204, 255]] as [[UInt8]]))

        // cv2.equalizeHist(gray)[::50, ::50]
        let ret = Matft.image.equalizeHist(loadRenaGray8())
        XCTAssertEqual(ret[~<<50, ~<<50], MfArray([[203, 112, 138, 183, 113], [67, 101, 228, 188, 20], [91, 128, 139, 196, 173],
                                                   [51, 42, 103, 22, 221], [11, 49, 151, 242, 135]] as [[UInt8]]))
        ImageSnapshot.check(ret, as: "equalizeHist")
    }

    func test_LUT() {
        // gamma 0.5: lut = np.rint((np.arange(256) / 255) ** 0.5 * 255)
        let lut = Matft.math.round(Matft.math.sqrt(Matft.arange(start: 0, to: 256, by: 1, mftype: .Float) / Float(255)) * Float(255)).astype(.UInt8)
        let src = MfArray([[0, 64], [128, 255]] as [[UInt8]])
        XCTAssertEqual(Matft.image.LUT(src, lut: lut), MfArray([[0, 128], [181, 255]] as [[UInt8]]))

        let ret = Matft.image.LUT(loadRena(.UInt8), lut: lut)
        XCTAssertEqual(ret.shape, [225, 225, 4])
        ImageSnapshot.check(ret, as: "LUT_gamma05")
    }

    func test_normalize() {
        let f = MfArray([[-1, 0.5], [2, 3]] as [[Float]])
        // cv2.normalize(f, None)
        XCTAssertLessThan(maxAbsDiff(Matft.image.normalize(f), MfArray([[-0.264906, 0.132453], [0.529813, 0.794719]] as [[Float]])), 1e-5)
        // cv2.normalize(f, None, 0, 1, cv2.NORM_MINMAX)
        XCTAssertLessThan(maxAbsDiff(Matft.image.normalize(f, alpha: 0, beta: 1, normType: .MinMax), MfArray([[0, 0.375], [0.75, 1]] as [[Float]])), 1e-6)
        // cv2.convertScaleAbs(f, alpha=100, beta=-50)
        XCTAssertEqual(Matft.image.convertScaleAbs(f, alpha: 100, beta: -50), MfArray([[150, 0], [150, 250]] as [[UInt8]]))
    }

    // MARK: - filter

    // a = np.arange(20, dtype=np.float32).reshape(4, 5)
    private let rampF = Matft.arange(start: 0, to: 20, by: 1, shape: [4, 5], mftype: .Float)
    // u = (np.arange(20) * 13 % 256).astype(np.uint8).reshape(4, 5)
    private let ramp8 = MfArray([[0, 13, 26, 39, 52], [65, 78, 91, 104, 117], [130, 143, 156, 169, 182], [195, 208, 221, 234, 247]] as [[UInt8]])

    func test_filter2D() {
        // correlation (not convolution): cv2.filter2D(a, -1, [[0,0,0],[0,0,1],[0,0,0]], borderType=cv2.BORDER_REPLICATE)
        let shift = MfArray([[0, 0, 0], [0, 0, 1], [0, 0, 0]] as [[Float]])
        XCTAssertEqual(Matft.image.filter2D(rampF, kernel: shift),
                       MfArray([[1, 2, 3, 4, 4], [6, 7, 8, 9, 9], [11, 12, 13, 14, 14], [16, 17, 18, 19, 19]] as [[Float]]))
        // column major input
        XCTAssertEqual(Matft.image.filter2D(rampF.to_contiguous(mforder: .Column), kernel: shift),
                       MfArray([[1, 2, 3, 4, 4], [6, 7, 8, 9, 9], [11, 12, 13, 14, 14], [16, 17, 18, 19, 19]] as [[Float]]))

        // even kernel and anchor
        let k2 = MfArray([[1, 2], [3, 4]] as [[Float]])
        // cv2.filter2D(a, -1, k2, anchor=(0, 0), borderType=cv2.BORDER_REPLICATE)
        XCTAssertEqual(Matft.image.filter2D(rampF, kernel: k2, anchor: (0, 0)),
                       MfArray([[41, 51, 61, 71, 75], [91, 101, 111, 121, 125], [141, 151, 161, 171, 175], [156, 166, 176, 186, 190]] as [[Float]]))
        // cv2.filter2D(a, -1, k2, borderType=cv2.BORDER_CONSTANT)
        XCTAssertEqual(Matft.image.filter2D(rampF, kernel: k2, borderType: .Constant),
                       MfArray([[0, 4, 11, 18, 25], [20, 41, 51, 61, 71], [50, 91, 101, 111, 121], [80, 141, 151, 161, 171]] as [[Float]]))

        // sharpen RGBA (UInt8 output is saturated)
        let sharpen = MfArray([[0, -1, 0], [-1, 5, -1], [0, -1, 0]] as [[Float]])
        let ret = Matft.image.filter2D(loadRena(.UInt8), kernel: sharpen)
        XCTAssertEqual(ret.mftype, .UInt8)
        XCTAssertEqual(ret.shape, [225, 225, 4])
        ImageSnapshot.check(ret, as: "filter2D_sharpen")
    }

    func test_blur() {
        // cv2.blur(u, (3, 3), borderType=cv2.BORDER_REPLICATE)
        XCTAssertEqual(Matft.image.blur(ramp8, ksize: (3, 3)),
                       MfArray([[26, 35, 48, 61, 69], [69, 78, 91, 104, 113], [134, 143, 156, 169, 178], [178, 186, 199, 212, 221]] as [[UInt8]]))
        // cv2.blur(u, (4, 2), borderType=cv2.BORDER_REPLICATE). [0, 3] is exactly 32.5, which OpenCV's UInt8 box filter rounds up
        XCTAssertEqual(Matft.image.blur(ramp8, ksize: (4, 2)),
                       MfArray([[3, 10, 20, 33, 42], [36, 42, 52, 65, 75], [101, 107, 117, 130, 140], [166, 172, 182, 195, 205]] as [[UInt8]]))
        // cv2.boxFilter(a, -1, (3, 3), normalize=False, borderType=cv2.BORDER_CONSTANT)
        XCTAssertEqual(Matft.image.boxFilter(rampF, ksize: (3, 3), normalize: false, borderType: .Constant),
                       MfArray([[12, 21, 27, 33, 24], [33, 54, 63, 72, 51], [63, 99, 108, 117, 81], [52, 81, 87, 93, 64]] as [[Float]]))

        let ret = Matft.image.blur(loadRena(), ksize: (5, 5))
        XCTAssertEqual(ret.shape, [225, 225, 4])
        ImageSnapshot.check(ret, as: "blur_5x5")
    }

    func test_GaussianBlur() {
        // cv2.getGaussianKernel(5, 0), cv2.getGaussianKernel(5, 1.5)
        XCTAssertEqual(Matft.image.getGaussianKernel(ksize: 5, sigma: 0), MfArray([0.0625, 0.25, 0.375, 0.25, 0.0625] as [Float]).reshape([5, 1]))
        XCTAssertLessThan(maxAbsDiff(Matft.image.getGaussianKernel(ksize: 5, sigma: 1.5),
                                     MfArray([0.120078, 0.233881, 0.292082, 0.233881, 0.120078] as [Float]).reshape([5, 1])), 1e-6)
        XCTAssertEqual(Matft.image.getGaussianKernel(ksize: 9, sigma: 0),
                       MfArray([0.015625, 0.05078125, 0.1171875, 0.19921875, 0.234375, 0.19921875, 0.1171875, 0.05078125, 0.015625] as [Float]).reshape([9, 1]))

        // cv2.GaussianBlur(u, (5, 5), 1.0, borderType=cv2.BORDER_REPLICATE)
        XCTAssertLessThanOrEqual(maxAbsDiff(Matft.image.GaussianBlur(ramp8, ksize: (5, 5), sigmaX: 1),
                                            MfArray([[27, 37, 49, 61, 70], [73, 82, 95, 107, 116], [131, 140, 152, 165, 174], [177, 186, 198, 210, 220]] as [[UInt8]])), 1)
        // cv2.GaussianBlur(a, (3, 5), 0, borderType=cv2.BORDER_REPLICATE)
        XCTAssertLessThan(maxAbsDiff(Matft.image.GaussianBlur(rampF, ksize: (3, 5), sigmaX: 0),
                                     MfArray([[2.125, 2.875, 3.875, 4.875, 5.625], [5.5625, 6.3125, 7.3125, 8.3125, 9.0625],
                                              [9.9375, 10.6875, 11.6875, 12.6875, 13.4375], [13.375, 14.125, 15.125, 16.125, 16.875]] as [[Float]])), 1e-5)

        let ret = Matft.image.GaussianBlur(loadRena(), ksize: (9, 9), sigmaX: 0)
        XCTAssertEqual(ret.shape, [225, 225, 4])
        ImageSnapshot.check(ret, as: "GaussianBlur_k9")
    }

    func test_Sobel() {
        // cv2.getDerivKernels(1, 0, 5), cv2.getDerivKernels(2, 0, 7)
        let (kx, ky) = Matft.image.getDerivKernels(dx: 1, dy: 0, ksize: 5)
        XCTAssertEqual(kx, MfArray([-1, -2, 0, 2, 1] as [Float]).reshape([5, 1]))
        XCTAssertEqual(ky, MfArray([1, 4, 6, 4, 1] as [Float]).reshape([5, 1]))
        XCTAssertEqual(Matft.image.getDerivKernels(dx: 2, dy: 0, ksize: 7).kx, MfArray([1, 2, -1, -4, -1, 2, 1] as [Float]).reshape([7, 1]))

        // cv2.Sobel(a, cv2.CV_32F, 1, 0, ksize=3, borderType=cv2.BORDER_REPLICATE)
        XCTAssertEqual(Matft.image.Sobel(rampF, dx: 1, dy: 0),
                       MfArray([[4, 8, 8, 8, 4], [4, 8, 8, 8, 4], [4, 8, 8, 8, 4], [4, 8, 8, 8, 4]] as [[Float]]))
        // cv2.Sobel(u, cv2.CV_32F, 0, 1, ksize=3, borderType=cv2.BORDER_REPLICATE)
        XCTAssertEqual(Matft.image.Sobel(ramp8, ddepth: .Float, dx: 0, dy: 1),
                       MfArray([[260, 260, 260, 260, 260], [520, 520, 520, 520, 520], [520, 520, 520, 520, 520], [260, 260, 260, 260, 260]] as [[Float]]))
        // cv2.Sobel(u, -1, 1, 0, ksize=3, borderType=cv2.BORDER_REPLICATE)
        let sobel8 = Matft.image.Sobel(ramp8, dx: 1, dy: 0)
        XCTAssertEqual(sobel8.mftype, .UInt8)
        XCTAssertEqual(sobel8, MfArray([[52, 104, 104, 104, 52], [52, 104, 104, 104, 52], [52, 104, 104, 104, 52], [52, 104, 104, 104, 52]] as [[UInt8]]))

        // |dx| of gray rena
        let gray = loadRenaGray8()
        let dx = Matft.image.convertScaleAbs(Matft.image.Sobel(gray, ddepth: .Float, dx: 1, dy: 0))
        ImageSnapshot.check(dx, as: "Sobel_dx")
    }

    func test_Laplacian() {
        // cv2.Laplacian(u, cv2.CV_32F, ksize=1 / 3 / 5, borderType=cv2.BORDER_REPLICATE)
        XCTAssertEqual(Matft.image.Laplacian(ramp8, ddepth: .Float, ksize: 1),
                       MfArray([[78, 65, 65, 65, 52], [13, 0, 0, 0, -13], [13, 0, 0, 0, -13], [-52, -65, -65, -65, -78]] as [[Float]]))
        XCTAssertEqual(Matft.image.Laplacian(ramp8, ddepth: .Float, ksize: 3),
                       MfArray([[312, 260, 260, 260, 208], [52, 0, 0, 0, -52], [52, 0, 0, 0, -52], [-208, -260, -260, -260, -312]] as [[Float]]))
        XCTAssertEqual(Matft.image.Laplacian(ramp8, ddepth: .Float, ksize: 5),
                       MfArray([[2496, 2288, 2080, 1872, 1664], [1456, 1248, 1040, 832, 624],
                                [-624, -832, -1040, -1248, -1456], [-1664, -1872, -2080, -2288, -2496]] as [[Float]]))

        let lap = Matft.image.convertScaleAbs(Matft.image.Laplacian(loadRenaGray8(), ddepth: .Float, ksize: 3))
        ImageSnapshot.check(lap, as: "Laplacian_k3")
    }

    func test_adaptiveThreshold() {
        // cv2.adaptiveThreshold(u, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 3, 5)
        XCTAssertEqual(Matft.image.adaptiveThreshold(ramp8, maxValue: 255, adaptiveMethod: .Mean, thresholdType: .Binary, blockSize: 3, C: 5),
                       MfArray([[0, 0, 0, 0, 0], [255, 255, 255, 255, 255], [255, 255, 255, 255, 255], [255, 255, 255, 255, 255]] as [[UInt8]]))

        let gray = loadRenaGray8()
        // (cv2.adaptiveThreshold(g, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 11, 2) // 255).sum() == 31668
        let mean = Matft.image.adaptiveThreshold(gray, maxValue: 255, adaptiveMethod: .Mean, thresholdType: .Binary, blockSize: 11, C: 2)
        XCTAssertEqual((mean.astype(.Float) / Float(255)).sum().scalar(Float.self)!, 31668)
        ImageSnapshot.check(mean, as: "adaptiveThreshold_mean")
        // (cv2.adaptiveThreshold(g, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 2) // 255).sum() == 16717
        let gauss = Matft.image.adaptiveThreshold(gray, maxValue: 255, adaptiveMethod: .Gaussian, thresholdType: .BinaryInv, blockSize: 11, C: 2)
        XCTAssertEqual((gauss.astype(.Float) / Float(255)).sum().scalar(Float.self)!, 16717, accuracy: 50)
        ImageSnapshot.check(gauss, as: "adaptiveThreshold_gaussian_inv")
    }

    // MARK: - morphology

    // u = np.array([[1,2,3,4,5],[6,7,8,9,10],[11,12,99,14,15],[16,17,18,0,20]], np.uint8)
    private let morphSrc = MfArray([[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12, 99, 14, 15], [16, 17, 18, 0, 20]] as [[UInt8]])

    func test_getStructuringElement() {
        // cv2.getStructuringElement(shape, (5, 5))
        XCTAssertEqual(Matft.image.getStructuringElement(shape: .Rect, ksize: (5, 5)), Matft.nums(UInt8(1), shape: [5, 5]))
        XCTAssertEqual(Matft.image.getStructuringElement(shape: .Cross, ksize: (5, 5)),
                       MfArray([[0, 0, 1, 0, 0], [0, 0, 1, 0, 0], [1, 1, 1, 1, 1], [0, 0, 1, 0, 0], [0, 0, 1, 0, 0]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.getStructuringElement(shape: .Ellipse, ksize: (5, 5)),
                       MfArray([[0, 0, 1, 0, 0], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1], [0, 0, 1, 0, 0]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.getStructuringElement(shape: .Ellipse, ksize: (7, 5)),
                       MfArray([[0, 0, 0, 1, 0, 0, 0], [1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1], [0, 0, 0, 1, 0, 0, 0]] as [[UInt8]]))
        // cv2.getStructuringElement(cv2.MORPH_CROSS, (4, 3), anchor=(1, 2))
        XCTAssertEqual(Matft.image.getStructuringElement(shape: .Cross, ksize: (4, 3), anchor: (1, 2)),
                       MfArray([[0, 1, 0, 0], [0, 1, 0, 0], [1, 1, 1, 1]] as [[UInt8]]))
    }

    func test_erode_dilate() {
        let rect = Matft.nums(UInt8(1), shape: [3, 3])
        let cross = Matft.image.getStructuringElement(shape: .Cross, ksize: (3, 3))
        // cv2.erode(u, np.ones((3, 3))), cv2.dilate(u, np.ones((3, 3)))
        XCTAssertEqual(Matft.image.erode(morphSrc, kernel: rect), MfArray([[1, 1, 2, 3, 4], [1, 1, 2, 3, 4], [6, 6, 0, 0, 0], [11, 11, 0, 0, 0]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.dilate(morphSrc, kernel: rect), MfArray([[7, 8, 9, 10, 10], [12, 99, 99, 99, 15], [17, 99, 99, 99, 20], [17, 99, 99, 99, 20]] as [[UInt8]]))
        // cv2.erode(u, cross), cv2.dilate(u, cross)
        XCTAssertEqual(Matft.image.erode(morphSrc, kernel: cross), MfArray([[1, 1, 2, 3, 4], [1, 2, 3, 4, 5], [6, 7, 8, 0, 10], [11, 12, 0, 0, 0]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.dilate(morphSrc, kernel: cross), MfArray([[6, 7, 8, 9, 10], [11, 12, 99, 14, 15], [16, 99, 99, 99, 20], [17, 18, 99, 20, 20]] as [[UInt8]]))
        // even kernel: cv2.dilate(u, np.array([[0, 1], [1, 1]]))
        XCTAssertEqual(Matft.image.dilate(morphSrc, kernel: MfArray([[0, 1], [1, 1]] as [[UInt8]])),
                       MfArray([[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12, 99, 99, 15], [16, 17, 99, 18, 20]] as [[UInt8]]))
        // center excluded: cv2.dilate(u, np.array([[1, 0, 1], [0, 0, 0], [1, 0, 1]]))
        XCTAssertEqual(Matft.image.dilate(morphSrc, kernel: MfArray([[1, 0, 1], [0, 0, 0], [1, 0, 1]] as [[UInt8]])),
                       MfArray([[7, 8, 9, 10, 9], [12, 99, 14, 99, 14], [17, 18, 17, 20, 9], [12, 99, 14, 99, 14]] as [[UInt8]]))
        // cv2.erode(u, np.ones((3, 3)), iterations=2)
        XCTAssertEqual(Matft.image.erode(morphSrc, kernel: rect, iterations: 2), MfArray([[1, 1, 1, 2, 3], [1, 0, 0, 0, 0], [1, 0, 0, 0, 0], [6, 0, 0, 0, 0]] as [[UInt8]]))
        // default kernel is 3x3 rect, and Float works too
        XCTAssertEqual(Matft.image.erode(morphSrc.astype(.Float)), MfArray([[1, 1, 2, 3, 4], [1, 1, 2, 3, 4], [6, 6, 0, 0, 0], [11, 11, 0, 0, 0]] as [[Float]]))

        let image = loadRena(.UInt8)
        let eroded = Matft.image.erode(image, kernel: Matft.image.getStructuringElement(shape: .Rect, ksize: (5, 5)))
        XCTAssertEqual(eroded.shape, [225, 225, 4])
        ImageSnapshot.check(eroded, as: "erode_rect5")
        let dilated = Matft.image.dilate(image, kernel: Matft.image.getStructuringElement(shape: .Ellipse, ksize: (7, 7)))
        ImageSnapshot.check(dilated, as: "dilate_ellipse7")
    }

    func test_morphologyEx() {
        let cross = Matft.image.getStructuringElement(shape: .Cross, ksize: (3, 3))
        // cv2.morphologyEx(u, op, cross)
        let expected: [(MfMorphOp, [[UInt8]])] = [
            (.Open, [[1, 2, 3, 4, 5], [6, 7, 8, 5, 10], [11, 12, 8, 10, 10], [12, 12, 12, 0, 10]]),
            (.Close, [[6, 6, 7, 8, 9], [6, 7, 8, 9, 10], [11, 12, 99, 14, 15], [16, 17, 18, 20, 20]]),
            (.Gradient, [[5, 6, 6, 6, 6], [10, 10, 96, 10, 10], [10, 92, 91, 99, 10], [6, 6, 99, 20, 20]]),
            (.TopHat, [[0, 0, 0, 0, 0], [0, 0, 0, 4, 0], [0, 0, 91, 4, 5], [4, 5, 6, 0, 10]]),
            (.BlackHat, [[5, 4, 4, 4, 4], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 20, 0]]),
        ]
        for (op, value) in expected {
            XCTAssertEqual(Matft.image.morphologyEx(morphSrc, op: op, kernel: cross), MfArray(value), "\(op)")
        }

        let (_, binary) = Matft.image.threshold(loadRenaGray8(), thresh: 0, maxval: 255, type: .Binary, otsu: true)
        let ellipse = Matft.image.getStructuringElement(shape: .Ellipse, ksize: (5, 5))
        ImageSnapshot.check(Matft.image.morphologyEx(binary, op: .Open, kernel: ellipse), as: "morphologyEx_open_ellipse5")
        ImageSnapshot.check(Matft.image.morphologyEx(loadRenaGray8(), op: .Gradient, kernel: cross), as: "morphologyEx_gradient_cross3")
    }

    // MARK: - geometry

    func test_flip_rotate() {
        let a = MfArray([[1, 2, 3], [4, 5, 6]] as [[UInt8]])
        // cv2.flip(a, 0 / 1 / -1)
        XCTAssertEqual(Matft.image.flip(a, flipCode: 0), MfArray([[4, 5, 6], [1, 2, 3]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.flip(a, flipCode: 1), MfArray([[3, 2, 1], [6, 5, 4]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.flip(a, flipCode: -1), MfArray([[6, 5, 4], [3, 2, 1]] as [[UInt8]]))
        // cv2.rotate(a, cv2.ROTATE_*)
        XCTAssertEqual(Matft.image.rotate(a, rotateCode: .Rotate90Clockwise), MfArray([[4, 1], [5, 2], [6, 3]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.rotate(a, rotateCode: .Rotate180), MfArray([[6, 5, 4], [3, 2, 1]] as [[UInt8]]))
        XCTAssertEqual(Matft.image.rotate(a, rotateCode: .Rotate90Counterclockwise), MfArray([[3, 6], [2, 5], [1, 4]] as [[UInt8]]))

        let image = loadRena()
        let flipped = Matft.image.flip(image, flipCode: 1)
        XCTAssertEqual(flipped[10, 0], image[10, 224])
        ImageSnapshot.check(flipped, as: "flip_horizontal")
        let rotated = Matft.image.rotate(image[0~<150], rotateCode: .Rotate90Clockwise)
        XCTAssertEqual(rotated.shape, [225, 150, 4])
        ImageSnapshot.check(rotated, as: "rotate_90cw")
    }

    func test_transform_matrix() {
        // cv2.getRotationMatrix2D((10, 20), 45, 0.5)
        XCTAssertLessThan(maxAbsDiff(Matft.image.getRotationMatrix2D(center: (10, 20), angle: 45, scale: 0.5),
                                     MfArray([[0.353553, 0.353553, -0.606602], [-0.353553, 0.353553, 16.464466]] as [[Float]])), 1e-5)
        // cv2.getAffineTransform([[0,0],[10,0],[0,10]], [[5,5],[25,10],[0,20]])
        let affine = Matft.image.getAffineTransform(src: MfArray([[0, 0], [10, 0], [0, 10]] as [[Float]]),
                                                    dst: MfArray([[5, 5], [25, 10], [0, 20]] as [[Float]]))
        XCTAssertEqual(affine.shape, [2, 3])
        XCTAssertLessThan(maxAbsDiff(affine, MfArray([[2, -0.5, 5], [0.5, 1.5, 5]] as [[Float]])), 1e-5)
        // cv2.getPerspectiveTransform([[0,0],[10,0],[10,10],[0,10]], [[1,2],[12,0],[9,11],[0,8]])
        let persp = Matft.image.getPerspectiveTransform(src: MfArray([[0, 0], [10, 0], [10, 10], [0, 10]] as [[Float]]),
                                                        dst: MfArray([[1, 2], [12, 0], [9, 11], [0, 8]] as [[Float]]))
        XCTAssertEqual(persp.shape, [3, 3])
        XCTAssertLessThan(maxAbsDiff(persp, MfArray([[0.533333, -0.1, 1], [-0.2, 0.651852, 2], [-0.047222, 0.006481, 1]] as [[Float]])), 1e-5)
    }

    func test_warpPerspective_remap() {
        let a = Matft.arange(start: 0, to: 36, by: 1, shape: [6, 6], mftype: .Float)
        let M = MfArray([[1.1, 0.1, -0.5], [0.05, 0.9, 0.3], [0.01, 0.02, 1]] as [[Double]])
        // cv2.warpPerspective(a, M, (6, 6), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=0)
        let expected = MfArray([[0.31168, 0.827686, 1.256027, 1.592092, 1.831033, 1.431091],
                                [5.051867, 5.734311, 6.42827, 7.134043, 7.851932, 6.357449],
                                [12.078473, 12.836364, 13.607336, 14.391732, 15.189902, 12.010749],
                                [19.425163, 20.264772, 21.119205, 21.988867, 22.874159, 17.933258],
                                [27.114323, 28.042561, 28.987574, 29.949833, 30.92981, 24.144682],
                                [3.451678, 3.86809, 3.998538, 4.131394, 4.266772, 3.33332]] as [[Float]])
        XCTAssertLessThan(maxAbsDiff(Matft.image.warpPerspective(a, M: M, dsize: (6, 6)), expected), 1e-3)
        // cv2.warpPerspective(a, M, (5, 4), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
        XCTAssertLessThan(maxAbsDiff(Matft.image.warpPerspective(a, M: M, dsize: (5, 4), borderMode: .Replicate),
                                     MfArray([[0.48731, 1.406346, 2.340557, 3.290323, 4.256034], [5.051867, 5.734311, 6.42827, 7.134043, 7.851932],
                                              [12.078473, 12.836364, 13.607336, 14.391732, 15.189902], [19.425163, 20.264772, 21.119205, 21.988867, 22.874159]] as [[Float]])), 1e-3)
        // cv2.warpPerspective(a, M, (6, 6), flags=cv2.INTER_NEAREST)
        XCTAssertEqual(Matft.image.warpPerspective(a, M: M, dsize: (6, 6), interpolation: .Nearest),
                       MfArray([[0, 1, 2, 0, 0, 0], [6, 7, 8, 9, 10, 11], [12, 13, 14, 15, 16, 17],
                                [18, 19, 20, 21, 22, 23], [30, 25, 26, 27, 28, 29], [0, 0, 0, 0, 0, 0]] as [[Float]]))

        // cv2.remap(a, mx, my, cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=100)
        let mx = MfArray([[0.5, 1.25, -1], [3.75, 4.5, 5.9]] as [[Float]])
        let my = MfArray([[0, 0.5, 2], [1.5, 5.2, -0.3]] as [[Float]])
        XCTAssertLessThan(maxAbsDiff(Matft.image.remap(a, map1: mx, map2: my, interpolation: .Linear, borderMode: .Constant, borderValue: [100]),
                                     MfArray([[0.5, 4.25, 100], [12.75, 47.599987, 93.350006]] as [[Float]])), 1e-4)

        // perspective of RGBA
        let src = MfArray([[0, 0], [224, 0], [224, 224], [0, 224]] as [[Float]])
        let dst = MfArray([[30, 10], [200, 40], [224, 200], [0, 224]] as [[Float]])
        let persp = Matft.image.getPerspectiveTransform(src: src, dst: dst)
        let ret = Matft.image.warpPerspective(loadRena(), M: persp, dsize: (225, 225), borderValue: [0, 0, 0, 1])
        XCTAssertEqual(ret.shape, [225, 225, 4])
        ImageSnapshot.check(ret, as: "warpPerspective")
        // warpAffine accepts the Double matrix of getRotationMatrix2D
        let rot = Matft.image.warpAffine(loadRena(), matrix: Matft.image.getRotationMatrix2D(center: (112, 112), angle: 45, scale: 0.8), width: 225, height: 225, borderValue: [0, 0, 0, 1])
        ImageSnapshot.check(rot, as: "warpAffine_getRotationMatrix2D_45")
    }

    func test_resize_interpolation() {
        // cv2.resize(u, (7, 3), interpolation=cv2.INTER_LINEAR / cv2.INTER_NEAREST)
        XCTAssertLessThanOrEqual(maxAbsDiff(Matft.image.resize(ramp8, width: 7, height: 3, interpolation: .Linear),
                                            MfArray([[11, 18, 27, 37, 46, 55, 63], [98, 105, 114, 124, 133, 142, 150], [184, 191, 201, 210, 219, 229, 236]] as [[UInt8]])), 1)
        XCTAssertEqual(Matft.image.resize(ramp8, width: 7, height: 3, interpolation: .Nearest),
                       MfArray([[0, 0, 13, 26, 26, 39, 52], [65, 65, 78, 91, 91, 104, 117], [130, 130, 143, 156, 156, 169, 182]] as [[UInt8]]))
        // cv2.resize(np.arange(36, dtype=np.float32).reshape(6, 6), (4, 9), interpolation=cv2.INTER_LINEAR)
        let a = Matft.arange(start: 0, to: 36, by: 1, shape: [6, 6], mftype: .Float)
        XCTAssertLessThan(maxAbsDiff(Matft.image.resize(a, width: 4, height: 9, interpolation: .Linear),
                                     MfArray([[0.25, 1.75, 3.25, 4.75], [3.25, 4.75, 6.25, 7.75], [7.25, 8.75, 10.25, 11.75],
                                              [11.25, 12.75, 14.25, 15.75], [15.25, 16.75, 18.25, 19.75], [19.25, 20.75, 22.25, 23.75],
                                              [23.25, 24.75, 26.25, 27.75], [27.25, 28.75, 30.25, 31.75], [30.25, 31.75, 33.25, 34.75]] as [[Float]])), 1e-5)

        let image = loadRena()
        ImageSnapshot.check(Matft.image.resize(image, width: 300, height: 150, interpolation: .Linear), as: "resize_linear_300x150")
        ImageSnapshot.check(Matft.image.resize(image, width: 100, height: 60, interpolation: .Nearest), as: "resize_nearest_100x60")
    }

    // MARK: - Canny

    func test_Canny() {
        // sq = np.zeros((8, 8), np.uint8); sq[2:6, 2:6] = 200; cv2.Canny(sq, 100, 200)
        let sq = Matft.nums(UInt8(0), shape: [8, 8])
        sq[2~<6, 2~<6] = MfArray([UInt8(200)])
        XCTAssertEqual(Matft.image.Canny(sq, threshold1: 100, threshold2: 200),
                       MfArray([[0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 255, 255, 0, 0, 0], [0, 0, 255, 0, 0, 255, 0, 0], [0, 255, 0, 0, 0, 255, 0, 0],
                                [0, 255, 0, 0, 0, 255, 0, 0], [0, 0, 255, 255, 255, 255, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0]] as [[UInt8]]))

        let gray = loadRenaGray8()
        // (cv2.Canny(g, 100, 200) // 255).sum() == 5558
        let edges = Matft.image.Canny(gray, threshold1: 100, threshold2: 200)
        XCTAssertEqual(edges.mftype, .UInt8)
        XCTAssertEqual((edges.astype(.Float) / Float(255)).sum().scalar(Float.self)!, 5558, accuracy: 30)
        ImageSnapshot.check(edges, as: "Canny_100_200")
        // (cv2.Canny(g, 50, 150, L2gradient=True) // 255).sum() == 6727
        let edgesL2 = Matft.image.Canny(gray, threshold1: 50, threshold2: 150, L2gradient: true)
        XCTAssertEqual((edgesL2.astype(.Float) / Float(255)).sum().scalar(Float.self)!, 6727, accuracy: 30)
        ImageSnapshot.check(edgesL2, as: "Canny_50_150_L2")
    }
}
#endif
