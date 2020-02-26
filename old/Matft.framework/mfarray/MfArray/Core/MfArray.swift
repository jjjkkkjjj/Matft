//
//  MfArray.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/06.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public class MfArray<T: MfNumeric>{
    //property
    public internal(set) var info: MfArrayInfo<T>
    public var data: UnsafeMutablePointer<Double>{
        return self.info.bufdata.baseAddress! + self.baseOffset
    }
    public var strides: [Int]{
        return self.info.strides
    }
    public var shape: [Int]{
        return self.info.shape
    }
    public var size: Int{
        return self.info.size
    }
    public var order: MfArrayType.MfOrder{
        return self.info.flags.order
    }
    public var ndim: Int{
        return self.shape.count
    }
    public var type: T.Type{
        return T.self
    }
    public var flags: MfArrayType{
        return self.info.flags
    }
    public var baseOffset: Int{
        return self.info.baseOffset
    }
    public var base: MfArray!{
        return self.info.base
    }
    
    //initialization
    init(mfarray: [Any], type: T.Type, order: String = "C") {
        switch order {
        case "C":
            self.info = anyArray2data_C(array: mfarray, type: type)

        case "F":
            fatalError("mfarray hasn't supported column mejor, i will support one in the future maybe...")
        default:
            fatalError("Undefined order name (\(order)) was found.")
        }
    }
    init(data: UnsafeMutableBufferPointer<Double>, type: T.Type, shape: [Int], order: String = "C") {
        switch order {
        case "C":
            self.info = MfArrayInfo(dataPointer: data, type: type, shape: shape, order: MfArrayType.MfOrder.C)
            
        case "F":
            fatalError("mfarray hasn't supported column mejor, i will support one in the future maybe...")
        default:
            fatalError("Undefined order name (\(order)) was found.")
        }
    }
    init(info: MfArrayInfo<T>) {
        self.info = info
    }
    
    
    //deinitialization
    deinit {
        self.info.free()
    }
    
    
}

