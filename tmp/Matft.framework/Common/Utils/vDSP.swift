//
//  vDSP.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/26.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation
import Accelerate


typealias vDSP_infix_func = (UnsafePointer<Double>, vDSP_Stride, UnsafePointer<Double>, vDSP_Stride, UnsafeMutablePointer<Double>, vDSP_Stride, vDSP_Length) -> Void

internal func vDSP_infix<T: MfNumeric>(_ left: MfArray<T>, _ right: MfArray<T>, _ vDSP_func: vDSP_infix_func) -> MfArray<T>{
    
    let new = Matft.mfarray.nums(num: 0, type: T.self, shape: left.shape)
    
    for i in (0..<left.ndim).reversed(){
        vDSP_func(left.data, vDSP_Stride(left.strides[i]), right.data, vDSP_Stride(right.strides[i]), new.data, vDSP_Stride(new.strides[i]), vDSP_Length())
    }
    
    
    return new
    /*
    let IA = vDSP_Stride(left_stride)
    let IB = vDSP_Stride(right_stride)
    let IC = vDSP_Stride(out_stride)
    let N = vDSP_Length(dim_shape)
    
    switch vDSP_function {
    case vDSP_op.infix.add:
        vDSP_vaddD(left_data, IA, right_data, IB, out_data, IC, N)
    case vDSP_op.infix.sub:
        vDSP_vsubD(left_data, IA, right_data, IB, out_data, IC, N)
    case vDSP_op.infix.mul:
        vDSP_vmulD(left_data, IA, right_data, IB, out_data, IC, N)
    case vDSP_op.infix.div:
        vDSP_vdivD(left_data, IA, right_data, IB, out_data, IC, N)
    }*/
}
/*
internal func vDSP_prefix(vDSP_function: vDSP_op.prefix, _ data: UnsafePointer<Double>, _ stride: Int, _ out_data: UnsafeMutablePointer<Double>, _ out_stride: Int, _ size: Int){
    let IA = vDSP_Stride(stride)
    let IC = vDSP_Stride(out_stride)
    let N = vDSP_Length(size)
    
    switch vDSP_function {
    case vDSP_op.prefix.neg:
        vDSP_vnegD(data, IA, out_data, IC, N)
    }
}


*/
