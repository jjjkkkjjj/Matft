//
//  reduce_mfarray.swift
//
//
//  Created by Junnosuke Kado on 2020/08/01.
//

import Foundation

extension MfArray{
    /**
       Reduce the array by repeatedly applying a binary function.

       Method version of `Matft.ufuncReduce(mfarray:ufunc:axis:keepDims:initial:)`.
       Equivalent to `numpy.ufunc.reduce` (e.g. `ufuncReduce(Matft.add)` is like `np.add.reduce`).
       - Parameters:
           - ufunc: A binary function `(MfArray, MfArray) -> MfArray`, such as `Matft.add`.
           - axis: (Optional) The axis to reduce, by default 0. If `nil`, all axes are reduced.
           - keepDims: (Optional) Whether to keep the reduced axes as dimensions of length 1, by default `false`.
           - initial: (Optional) The value combined with the first element, as `ufunc(initial, first)`. Note that it is ignored when `axis` is `nil`.
       - Returns: The reduced array.
    */
    public func ufuncReduce(_ ufunc: biopufuncNoargs, axis: Int? = 0, keepDims: Bool = false, initial: MfArray? = nil) -> MfArray{
        return Matft.ufuncReduce(mfarray: self, ufunc: ufunc, axis: axis, keepDims: keepDims, initial: initial)
    }

    /**
        Accumulate the result of applying a binary function along the given axis.

        Method version of `Matft.ufuncAccumulate(mfarray:ufunc:axis:)`.
        Equivalent to `numpy.ufunc.accumulate` (e.g. `ufuncAccumulate(Matft.add)` is like `np.add.accumulate`).
        - Parameters:
            - ufunc: A binary function `(MfArray, MfArray) -> MfArray`, such as `Matft.add`.
            - axis: (Optional) The axis along which to accumulate, by default 0.
        - Returns: The accumulated array, which has the same shape as the input.
     */
    public func ufuncAccumulate(_ ufunc: biopufuncNoargs, axis: Int = 0) -> MfArray {
        return Matft.ufuncAccumulate(mfarray: self, ufunc: ufunc, axis: axis)
    }
}
