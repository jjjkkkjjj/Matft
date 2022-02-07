//
//  conversion_static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension Matft{

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
