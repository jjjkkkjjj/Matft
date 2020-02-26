//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public struct MfData{
    internal var _data: UnsafeMutableRawBufferPointer
    internal var _shape: UnsafeMutableBufferPointer<Int>
    internal var _strides: UnsafeMutableBufferPointer<Int>
    internal var _mftype: MfType
    internal var _size: Int
    
    public init(dataptr: UnsafeMutableRawBufferPointer, shapeptr: UnsafeMutableBufferPointer<Int>, mftype: MfType, stridesptr: UnsafeMutableBufferPointer<Int>? = nil){
        
        self._data = dataptr
        self._shape = shapeptr
        self._size = shape2size(shapeptr)
        if let stridesptr = stridesptr{
            self._strides = stridesptr
        }
        else{
            self._strides = shape2strides(self._shape)
        }
        self._mftype = mftype
    }
    
    internal func free() {
        self._data.deallocate()
        self._shape.deallocate()
        self._strides.deallocate()
    }
}

