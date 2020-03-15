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
            ==> mfarray =
                [[    2.0,        -3.0]], type=Float, shape=[1, 2]
     
            
            //numpy
            >>> a = np.array([[4,2],[4,5]])
            >>> b = np.array([2,-7])
            >>> np.linalg.solve(a,b)
            array([ 2., -3.])
            >>> np.linalg.solve(a,b.T)
            array([ 2., -3.])
            >>> b = np.array([[2,-7]])
            >>> np.linalg.solve(a,b.T)
            array([[ 2.],
                   [-3.]])

                
            */
     */
    public static func solve(_ coef: MfArray, b: MfArray) throws -> MfArray{
        precondition(((coef.ndim == b.ndim) && (b.ndim == 2)), "cannot solve non linear simultaneous equations")
        let returnedType = StoredType.priority(coef.storedType, b.storedType)
        
        //get column flatten
        let coefflatten = coef.flatten(.Column)
        switch returnedType{
        case .Float:
            let _coefflatten = coefflatten.astype(.Float) //even if original one is float, create copy
            let ret = b.astype(.Float) //even if original one is float, create copy
            
            try _coefflatten.withDataUnsafeMBPtrT(datatype: Float.self){
                _coefflattenptr in
                try ret.withDataUnsafeMBPtrT(datatype: Float.self){
                    try solve_by_lapack(copiedCoefPtr: _coefflattenptr.baseAddress!, coef.shape[0], $0.baseAddress!, ret.shape[1], sgesv_)
                }
            }
            
            
            return ret
            
        case .Double:
            let _coefflatten = coefflatten.astype(.Double) //even if original one is float, create copy
            let ret = b.astype(.Double) //even if original one is float, create copy
            
            try _coefflatten.withDataUnsafeMBPtrT(datatype: Double.self){
                _coefflattenptr in
                try ret.withDataUnsafeMBPtrT(datatype: Double.self){
                    try solve_by_lapack(copiedCoefPtr: _coefflattenptr.baseAddress!, coef.shape[0], $0.baseAddress!, ret.shape[1], dgesv_)
                }
            }
            
            return ret
        }
    }
    /*
    public static func inv(_ mfarray: MfArray) throws -> MfArray{
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(mfarray.shapeptr[mfarray.ndim - 1] == mfarray.shapeptr[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        let squaredSize = mfarray.shapeptr[mfarray.ndim - 1]
        let matricesNum = mfarray.size / (squaredSize * squaredSize)
        
        let inversedMfArray = mfarray.deepcopy()
        var dataPointer = inversedMfArray.data
        for _ in 0..<matricesNum{
            let eye = Matft.mfarray.eye(dim: squaredSize)
            try Matft.mfarray.linalg.solve(<#T##coef: MfArray##MfArray#>, b: <#T##MfArray#>)

            dataPointer += squaredSize * squaredSize
        }
    }*/
}

