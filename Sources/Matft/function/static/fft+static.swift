//
//  fft+static.swift
//  
//
//  Created by Junnosuke Kado on 2023/02/06.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

// ortho について
// https://helve-blog.com/posts/python/numpy-fast-fourier-transform/

extension Matft.fft{
    
    /// Compute the one-dimensional discrete Fourier transform of a real signal.
    ///
    /// Equivalent to `numpy.fft.rfft`. Only the non-negative frequency terms are returned, so the transformed axis has length `number / 2 + 1`.
    ///
    /// ```swift
    /// let a = MfArray([0, 1, 0, 0])
    /// let spectrum = Matft.fft.rfft(a) // complex, real: [1, 0, -1], imag: [0, -1, 0]
    /// ```
    ///
    /// - Parameters:
    ///   - signal: The real input signal.
    ///   - number: The number of points along `axis` to use. The input is cropped if it is longer, or zero-padded if it is shorter. If `nil` (default), the length of `signal` along `axis` is used.
    ///   - axis: The axis over which to compute the FFT. Default is -1 (the last axis).
    ///   - norm: The normalization mode. `.backward` (default) applies no scaling to the forward transform, `.ortho` scales by `1/sqrt(n)` and `.forward` scales by `1/n`.
    ///   - vDSP: If `true`, use Accelerate vDSP (Apple platforms only), which requires `number` to be a power of 2 and keeps `.Float` input as `.Float`. If `false` (default), use pocketFFT, which supports any `number` and always computes in `Double`.
    /// - Returns: A complex array whose `axis` has length `number / 2 + 1`. It is `.Double` with pocketFFT; with vDSP it is `.Double` for `.Double` input and `.Float` otherwise.
    /// - Precondition: `number` must be positive. With `vDSP: true`, `signal` must be real and `number` must be a power of 2 (at least 2).
    static public func rfft(_ signal: MfArray, number: Int? = nil, axis: Int = -1, norm: FFTNorm = .backward, vDSP: Bool = false) -> MfArray {
        
        let number = number ?? signal.shape[get_positive_axis(axis, ndim: signal.ndim)]
        #if canImport(Accelerate)
        if vDSP{
            return rfft_by_vDSP(signal, number: number, axis: axis, norm: norm)
        }
        else{
            return fft_by_pocketFFT(signal, number: number, axis: axis, isReal: true, isForward: true, norm: norm)
        }
        #else
        // vDSP not available on this platform, use pocketFFT
        return fft_by_pocketFFT(signal, number: number, axis: axis, isReal: true, isForward: true, norm: norm)
        #endif
    }
    
    /// Compute the inverse of `rfft(_:number:axis:norm:vDSP:)`.
    ///
    /// Equivalent to `numpy.fft.irfft`. The input is treated as the non-negative frequency terms of a Hermitian-symmetric spectrum, and a real signal is returned.
    ///
    /// - Parameters:
    ///   - signal: The (complex) half spectrum, e.g. the output of `rfft`.
    ///   - number: The length of the output along `axis`. If `nil` (default), `2 * (m - 1)` is used, where `m` is the length of `signal` along `axis`. Pass the original length to recover an odd-length signal.
    ///   - axis: The axis over which to compute the inverse FFT. Default is -1 (the last axis).
    ///   - norm: The normalization mode. `.backward` (default) scales the inverse transform by `1/n`, `.ortho` scales by `1/sqrt(n)` and `.forward` applies no scaling.
    ///   - vDSP: Must be `false` (default). The vDSP backend is not implemented yet for the inverse transform and traps.
    /// - Returns: A real `.Double` array whose `axis` has length `number`.
    /// - Precondition: `number` must be positive, and `vDSP` must be `false`.
    static public func irfft(_ signal: MfArray, number: Int? = nil, axis: Int = -1, norm: FFTNorm = .backward, vDSP: Bool = false) -> MfArray {

        let number = number ?? (signal.shape[get_positive_axis(axis, ndim: signal.ndim)] - 1)*2
        #if canImport(Accelerate)
        if vDSP{
            preconditionFailure("unsupported now")
            /*
            switch signal.storedType {
            case .Float:
                return fft_zr_by_vDSP(signal, number, axis, true, vDSP_func: vDSP_fft_zrop)
            case .Double:
                return fft_zr_by_vDSP(signal, number, axis, true, vDSP_func: vDSP_fft_zropD)
            }*/
        }
        else{
            return fft_by_pocketFFT(signal, number: number, axis: axis, isReal: true, isForward: false, norm: norm)
        }
        #else
        // vDSP not available on this platform, use pocketFFT
        return fft_by_pocketFFT(signal, number: number, axis: axis, isReal: true, isForward: false, norm: norm)
        #endif
    }
}

/// The normalization mode of the FFT functions. Same as the `norm` argument of `numpy.fft`.
public enum FFTNorm: Int{
    /// Scale the forward transform by `1/n` and apply no scaling to the inverse.
    case forward
    /// Apply no scaling to the forward transform and scale the inverse by `1/n`. This is the default.
    case backward
    /// Scale both the forward and the inverse transforms by `1/sqrt(n)`, making them unitary.
    case ortho
}
