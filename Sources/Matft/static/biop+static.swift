//
//  biop+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation
import Accelerate

extension Matft{
    
    
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        (l_mfarray, r_mfarray) = to_samestructure(l_mfarray, r_mfarray)
        
        
        var ret = zip(l_mfarray.mfdata.storedData, r_mfarray.mfdata.storedData).map{ $0 == $1 ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let l_scalar = T.StoredType.from(l_scalar)
        
        var ret = r_mfarray.mfdata.storedData.map{ $0 == l_scalar ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let r_scalar = T.StoredType.from(r_scalar)
        
        var ret = l_mfarray.mfdata.storedData.map{ $0 == r_scalar ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
    
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        (l_mfarray, r_mfarray) = to_samestructure(l_mfarray, r_mfarray)
        
        
        var ret = zip(l_mfarray.mfdata.storedData, r_mfarray.mfdata.storedData).map{ $0 != $1 ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let l_scalar = T.StoredType.from(l_scalar)
        
        var ret = r_mfarray.mfdata.storedData.map{ $0 != l_scalar ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let r_scalar = T.StoredType.from(r_scalar)
        
        var ret = l_mfarray.mfdata.storedData.map{ $0 != r_scalar ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
    
    /// Check equality in element-wise, and then when all of elements are true, return true, otherwise false
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: Whether it's equal or not
    public static func equalAll<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> Bool{
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        (l_mfarray, r_mfarray) = to_samestructure(l_mfarray, r_mfarray)
        
        return l_mfarray.mfdata.storedData == r_mfarray.mfdata.storedData
    }
}