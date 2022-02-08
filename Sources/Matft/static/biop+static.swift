//
//  biop+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation
import Accelerate

extension Matft{
    
    //============= 2 mfarray operation =============//
    /// Element-wise addition of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The added mfarray
    public static func add<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_addvv_func)
    }
    /// Element-wise subtraction of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The added mfarray
    public static func sub<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_subvv_func)
    }
    /// Element-wise multiplication of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The added mfarray
    public static func mul<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_mulvv_func)
    }
    /// Element-wise division of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The added mfarray
    public static func div<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_divvv_func)
    }
    
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        (l_mfarray, r_mfarray) = to_samestructure(l_mfarray, r_mfarray)
        
        var ret = zip(l_mfarray.mfdata.storedData, r_mfarray.mfdata.storedData).map{ T.StoredType.nealy_equal($0, $1) ? Bool.StoredType(1) : Bool.StoredType.zero }
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
        
        
        var ret = zip(l_mfarray.mfdata.storedData, r_mfarray.mfdata.storedData).map{ !T.StoredType.nealy_equal($0, $1) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
    //============= left mfarray, right scalar operation =============//
    
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let r_scalar = T.StoredType.from(r_scalar)
        
        var ret = l_mfarray.mfdata.storedData.map{ T.StoredType.nealy_equal($0, r_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let r_scalar = T.StoredType.from(r_scalar)
        
        var ret = l_mfarray.mfdata.storedData.map{ !T.StoredType.nealy_equal($0, r_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
    
    //============= right mfarray, left scalar operation =============//
    
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let l_scalar = T.StoredType.from(l_scalar)
        
        var ret = r_mfarray.mfdata.storedData.map{ T.StoredType.nealy_equal($0, l_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let l_scalar = T.StoredType.from(l_scalar)
        
        var ret = r_mfarray.mfdata.storedData.map{ !T.StoredType.nealy_equal($0, l_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
    
    /// Check equality in element-wise, and then when all of elements are true, return true, otherwise false
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: Whether it's equal or not
    public static func equalAll<T>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> Bool{
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        (l_mfarray, r_mfarray) = to_samestructure(l_mfarray, r_mfarray)
        if let ldata = l_mfarray.data as? [Float], let rdata = r_mfarray.data as? [Float]{
            return zip(ldata, rdata).allSatisfy{ fabsf($0 - $1) <= 1e-5 }
        }
        else if let ldata = l_mfarray.data as? [Double], let rdata = r_mfarray.data as? [Double]{
            return zip(ldata, rdata).allSatisfy{ fabs($0 - $1) <= 1e-10 }
        }
        else{
            return zip(l_mfarray.data, r_mfarray.data).allSatisfy{ $0 == $1 }
        }
        
    }
}
