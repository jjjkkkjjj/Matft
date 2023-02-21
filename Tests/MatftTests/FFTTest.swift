import XCTest
//@testable import Matft
import Matft
import Accelerate

final class FFTTests: XCTestCase {
    func testrfft() {
        /*
        do {
            let a = MfArray([0, 1, 0, 0])
            let real = MfArray([ 1,  0, -1])
            let imag = MfArray([ 0,  -1, 0])
            
            XCTAssertEqual(Matft.fft.rfft(a, vDSP: true), MfArray(real: real, imag: imag, mftype: .Float))
        }*/
        
        do {
            let a = MfArray([0, 1, 0, 0])
            let real = MfArray([ 1,  0, -1])
            let imag = MfArray([ 0,  -1, 0])
            
            XCTAssertEqual(Matft.fft.rfft(a, vDSP: false), MfArray(real: real, imag: imag, mftype: .Float))
        }
    }
}
