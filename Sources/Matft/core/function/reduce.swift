//
//  reduce.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/19.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

public typealias biopufuncNoargs = (MfArray, MfArray) -> MfArray

extension Matft{
    /**
        Return reduced MfArray applied passed ufunc
        - Parameters:
            - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
            - initial: Initial MfArray
     */
    public static func ufuncreduce(mfarray: MfArray, ufunc: biopufuncNoargs, axis: Int = 0, keepDims: Bool = false, initial: MfArray? = nil) -> MfArray {
        let axis = get_axis(axis, ndim: mfarray.ndim)
        /*
         e.g.) ndim=6, axis=2
         shape = (a,b,c,d,e,f)
         //conversion
         axes = (4,5,0,1,2,3)    //saxes = (4,5):snum=2 laxes = (0,1,2,3):lnum=4
         shape = (c,d,e,f,a,b)
               = (-,d,e,f,a,b)
         //re-conversion
         axes = (2,3,4,0,1)      //saxes = (2,3,4) laxes = (0,1)
         shape = (a,b,d,e,f)
         */
        var saxes = Array(axis..<mfarray.ndim)
        var laxes = Array(0..<axis)
        
        let movedMfArray = mfarray.transpose(axes: saxes + laxes).conv_order(mforder: .Row)// to Row order
        
        let first: MfArray
        if let initial = initial{
            first = ufunc(initial, movedMfArray.first!)
        }
        else{
            first = movedMfArray.first!
        }
        
        let reducedArray = movedMfArray.dropFirst().reduce(first){ ufunc($0, $1) }
        
        saxes = Array(axis..<reducedArray.ndim)
        laxes = Array(0..<axis)
        let ret = reducedArray.transpose(axes: saxes + laxes)
        return keepDims ? Matft.expand_dims(ret, axis: axis) : ret
    }
}

extension Array where Element == MfArray{
    /**
        Return reduced MfArray applied passed ufunc
        - Parameters:
            - ufunc: Binary operation function with two arguments like (l_mfarray: MfArray, r_mfarray: MfArray)
            - initial: Initial MfArray
     */
    public func ufuncreduce(_ ufunc: biopufuncNoargs, initial: MfArray? = nil) -> MfArray {
        precondition(self.count > 0, "must be more than one element")
        let first: MfArray
        if let initial = initial{
            first = ufunc(initial, self.first!)
        }
        else{
            first = self.first!
        }
        
        return self.dropFirst().reduce(first){ ufunc($0, $1) }
    }
}

