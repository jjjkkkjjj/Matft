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

internal func math_vv_by_vForce<T: MfStoredAcceleratable>(_ mfarray: MfArray, _ vForce_func: vForce_vv_func<T>) -> MfArray{
    var mfarray = mfarray
    mfarray = check_contiguous(mfarray)
    
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            [unowned mfarray] in
            var storedSize = Int32(mfarray.storedSize)
            vForce_func(dstptrT, $0.baseAddress!, &storedSize)
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

internal typealias vForce_biop_vv_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

internal func math_biop_vv_by_vForce<T: MfStoredAcceleratable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ vForce_func: vForce_biop_vv_func<T>) -> MfArray{
    let l_mfarray = to_row_major(l_mfarray)
    let r_mfarray = to_row_major(r_mfarray)
    
    var storedSize = Int32(l_mfarray.storedSize)
    let newdata = withDummyDataMRPtr(l_mfarray.mftype, storedSize: l_mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: l_mfarray.storedSize)
        l_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            lptr in
            r_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
                rptr in
                vForce_func(dstptrT, lptr.baseAddress!, rptr.baseAddress!, &storedSize)
            }
        }
    }

    let newmfstructure = copy_mfstructure(l_mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
