//
//  conversion+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension Matft{
    
    
    /// Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    /// - Returns: A transposed mfarray
    public static func transpose<T: MfTypeUsable>(_ mfarray: MfArray<T>, axes: [Int]? = nil) -> MfArray<T>{
        var permutation: [Int] = [], reverse_permutation: [Int] = []
        let ndim =  mfarray.shape.count
        
        if let axes = axes{
            precondition(axes.count == ndim, "axes(\(axes.count) don't match array's dimension(\(ndim)")
            for _ in 0..<ndim{
                reverse_permutation.append(-1)
            }
            for i in 0..<ndim{
                let axis = get_positive_axis(axes[i], ndim: ndim)

                precondition(reverse_permutation[axis] == -1, "repeated axis in transpose")
                reverse_permutation[axis] = i
                permutation.append(axis)
            }
        }
        else {
            for i in 0..<ndim{
                permutation.append(ndim - 1 - i)
            }
        }
        let orig_shape = mfarray.shape
        let orig_strides = mfarray.strides
        var new_shape = mfarray.shape
        var new_strides = mfarray.strides

        for i in 0..<ndim{
            new_shape[i] = orig_shape[permutation[i]]
            new_strides[i] = orig_strides[permutation[i]]
        }
        
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    
    
    /// Create broadcasted mfarray.
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - shape: A new shape
    /// - Returns: The broadcasted mfarray
    public static func broadcast_to<T: MfTypeUsable>(_ mfarray: MfArray<T>, shape: [Int]) -> MfArray<T>{
        var new_shape = shape
        //let newarray = Matft.shallowcopy(mfarray)
        let new_ndim = shape2ndim(&new_shape)
        
        let idim_start = new_ndim  - mfarray.ndim
        
        precondition(idim_start >= 0, "can't broadcast to fewer dimensions")
        
        let orig_strides = mfarray.strides
        let orig_shape = mfarray.shape
        
        var new_strides = Array<Int>(repeating: 0, count: new_ndim)
        
        // Calculate a new strides for a given a new shape
        for idim in (idim_start..<new_ndim).reversed(){
            let strides_shape_value = orig_shape[idim - idim_start]
            /* If it doesn't have dimension one, it must match */
            if strides_shape_value == 1{
                new_strides[idim] = 0
            }
            else if strides_shape_value != shape[idim]{
                preconditionFailure("could not broadcast from shape \(orig_shape) into shape \(shape)")
            }
            else{
                new_strides[idim] = orig_strides[idim - idim_start]
            }
        }
        
        /* New dimensions get a zero stride */
        for idim in 0..<idim_start{
            new_strides[idim] = 0
        }
        
        
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        
        //newarray.mfstructure = newstructure
        //return newarray
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    
    
    /// Convert a given mfarray into a contiguous one
    /// - Parameters:
    ///   - mfarray: The source mfarray
    ///   - mforder: An order
    /// - Returns: The contiguous mfarray
    public static func to_contiguous<T: MfTypeUsable>(_ mfarray: MfArray<T>, mforder: MfOrder) -> MfArray<T>{
        return contiguous_by_cblas(mfarray, cblas_func: T.StoredType.cblas_copy_func, mforder: mforder)
    }
}
