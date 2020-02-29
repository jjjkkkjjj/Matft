//
//  conversion_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    public func astype(_ mftype: MfType) -> MfArray{
        return Matft.mfarray.astype(self, mftype: mftype)
    }
    
    public func transpose(axes: [Int]? = nil) -> MfArray{
        return Matft.mfarray.transpose(self, axes: axes)
    }
    public var T: MfArray{
        return Matft.mfarray.transpose(self)
    }
    
    public func broadcast_to(shape: [Int]) throws -> MfArray{
        return try Matft.mfarray.broadcast_to(self, shape: shape)
    }
}

extension MfData{
    public func astype(_ mftype: MfType) -> MfData{
        return Matft.mfarray.mfdata.astype(self, mftype: mftype)
    }
}
