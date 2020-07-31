//
//  reduce_mfarray.swift
//  
//
//  Created by Junnosuke Kado on 2020/08/01.
//

import Foundation

extension MfArray{
    public func ufuncreduce(_ ufunc: biopufuncNoargs, axis: Int = 0, keepDims: Bool = false, initial: MfArray? = nil) -> MfArray{
        return Matft.ufuncreduce(mfarray: self, ufunc: ufunc, axis: axis, keepDims: keepDims, initial: initial)
    }
}
