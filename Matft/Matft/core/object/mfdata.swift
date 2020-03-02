//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public struct MfData{
    public var _data: UnsafeMutableRawBufferPointer
    private var __shape: UnsafeMutableBufferPointer<Int>
    public var _shape: UnsafeMutableBufferPointer<Int>{
        get{
            return self.__shape
        }
        set(newValue){
            //free
            //self.__shape.deallocate()
            self.__shape = newValue
        }
    }
    private var __strides: UnsafeMutableBufferPointer<Int>
    public var _strides: UnsafeMutableBufferPointer<Int>{
        get{
            return self.__strides
        }
        set(newValue){
            //free
            //self.__strides.deallocate()
            self.__strides = newValue
        }
    }

    public var _mftype: MfType
    public var _size: Int
    public var _storedSize: Int
    public var _isView: Bool{
        return self.__offset != nil
    }
    private var __offset: Int?
    public var _offset: Int{
        get{
            guard let offset = self.__offset else{
                return 0
            }
            switch self._storedType {
            case .Float:
                return offset * MemoryLayout<Float>.size
            case .Double:
                return offset * MemoryLayout<Double>.size
            }
        }
    }
    public var _offsetFlattenIndex: Int{
        get{
            return self.__offset ?? 0
        }
        set (newValue){
            self.__offset = newValue
        }
    }
    
    internal var _storedType: StoredType{
        return MfType.storedType(self._mftype)
    }
    
    public init(dataptr: UnsafeMutableRawBufferPointer, storedSize: Int, shapeptr: UnsafeMutableBufferPointer<Int>, mftype: MfType, stridesptr: UnsafeMutableBufferPointer<Int>? = nil){
        
        self._data = dataptr
        self._storedSize = storedSize
        self.__shape = shapeptr
        self._size = shape2size(shapeptr)
        if let stridesptr = stridesptr{
            self.__strides = stridesptr
        }
        else{
            self.__strides = shape2strides(shapeptr)
        }
        self._mftype = mftype
    }
    public init(mfdata: MfData){
        self._data = mfdata._data
        self._storedSize = mfdata._storedSize
        self.__shape = mfdata._shape
        self._size = mfdata._size
        self.__strides = mfdata._strides
        self._mftype = mfdata._mftype
    }
    // create view
    public init(refdata: MfData, offset: Int, shapeptr: UnsafeMutableBufferPointer<Int>, stridesptr: UnsafeMutableBufferPointer<Int>? = nil){
        self._data = refdata._data
        self._storedSize = refdata._storedSize
        self.__shape = shapeptr
        self._size = shape2size(shapeptr)
        if let stridesptr = stridesptr{
            self.__strides = stridesptr
        }
        else{
            self.__strides = shape2strides(shapeptr)
        }
        self._mftype = refdata._mftype
        
        self.__offset = offset
    }
    
    internal func free() {
        if !self._isView{
            self._data.deallocate()
        }
        self.__shape.deallocate()
        self.__strides.deallocate()
    }
}

