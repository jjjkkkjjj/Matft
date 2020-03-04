//
//  linalg.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension Matft.mfarray.linalg{
    /**
        Solve N simultaneous equation
        - parameters:
            - coef: Coefficients MfArray for N simultaneous equation
            - b: Biases MfArray for N simultaneous equation
        - throws:
        An error of type `MfError.LinAlg.FactorizationError`
     */
    public static func solve(_ coef: MfArray, b: MfArray) throws -> MfArray{
        return MfArray([1])
    }
    
}
