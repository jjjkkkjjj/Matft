//
//  vecLib.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal typealias vForce_vv_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

internal func math_vv_by_vForce<T: MfTypable, U: MfStorable, V: MfTypable>(_ mfarray: MfArray<T>, _ vForce_func: vForce_vv_func<U>) -> MfArray<V>{
    var mfarray = mfarray
    mfarray = check_contiguous(mfarray)
    
    let newdata = withDummyDataMRPtr(V.self, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrU = dstptr.bindMemory(to: U.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            [unowned mfarray] in
            var storedSize = Int32(mfarray.storedSize)
            vForce_func(dstptrU, $0.baseAddress!, &storedSize)
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

internal typealias vForce_biop_vv_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

internal func math_biop_vv_by_vForce<T: MfTypable, U: MfStorable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, _ vForce_func: vForce_biop_vv_func<U>) -> MfArray<T>{
    let l_mfarray = to_row_major(l_mfarray)
    let r_mfarray = to_row_major(r_mfarray)
    
    var storedSize = Int32(l_mfarray.storedSize)
    let newdata = withDummyDataMRPtr(T.self, storedSize: l_mfarray.storedSize){
        dstptr in
        let dstptrU = dstptr.bindMemory(to: U.self, capacity: l_mfarray.storedSize)
        l_mfarray.withDataUnsafeMBPtrT(datatype: U.self){
            lptr in
            r_mfarray.withDataUnsafeMBPtrT(datatype: U.self){
                rptr in
                vForce_func(dstptrU, lptr.baseAddress!, rptr.baseAddress!, &storedSize)
            }
        }
    }

    let newmfstructure = copy_mfstructure(l_mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
