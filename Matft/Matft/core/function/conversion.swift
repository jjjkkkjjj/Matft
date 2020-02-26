//
//  conversion.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension Matft.mfarray{
    public static func astype(_ mfarray: MfArray, mftype: MfType) -> MfArray{
        let newarray = Matft.mfarray.create_view(mfarray)
        newarray.mfdata._mftype = mftype
        return newarray
    }
    
    public static func transpose(_ mfarray: MfArray, axes: [Int]? = nil) -> MfArray{
        var permutation: [Int] = [], reverse_permutation: [Int] = []
        let dim =  mfarray.shape.count
        
        if let axes = axes{
            precondition(axes.count == dim, "axes don't match array")
            for _ in 0..<dim{
                reverse_permutation.append(-1)
            }
            for i in 0..<dim{
                let axis = axes[i]
                precondition(axis < dim, "invalid axes")
                precondition(reverse_permutation[axis] == -1, "repeated axis in transpose")
                reverse_permutation[axis] = i
                permutation.append(axis)
            }
        }
        else {
            for i in 0..<dim{
                permutation.append(dim - 1 - i)
            }
        }
        
        var newShape: [Int] = [], newStrides: [Int] = []
        
        for i in 0..<dim{
            newShape.append(mfarray.shape[permutation[i]])
            newStrides.append(mfarray.strides[permutation[i]])
        }
        
        let newarray = Matft.mfarray.create_view(mfarray)
        newarray.mfdata._shape = array2UnsafeMBPtrT(&newShape)
        newarray.mfdata._strides = array2UnsafeMBPtrT(&newStrides)
        
        return newarray
    }
    
    public static func broadcast_to(_ mfarray: MfArray, shape: [Int]) -> MfArray{
        var shape = shape
        let out_ndim = shape2ndim(&shape)
        var out_strides = Array<Int>(repeating: 0, count: out_ndim)
        
        let idim_start = out_ndim - mfarray.ndim
        
        
        if idim_start < 0{
            fatalError("can't broadcast to fewer dimensions")
        }
        
        for idim in (idim_start..<out_ndim).reversed(){
            let strides_shape_value = mfarray.shape[idim - idim_start]
            /* If it doesn't have dimension one, it must match */
            if strides_shape_value == 1{
                out_strides[idim] = 0
            }
            else if strides_shape_value != shape[idim]{
                fatalError("could not broadcast from shape \(mfarray.shapeptr.count), \(mfarray.shape) into shape \(out_ndim), \(shape)")
            }
            else{
                out_strides[idim] = mfarray.strides[idim - idim_start]
            }
        }
        
        /* New dimensions get a zero stride */
        for idim in 0..<idim_start{
            out_strides[idim] = 0
        }
        
        let newarray = Matft.mfarray.create_view(mfarray)
        newarray.mfdata._shape = array2UnsafeMBPtrT(&shape)
        newarray.mfdata._strides = array2UnsafeMBPtrT(&out_strides)
        
        return newarray
    }
}
