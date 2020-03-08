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
    public var _shape: UnsafeMutablePointer<Int>
    public var _strides: UnsafeMutablePointer<Int>

    public var _mftype: MfType
    public var _size: Int
    public var _storedSize: Int
    public var _storedByteSize: Int{
        switch self._storedType {
        case .Float:
            return self._storedSize * MemoryLayout<Float>.size
        case .Double:
            return self._storedSize * MemoryLayout<Double>.size
        }
    }
    public var _ndim: Int
    public var _isView: Bool{
        return self.__offset != nil
    }
    private var __offset: Int?
    public var _offset: Int{
        get{
            return self.__offset ?? 0
        }
        set{
            self.__offset = newValue
        }
    }
    public var _byteOffset: Int{
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
    
    internal var _storedType: StoredType{
        return MfType.storedType(self._mftype)
    }
    
    public var _flags: MfFlags
    public var _order: MfOrder{
        return MfOrder.get_order(mfflags: self._flags)
    }
    
    public init(dataptr: UnsafeMutableRawPointer, storedSize: Int, shapeptr: UnsafeMutablePointer<Int>, mftype: MfType, ndim: Int, stridesptr: UnsafeMutablePointer<Int>){
        
        self._data = dataptr
        self._storedSize = storedSize
        self._shape = shapeptr
        self._ndim = ndim
        let _shapeptr = UnsafeMutableBufferPointer<Int>(start: shapeptr, count: ndim)
        self._size = shape2size(_shapeptr)
        
        self._strides = stridesptr
        self._flags = MfFlags(shapeptr: shapeptr, stridesptr: stridesptr, ndim: ndim)
        
        self._mftype = mftype
    }
    public init(dataptr: UnsafeMutableRawPointer, storedSize: Int, shapeptr: UnsafeMutablePointer<Int>, mftype: MfType, ndim: Int, mforder: MfOrder){
        
        self._data = dataptr
        self._storedSize = storedSize
        self._shape = shapeptr
        self._ndim = ndim
        let _shapeptr = UnsafeMutableBufferPointer<Int>(start: shapeptr, count: ndim)
        self._size = shape2size(_shapeptr)
        
        let stridesptr = UnsafeMutablePointer<Int>(shape2strides(_shapeptr, mforder: mforder).baseAddress!)
        self._strides = stridesptr
        self._flags = MfFlags(shapeptr: shapeptr, stridesptr: stridesptr, ndim: ndim)
        
        self._mftype = mftype
    }
    public init(mfdata: MfData){
        self._data = mfdata._data
        self._storedSize = mfdata._storedSize
        self._shape = mfdata._shape
        self._size = mfdata._size
        self._flags = mfdata._flags
        self._strides = mfdata._strides
        self._mftype = mfdata._mftype
        self._ndim = mfdata._ndim
    }
    // create view
    public init(refdata: MfData, offset: Int, shapeptr: UnsafeMutablePointer<Int>, ndim: Int, mforder: MfOrder, stridesptr: UnsafeMutablePointer<Int>? = nil){
        self._data = refdata._data
        self._storedSize = refdata._storedSize
        self._shape = shapeptr
        let _shapeptr = UnsafeMutableBufferPointer(start: shapeptr, count: ndim)
        self._size = shape2size(_shapeptr)
        
        if let stridesptr = stridesptr{
            self._strides = stridesptr
            self._flags = MfFlags(shapeptr: shapeptr, stridesptr: stridesptr, ndim: ndim)
        }
        else{
            let stridesptr = UnsafeMutablePointer<Int>(shape2strides(_shapeptr, mforder: mforder).baseAddress!)
            self._strides = stridesptr
            self._flags = MfFlags(shapeptr: shapeptr, stridesptr: stridesptr, ndim: ndim)
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
        self._shape.deinitialize(count: self._ndim)
        self._shape.deallocate()
        self._strides.deinitialize(count: self._ndim)
        self._strides.deallocate()
    }
}

