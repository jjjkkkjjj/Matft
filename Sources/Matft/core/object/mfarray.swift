//
//  mfarray.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

public class MfArray<T: MfTypable>{
    public typealias ArrayType = T
    
    public internal(set) var mfdata: MfData<ArrayType> // Only setter is private
    public internal(set) var mfstructure: MfStructure

    public internal(set) var base: MfArray?
    public var offsetIndex: Int{
        return self.mfdata._offset
    }
    

    
    //mfdata getter
    //return base's data
    public var data: [ArrayType]{
        if let base = self.base{
            return base.data
        }
        else{
            return self.withDataUnsafeMRPtr{
                [unowned self] in
                unsafeMRBPtr2array_viaForD($0, size: self.storedSize)
            }
        }
    }
    
    public var storedType: StoredType{
        return self.mfdata._storedType
    }
    public var storedSize: Int{
        return self.mfdata._storedSize
    }
    public var storedByteSize: Int{
        return self.mfdata._storedByteSize
    }
    
    //mfstructure getter
    public var shape: [Int]{
        return self.withShapeUnsafeMBPtr{
            Array($0)
        }
    }
    public var strides: [Int]{
        return self.withStridesUnsafeMBPtr{
            Array($0)
        }
    }
    
    public var ndim: Int{
        return self.mfstructure._ndim
    }
    public var size: Int{
        return self.mfstructure._size
    }
    public var byteSize: Int{
        switch self.storedType {
        case .Float:
            return self.size * MemoryLayout<Float>.size
        case .Double:
            return self.size * MemoryLayout<Double>.size
        }
    }
    public var mfflags: MfFlags{
        return self.mfstructure._flags
    }
    
    
    public init (_ array: [Any], shape: [Int]? = nil, mforder: MfOrder = .Row) {
        
        var _mforder = mforder
        
        var (flatten, _shape): ([ArrayType], [Int]) = array.withUnsafeBufferPointer{
            flatten_array(ptr: $0, mforder: &_mforder)
        }
        
        let ptr = flattenarray2UnsafeMRPtr_viaForD(&flatten)
        
        // set mfdata and mfstructure
        var shape = shape ?? _shape
        precondition(shape2size(&shape) == flatten.count, "Invalid shape, size must be \(flatten.count), but got \(shape2size(&shape))")
        let shapeptr = array2UnsafeMPtrT(&shape)
        self.mfdata = MfData(dataptr: ptr, storedSize: flatten.count)
        self.mfstructure = MfStructure(shapeptr: shapeptr, mforder: _mforder, ndim: shape.count)
    }
    public init (mfdata: MfData<ArrayType>, mfstructure: MfStructure){
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




