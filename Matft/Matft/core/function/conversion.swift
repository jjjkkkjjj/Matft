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
}
