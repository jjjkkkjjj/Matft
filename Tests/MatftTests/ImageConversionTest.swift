#if canImport(Accelerate) && canImport(CoreGraphics)
import XCTest
import CoreGraphics

import Matft

/// CGImage <-> MfArray keeps the stored pixel values (straight alpha) like PIL `np.asarray(Image.open(...))` and `cv2.imread(..., IMREAD_UNCHANGED)`
final class ImageConversionTests: XCTestCase {

    private func makeImage(_ bytes: [UInt8], width: Int, height: Int, channel: Int, alpha: CGImageAlphaInfo) -> CGImage {
        let space = channel == 1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB()
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8 * channel, bytesPerRow: width * channel, space: space, bitmapInfo: CGBitmapInfo(rawValue: alpha.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }

    func testStraightAlpha(){
        // two pixels with a translucent one
        let bytes: [UInt8] = [200, 100, 50, 128, 10, 20, 30, 255]
        let image = makeImage(bytes, width: 2, height: 1, channel: 4, alpha: .last)

        let u8 = Matft.image.cgimage2mfarray(image, mftype: .UInt8)
        XCTAssertEqual(u8.shape, [1, 2, 4])
        XCTAssertEqual(u8.mftype, .UInt8)
        XCTAssertEqual(u8.flatten().data as! [UInt8], bytes)

        let f = Matft.image.cgimage2mfarray(image, mftype: .Float)
        XCTAssertEqual(f.shape, [1, 2, 4])
        XCTAssertClose(f, MfArray(bytes.map{ Float($0) / 255 }, shape: [1, 2, 4]), rtol: 1e-6)
    }

    func testRGBWithoutAlpha(){
        // 24 bit RGB (e.g. JPEG) becomes RGBA with opaque alpha
        let image = makeImage([200, 100, 50, 10, 20, 30], width: 2, height: 1, channel: 3, alpha: .none)
        let u8 = Matft.image.cgimage2mfarray(image, mftype: .UInt8)
        XCTAssertEqual(u8.shape, [1, 2, 4])
        XCTAssertEqual(u8.flatten().data as! [UInt8], [200, 100, 50, 255, 10, 20, 30, 255])
    }

    func testGray(){
        let image = makeImage([0, 128, 255, 7], width: 2, height: 2, channel: 1, alpha: .none)
        let u8 = Matft.image.cgimage2mfarray(image, mftype: .UInt8)
        XCTAssertEqual(u8, MfArray([[0, 128], [255, 7]], mftype: .UInt8))
        let f = Matft.image.cgimage2mfarray(image, mftype: .Float)
        XCTAssertClose(f, MfArray([[0, 128], [255, 7]] as [[Float]]) / 255, rtol: 1e-6)
    }

    func testRoundTrip(){
        let u8 = MfArray([[[200, 100, 50, 128], [10, 20, 30, 255]], [[0, 0, 0, 0], [255, 255, 255, 64]]], mftype: .UInt8)
        XCTAssertEqual(Matft.image.cgimage2mfarray(Matft.image.mfarray2cgimage(u8), mftype: .UInt8), u8)

        let f = u8.astype(.Float) / 255
        XCTAssertClose(Matft.image.cgimage2mfarray(Matft.image.mfarray2cgimage(f), mftype: .Float), f, rtol: 1e-6, atol: 1e-7)
    }
}
#endif
