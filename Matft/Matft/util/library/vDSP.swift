//
//  vDSP.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

//converter
internal typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

internal func unsafePtrT2UnsafeMPtrU<T, U>(_ srcptr: UnsafePointer<T>,  _ dstptr: UnsafeMutablePointer<U>, _ vDSP_func: vDSP_convert_func<T, U>, _ count: Int){
    vDSP_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}
internal func preop_by_vDSP<T: Numeric>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    return MfArray(mfdata: newdata, mfstructure: mfarray.mfstructure)
}

//binary operation
internal typealias vDSP_biop_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func biop_unsafePtrT<T>(_ lptr: UnsafePointer<T>, _ lstride: Int, _ rptr: UnsafePointer<T>, _ rstride: Int, _ dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_func<T>){
    vDSP_func(lptr, vDSP_Stride(lstride), rptr, vDSP_Stride(rstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_by_vDSP<T: Numeric>(_ bigger_mfarray: MfArray, _ smaller_mfarray: MfArray, vDSP_func: vDSP_biop_func<T>) -> MfArray{
    
    let newdata = withDummyDataMRPtr(bigger_mfarray.mftype, storedSize: bigger_mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: bigger_mfarray.storedSize)
        bigger_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            bptr in
            smaller_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
                sptr in
                for vDSPPrams in OptOffsetParams(bigger_mfarray: bigger_mfarray, smaller_mfarray: smaller_mfarray){
                biop_unsafePtrT(bptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, sptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
                }
            }
        }
    }
    
    return MfArray(mfdata: newdata, mfstructure: bigger_mfarray.mfstructure)
}
