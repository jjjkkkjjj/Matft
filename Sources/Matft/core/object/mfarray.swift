//
//  mfarray.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate
import CoreML

open class MfArray: MfArrayProtocol{
    public typealias MFDATA = MfData
    public internal(set) var mfdata: MfData // Only setter is private
    public internal(set) var mfstructure: MfStructure

    public internal(set) var base: MfArray?
    
    
    /// Create a mfarray from Swift Array
    /// - Parameters:
    ///    - array: A Swift Array
    ///    - mftype: The Type
    ///    - shape: The shape
    ///    - mforder: The order
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
    
    /// Create complex mfarray from MfArray. Either real or imag must be given.
    /// - Parameters:
    ///    - real: A real MfArray
    ///    - imag: A imag MfArray
    ///    - mftype: The Type
    ///    - mforder: The order
    public init(real: MfArray?, imag: MfArray?, mftype: MfType? = nil,  mforder: MfOrder = .Row){
        let realmfdata: MFDATA
        let imagmfdata: MFDATA
        let shape: [Int]
        let strides: [Int]
        if let real = real, let imag = imag{// complex
            precondition(real.isReal, "Argument: real must be real")
            precondition(imag.isReal, "Argument: imag must be real")
            
            let (real, imag) = _check_same_structure(real, imag, mftype: mftype)
            realmfdata = real.mfdata
            imagmfdata = imag.mfdata
            shape = real.shape
            strides = real.strides
        }
        else if let real = real {
            precondition(real.isReal, "Argument: real must be real")
            
            realmfdata = real.mfdata
            imagmfdata = MFDATA(size: real.storedSize, mftype: real.mftype)
            shape = real.shape
            strides = real.strides
        }
        else if let imag = imag {
            precondition(imag.isReal, "Argument: imag must be real")
            
            imagmfdata = imag.mfdata
            realmfdata = MFDATA(size: imag.storedSize, mftype: imag.mftype)
            shape = imag.shape
            strides = imag.strides
        }
        else{
            preconditionFailure("Either real or imag must be given.")
        }
        
        self.mfdata = MFDATA(ref_realdata: realmfdata, ref_imagdata: imagmfdata, offset: realmfdata.offset)
        self.mfstructure = MfStructure(shape: shape, strides: strides)
    }
    
    /// Create mfarray from MfData and MfStructure
    /// - Parameters:
    ///    - mfdata: MfData
    ///    - mfstructure: MfStructure
    public init (mfdata: MfData, mfstructure: MfStructure){
        self.mfdata = mfdata
        self.mfstructure = mfstructure
    }
    
    /// Create a VIEW mfarray from MfArray
    /// - Parameters:
    ///    - base: A base MfArray
    ///    - mfstructure: MfStructure
    ///    - offset: The offset index
    public init (base: MfArray, mfstructure: MfStructure, offset: Int){
        self.base = base
        self.mfdata = MfData(refdata: base.mfdata, offset: offset)
        self.mfstructure = mfstructure//mfstructure will be copied because mfstructure is struct
    }
    
    /// Create a VIEW or Copy mfarray from MLShapedArray
    /// - Parameters:
    ///    - base: A base MLShapedArray
    @available(macOS 12.0, *)
    public init<T: MLShapedArrayScalar & MfStorable> (base: inout MLShapedArray<T>){

        let ptr = base.withUnsafeMutableShapedBufferPointer{ptr,shape,strides in
            return ptr
        }
        
        let mfdata = MfData(source: base, data_real_ptr: ptr.baseAddress!, storedSize: base.scalarCount, mftype: MfType.mftype(value: T.self), offset: base.startIndex)
        self.mfdata = mfdata
        self.mfstructure = MfStructure(shape: base.shape, strides: base.strides)
    }

    deinit {
        self.base = nil
        //self.mfdata.free()
        //self.mfstructure.free()
    }
}


extension MfArray{
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
    /// Alias for data
    public var data_real: [Any]{
        return self.data
    }
    /// imag data
    public var data_imag: [Any]?{
        if self.mfdata._isReal{
            return nil
        }
        
        if let base = self.base{
            return base.data
        }
        else{
            return self.withUnsafeMutableStartRawImagPointer{
                [unowned self] in
                data2flattenArray($0!, mftype: self.mftype, size: self.storedSize)
            }
        }
    }
    
    public var storedData: [Any]{
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
    
    public var real: MfArray{
        if self.mfdata._isReal{
            return self
        }
        else{
            let mfdata = MfData(source: self.mfdata, data_real_ptr: self.mfdata.data_real, storedSize: self.mfdata.storedSize, mftype: self.mfdata.mftype, offset: self.mfdata.offset)
            return MfArray(mfdata: mfdata, mfstructure: self.mfstructure)
        }
    }
    public var imag: MfArray?{
        if self.mfdata._isReal{
            return nil
        }
        else{
            let mfdata = MfData(source: self.mfdata, data_real_ptr: self.mfdata.data_imag!, storedSize: self.mfdata.storedSize, mftype: self.mfdata.mftype, offset: self.mfdata.offset)
            return MfArray(mfdata: mfdata, mfstructure: self.mfstructure)
        }
    }
    
    public var isReal: Bool{
        return self.mfdata._isReal
    }
    public var isComplex: Bool{
        return !self.mfdata._isReal
    }
}


fileprivate func _check_same_structure(_ real: MfArray, _ imag: MfArray, mftype: MfType?) -> (real: MfArray, imag: MfArray){
    
    var r: MfArray = real
    var i: MfArray = imag
    // check same shape
    if real.shape != imag.shape{
        let ret = biop_broadcast_to(real, imag)
        r = ret.l
        i = ret.r
    }
    
    let rettype = mftype ?? MfType.priority(r.mftype, i.mftype)
    
    // check same strides and type
    if (r.strides != i.strides) ||
        (rettype != r.mftype) || (rettype != i.mftype) ||
        (r.offsetIndex != i.offsetIndex){
        // TODO: This code is redundant
        r = r.astype(rettype, mforder: .Row)
        i = i.astype(rettype, mforder: .Row)
    }
    
    assert((real.shape == imag.shape) &&
         (real.strides == imag.strides) &&
         (real.mftype == imag.mftype) &&
         (real.offsetIndex == imag.offsetIndex), "Not same structure")
    
    return (r, i)
}
