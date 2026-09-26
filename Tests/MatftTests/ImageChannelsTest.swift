#if canImport(Accelerate)
import XCTest

import Matft

/// Images with more than 4 channels are processed plane by plane
final class ImageChannelsTests: XCTestCase {

    func testWarpAffineManyChannels(){
        // (5, 6, 6) with distinct planes
        let image = Matft.arange(start: 0, to: 180, by: 1, shape: [5, 6, 6], mftype: .Float) / 180
        // translate by (1.5, -1) and rotate slightly
        let matrix = MfArray([[0.98, -0.17, 1.5], [0.17, 0.98, -1]] as [[Float]])
        let ret = Matft.image.warpAffine(image, matrix: matrix, width: 7, height: 4, borderValue: [0.25])
        XCTAssertEqual(ret.shape, [4, 7, 6])
        for c in 0..<6{
            let plane = image[Matft.all, Matft.all, c]
            let expected = Matft.image.warpAffine(plane, matrix: matrix, width: 7, height: 4, borderValue: [0.25])
            XCTAssertClose(ret[Matft.all, Matft.all, c], expected, rtol: 1e-6, atol: 1e-7)
        }
        // the border value of each channel
        let perChannel: [Float] = [0, 0.1, 0.2, 0.3, 0.4, 0.5]
        let ret2 = Matft.image.warpAffine(image, matrix: MfArray([[1, 0, 100], [0, 1, 0]] as [[Float]]), width: 2, height: 2, borderValue: perChannel)
        for c in 0..<6{
            XCTAssertClose(ret2[Matft.all, Matft.all, c], Matft.nums(perChannel[c], shape: [2, 2]), rtol: 1e-6)
        }
    }
}
#endif
