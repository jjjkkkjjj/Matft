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
    static public func rfft(_ signal: MfArray, number: Int? = nil, axis: Int = -1, norm: FFTNorm = .forward, vDSP: Bool = false) -> MfArray {
        
        if vDSP{
            switch signal.storedType {
            case .Float:
                return fft_zr_by_vDSP(signal, number, axis, true, vDSP_func: vDSP_fft_zrop)
            case .Double:
                return fft_zr_by_vDSP(signal, number, axis, true, vDSP_func: vDSP_fft_zropD)
            }
        }
        else{
            return pocketFFT_execute(signal, number: number, axis: axis, isForward: true, norm: norm)
        }
    }
}

public enum FFTNorm: Int{
    case forward
    case backward
    case ortho
}
