//
//  mfarray.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

public class MfArray{
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
                unsafeMRBPtr2array_viaForD($0, mftype: self.mftype, size: self.storedSize)
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
        switch self.storedType {
        case .Float:
            return self.size * MemoryLayout<Float>.size
        case .Double:
            return self.size * MemoryLayout<Double>.size
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




