//
//  creation.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension Matft.mfarray{
    static public func create_view(_ mfarray: MfArray) -> MfArray{
        return MfArray(base: mfarray)
    }
    static public func deepcopy(_ mfarray: MfArray) -> MfArray{
        let newdata = Matft.mfarray.mfdata.deepcopy(mfarray.mfdata)
        let newarray = MfArray(mfdata: newdata)
        return newarray
    }
    
    static public func nums<T: Numeric>(_ value: T, shape: [Int], mftype: MfType? = nil) -> MfArray{
        var shape = shape
        let size = shape.withUnsafeMutableBufferPointer{
            shape2size($0)
        }
        return MfArray(Array(repeating: value, count: size), mftype: mftype, shape: shape)
    }
    static public func arange<T: Strideable>(start: T, stop: T, step: T.Stride, shape: [Int]? = nil, mftype: MfType? = nil) -> MfArray{
        return MfArray(Array(stride(from: start, to: stop, by: step)), mftype: mftype, shape: shape)
    }
}

extension Matft.mfarray.mfdata{
    static public func deepcopy(_ mfdata: MfData) -> MfData{

        //copy data
        let dataptr = mfdata._mftype == .Double ? create_unsafeMRBPtr(type: Double.self, count: mfdata._size) : create_unsafeMRBPtr(type: Float.self, count: mfdata._size)
        memcpy(dataptr.baseAddress!, mfdata._data.baseAddress!, mfdata._data.count)
        
        //copy shape
        let shapeptr = create_unsafeMBPtrT(type: Int.self, count: mfdata._shape.count)
        memcpy(shapeptr.baseAddress!, mfdata._shape.baseAddress!, MemoryLayout<Int>.size * mfdata._shape.count)
        
        //copy strides
        let stridesptr = create_unsafeMBPtrT(type: Int.self, count: mfdata._shape.count)
        memcpy(stridesptr.baseAddress!, mfdata._strides.baseAddress!, MemoryLayout<Int>.size * mfdata._strides.count)
        
        let newmfdata = MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mfdata._mftype, stridesptr: stridesptr)
        
        return newmfdata
        
    }
    static public func shallowcopy(_ mfdata: MfData) -> MfData{
        //copy shape
        let shapeptr = create_unsafeMBPtrT(type: Int.self, count: mfdata._shape.count)
        memcpy(shapeptr.baseAddress!, mfdata._shape.baseAddress!, MemoryLayout<Int>.size * mfdata._shape.count)
        
        //copy strides
        let stridesptr = create_unsafeMBPtrT(type: Int.self, count: mfdata._shape.count)
        memcpy(stridesptr.baseAddress!, mfdata._strides.baseAddress!, MemoryLayout<Int>.size * mfdata._strides.count)
        
        let newmfdata = MfData(refdata: mfdata, offset: 0, shapeptr: shapeptr, stridesptr: stridesptr)
        
        return newmfdata
    }
}
