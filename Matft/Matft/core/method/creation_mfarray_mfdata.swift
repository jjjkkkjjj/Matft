//
//  creation_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    public func deepcopy() -> MfArray{
        return Matft.mfarray.deepcopy(self)
    }
    public func shallowcopy() -> MfArray{
        return Matft.mfarray.shallowcopy(self)
    }
}
 
extension MfData{
    public func deepcopy() -> MfData{
        return Matft.mfarray.mfdata.deepcopy(self)
    }
    public func shallowcopy() -> MfData{
        return Matft.mfarray.mfdata.shallowcopy(self)
    }
}
