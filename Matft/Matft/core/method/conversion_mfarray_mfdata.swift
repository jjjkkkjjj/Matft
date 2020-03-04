//
//  conversion_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    /**
       Create another typed mfarray. Created mfarray will be different object from original one
       - parameters:
            - mftype: the type of mfarray
    */
    public func astype(_ mftype: MfType) -> MfArray{
        return Matft.mfarray.astype(self, mftype: mftype)
    }
    /**
       Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
            - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    */
    public func transpose(axes: [Int]? = nil) -> MfArray{
        return Matft.mfarray.transpose(self, axes: axes)
    }
    /**
       Create transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
    */
    public var T: MfArray{
        return Matft.mfarray.transpose(self)
    }
    /**
       Create broadcasted mfarray.
       - parameters:
            - shape: shape
       - throws:
        An error of type `MfError.conversionError`
    */
    public func broadcast_to(shape: [Int]) throws -> MfArray{
        return try Matft.mfarray.broadcast_to(self, shape: shape)
    }
}

extension MfData{
    /**
       Create another typed mfdata. Created mfdata will be different object from original one
       - parameters:
            - mftype: the type of mfarray
    */
    public func astype(_ mftype: MfType) -> MfData{
        return Matft.mfarray.mfdata.astype(self, mftype: mftype)
    }
}
