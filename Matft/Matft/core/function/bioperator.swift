//
//  bioperator.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray{
    public static func add(_ lmfarray: MfArray, _ rmfarray: MfArray) -> MfArray{
        biop_by_vDSP(l_mfarray: lmfarray, r_mfarray: rmfarray, vDSP_func: vDSP_vadd)
    }
}
