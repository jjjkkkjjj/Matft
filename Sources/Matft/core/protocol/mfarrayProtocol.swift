//
//  mfarrayProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/10.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation


public protocol MfArrayProtocol{
    associatedtype ArrayType
    
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
