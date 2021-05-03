//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public class MfData{
    private var __refdata: MfData? // must be referenced because refdata could be freed automatically?
    public internal(set) var _data: UnsafeMutableRawPointer
    
    public internal(set) var _mftype: MfType
    internal var _storedType: StoredType{
        return MfType.storedType(self._mftype)
    }
    public let _storedSize: Int
    public var _storedByteSize: Int{
        switch self._storedType {
        case .Float:
            return self._storedSize * MemoryLayout<Float>.size
        case .Double:
            return self._storedSize * MemoryLayout<Double>.size
        }
    }

    public var _isView: Bool{
        return self.__refdata != nil
    }
    
    public let _offset: Int
    public var _byteOffset: Int{
        get{
            switch self._storedType {
            case .Float:
                return self._offset * MemoryLayout<Float>.size
            case .Double:
                return self._offset * MemoryLayout<Double>.size
            }
        }
    }
    
    
    
    
    public init(dataptr: UnsafeMutableRawPointer, storedSize: Int, mftype: MfType){
        self._data = dataptr
        self._storedSize = storedSize
        self._mftype = mftype
        self._offset = 0
    }
    public init(mfdata: MfData){
        self._data = mfdata._data
        self._storedSize = mfdata._storedSize
        self._mftype = mfdata._mftype
        self._offset = 0
    }
    
    
    // create view
    public init(refdata: MfData, offset: Int){
        self.__refdata = refdata
        self._data = refdata._data
        self._storedSize = refdata._storedSize
        self._mftype = refdata._mftype
        self._offset = offset
    }
    
    deinit {
        if !self._isView{
            func _deallocate<T: MfStorable>(_ type: T.Type){
                let dataptr = self._data.bindMemory(to: T.self, capacity: self._storedSize)
                dataptr.deinitialize(count: self._storedSize)
                dataptr.deallocate()
            }
            switch self._storedType {
            case .Float:
                _deallocate(Float.self)
            case .Double:
                _deallocate(Double.self)
            }
            //self._data.deallocate()
        }
        self.__refdata = nil
    }
}

