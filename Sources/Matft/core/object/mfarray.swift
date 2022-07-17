//
//  mfarray.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

open class MfArray{
    public internal(set) var mfdata: MfData // Only setter is private
    public internal(set) var mfstructure: MfStructure

    public internal(set) var base: MfArray?
    public var offsetIndex: Int{
        return self.mfdata.offset
    }
    
    //mfdata getter
    //return base's data
    public var data: [Any]{
        if let base = self.base{
            return base.data
        }
        else{
            return self.withUnsafeMutableStartRawPointer{
                [unowned self] in
                data2flattenArray($0, mftype: self.mftype, size: self.storedSize)
            }
        }
    }
    internal var storedData: [Any]{
        if let base = self.base{
            return base.storedData
        }
        else{
            switch self.storedType {
            case .Float:
                return self.withUnsafeMutableStartPointer(datatype: Float.self){
                    Array(UnsafeMutableBufferPointer(start: $0, count: self.storedSize)) as [Any]
                }
            case .Double:
                return self.withUnsafeMutableStartPointer(datatype: Double.self){
                    Array(UnsafeMutableBufferPointer(start: $0, count: self.storedSize)) as [Any]
                }
            }
        }
    }
    
    public var mftype: MfType{
        return self.mfdata.mftype
    }
    public var storedType: StoredType{
        return self.mfdata.storedType
    }
    public var storedSize: Int{
        return self.mfdata.storedSize
    }
    public var storedByteSize: Int{
        return self.mfdata.storedByteSize
    }
    
    //mfstructure getter
    public var shape: [Int]{
        return self.mfstructure.shape
    }
    public var strides: [Int]{
        return self.mfstructure.strides
    }
    
    public var ndim: Int{
        return self.mfstructure.shape.count
    }
    public var size: Int{
        return shape2size(&self.mfstructure.shape)
    }
    public var byteSize: Int{
        let num = self.mftype.isComplex() ? 2 : 1
        switch self.storedType {
        case .Float:
            return self.size * MemoryLayout<Float>.size * num
        case .Double:
            return self.size * MemoryLayout<Double>.size * num
        }
    }

    public init (_ array: [Any], mftype: MfType? = nil, shape: [Int]? = nil, mforder: MfOrder = .Row) {
        
        var (flattenArray, shape_from_array) = array.withUnsafeBufferPointer{
            flatten_array(ptr: $0, mforder: mforder)
        }
    
        if mftype == .Object || mftype == .None{
            //print(flatten)
            preconditionFailure("Matft does not support Object and None. Shape was \(shape_from_array)")
        }
        let mftype_from_array = get_mftype(&flattenArray)
        let mftype = mftype ?? mftype_from_array
        
        // set mfdata and mfstructure
        var shape = shape ?? shape_from_array
        precondition(shape2size(&shape) == flattenArray.count, "Invalid shape, size must be \(flattenArray.count), but got \(shape2size(&shape))")
        
        self.mfdata = MfData(flattenArray: &flattenArray, mftype: mftype)
        self.mfstructure = MfStructure(shape: shape, mforder: mforder)
        
    }
    public init (mfdata: MfData, mfstructure: MfStructure){
        self.mfdata = mfdata
        self.mfstructure = mfstructure
    }
    //create view
    public init (base: MfArray, mfstructure: MfStructure, offset: Int){
        self.base = base
        self.mfdata = MfData(refdata: base.mfdata, offset: offset)
        self.mfstructure = mfstructure//mfstructure will be copied because mfstructure is struct
    }

    deinit {
        self.base = nil
        //self.mfdata.free()
        //self.mfstructure.free()
    }
}


open class MfComplexArray{
    private var _real: MfArray? // Only setter is private
    public var real: MfArray?{
        get {
            return self._real
        }
    }
    
    private var _imag: MfArray?
    public var imag: MfArray?{
        get {
            return self._imag
        }
    }
    private var __basemfarray: MfArray{ // real or imag to access meta data in mfstructure and mfdata
        get {
            if let real = self._real{
                return real
            }
            else if let imag = self._imag{
                return imag
            }
            else{
                fatalError("Bug!!")
            }
        }
    }
    
    internal func set_data(_ real: MfArray?, _ imag: MfArray?){
        precondition(real?.shape == imag?.shape, "real and imag shape are not same.")
        precondition(real?.mftype == imag?.mftype, "real and imag shape are not same type.")
        
        let _ = _check_same_structure(real, imag)
        self._real = real
        self._imag = imag
    }
    
    public internal(set) var base: MfComplexArray?
    public var offsetIndex: Int{
        return self.__basemfarray.offsetIndex
    }
    public var mftype: MfType{
        return self.__basemfarray.mftype
    }
    public var storedType: StoredType{
        return self.__basemfarray.storedType
    }
    public var storedSize: Int{
        return self.__basemfarray.storedSize
    }
    public var storedByteSize: Int{
        return self.__basemfarray.storedByteSize
    }
    
    //mfstructure getter
    public var shape: [Int]{
        return self.__basemfarray.shape
    }
    public var strides: [Int]{
        return self.__basemfarray.strides
    }
    
    public var ndim: Int{
        return self.__basemfarray.ndim
    }
    public var size: Int{
        return self.__basemfarray.size
    }
    public var byteSize: Int{
        return self.__basemfarray.byteSize
    }
    
    public init(real: MfArray?, imag: MfArray?, mftype: MfType? = nil,  mforder: MfOrder = .Row){
        
        let retmftype: MfType
        if let real = real, let imag = imag {
            retmftype = mftype ?? MfType.priority(real.mftype, imag.mftype)
            
        }
        else if let real = real{
            retmftype = mftype ?? real.mftype
        }
        else if let imag = imag {
            retmftype = mftype ?? imag.mftype
        }
        else{
            preconditionFailure("set either real or image!")
        }
        
        // copy
        self.set_data(real?.astype(retmftype, mforder: mforder), imag?.astype(retmftype, mforder: mforder))
        //self._real = real.astype(mftype, mforder: mforder)
        //self._imag = imag.astype(mftype, mforder: mforder)
    }
    
    deinit {
        self.base = nil
        //self.mfdata.free()
        //self.mfstructure.free()
    }
}

fileprivate func _check_same_structure(_ real: MfArray?, _ imag: MfArray?) -> MfArray{
    if let real = real, let imag = imag {
        precondition((real.shape == imag.shape) &&
                     (real.strides == imag.strides) &&
                     (real.mftype == imag.mftype) &&
                     (real.offsetIndex == imag.offsetIndex), "Not same structure")
        return real
    }
    else if let real = real {
        return real
    }
    else if let imag = imag {
        return imag
    }
    else{
        preconditionFailure("set either real or imag!")
    }
}
