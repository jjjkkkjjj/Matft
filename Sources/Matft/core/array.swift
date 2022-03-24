//
//  array.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/05.
//

import Foundation
import Accelerate

public class MfArray<T: MfTypeUsable>{
    public typealias MfArrayType = T
    public typealias MfArrayStoredType = T.StoredType
    
    public internal(set) var mfdata: MfData<MfArrayType>
    public internal(set) var mfstructure: MfStructure
    
    public internal(set) var base: MfArray?
    
    
    /// Dimension
    public var ndim: Int{
        return self.mfstructure.shape.count
    }
    /// Shape
    public var shape: [Int]{
        return self.mfstructure.shape
    }
    /// Strides
    public var strides: [Int]{
        return self.mfstructure.strides
    }
    /// Size
    public var size: Int{
        return shape2size(&self.mfstructure.shape)
    }
    /// Stored size
    public var storedSize: Int{
        return self.mfdata.storedSize
    }
    /// The offset index for data
    public var offsetIndex: Int{
        return self.mfdata.offset
    }
    /// data
    public var data: [MfArrayType]{
        if let base = self.base{
            return base.data
        }
        else{
            var ret = Array<MfArrayType>(repeating: MfArrayType.zero, count: self.storedSize)
            _ = ret.withUnsafeMutableBufferPointer{
                ArrayConversionToOriginalType(src: self.mfdata.storedPtr.baseAddress!, dst: $0.baseAddress!, size: self.storedSize)
            }
            
            return ret
        }
    }
    
    
    /// Create MfArray from a structured array
    /// - Parameters:
    ///   - array: A structured array
    ///   - shape: A shape array (Optional)
    ///   - mforder: Order (Optional)
    public init(_ array: [Any], shape: [Int]? = nil, mforder: MfOrder = .Row){
        
        // convert a given array into flatten array
        var (flatten, _shape): ([MfArrayType], [Int]) = flatten_array(array: array, mforder: mforder)
        
        var shape = shape ?? _shape
        precondition(shape2size(&shape) == flatten.count, "Invalid shape, size must be \(flatten.count), but got \(shape2size(&shape))")
        
        self.mfdata = MfData(flattenArray: &flatten)
        self.mfstructure = MfStructure(shape: shape, mforder: mforder)
    }
    
    
    /// Create a MfArray with VIEW based on base mfarray
    /// - Parameters:
    ///   - base: The base mfarray
    ///   - mfstructure: New structure
    ///   - offset: The offset value from base's data
    public init (base: MfArray, mfstructure: MfStructure, offset: Int){
        self.base = base
        self.mfdata = MfData(base: base.mfdata, offset: offset)
        self.mfstructure = mfstructure//mfstructure will be copied because mfstructure is struct
    }
    
    
    /// Create a MfArray from mfdata and mfstructure
    /// - Parameters:
    ///   - mfdata: New data
    ///   - mfstructure: New structure
    public init (mfdata: MfData<MfArrayType>, mfstructure: MfStructure){
        self.mfdata = mfdata
        self.mfstructure = mfstructure
    }
    
    deinit {
        self.base = nil
    }
}

