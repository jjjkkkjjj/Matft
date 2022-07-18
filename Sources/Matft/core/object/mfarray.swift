//
//  mfarray.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

open class MfArray: MfStructuredProtocol{
    typealias MFDATA = MfData
    public internal(set) var mfdata: MfData // Only setter is private
    public internal(set) var mfstructure: MfStructure

    public internal(set) var base: MfArray?
    
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


open class MfComplexArray: MfStructuredProtocol{
    typealias MFDATA = MfComplexData
    public internal(set) var mfdata: MfComplexData // Only setter is private
    public internal(set) var mfstructure: MfStructure

    public internal(set) var base: MfComplexArray?
    
    public var real: MfArray{
        let mfdata = MfData(dataptr: self.mfdata.data_real, storedSize: self.mfdata.storedSize, mftype: self.mfdata.mftype, offset: self.mfdata.offset)
        return MfArray(mfdata: mfdata, mfstructure: self.mfstructure)
    }
    public var imag: MfArray{
        let mfdata = MfData(dataptr: self.mfdata.data_imag, storedSize: self.mfdata.storedSize, mftype: self.mfdata.mftype, offset: self.mfdata.offset)
        return MfArray(mfdata: mfdata, mfstructure: self.mfstructure)
    }
    
    //mfdata getter
    //return base's data
    public var data: (real: [Any], imag: [Any]){
        if let base = self.base{
            return base.data
        }
        else{
            return self.withUnsafeMutableStartRawPointer{
                [unowned self] rptr, iptr in
                return (data2flattenArray(rptr, mftype: self.mftype, size: self.storedSize), data2flattenArray(iptr, mftype: self.mftype, size: self.storedSize))
            }
        }
    }
    internal var storedData: (real: [Any], imag: [Any]){
        if let base = self.base{
            return base.storedData
        }
        else{
            switch self.storedType {
            case .Float:
                return self.withUnsafeMutableStartPointer(datatype: Float.self){ rptrT, iptrT in
                    return (Array(UnsafeMutableBufferPointer(start: rptrT, count: self.storedSize)) as [Any], Array(UnsafeMutableBufferPointer(start: iptrT, count: self.storedSize)) as [Any])
                }
            case .Double:
                return self.withUnsafeMutableStartPointer(datatype: Double.self){ rptrT, iptrT in
                    return (Array(UnsafeMutableBufferPointer(start: rptrT, count: self.storedSize)) as [Any], Array(UnsafeMutableBufferPointer(start: iptrT, count: self.storedSize)) as [Any])
                }
            }
        }
    }
   
    
    public init(real: MfArray, imag: MfArray, mftype: MfType? = nil,  mforder: MfOrder = .Row){

        let (real, imag) = _check_same_structure(real, imag, mftype: mftype)
        self.mfdata = MFDATA(ref_realdata: real.mfdata, ref_imagdata: imag.mfdata, offset: real.offsetIndex)
        self.mfstructure = MfStructure(shape: real.shape, strides: real.strides)
    }
    public init (mfdata: MfComplexData, mfstructure: MfStructure){
        self.mfdata = mfdata
        self.mfstructure = mfstructure
    }
    
    deinit {
        self.base = nil
        //self.mfdata.free()
        //self.mfstructure.free()
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
