//
//  InfoConversion.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/19.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension MfArrayInfo{
    internal func astype<U>(type: U.Type) -> MfArrayInfo<U> {
        let info = MfArrayInfo<U>(dataPointer: self.bufdata, type: U.self, shape: self.shape, strides: self.strides, order: self.flags.order)
        return info.deepcopy()
    }
}
