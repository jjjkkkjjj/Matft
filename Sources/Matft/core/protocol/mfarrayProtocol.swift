//
//  mfarrayProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/10.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// A type that holds its elements in an `MfData`.
public protocol HasMfDataProtocol{
    /// The underlying data storage.
    var mfdata: MfData { get }

    /// The element offset of the first element within the underlying buffer.
    var offsetIndex: Int { get }
    /// The element type (the counterpart of Numpy's `dtype`).
    var mftype: MfType { get }
    /// The type used to store the elements in memory (`Float` or `Double`).
    var storedType: StoredType { get }
    /// The number of elements in the underlying buffer, which may differ from `size` for views.
    var storedSize: Int { get }
    /// The size of the underlying buffer in bytes.
    var storedByteSize: Int { get }
    /// Whether the array shares memory with another object (a view of another array or of an external buffer).
    var isView: Bool { get }
}

extension HasMfDataProtocol{
    /// The element offset of the first element within the underlying buffer.
    public var offsetIndex: Int{
        return self.mfdata.offset
    }
    /// The element type (the counterpart of Numpy's `dtype`).
    public var mftype: MfType{
        return self.mfdata.mftype
    }
    /// The type used to store the elements in memory (`Float` or `Double`).
    public var storedType: StoredType{
        return self.mfdata.storedType
    }
    /// The number of elements in the underlying buffer, which may differ from `size` for views.
    public var storedSize: Int{
        return self.mfdata.storedSize
    }
    /// The size of the underlying buffer in bytes.
    public var storedByteSize: Int{
        return self.mfdata.storedByteSize
    }
    /// Whether the array shares memory with another object (a view of another array or of an external buffer).
    public var isView: Bool{
        return self.mfdata._isView
    }
}

/// A type that has a shape and strides described by an `MfStructure`.
public protocol HasMfStructurProtocol{
    /// The structure (shape and strides).
    var mfstructure: MfStructure { get }

    /// The length of each axis. Equivalent to `numpy.ndarray.shape`.
    var shape: [Int] { get }
    /// The step, in elements (not bytes), to move along each axis in the underlying buffer.
    var strides: [Int] { get }
    /// The number of dimensions. Equivalent to `numpy.ndarray.ndim`.
    var ndim: Int { get }
    /// The total number of elements. Equivalent to `numpy.ndarray.size`.
    var size: Int { get }
    /// The total size of the elements in bytes, computed with the stored type (`size * sizeof(storedType)`).
    var byteSize: Int { get }
}

extension HasMfStructurProtocol{

    /// The length of each axis. Equivalent to `numpy.ndarray.shape`.
    public var shape: [Int]{
        return self.mfstructure.shape
    }
    /// The step, in elements (not bytes), to move along each axis in the underlying buffer.
    public var strides: [Int]{
        return self.mfstructure.strides
    }

    /// The number of dimensions. Equivalent to `numpy.ndarray.ndim`.
    public var ndim: Int{
        return self.mfstructure.shape.count
    }
    /// The total number of elements. Equivalent to `numpy.ndarray.size`.
    public var size: Int{
        return shape2size(&self.mfstructure.shape)
    }
}

/// A type that has both data storage and a structure, i.e. an n-dimensional array.
public protocol MfArrayProtocol: HasMfDataProtocol, HasMfStructurProtocol{}
extension MfArrayProtocol{
    /// The total size of the elements in bytes, computed with the stored type (`size * sizeof(storedType)`).
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
