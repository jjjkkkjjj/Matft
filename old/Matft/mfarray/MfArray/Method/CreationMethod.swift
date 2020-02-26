//
//  CreationMethod.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/13.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    //copyr
    public func view(mfarray: MfArray, shape: [Int]) -> MfArray{
        let newinfo = MfArrayInfo(base: mfarray, shape: mfarray.shape, strides: mfarray.strides, baseOffset: 0)
        return MfArray(info: newinfo)
    }
    
    //copy all data
    public func deepcopy() -> MfArray{
        let newInfo = self.info.deepcopy()
        return MfArray(info: newInfo)
    }
    
}
