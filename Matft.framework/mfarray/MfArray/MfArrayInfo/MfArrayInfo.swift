//
//  MfArrayInfo.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/11.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public class MfArrayInfo<T: MfNumeric>{
    internal var _bufdata: UnsafeMutableBufferPointer<Double>
    public var bufdata: UnsafeMutableBufferPointer<Double>{
        get{
            if self.flags.type == MfArrayType.MfType.copy{
                return self._bufdata
            }
            else{//view
                return self.base.info.bufdata
            }
        }
    }
    var shape: [Int]
    var strides: [Int]
    var size: Int
    var baseOffset = 0
    var flags: MfArrayType
    var base: MfArray<T>!
    
    /*
     Below init method is for copy
     */
    init(data: [Double], type: T.Type, shape: [Int], order: MfArrayType.MfOrder) {
        typealias TPointer = UnsafeMutableBufferPointer<Double>
        let dataPointer = TPointer.allocate(capacity: data.count)
        let _ = dataPointer.initialize(from: data)
        
        self._bufdata = dataPointer
        
        self.shape = shape
        self.strides = _shape2strides(shape, data.count)
        self.size = _shape2size(shape)
        
        self.flags = MfArrayType(type: MfArrayType.MfType.copy, order: order, shape: self.shape, strides: self.strides)
    }
    
    init(dataPointer: UnsafeMutableBufferPointer<Double>, type: T.Type, shape: [Int], strides: [Int]! = nil, order: MfArrayType.MfOrder) {
        self._bufdata = dataPointer
        
        self.shape = shape
        self.size = _shape2size(shape)
        if strides == nil{
            self.strides = _shape2strides(shape, self.size)
        }
        else{
            self.strides = strides
        }
        self.flags = MfArrayType(type: MfArrayType.MfType.copy, order: order, shape: self.shape, strides: self.strides)
    }
    
    /*
     Below init method is for view which means reference type
     */
    init(base: MfArray<T>, shape: [Int], strides: [Int]! = nil, baseOffset: Int){
        typealias TPointer = UnsafeMutableBufferPointer<Double>
        let dataPointer = TPointer.allocate(capacity: 1)
        self._bufdata = dataPointer
        
        self.shape = shape
        self.size = _shape2size(shape)
        if strides == nil{
            self.strides = _shape2strides(shape, self.size)
        }
        else{
            self.strides = strides
        }
        self.baseOffset = baseOffset
        
        self.base = base
        self.flags = MfArrayType(type: MfArrayType.MfType.view, order: base.order, shape: self.shape, strides: self.strides)
    }
    
    
    internal func free() {
        self._bufdata.deallocate()
    }
    
}


