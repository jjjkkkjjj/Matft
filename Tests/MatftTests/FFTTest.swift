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
            
            XCTAssertEqual(Matft.fft.rfft(a, vDSP: false), MfArray(real: real, imag: imag, mftype: .Double))
        }
        
        do {
            let a = MfArray([[1, 0, 5, 1, 2, 1],
                             [1, 0, 5, 1, 2, 1],
                             [1, 0, 5, 1, 2, 1]])
            let real = MfArray([[10.0, -3, -2,  6],
                                [10.0, -3, -2,  6],
                                [10.0, -3, -2,  6]] as [[Double]])
            let imag = MfArray([[ 0.0        , -1.73205081,  3.46410162,  0.0        ],
                                [ 0.0        , -1.73205081,  3.46410162,  0.0        ],
                                [ 0.0        , -1.73205081,  3.46410162,  0.0        ]] as [[Double]])
            let answer = MfArray(real: real, imag: imag, mftype: .Double)
            let fft = Matft.fft.rfft(a, vDSP: false)
            XCTAssertEqual(fft.real.round(decimals: 6), answer.real.round(decimals: 6))
            XCTAssertEqual(fft.imag!.round(decimals: 6), answer.imag!.round(decimals: 6))
        }
    }
}
