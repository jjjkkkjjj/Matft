//
//  mfstructure.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/10.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public struct MfStructure{
    public var _shape: UnsafeMutablePointer<Int>
    public var _strides: UnsafeMutablePointer<Int>
    public var _ndim: Int
    public var _size: Int
    public var _flags: MfFlags
    
    public init(shapeptr: UnsafeMutablePointer<Int>, mforder: MfOrder, ndim: Int){
        self._shape = shapeptr
        let shapeMBPtr = UnsafeMutableBufferPointer(start: shapeptr, count: ndim)
        let stridesptr = shape2strides(shapeMBPtr, mforder: mforder)
        self._strides = stridesptr.baseAddress!
        self._ndim = ndim
        self._size = shape2size(shapeMBPtr)
        
        self._flags = MfFlags(shapeptr: self._shape, stridesptr: self._strides, ndim: self._ndim)
    }
    public init(shapeptr: UnsafeMutablePointer<Int>, stridesptr: UnsafeMutablePointer<Int>, ndim: Int){
        self._shape = shapeptr
        self._strides = stridesptr
        self._ndim = ndim
        let shapeMBPtr = UnsafeMutableBufferPointer(start: shapeptr, count: ndim)
        self._size = shape2size(shapeMBPtr)
        
        self._flags = MfFlags(shapeptr: self._shape, stridesptr: self._strides, ndim: self._ndim)
    }
    internal func free(){
        self._shape.deinitialize(count: self._ndim)
        self._shape.deallocate()
        
        self._strides.deinitialize(count: self._ndim)
        self._strides.deallocate()
    }
}

