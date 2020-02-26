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
}
 
