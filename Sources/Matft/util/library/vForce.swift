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

internal func math_vv_by_vForce<T: MfStorable>(_ mfarray: MfArray, _ vForce_func: vForce_vv_func<T>) -> MfArray{
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

internal typealias vForce_1arg_vv_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

internal func math_1arg_vv_by_vForce<T: MfStorable>(_ mfarray: MfArray, _ arg: UnsafePointer<T>, _ vForce_func: vForce_1arg_vv_func<T>) -> MfArray{
    var mfarray = mfarray
    mfarray = check_contiguous(mfarray)
    
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            [unowned mfarray] in
            var storedSize = Int32(mfarray.storedSize)
            vForce_func(dstptrT, $0.baseAddress!, arg, &storedSize)
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
