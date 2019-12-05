//
//  conversionType_mfarray.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/12.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension MfArrayInfo{
    /*
    internal func astype<U>(type: U.Type) -> MfArrayInfo<U> {
        // BinaryInterger from below
        if let int = U.self as? Int32.Type{
            return self.astype_to_Interger(type: int) as! MfArrayInfo<U>
        }
        /*
        else if let uint = U.self as? UInt.Type{
            return self.astype_to_Interger(type: uint) as! MfArrayInfo<U>
        }*/
        // FloatingPoint from below
        else if let float = U.self as? Float.Type{
            return self.astype_to_FloatingPoint(type: float) as! MfArrayInfo<U>
        }
        else if let double = U.self as? Double.Type{
            return self.astype_to_FloatingPoint(type: double) as! MfArrayInfo<U>
        }
            //cannot be converted
        else{
            fatalError("mfarray.astype(\(String(describing: U.self))) is not supported")
        }
    }
    
    private func astype_to_Interger<U: BinaryInteger>(type: U.Type) -> MfArrayInfo<U>{
        typealias TPointer = UnsafeMutableBufferPointer<U>
        let newdataPointer = TPointer.allocate(capacity: self.size)
        
        // convert int32 to U
        if let data = self.bufdata as? UnsafeMutableBufferPointer<Int32>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }
        /*
        // convert uint to U
        else if let data = self.bufdata as? UnsafeMutableBufferPointer<Float>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }*/
        // convert float to U
        else if let data = self.bufdata as? UnsafeMutableBufferPointer<Float>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }
            // convert double to U
        else if let data = self.bufdata as? UnsafeMutableBufferPointer<Double>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }
            // cannot be converted
        else{
            fatalError("mfarray.astype() whose type is (\(String(describing: T.self))) is not supported")
        }
        
        return MfArrayInfo<U>(dataPointer: newdataPointer, type: U.self, shape: self.shape, strides: self.strides, order: self.flags.order)
    }
    private func astype_to_FloatingPoint<U: BinaryFloatingPoint>(type: U.Type) -> MfArrayInfo<U>{
        typealias TPointer = UnsafeMutableBufferPointer<U>
        let newdataPointer = TPointer.allocate(capacity: self.size)
        
        // convert int32 to U
        if let data = self.bufdata as? UnsafeMutableBufferPointer<Int32>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }
            /*
            // convert uint to U
        else if let data = self.bufdata as? UnsafeMutableBufferPointer<Float>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }*/
            // convert float to U
        else if let data = self.bufdata as? UnsafeMutableBufferPointer<Float>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }
            // convert double to U
        else if let data = self.bufdata as? UnsafeMutableBufferPointer<Double>{
            let _ = newdataPointer.initialize(from: data.map{ U.init(exactly: $0)! })
        }
            // cannot convert
        else{
            fatalError("mfarray.astype() whose type is (\(String(describing: T.self))) is not supported")
        }
        
        return MfArrayInfo<U>(dataPointer: newdataPointer, type: U.self, shape: self.shape, strides: self.strides, order: self.flags.order)
    }*/
}
