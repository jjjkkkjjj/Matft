//
//  vecLib.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

internal typealias vDSP_vv_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

internal func math_vv_by_vecLib<T: Numeric>(_ mfarray: MfArray, _ vDSP_func: vDSP_vv_func<T>) -> MfArray{
    let dstptrT = create_unsafeMPtrT(type: T.self, count: mfarray.storedSize)
    let srcptrT = mfarray.dataptr.bindMemory(to: T.self)

    var storedSize = Int32(mfarray.storedSize)
    
    vDSP_func(dstptrT, srcptrT.baseAddress!, &storedSize)
    
    let dstptr = UnsafeMutableRawPointer(dstptrT)
    
    let shapeptr = create_unsafeMPtrT(type: Int.self, count: mfarray.ndim)
    shapeptr.assign(from: mfarray.mfdata._shape, count: mfarray.ndim)
    
    let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfarray.ndim)
    stridesptr.assign(from: mfarray.mfdata._strides, count: mfarray.ndim)
    
    let newdata = MfData(dataptr: dstptr, storedSize: mfarray.storedSize, shapeptr: shapeptr, mftype: mfarray.mftype, ndim: mfarray.ndim, stridesptr: stridesptr)
    return MfArray(mfdata: newdata)
}

internal typealias vDSP_1arg_vv_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

internal func math_1arg_vv_by_vecLib<T: Numeric>(_ mfarray: MfArray, _ arg: UnsafePointer<T>, _ vDSP_func: vDSP_1arg_vv_func<T>) -> MfArray{
    let dstptrT = create_unsafeMPtrT(type: T.self, count: mfarray.storedSize)
    let srcptrT = mfarray.dataptr.bindMemory(to: T.self)

    var storedSize = Int32(mfarray.storedSize)
    
    vDSP_func(dstptrT, srcptrT.baseAddress!, arg, &storedSize)
    
    let dstptr = UnsafeMutableRawPointer(dstptrT)
    
    let shapeptr = create_unsafeMPtrT(type: Int.self, count: mfarray.ndim)
    shapeptr.assign(from: mfarray.mfdata._shape, count: mfarray.ndim)
    
    let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfarray.ndim)
    stridesptr.assign(from: mfarray.mfdata._strides, count: mfarray.ndim)
    
    let newdata = MfData(dataptr: dstptr, storedSize: mfarray.storedSize, shapeptr: shapeptr, mftype: mfarray.mftype, ndim: mfarray.ndim, stridesptr: stridesptr)
    return MfArray(mfdata: newdata)
}
