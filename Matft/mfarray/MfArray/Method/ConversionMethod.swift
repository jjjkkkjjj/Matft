//
//  ConversionMethod.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/13.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    public var T: MfArray<T>{
        return Matft.mfarray.transpose(mfarray: self, axes: nil)
    }
    
    public func astype<U: MfNumeric>(_ type: U.Type) -> MfArray<U>{
        let newinfo = self.info.astype(type: U.self)
        return MfArray<U>(info: newinfo)
    }
}
