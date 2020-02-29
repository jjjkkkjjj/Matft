//
//  mfarray.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public class MfArray{
    public internal(set) var mfdata: MfData
    
    public var shape: [Int]{
        return Array(self.mfdata._shape)
    }
    internal var shapeptr: UnsafeMutableBufferPointer<Int>{
        return self.mfdata._shape
    }
    public var strides: [Int]{
        return Array(self.mfdata._strides)
    }
    internal var stridesptr: UnsafeMutableBufferPointer<Int>{
        return self.mfdata._strides
    }
    public var ndim: Int{
        return self.mfdata._shape.count
    }
    public var size: Int{
        return self.mfdata._size
    }
    public var mftype: MfType{
        return self.mfdata._mftype
    }
    // return flatten array
    public var data: [Any]{
        return unsafeMRBPtr2array_viaForD(self.dataptr, mftype: self.mftype, size: self.size)
    }
    internal var dataptr: UnsafeMutableRawBufferPointer{
        if let base = self.base{
            return base.dataptr
        }
        else{
            return self.mfdata._data
        }
    }
    internal var storedSize: Int{
        return self.mfdata._storedSize
    }
    internal var storedType: StoredType{
        return self.mfdata._storedType
    }
    
    public var base: MfArray?
    
    public init (_ array: [Any], mftype: MfType? = nil) throws {
        
        var _mftype: MfType = .None
        var (flatten, shape) = array.withUnsafeBufferPointer{
            flatten_array(ptr: $0, mftype: &_mftype)
        }
    
        if _mftype == .Object{
            //print(flatten)
            throw MfError.creationError("Matft does not support Object. Shape was \(shape)")
        }
        
        //flatten array to pointer
        switch _mftype {
            case .Object:
                throw MfError.creationError("Matft does not support Object. Shape was \(shape)")
            case .None:
                throw MfError.creationError("Matft does not support empty object.")
            default:
                let ptr = flattenarray2UnsafeMRBPtr_viaForD(&flatten)
                let shapeptr = array2UnsafeMBPtrT(&shape)
                self.mfdata = MfData(dataptr: ptr, storedSize: flatten.count, shapeptr: shapeptr, mftype: _mftype)
        }
    }
    public init (_ mfdata: MfData){
        self.mfdata = mfdata
    }
    public init (base: MfArray){
        self.base = base
        self.mfdata = base.mfdata.shallowcopy()
    }
    deinit {
        self.mfdata.free()
    }
}

