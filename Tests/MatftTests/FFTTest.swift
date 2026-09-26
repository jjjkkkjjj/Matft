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
        func assertComplexEqual(_ ret: MfArray, real: [Float], imag: [Float], file: StaticString = #filePath, line: UInt = #line){
            XCTAssertEqual(ret.real.round(decimals: 4), MfArray(real).round(decimals: 4), file: file, line: line)
            XCTAssertEqual(ret.imag!.round(decimals: 4), MfArray(imag).round(decimals: 4), file: file, line: line)
        }
        let x = Matft.arange(start: 1, to: 9, by: 1, mftype: .Float)
        do {
            // np.fft.rfft(np.arange(1, 9))
            let ret = Matft.fft.rfft(x, vDSP: true)
            XCTAssertEqual(ret.mftype, .Float)
            XCTAssertEqual(ret.shape, [5])
            assertComplexEqual(ret, real: [36, -4, -4, -4, -4], imag: [0, 9.656854, 4, 1.656854, 0])
            // the input stays real
            XCTAssertTrue(x.isReal)
        }
        do {
            // crop: np.fft.rfft(x, n=4) / zero pad: np.fft.rfft(x[:6], n=8)
            assertComplexEqual(Matft.fft.rfft(x, number: 4, vDSP: true), real: [10, -2, -2], imag: [0, 2, 0])
            assertComplexEqual(Matft.fft.rfft(x[0~<6], number: 8, vDSP: true), real: [21, -9.656854, 3, 1.656854, -3], imag: [0, -3, -4, 3, 0])
        }
        do {
            // norm
            assertComplexEqual(Matft.fft.rfft(x, norm: .ortho, vDSP: true), real: [12.727922, -1.414214, -1.414214, -1.414214, -1.414214], imag: [0, 3.414214, 1.414214, 0.585786, 0])
            assertComplexEqual(Matft.fft.rfft(x, norm: .forward, vDSP: true), real: [4.5, -0.5, -0.5, -0.5, -0.5], imag: [0, 1.207107, 0.5, 0.207107, 0])
        }
        do {
            // n-d along each axis, and Double: same as pocketFFT (verified with numpy above)
            let a = MfArray([[1, 0, 5, 1, 2, 1, 3, 2],
                             [0, 2, 1, 4, 1, 0, 2, 3],
                             [3, 1, 0, 2, 5, 1, 1, 0],
                             [2, 2, 1, 1, 0, 3, 4, 1]] as [[Float]])
            for (name, signal, axis) in [("axis -1", a, -1), ("axis 0", a, 0), ("transposed", a.T, 0), ("view", a[1~<3], -1), ("double", a.astype(.Double), -1)]{
                let ret = Matft.fft.rfft(signal, axis: axis, vDSP: true)
                let ans = Matft.fft.rfft(signal, axis: axis, vDSP: false)
                XCTAssertEqual(ret.mftype, signal.mftype == .Double ? .Double : .Float, name)
                XCTAssertEqual(ret.shape, ans.shape, name)
                XCTAssertEqual(ret.real.astype(.Double).round(decimals: 4), ans.real.round(decimals: 4), name)
                XCTAssertEqual(ret.imag!.astype(.Double).round(decimals: 4), ans.imag!.round(decimals: 4), name)
            }
        }
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
