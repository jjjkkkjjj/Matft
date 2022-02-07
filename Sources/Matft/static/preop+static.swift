//
//  preop+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation

extension Matft{

    /// Element-wise negativity
    /// - Parameter mfarray: An input mfarray
    /// - Returns: Negated mfarray
    public static func neg<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        return preop_by_vDSP(mfarray, T.StoredType.vDSP_preop_func)
    }
    
    
    /// Element-wise Not mfarray. Returned mfarray will be bool
    /// - Parameter mfarray: An input mfarray
    /// - Returns: The output mfarray
    public static func logical_not(_ mfarray: MfArray<Bool>) -> MfArray<Bool>{
        var ret = mfarray.mfdata.storedData.map{ $0 != Bool.StoredType.zero ? Bool.StoredType.zero : Bool.StoredType(1) }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}
