import XCTest

import Matft

final class FFTPefTests: XCTestCase {
    
    func testPeformanceRfft1() {
        let signal = PerfFixtures.signal
        self.measureWithWarmup {
            let _ = Matft.fft.rfft(signal)
        }
    }
    
    func testPeformanceRfftVDSP1() {
        let signal = PerfFixtures.signal
        self.measureWithWarmup {
            let _ = Matft.fft.rfft(signal, vDSP: true)
        }
    }
}
