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
        ImageSnapshot.save(bgra, as: "cvtColor_rgba2bgra")
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
        ImageSnapshot.save(hsv[Matft.all, Matft.all, 0], as: "cvtColor_rgb2hsv_h")
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
        ImageSnapshot.save(rena, as: "threshold_binary_127")
    }

    func test_threshold_otsu() {
        // cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[0] == 116
        let (retval, dst) = Matft.image.threshold(loadRenaGray8(), thresh: 0, maxval: 255, type: .Binary, otsu: true)
        XCTAssertEqual(retval, 116)
        ImageSnapshot.save(dst, as: "threshold_otsu")
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
        // NOTE: use item() because step slices of non-divisible length have a bug for now
        let sampled = (0..<5).map { i in (0..<5).map { j in ret.item(indices: [i * 50, j * 50], type: UInt8.self) } }
        XCTAssertEqual(sampled, [[203, 112, 138, 183, 113], [67, 101, 228, 188, 20], [91, 128, 139, 196, 173],
                                 [51, 42, 103, 22, 221], [11, 49, 151, 242, 135]])
        ImageSnapshot.save(ret, as: "equalizeHist")
    }

    func test_LUT() {
        // gamma 0.5: lut = np.rint((np.arange(256) / 255) ** 0.5 * 255)
        let lut = Matft.math.round(Matft.math.sqrt(Matft.arange(start: 0, to: 256, by: 1, mftype: .Float) / Float(255)) * Float(255)).astype(.UInt8)
        let src = MfArray([[0, 64], [128, 255]] as [[UInt8]])
        XCTAssertEqual(Matft.image.LUT(src, lut: lut), MfArray([[0, 128], [181, 255]] as [[UInt8]]))

        let ret = Matft.image.LUT(loadRena(.UInt8), lut: lut)
        XCTAssertEqual(ret.shape, [225, 225, 4])
        ImageSnapshot.save(ret, as: "LUT_gamma05")
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
        ImageSnapshot.save(ret, as: "filter2D_sharpen")
    }

    func test_blur() {
        // cv2.blur(u, (3, 3), borderType=cv2.BORDER_REPLICATE)
        XCTAssertEqual(Matft.image.blur(ramp8, ksize: (3, 3)),
                       MfArray([[26, 35, 48, 61, 69], [69, 78, 91, 104, 113], [134, 143, 156, 169, 178], [178, 186, 199, 212, 221]] as [[UInt8]]))
        // cv2.blur(u, (4, 2), borderType=cv2.BORDER_REPLICATE)
        XCTAssertEqual(Matft.image.blur(ramp8, ksize: (4, 2)),
                       MfArray([[3, 10, 20, 33, 42], [36, 42, 52, 65, 75], [101, 107, 117, 130, 140], [166, 172, 182, 195, 205]] as [[UInt8]]))
        // cv2.boxFilter(a, -1, (3, 3), normalize=False, borderType=cv2.BORDER_CONSTANT)
        XCTAssertEqual(Matft.image.boxFilter(rampF, ksize: (3, 3), normalize: false, borderType: .Constant),
                       MfArray([[12, 21, 27, 33, 24], [33, 54, 63, 72, 51], [63, 99, 108, 117, 81], [52, 81, 87, 93, 64]] as [[Float]]))

        let ret = Matft.image.blur(loadRena(), ksize: (5, 5))
        XCTAssertEqual(ret.shape, [225, 225, 4])
        ImageSnapshot.save(ret, as: "blur_5x5")
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
        ImageSnapshot.save(ret, as: "GaussianBlur_k9")
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
        ImageSnapshot.save(dx, as: "Sobel_dx")
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
        ImageSnapshot.save(lap, as: "Laplacian_k3")
    }

    func test_adaptiveThreshold() {
        // cv2.adaptiveThreshold(u, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 3, 5)
        XCTAssertEqual(Matft.image.adaptiveThreshold(ramp8, maxValue: 255, adaptiveMethod: .Mean, thresholdType: .Binary, blockSize: 3, C: 5),
                       MfArray([[0, 0, 0, 0, 0], [255, 255, 255, 255, 255], [255, 255, 255, 255, 255], [255, 255, 255, 255, 255]] as [[UInt8]]))

        let gray = loadRenaGray8()
        // (cv2.adaptiveThreshold(g, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 11, 2) // 255).sum() == 31668
        let mean = Matft.image.adaptiveThreshold(gray, maxValue: 255, adaptiveMethod: .Mean, thresholdType: .Binary, blockSize: 11, C: 2)
        XCTAssertEqual((mean.astype(.Float) / Float(255)).sum().scalar(Float.self)!, 31668)
        ImageSnapshot.save(mean, as: "adaptiveThreshold_mean")
        // (cv2.adaptiveThreshold(g, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 2) // 255).sum() == 16717
        let gauss = Matft.image.adaptiveThreshold(gray, maxValue: 255, adaptiveMethod: .Gaussian, thresholdType: .BinaryInv, blockSize: 11, C: 2)
        XCTAssertEqual((gauss.astype(.Float) / Float(255)).sum().scalar(Float.self)!, 16717, accuracy: 50)
        ImageSnapshot.save(gauss, as: "adaptiveThreshold_gaussian_inv")
    }
}
#endif
