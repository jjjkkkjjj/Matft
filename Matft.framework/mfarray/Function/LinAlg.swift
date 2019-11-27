//
//  function_mfarray.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/06.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray.linalg{
    //solve
    public static func solve<T, U>(_ a: MfArray<T>, _ b: MfArray<U>) throws -> MfArray<Double>{
        precondition(((a.ndim == b.ndim) && (b.ndim == 2)), "cannot solve non linear simultaneous equations")
        
        //convert float
        let _A = a.astype(Double.self)
        let _B = b.astype(Double.self)

        let A = _A.data
        let B = _B.data

        try self._solve(A, a.shape[0], B, b.shape[1])

        return _B
    }
    private static func _solve(_ a: UnsafeMutablePointer<Double>, _ arowNum: Int, _ b_solved: UnsafeMutablePointer<Double>, _ bcolNum: Int) throws {
        //arow
        var _N = __CLPK_integer(arowNum)
        let N = UnsafeMutablePointer(&_N)
        //bcol
        var _NRHS = __CLPK_integer(bcolNum)
        let NRHS = UnsafeMutablePointer(&_NRHS)
        
        var IPIV = [__CLPK_integer](repeating: 0, count: arowNum)
        
        var INFO: __CLPK_integer = 0

        dgesv_(N, NRHS, a, N, &IPIV, b_solved, NRHS, &INFO)
        if INFO < 0 {
            throw MfError.LinAlgError.FactorizationError
        } else if INFO > 0 {
            throw MfError.LinAlgError.SingularMatrix
        }
    }
    
    //inverse matrix
    public static func inverse<T>(_ a: MfArray<T>) throws -> MfArray<Double>{
        precondition(a.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(a.shape[a.ndim - 1] == a.shape[a.ndim - 2], "Last 2 dimensions of the mfarray must be square")
        /*
         let arr = MfArray(mfarray: [[[[ 0,  1],
         [ 2,  3]],
         
         [[ 4,  5],
         [ 6,  7]],
         
         [[ 8,  9],
         [10, 11]]],
         
         
         [[[12, 13],
         [14, 15]],
         
         [[16, 17],
         [18, 19]],
         
         [[20, 21],
         [22, 23]]]], type: Int.self)
         
         print(Matft.mfarray.linalg.inverse(arr))
         ->mfarray =
         [[[[    -1.5,        0.5],
         [    1.0,        0.0]],
         
         [[    -3.5000000000000053,        2.5000000000000036],
         [    3.0000000000000044,        -2.000000000000003]],
         
         [[    -5.499999999999976,        4.4999999999999805],
         [    4.999999999999978,        -3.9999999999999822]]],
         
         
         [[[    -7.500000000000027,        6.500000000000023],
         [    7.000000000000025,        -6.000000000000021]],
         
         [[    -9.500000000000034,        8.50000000000003],
         [    9.000000000000032,        -8.000000000000028]],
         
         [[    -11.500000000000039,        10.500000000000037],
         [    11.000000000000039,        -10.000000000000036]]]], type=Double, shape=[2, 3, 2, 2]
         */

        let squaredSize = a.shape[a.ndim - 1]
        let matricesNum = a.size / (squaredSize * squaredSize)
        
        let inversedMfArray = a.astype(Double.self)
        var dataPointer = inversedMfArray.data
        
        for _ in 0..<matricesNum{
            let eye = Matft.mfarray.eye(squaredSize, type: Double.self)
            try self._solve(dataPointer, squaredSize, eye.data, squaredSize)
            
            memcpy(dataPointer, eye.data, MemoryLayout<Double>.size * squaredSize * squaredSize)

            dataPointer += squaredSize * squaredSize
        }
        return inversedMfArray
    }
    
}

