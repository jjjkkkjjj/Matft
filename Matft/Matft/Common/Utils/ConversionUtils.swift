//
//  Conversion.swift
//  Matft
//
//  Created by Junnosuke Kado on 2019/12/09.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

internal func _check_broadcastable_and_get_broadcastedMfArray<T>(_ a: MfArray<T>, _ b: MfArray<T>) -> (a_: MfArray<T>, b_: MfArray<T>){
    var mindim_array = a
    var grdim_array = b
    var mina = true //means a has smaller dimension than b
    if a.ndim > b.ndim{
        mindim_array = b
        grdim_array = a
        mina = false
    }
    
    var mindim_newShape: [Int] = Array<Int>(repeating: 0, count: grdim_array.ndim)
    var grdim_newShape: [Int] = Array<Int>(repeating: 0, count: grdim_array.ndim)
    
    for i in 0..<mindim_array.ndim{
        //get dim of shape from back
        let mindim_shape = mindim_array.shape[mindim_array.ndim - 1 - i]
        let grdim_shape = grdim_array.shape[grdim_array.ndim - 1 - i]
        
        let index = grdim_array.ndim - 1 - i
        if mindim_shape == grdim_shape{//when the shapes' size are same, continue
            mindim_newShape[index] = mindim_shape
            grdim_newShape[index] = mindim_shape
            continue
        }
        else{
            if mindim_shape == 1{
                mindim_newShape[index] = grdim_shape
                grdim_newShape[index] = grdim_shape
            }else if grdim_shape == 1{
                mindim_newShape[index] = mindim_shape
                grdim_newShape[index] = mindim_shape
            }
            else{//cannot broadcast
                fatalError("operands could not be broadcast together with shapes \(a.shape) \(b.shape)")
            }
        }
    }
    
    for i in mindim_array.ndim..<grdim_array.ndim{
        let index = grdim_array.ndim - 1 - i
        mindim_newShape[index] = grdim_array.shape[index]
        grdim_newShape[index] = grdim_array.shape[index]
    }
    
    mindim_array = mindim_array.broadcast_to(shape: mindim_newShape)
    grdim_array = grdim_array.broadcast_to(shape: grdim_newShape)
    if mina{
        return (mindim_array, grdim_array)
    }
    else{
        return (grdim_array, mindim_array)
    }
}

internal func _get_storedSize<T>(mfarray: MfArray<T>) -> Int{
    // check stordsize
    var _base = mfarray.base
    var _storedSize = mfarray.size
    while _base != nil {
        _storedSize = _base!.size
        _base = _base!.base
    }
    return _storedSize
}
