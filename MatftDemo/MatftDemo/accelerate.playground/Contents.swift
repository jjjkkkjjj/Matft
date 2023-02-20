import Accelerate


var sreal: [Float] = [Float(0), 1, 0, 0]
var simag: [Float] = Array(repeating: Float.zero, count: sreal.count)

var real = Array(repeating: Float.zero, count: 3)
var imag = Array(repeating: Float.zero, count: 3)
let log2N = 2

let setup = vDSP_create_fftsetup(vDSP_Length(log2N), FFTRadix(kFFTRadix2))!
let direction = kFFTDirection_Forward

sreal.withUnsafeMutableBufferPointer{
    srealptr in
    simag.withUnsafeMutableBufferPointer{
        simagptr in
        real.withUnsafeMutableBufferPointer{
            realptr in
            imag.withUnsafeMutableBufferPointer{
                imagptr in
                var src = DSPSplitComplex(realp: srealptr.baseAddress!, imagp: simagptr.baseAddress!)
                var dst = DSPSplitComplex(realp: realptr.baseAddress!, imagp: imagptr.baseAddress!)
                vDSP_fft_zrop(setup, &src, vDSP_Stride(1), &dst, vDSP_Stride(1), vDSP_Length(log2N), FFTDirection(direction))

            }
        }
    }
    
}

vDSP_destroy_fftsetup(setup)

print(real)
print(imag)
