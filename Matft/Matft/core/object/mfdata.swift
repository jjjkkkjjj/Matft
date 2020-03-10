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
    internal var _storedType: StoredType
    public var _storedSize: Int
    public var _storedByteSize: Int{
        switch self._storedType {
        case .Float:
            return self._storedSize * MemoryLayout<Float>.size
        case .Double:
            return self._storedSize * MemoryLayout<Double>.size
        }
    }

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
    
    
    
    
    public init(dataptr: UnsafeMutableRawPointer, storedSize: Int, storedType: StoredType){
        self._data = dataptr
        self._storedSize = storedSize
        self._storedType = storedType
    }
    public init(mfdata: MfData){
        self._data = mfdata._data
        self._storedSize = mfdata._storedSize
        self._storedType = mfdata._storedType
    }
    // create dummy
    public init(storedSize: Int, storedType: StoredType){
        switch storedType {
        case .Float:
            self._data = create_unsafeMRPtr(type: Float.self, count: storedSize)
        case .Double:
            self._data = create_unsafeMRPtr(type: Double.self, count: storedSize)
        }
        self._storedSize = storedSize
        self._storedType = storedType
    }
    
    // create view
    public init(refdata: MfData, offset: Int){
        self._data = refdata._data
        self._storedSize = refdata._storedSize
        self._storedType = refdata._storedType
        self.__offset = offset
    }
    
    internal func free() {
        self.free_data()
    }
}

