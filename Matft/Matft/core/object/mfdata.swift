//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public struct MfData{
    private var __data: UnsafeMutableRawBufferPointer
    public var _data: UnsafeMutableRawBufferPointer{
        return self.__data.dropFirst(self._offset).base
    }
    public var _shape: UnsafeMutableBufferPointer<Int>
    public var _strides: UnsafeMutableBufferPointer<Int>
    public var _mftype: MfType
    public var _size: Int
    public var _storedSize: Int
    public var _isView: Bool{
        return self.__offset != nil
    }
    private var __offset: Int? //cannot access from outside for safety
    private var _offset: Int{
        get{
            return self.__offset ?? 0
        }
        set (newValue){
            switch self._storedType {
            case .Float:
                self.__offset = newValue * MemoryLayout<Float>.size
            case .Double:
                self.__offset = newValue * MemoryLayout<Double>.size
            }
        }
    }
    
    internal var _storedType: StoredType{
        return MfType.storedType(self._mftype)
    }
    
    public init(dataptr: UnsafeMutableRawBufferPointer, storedSize: Int, shapeptr: UnsafeMutableBufferPointer<Int>, mftype: MfType, stridesptr: UnsafeMutableBufferPointer<Int>? = nil){
        
        self.__data = dataptr
        self._storedSize = storedSize
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
    public init(mfdata: MfData){
        self.__data = mfdata._data
        self._storedSize = mfdata._storedSize
        self._shape = mfdata._shape
        self._size = mfdata._size
        self._strides = mfdata._strides
        self._mftype = mfdata._mftype
    }
    // create view
    public init(refdata: MfData, offset: Int, shapeptr: UnsafeMutableBufferPointer<Int>, stridesptr: UnsafeMutableBufferPointer<Int>? = nil){
        self.__data = refdata._data
        self._storedSize = refdata._storedSize
        self._shape = shapeptr
        self._size = shape2size(shapeptr)
        if let stridesptr = stridesptr{
            self._strides = stridesptr
        }
        else{
            self._strides = shape2strides(self._shape)
        }
        self._mftype = refdata._mftype
        
        self._offset = offset
    }
    
    internal func free() {
        if !self._isView{
            self.__data.deallocate()
        }
        self._shape.deallocate()
        self._strides.deallocate()
    }
}

