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
        return unsafeMRBPtr2array_viaForD(self.dataptr, mftype: self.mftype, size: self.storedSize)
    }
    internal var dataptr: UnsafeMutableRawBufferPointer{
        return self.mfdata._data
    }
    internal var dataptrF: UnsafeMutableBufferPointer<Float>?{
        return self.storedType == .Float ? self.dataptr.bindMemory(to: Float.self) : nil
    }
    internal var dataptrD: UnsafeMutableBufferPointer<Double>?{
        return self.storedType == .Double ? self.dataptr.bindMemory(to: Double.self) : nil
    }
    internal var storedSize: Int{
        return self.mfdata._storedSize
    }
    internal var storedType: StoredType{
        return self.mfdata._storedType
    }
    
    public var base: MfArray?
    public var offsetFlattenIndex: Int{
        return self.mfdata._offsetFlattenIndex
    }
    
    public init (_ array: [Any], mftype: MfType? = nil, shape: [Int]? = nil) {
        
        var _mftype: MfType = .None
        var (flatten, _shape) = array.withUnsafeBufferPointer{
            flatten_array(ptr: $0, mftype: &_mftype)
        }
    
        if _mftype == .Object{
            //print(flatten)
            fatalError("Matft does not support Object. Shape was \(_shape)")
        }
        
        //flatten array to pointer
        switch _mftype {
            case .Object:
                fatalError("Matft does not support Object. Shape was \(_shape)")
            case .None:
                fatalError("Matft does not support empty object.")
            default:
                let ptr = flattenarray2UnsafeMRBPtr_viaForD(&flatten)
                if var shape = shape{
                    precondition(shape2size(&shape) == flatten.count, "Invalid shape, size must be \(flatten.count), but got \(shape2size(&shape))")
                    let shapeptr = array2UnsafeMBPtrT(&shape)
                    self.mfdata = MfData(dataptr: ptr, storedSize: flatten.count, shapeptr: shapeptr, mftype: _mftype)
                }
                else{
                    let shapeptr = array2UnsafeMBPtrT(&_shape)
                    self.mfdata = MfData(dataptr: ptr, storedSize: flatten.count, shapeptr: shapeptr, mftype: _mftype)
                }
        }
    }
    public init (mfdata: MfData){
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


