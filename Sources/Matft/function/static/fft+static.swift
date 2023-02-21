//
//  fft+static.swift
//  
//
//  Created by Junnosuke Kado on 2023/02/06.
//

import Foundation
import Accelerate

// ortho について
// https://helve-blog.com/posts/python/numpy-fast-fourier-transform/

extension Matft.fft{
    
    /// Real forward FFT
    /// - Parameters:
    ///   - signal: The source signal mfarray
    ///   - number: The number to be processed
    ///   - axis: The axis
    ///   - norm: The normalization mode.
    ///     - forward
    ///     - backward
    ///     - ortho: multiply 1/sqrt(N) to normalize
    ///   - vDSP: Whether to use vDSP
    /// - Returns: FFT complex mfarray
    static public func rfft(_ signal: MfArray, number: Int? = nil, axis: Int = -1, norm: FFTNorm = .forward, vDSP: Bool = false) -> MfArray {
        
        let number = number ?? signal.shape[get_positive_axis(axis, ndim: signal.ndim)]
        if vDSP{
            switch signal.storedType {
            case .Float:
                return fft_zr_by_vDSP(signal, number, axis, true, vDSP_func: vDSP_fft_zrop)
            case .Double:
                return fft_zr_by_vDSP(signal, number, axis, true, vDSP_func: vDSP_fft_zropD)
            }
        }
        else{
            return fft_by_pocketFFT(signal, number: number, axis: axis, isReal: true, isForward: true, norm: norm)
        }
    }
    
    /// Real backward FFT
    /// - Parameters:
    ///   - signal: The source signal mfarray
    ///   - number: The number to be processed
    ///   - axis: The axis
    ///   - norm: The normalization mode.
    ///     - backward
    ///     - forward
    ///     - ortho: multiply 1/sqrt(N) to normalize
    ///   - vDSP: Whether to use vDSP
    /// - Returns: FFT complex mfarray
    static public func irfft(_ signal: MfArray, number: Int? = nil, axis: Int = -1, norm: FFTNorm = .backward, vDSP: Bool = false) -> MfArray {
        
        let number = number ?? (signal.shape[get_positive_axis(axis, ndim: signal.ndim)] - 1)*2
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
    }
}

public enum FFTNorm: Int{
    case forward
    case backward
    case ortho
}
