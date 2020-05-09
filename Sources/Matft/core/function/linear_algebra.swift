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
        An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
     
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
        precondition((coef.ndim == 2), "cannot solve non linear simultaneous equations")
        
        let coefShape = coef.shape
        let bShape = b.shape
        
        precondition(b.ndim <= 2, "Invalid b. Dimension must be 1 or 2")
        var dstColNum = 0
        // check argument
        if b.ndim == 1{
            //(m,m)(m)=(m)
            precondition((coefShape[0] == coefShape[1] && bShape[0] == coefShape[0]), "cannot solve (\(coefShape[0]),\(coefShape[1]))(\(bShape[0]))=(\(bShape[0])) problem")
            dstColNum = 1
        }
        else{//ndim == 2
            //(m,m)(m,n)=(m,n)
            precondition((coefShape[0] == coefShape[1] && bShape[0] == coefShape[0]), "cannot solve (\(coefShape[0]),\(coefShape[1]))(\(bShape[0]),\(bShape[1]))=(\(bShape[0]),\(bShape[1])) problem")
            dstColNum = bShape[1]
        }
                
        let returnedType = StoredType.priority(coef.storedType, b.storedType)
        

        switch returnedType{
        case .Float:
            let coefF = coef.astype(.Float) //even if original one is float, create copy
            let bF = b.astype(.Float)
            
            let ret = try solve_by_lapack(coefF, bF, coefShape[0], dstColNum, sgesv_)
            
            return ret
            
        case .Double:
            let coefD = coef.astype(.Double) //even if original one is float, create copy
            let bD = b.astype(.Double) //even if original one is float, create copy
            
            let ret = try solve_by_lapack(coefD, bD, coefShape[0], dstColNum, dgesv_)
            
            return ret
        }
    }
    
    /**
       Get last 2 dim's NxN mfarray's inverse. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    */
    public static func inv(_ mfarray: MfArray) throws -> MfArray{
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        switch mfarray.storedType {
        case .Float:
            return try inv_by_lapack(mfarray, sgetrf_, sgetri_, .Float)
        case .Double:
            return try inv_by_lapack(mfarray, dgetrf_, dgetri_, .Double)
        }

    }
    
    /**
       Get last 2 dim's NxN mfarray's determinant. Returned mfarray's type will be float but be double in case that mftype of mfarray is double.
       - parameters:
           - mfarray: mfarray
       - throws:
       An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
    */
    public static func det(_ mfarray: MfArray) throws -> MfArray{
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get a determinant from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        let retSize = mfarray.size / (shape[mfarray.ndim - 1] * shape[mfarray.ndim - 1])
        switch mfarray.storedType {
        case .Float:
            return try det_by_lapack(mfarray, sgetrf_, .Float, retSize)
            
        case .Double:
            return try det_by_lapack(mfarray, dgetrf_, .Double, retSize)
        }

    }
    
    /**
        Get eigenvelues. Returned mfarray's type will be converted properly.
        - parameters:
            - mfarray: mfarray
        - throws:
        An error of type `MfError.LinAlg.FactorizationError` and `MfError.LinAlgError.singularMatrix`
     */
    /*
    public static func eigen(_ mfarray: MfArray) throws -> MfArray{
        let shape = mfarray.shape
        precondition(mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(shape[mfarray.ndim - 1] == shape[mfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        
        switch mfarray.storedType {
        case .Float:
            let newmfdata = try withDummyDataMRPtr(.Float, storedSize: mfarray.size){
                dstptr in
                let dstptrF = dstptr.bindMemory(to: Float.self, capacity: mfarray.size)
                
                try _withNNStackedColumnMajorPtr(mfarray: mfarray, type: Float.self){
                    srcptr, squaredSize, offset in
                    //LU decomposition
                    var IPIV = try LU_by_lapack(squaredSize, squaredSize, srcdstptr: srcptr, lapack_func: sgetrf_)
                    
                    //calculate inv
                    try inv_by_lapack(squaredSize, srcdstptr: srcptr, &IPIV, lapack_func: sgetri_)
                    
                    //move
                    (dstptrF + offset).moveAssign(from: srcptr, count: squaredSize*squaredSize)
                }
            }
            
            let newmfstructure = withDummyShapeStridesMBPtr(mfarray.ndim){
                [unowned mfarray] (shapeptr, stridesptr) in
                
                //shape
                mfarray.withShapeUnsafeMBPtr{
                    [unowned mfarray] in
                    shapeptr.baseAddress!.assign(from: $0.baseAddress!, count: mfarray.ndim)
                }
                
                //strides
                let newstridesptr = shape2strides(shapeptr, mforder: .Row)
                stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: mfarray.ndim)
                
                newstridesptr.deallocate()
            }
            
            return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
            
        case .Double:
            let newmfdata = try withDummyDataMRPtr(.Double, storedSize: mfarray.size){
                dstptr in
                let dstptrD = dstptr.bindMemory(to: Double.self, capacity: mfarray.size)
                
                try _withNNStackedColumnMajorPtr(mfarray: mfarray, type: Double.self){
                    srcptr, squaredSize, offset in
                    //LU decomposition
                    var IPIV = try LU_by_lapack(squaredSize, squaredSize, srcdstptr: srcptr, lapack_func: dgetrf_)
                    
                    //calculate inv
                    try inv_by_lapack(squaredSize, srcdstptr: srcptr, &IPIV, lapack_func: dgetri_)
                    
                    //move
                    (dstptrD + offset).moveAssign(from: srcptr, count: squaredSize*squaredSize)
                }
            }
            
            let newmfstructure = withDummyShapeStridesMBPtr(mfarray.ndim){
                [unowned mfarray] (shapeptr, stridesptr) in
                
                //shape
                mfarray.withShapeUnsafeMBPtr{
                    [unowned mfarray] in
                    shapeptr.baseAddress!.assign(from: $0.baseAddress!, count: mfarray.ndim)
                }
                
                //strides
                let newstridesptr = shape2strides(shapeptr, mforder: .Row)
                stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: mfarray.ndim)
                
                newstridesptr.deallocate()
            }
            
            return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
        }

    }*/
}

