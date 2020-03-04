//
//  linalg.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray.linalg{
    /**
        Solve N simultaneous equation. Get x in coef*x = b. Returned mfarray's type will be float but be double in case that  mftype of either coef or b is double.
        - parameters:
            - coef: Coefficients MfArray for N simultaneous equation
            - b: Biases MfArray for N simultaneous equation
        - throws:
        An error of type `MfError.LinAlg.FactorizationError`
     
            /*
            //must be flatten....?
            let a = MfArray([[4, 2],
                            [4, 5]])
            let b = MfArray([[2, -7]])
            let x = try! Matft.mfarray.linalg.solve(a, b: b)
            print(x)
            */
     */
    public static func solve(_ coef: MfArray, b: MfArray) throws -> MfArray{
        precondition(((coef.ndim == b.ndim) && (b.ndim == 2)), "cannot solve non linear simultaneous equations")
        let returnedType = StoredType.priority(coef.storedType, b.storedType)
        
        switch returnedType{
        case .Float:
            let _coef = coef.astype(.Float) //even if original one is float, create copy
            let ret = b.astype(.Float) //even if original one is float, create copy
            
            try solve_by_lapack(copiedCoefPtr: _coef.dataptr.bindMemory(to: Float.self).baseAddress!, _coef.shapeptr[0], ret.dataptr.bindMemory(to: Float.self).baseAddress!, ret.shapeptr[1], sgesv_)
            
            return ret
            
        case .Double:
            let _coef = coef.astype(.Double) //even if original one is float, create copy
            let ret = b.astype(.Double) //even if original one is float, create copy
            
            try solve_by_lapack(copiedCoefPtr: _coef.dataptr.bindMemory(to: Double.self).baseAddress!, _coef.shapeptr[0], ret.dataptr.bindMemory(to: Double.self).baseAddress!, ret.shapeptr[1], dgesv_)
            
            return ret
        }
    }
}

