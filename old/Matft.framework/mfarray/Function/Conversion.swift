//
//  Conversion.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/13.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension Matft.mfarray{
    public static func transpose<T>(mfarray: MfArray<T>, axes: [Int]! = nil) -> MfArray<T>{
        /*
        let newMfArrayInfo = _transpose(mfarray: mfarray, axes: axes)
        newMfArrayInfo.newDataPointer()
        return MfArray(info: newMfArrayInfo)*/
        let newMfArrayInfo = self._mfarray_transpose(mfarray: mfarray, axes: axes)
        let newinfo = MfArrayInfo(base: mfarray, shape: newMfArrayInfo.shape, strides: newMfArrayInfo.strides, baseOffset: 0)
        return MfArray(info: newinfo)
    }
    
    private static func _mfarray_transpose<T>(mfarray: MfArray<T>, axes: [Int]! = nil) -> (shape: [Int], strides: [Int]){
        var permutation: [Int] = [], reverse_permutation: [Int] = []
        let dim =  mfarray.shape.count
        
        if axes == nil{
            for i in 0..<dim{
                permutation.append(dim - 1 - i)
            }
        }
        else{
            precondition(axes.count == dim, "axes don't match array")
            for _ in 0..<dim{
                reverse_permutation.append(-1)
            }
            for i in 0..<dim{
                let axis = axes[i]
                precondition(axis >= dim, "invalid axes")
                precondition(reverse_permutation[axis] == -1, "repeated axis in transpose")
                reverse_permutation[axis] = i
                permutation.append(axis)
            }
        }
        
        var newShape: [Int] = [], newStrides: [Int] = []
        
        for i in 0..<dim{
            newShape.append(mfarray.shape[permutation[i]])
            newStrides.append(mfarray.strides[permutation[i]])
        }
        return (newShape, newStrides)
    }
    
    //astype
    public static func astype<T, U: Numeric>(mfarray: MfArray<T>, type: U.Type) -> MfArray<U>{
        if mfarray.type is U.Type{
            return mfarray.deepcopy() as! MfArray<U>
        }
        /*
         let array2 = MfArray(mfarray: [[1,2,3,4,5,6]], type: Int.self)
         
         print(array2)
         let convertedArr = Matft.mfarray.astype(mfarray: array2, type: Double.self)
         print(convertedArr)
         
         /////////
         mfarray =
         [[    1,        2,        3,        4,        5,        6]], type=Int, shape=[1, 6]
         mfarray =
         [[    1.0,        2.0,        3.0,        4.0,        5.0,        6.0]], type=Double, shape=[1, 6]
         ////////
         */
        let newinfo = mfarray.info.astype(type: U.self)
        return MfArray<U>(info: newinfo)
    }
}

/*
public func _transpose<T>(mfarray: MfArray<T>, axes: [Int]! = nil) -> MfArrayInfo<T>{
    var permutation: [Int] = [], reverse_permutation: [Int] = []
    let dim =  mfarray.shape.count
    
    if axes == nil{
        for i in 0..<dim{
            permutation.append(dim - 1 - i)
        }
    }
    else{
        precondition(axes.count == dim, "axes don't match array")
        for _ in 0..<dim{
            reverse_permutation.append(-1)
        }
        for i in 0..<dim{
            let axis = axes[i]
            precondition(axis >= dim, "invalid axes")
            precondition(reverse_permutation[axis] == -1, "repeated axis in transpose")
            reverse_permutation[axis] = i
            permutation.append(axis)
        }
    }
    
    var newShape: [Int] = [], newStrides: [Int] = []
    
    for i in 0..<dim{
        newShape.append(mfarray.shape[permutation[i]])
        newStrides.append(mfarray.strides[permutation[i]])
    }
    return MfArrayInfo(dataPointer: mfarray.data, type: mfarray.type, shape: newShape, strides: newStrides, order: mfarray.order)
}
*/
