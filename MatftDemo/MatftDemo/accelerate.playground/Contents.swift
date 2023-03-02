import Accelerate


var sreal: [Float] = [Float(0), 1, 0, 0]
var simag: [Float] = Array(repeating: Float.zero, count: sreal.count)

var real = Array(repeating: Float.zero, count: 4)
var imag = Array(repeating: Float.zero, count: 4)
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
                //vDSP_fft_zrop(setup, &src, vDSP_Stride(1), &dst, vDSP_Stride(1), vDSP_Length(log2N), FFTDirection(direction))
                vDSP_fft_zrip(setup, &src, vDSP_Stride(1), vDSP_Length(log2N), FFTDirection(direction))

            }
        }
    }
    
}

vDSP_destroy_fftsetup(setup)

print(sreal)
print(simag)

sreal = [Float(0), 1, 0, 0]
simag = Array(repeating: Float.zero, count: sreal.count)

real = Array(repeating: Float.zero, count: 4)
imag = Array(repeating: Float.zero, count: 4)

let setup_dft = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(4), vDSP_DFT_Direction.FORWARD)

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
                //vDSP_fft_zrop(setup, &src, vDSP_Stride(1), &dst, vDSP_Stride(1), vDSP_Length(log2N), FFTDirection(direction))
                vDSP_DFT_Execute(setup, <#T##__Ir: UnsafePointer<Float>##UnsafePointer<Float>#>, <#T##__Ii: UnsafePointer<Float>##UnsafePointer<Float>#>, <#T##__Or: UnsafeMutablePointer<Float>##UnsafeMutablePointer<Float>#>, <#T##__Oi: UnsafeMutablePointer<Float>##UnsafeMutablePointer<Float>#>)(setup, &src, vDSP_Stride(1), vDSP_Length(log2N), FFTDirection(direction))

            }
        }
    }
    
}
vDSP.FFT(log2n: <#T##vDSP_Length#>, radix: <#T##vDSP.Radix#>, ofType: <#T##_.Type#>).fo
vDSP_destroy_fftsetup(setup)

print(sreal)
print(simag)
