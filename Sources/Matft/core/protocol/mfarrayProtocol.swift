//
//  mfarrayProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/10.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation


internal protocol MfStructuredProtocol{
    associatedtype MFDATA: MfDataProtocol
    var mfdata: MFDATA { get set }
    var mfstructure: MfStructure { get set }
    
    /// The offset index
    var offsetIndex: Int { get }
    /// The type
    var mftype: MfType { get }
    /// The stored type
    var storedType: StoredType { get }
    /// The size of the stored data
    var storedSize: Int { get }
    /// The size of the stored data (byte)
    var storedByteSize: Int { get }
    
    /// The shape of ndarray
    var shape: [Int] { get }
    /// The strides of data representing ndarray
    var strides: [Int] { get }
    /// The dimension number
    var ndim: Int { get }
    /// The total element size
    var size: Int { get }
    /// The  total byte size
    var byteSize: Int { get }
}

extension MfStructuredProtocol{
    public var offsetIndex: Int{
        return self.mfdata.offset
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
}

internal protocol MfDataProtocol{
    //var _base: Self? { get set }
    var mftype: MfType { get set }
    var storedType: StoredType { get }
    /// The size of the stored data
    var storedSize: Int { get }
    /// The size of the stored data (byte)
    var storedByteSize: Int { get }
    
    /// Whether to be VIEW or not
    var _isView: Bool { get }
    
    /// The offset value
    var offset: Int { get }
    /// The offset value (byte)
    var byteOffset: Int { get }
}


extension MfDataProtocol{
    internal var storedType: StoredType{
        return MfType.storedType(self.mftype)
    }
    /// The size of the stored data (byte)
    internal var storedByteSize: Int{
        switch self.storedType {
        case .Float:
            return self.storedSize * MemoryLayout<Float>.size
        case .Double:
            return self.storedSize * MemoryLayout<Double>.size
        }
    }
    /// Whether to be VIEW or not
    /*// error is raised!
    internal var _isView: Bool{
        return self._base != nil
    }*/
    /// The offset value (byte)
    internal var byteOffset: Int{
        get{
            switch self.storedType {
            case .Float:
                return self.offset * MemoryLayout<Float>.size
            case .Double:
                return self.offset * MemoryLayout<Double>.size
            }
        }
    }
}
