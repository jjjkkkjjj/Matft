//
//  order.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/06.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal func to_row_major(){
    for vDSPPrams in vDSPOptParams(bigger_mfarray: bigger_mfarray, smaller_mfarray: smaller_mfarray){
        biop_unsafePtrT(lptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptr + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
    }
}

internal func to_column_major(){
    cblas_scopy(<#T##__N: Int32##Int32#>, <#T##__X: UnsafePointer<Float>!##UnsafePointer<Float>!#>, <#T##__incX: Int32##Int32#>, <#T##__Y: UnsafeMutablePointer<Float>!##UnsafeMutablePointer<Float>!#>, <#T##__incY: Int32##Int32#>)
    cblas_dcopy(<#T##__N: Int32##Int32#>, <#T##__X: UnsafePointer<Double>!##UnsafePointer<Double>!#>, <#T##__incX: Int32##Int32#>, <#T##__Y: UnsafeMutablePointer<Double>!##UnsafeMutablePointer<Double>!#>, <#T##__incY: Int32##Int32#>)
}

