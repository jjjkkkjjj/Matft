//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/12/15.
//

import Foundation

internal protocol MfInterpProtocol{
    associatedtype ParamsType: MfInterpParamsProtocol
    
    var orig_x: MfArray { get }
    var orig_y: MfArray { get }
    var axis: Int { get }
    var assume_sorted: Bool { get }
    var params: ParamsType? { get set }
    
    mutating func fit() -> Self
    func interpolate(_ x: MfArray) -> MfArray
}

extension MfInterpProtocol{
    var orig_num: Int {
        return self.orig_x.size
    }
}

internal protocol MfInterpParamsProtocol{
    
}
