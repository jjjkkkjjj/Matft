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
        let newarray = MfArray(newdata)
        return newarray
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
        
        let newmfdata = MfData(dataptr: dataptr, shapeptr: shapeptr, mftype: mfdata._mftype, stridesptr: stridesptr)
        
        return newmfdata
        
    }
}
