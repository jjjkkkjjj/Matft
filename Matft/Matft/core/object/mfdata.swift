//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public struct MfData{
    public var _data: UnsafeMutableRawPointer
    private var __shape: UnsafeMutablePointer<Int>
    public var _shape: UnsafeMutablePointer<Int>{
        get{
            return self.__shape
        }
        set(newValue){
            //free
            self.__shape.deinitialize(count: self._ndim)
            self.__shape.deallocate()
            self.__shape = newValue
        }
    }
    private var __strides: UnsafeMutablePointer<Int>
    public var _strides: UnsafeMutablePointer<Int>{
        get{
            return self.__strides
        }
        set(newValue){
            //free
            self.__strides.deinitialize(count: self._ndim)
            self.__strides.deallocate()
            self.__strides = newValue
        }
    }

    public var _mftype: MfType
    public var _size: Int
    public var _storedSize: Int
    public var _ndim: Int
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
    
    public init(dataptr: UnsafeMutableRawPointer, storedSize: Int, shapeptr: UnsafeMutablePointer<Int>, mftype: MfType, ndim: Int, stridesptr: UnsafeMutablePointer<Int>? = nil){
        
        self._data = dataptr
        self._storedSize = storedSize
        self.__shape = shapeptr
        self._ndim = ndim
        let _shapeptr = UnsafeMutableBufferPointer<Int>(start: shapeptr, count: ndim)
        self._size = shape2size(_shapeptr)
        if let stridesptr = stridesptr{
            self.__strides = stridesptr
        }
        else{
            self.__strides = UnsafeMutablePointer<Int>(shape2strides(_shapeptr).baseAddress!)
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
        self._ndim = mfdata._ndim
    }
    // create view
    public init(refdata: MfData, offset: Int, shapeptr: UnsafeMutablePointer<Int>, ndim: Int, stridesptr: UnsafeMutablePointer<Int>? = nil){
        self._data = refdata._data
        self._storedSize = refdata._storedSize
        self.__shape = shapeptr
        let _shapeptr = UnsafeMutableBufferPointer(start: shapeptr, count: ndim)
        self._size = shape2size(_shapeptr)
        if let stridesptr = stridesptr{
            self.__strides = stridesptr
        }
        else{
            self.__strides = UnsafeMutablePointer<Int>(shape2strides(_shapeptr).baseAddress!)
        }
        self._mftype = refdata._mftype
        self._ndim = ndim
        
        self.__offset = offset
    }
    
    internal func free() {
        if !self._isView{
            switch self._storedType {
            case .Float:
                let dataptr = self._data.bindMemory(to: Float.self, capacity: self._storedSize)
                dataptr.deinitialize(count: self._storedSize)
                dataptr.deallocate()
            case .Double:
                let dataptr = self._data.bindMemory(to: Double.self, capacity: self._storedSize)
                dataptr.deinitialize(count: self._storedSize)
                dataptr.deallocate()
            }
            //self._data.deallocate()
        }
        self.__shape.deinitialize(count: self._ndim)
        self.__shape.deallocate()
        self.__strides.deinitialize(count: self._ndim)
        self.__strides.deallocate()
    }
}

