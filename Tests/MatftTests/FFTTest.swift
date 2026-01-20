// Execution disabled for WASI until we support complex operations
#if !os(WASI)
import XCTest

@testable import Matft

final class FFTTests: XCTestCase {
    func testrfft() {
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
        
        do {
            let a = MfArray([[1, 0, 5, 1, 2, 1],
                             [1, 0, 5, 1, 2, 1],
                             [1, 0, 5, 1, 2, 1]])
            let real = MfArray([[ 3.0,  0.0, 15.0,  3.0,  6.0,  3.0],
                                [ 0.0,  0.0,  0.0,  0.0,  0.0,  0.0]] as [[Double]])
            let imag = MfArray([[0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                                [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]] as [[Double]])
            let answer = MfArray(real: real, imag: imag, mftype: .Double)
            let fft = Matft.fft.rfft(a, axis: 0, vDSP: false)
            XCTAssertEqual(fft.real.round(decimals: 6), answer.real.round(decimals: 6))
            XCTAssertEqual(fft.imag!.round(decimals: 6), answer.imag!.round(decimals: 6))
        }
    }
    
    func testrfft_vDSP() {
        /*
        do {
            let a = MfArray([0, 1, 0, 0])
            let real = MfArray([ 1,  0, -1])
            let imag = MfArray([ 0,  -1, 0])
            
            XCTAssertEqual(Matft.fft.rfft(a, vDSP: true), MfArray(real: real, imag: imag, mftype: .Float))
        }*/
    }
    
    func testirfft() {
        /*
        do {
            let a = MfArray([0, 1, 0, 0])
            let real = MfArray([ 1,  0, -1])
            let imag = MfArray([ 0,  -1, 0])
            
            XCTAssertEqual(Matft.fft.rfft(a, vDSP: true), MfArray(real: real, imag: imag, mftype: .Float))
        }*/
        do {
            let a = MfArray(real: MfArray([1,0,-1]), imag: MfArray([0,-1,0]))
            let ans = MfArray([ 0,  1,  0,  0])

            XCTAssertEqual(Matft.fft.irfft(a, vDSP: false), ans)
        }
        
        do {
            let a = MfArray([0, 1, 0, 0])
            
            XCTAssertEqual(Matft.fft.irfft(Matft.fft.rfft(a)).astype(.Int), a)
        }
        
        do {
            let real = MfArray([[10.0, -3, -2,  6],
                                [10.0, -3, -2,  6],
                                [10.0, -3, -2,  6]] as [[Double]])
            let imag = MfArray([[ 0.0        , -1.73205081,  3.46410162,  0.0        ],
                                [ 0.0        , -1.73205081,  3.46410162,  0.0        ],
                                [ 0.0        , -1.73205081,  3.46410162,  0.0        ]] as [[Double]])
            let a = MfArray(real: real, imag: imag, mftype: .Double)
            let ifft = Matft.fft.irfft(a)
            XCTAssertEqual(ifft.round(decimals: 7), MfArray([[1, 0, 5, 1, 2, 1],
                                          [1, 0, 5, 1, 2, 1],
                                          [1, 0, 5, 1, 2, 1]]))
        }
    }
}
#endif
