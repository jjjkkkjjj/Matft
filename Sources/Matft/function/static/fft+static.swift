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
    static public func rfft(_ signal: MfArray, number: Int? = nil, axis: Int = -1, isForward: Bool = false) -> MfArray {
        switch signal.storedType {
        case .Float:
            return fft_zr_by_vDSP(signal, number, axis, isForward, vDSP_func: vDSP_fft_zrop)
        case .Double:
            return fft_zr_by_vDSP(signal, number, axis, isForward, vDSP_func: vDSP_fft_zropD)
        }
    }
}
