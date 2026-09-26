//
//  ImagePreprocessPefTests.swift
//

// The resize loops are too slow in debug build (about 200s), so these run only in release build
// (scripts/benchmark.py uses `swift test -c release`)
#if !DEBUG
import XCTest

import Matft

final class ImagePreprocessPefTests: XCTestCase {

    /// 1920x1080 RGB UInt8 image
    static let image1080p: MfArray = {
        var values = [UInt8](repeating: 0, count: 1080 * 1920 * 3)
        for i in 0..<values.count {
            values[i] = UInt8((i * 37 + (i / 5760) * 91) % 256)
        }
        return MfArray(values, mftype: .UInt8, shape: [1080, 1920, 3])
    }()

    func testPeformanceResizeBicubic() {
        let image = ImagePreprocessPefTests.image1080p

        self.measureWithWarmup {
            let _ = Matft.image.resize(image, width: 1316, height: 728, resample: .bicubic)
        }
    }

    func testPeformanceCLIPPreprocess() {
        let image = ImagePreprocessPefTests.image1080p

        self.measureWithWarmup {
            let _ = Matft.image.clip_preprocess(image)
        }
    }

    func testPeformanceQwen2VLPreprocess() {
        let image = ImagePreprocessPefTests.image1080p

        self.measureWithWarmup {
            let _ = Matft.image.qwen2vl_preprocess(image)
        }
    }
}
#endif
