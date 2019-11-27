//
//  Enum.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/18.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public struct MfArrayType {
    var type: MfType
    var order: MfOrder
    var C_CONTIGUOUS = true
    var F_CONTIGUOUS = false
    
    init(type: MfType, order: MfOrder, shape: [Int], strides: [Int]) {
        self.type = type
        self.order = order
        
        self.updateContiguous(shape: shape, strides: strides)
    }
    
    public mutating func updateContiguous(shape: [Int], strides: [Int]){
        (self.C_CONTIGUOUS, self.F_CONTIGUOUS) = _check_contiguous(shape: shape, strides: strides)
    }
    
    public enum MfType: String {
        case copy
        case view
    }
    public enum MfOrder: String{
        case C
        case F
    }
}
