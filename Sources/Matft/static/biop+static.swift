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
    /// - Returns: The result mfarray
    public static func add<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_addvv_func)
    }
    /// Element-wise subtraction of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func sub<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_subvv_func)
    }
    /// Element-wise multiplication of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func mul<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_mulvv_func)
    }
    /// Element-wise division of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func div<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: T.StoredType.vDSP_divvv_func)
    }
    
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        /*
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        (l_mfarray, r_mfarray) = to_samestructure(l_mfarray, r_mfarray)
        
        var ret = zip(l_mfarray.mfdata.storedData, r_mfarray.mfdata.storedData).map{ T.StoredType.nealy_equal($0, $1) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        //toBool_by_vDSP(l_mfarray - r_mfarray)
        return MfArray(mfdata: newdata, mfstructure: newstructure)*/
        return toIBool_by_vDSP(l_mfarray - r_mfarray)
    }
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        /*
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        (l_mfarray, r_mfarray) = to_samestructure(l_mfarray, r_mfarray)
        
        
        var ret = zip(l_mfarray.mfdata.storedData, r_mfarray.mfdata.storedData).map{ !T.StoredType.nealy_equal($0, $1) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)*/
        return toBool_by_vDSP(l_mfarray - r_mfarray)
    }
    
    /// Check left mfarray's elements are less than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func less<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = r_mfarray - l_mfarray
        return toBool_by_vDSP(diff.clip(minval: T.zero, maxval: nil))
    }
    
    /// Check left mfarray's elements are less equal than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func less_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = r_mfarray - l_mfarray
        return toBool_by_vDSP(diff.sign() + T.from(1))
    }
    
    /// Check left mfarray's elements are greater than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func greater<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = l_mfarray - r_mfarray
        return toBool_by_vDSP(diff.clip(minval: T.zero, maxval: nil))
    }
    
    /// Check left mfarray's elements are greater equal than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func greater_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = l_mfarray - r_mfarray
        return toBool_by_vDSP(diff.sign() + T.from(1))
    }
    
    //===== vector =====//
    /// Matrix multiplication
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func matmul<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        precondition(l_mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        precondition(r_mfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
        let (l_mfarray, r_mfarray) = matmul_broadcast_to(l_mfarray, r_mfarray)
        
        return matmul_by_cblas(l_mfarray, r_mfarray, cblas_func: T.StoredType.cblas_matmul_func)
    }
    
    /// Inner product
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func inner<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let last_dim = l_mfarray.shape[l_mfarray.ndim - 1]
        precondition(last_dim == r_mfarray.shape[r_mfarray.ndim - 1], "Last dimension must be same")
        let ret_shape = Array(l_mfarray.shape.prefix(l_mfarray.ndim - 1) + r_mfarray.shape.prefix(r_mfarray.ndim - 1))
        
        //convert shape to calculate
        let l_mfarray = l_mfarray.reshape([-1, last_dim])
        let l_calcsize = l_mfarray.shape[0]
        let r_mfarray = r_mfarray.reshape([-1, last_dim])
        let r_calcsize = r_mfarray.shape[0]
        
        let ret = Matft.nums(T.zero, shape: [l_calcsize*r_calcsize])
        for lind in 0..<l_calcsize{
            for rind in 0..<r_calcsize{
                ret[lind*r_calcsize + rind] = (l_mfarray[lind] * r_mfarray[rind]).sum()
            }
        }
        
        return ret.reshape(ret_shape.count != 0 ? ret_shape : [1])
    }
    
    /// Cross product
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func cross<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        let orig_shape_for3d = l_mfarray.shape
        let last_dim = orig_shape_for3d[l_mfarray.ndim - 1]
        
        //convert shape to calculate
        l_mfarray = l_mfarray.reshape([-1, last_dim])
        r_mfarray = r_mfarray.reshape([-1, last_dim])

        if last_dim == 2{
            let ret = l_mfarray[0~<,0] * r_mfarray[0~<,1] - l_mfarray[0~<,1]*r_mfarray[0~<,0]
            return ret
        }
        else if last_dim == 3{
            let ret = Matft.nums(T.zero, shape: [l_mfarray.shape[0], last_dim])
            
            ret[0~<,0] = l_mfarray[0~<,1] * r_mfarray[0~<,2] - l_mfarray[0~<,2]*r_mfarray[0~<,1]
            ret[0~<,1] = l_mfarray[0~<,2] * r_mfarray[0~<,0] - l_mfarray[0~<,0]*r_mfarray[0~<,2]
            ret[0~<,2] = l_mfarray[0~<,0] * r_mfarray[0~<,1] - l_mfarray[0~<,1]*r_mfarray[0~<,0]
            
            return ret.reshape(orig_shape_for3d)
        }
        else{
            preconditionFailure("Last dimension must be 2 or 3")
        }
    }
    
    
    //============= left mfarray, right scalar operation =============//
    
    /// Element-wise addition of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The result mfarray
    public static func add<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{
        return biopvs_by_vDSP(l_mfarray, T.StoredType.from(r_scalar), vDSP_func: T.StoredType.vDSP_addvs_func)
    }
    /// Element-wise subtraction of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The result mfarray
    public static func sub<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{
        return biopvs_by_vDSP(l_mfarray, -T.StoredType.from(r_scalar), vDSP_func: T.StoredType.vDSP_addvs_func)
    }
    /// Element-wise multiplication of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The result mfarray
    public static func mul<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{
        return biopvs_by_vDSP(l_mfarray, T.StoredType.from(r_scalar), vDSP_func: T.StoredType.vDSP_mulvs_func)
    }
    /// Element-wise division of  two mfarray
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The result mfarray
    public static func div<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{
        return biopvs_by_vDSP(l_mfarray, T.StoredType.from(r_scalar), vDSP_func: T.StoredType.vDSP_divvs_func)
    }
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        //let r_scalar = T.StoredType.from(r_scalar)
        /*
        var ret = l_mfarray.mfdata.storedData.map{ T.StoredType.nealy_equal($0, r_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)*/
        return toIBool_by_vDSP(l_mfarray - r_scalar)
    }
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        /*
        let r_scalar = T.StoredType.from(r_scalar)
        
        var ret = l_mfarray.mfdata.storedData.map{ !T.StoredType.nealy_equal($0, r_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: l_mfarray.shape, strides: l_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)*/
        return toBool_by_vDSP(l_mfarray - r_scalar)
    }
    
    /// Check left mfarray's elements are less than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func less<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let diff = r_scalar - l_mfarray
        return toBool_by_vDSP(diff.clip(minval: T.zero, maxval: nil))
    }
    
    /// Check left mfarray's elements are less equal than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func less_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let diff = r_scalar - l_mfarray
        return toBool_by_vDSP(diff.sign() + T.from(1))
    }
    
    /// Check left mfarray's elements are greater than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func greater<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let diff = l_mfarray - r_scalar
        return toBool_by_vDSP(diff.clip(minval: T.zero, maxval: nil))
    }
    
    /// Check left mfarray's elements are greater equal than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_mfarray: The left mfarray
    ///   - r_scalar: The right scalar
    /// - Returns: The bool mfarray
    public static func greater_equal<T: MfTypeUsable>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        let diff = l_mfarray - r_scalar
        return toBool_by_vDSP(diff.sign() + T.from(1))
    }
    
    
    //============= right mfarray, left scalar operation =============//
    
    /// Element-wise addition of  two mfarray
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func add<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        return biopvs_by_vDSP(r_mfarray, T.StoredType.from(l_scalar), vDSP_func: T.StoredType.vDSP_addvs_func)
    }
    /// Element-wise addition of  two mfarray
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func sub<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        return biopvs_by_vDSP(-r_mfarray, T.StoredType.from(l_scalar), vDSP_func: T.StoredType.vDSP_addvs_func)
    }
    /// Element-wise addition of  two mfarray
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func mul<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        return biopvs_by_vDSP(r_mfarray, T.StoredType.from(l_scalar), vDSP_func: T.StoredType.vDSP_mulvs_func)
    }
    /// Element-wise addition of  two mfarray
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The result mfarray
    public static func div<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        return biopsv_by_vDSP(T.StoredType.from(l_scalar), r_mfarray, vDSP_func: T.StoredType.vDSP_divsv_func)
    }
    /// Check equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        /*
        let l_scalar = T.StoredType.from(l_scalar)
        
        var ret = r_mfarray.mfdata.storedData.map{ T.StoredType.nealy_equal($0, l_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)*/
        return toIBool_by_vDSP(l_scalar - r_mfarray)
    }
    /// Check NOT equality in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func not_equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        /*
        let l_scalar = T.StoredType.from(l_scalar)
        
        var ret = r_mfarray.mfdata.storedData.map{ !T.StoredType.nealy_equal($0, l_scalar) ? Bool.StoredType(1) : Bool.StoredType.zero }
        let newdata = MfData(Bool.self, storedFlattenArray: &ret)
        let newstructure = MfStructure(shape: r_mfarray.shape, strides: r_mfarray.strides)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)*/
        return toBool_by_vDSP(l_scalar - r_mfarray)
    }
    
    /// Check left mfarray's elements are less than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func less<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = r_mfarray - l_scalar
        return toBool_by_vDSP(diff.clip(minval: T.zero, maxval: nil))
    }
    
    /// Check left mfarray's elements are less equal than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func less_equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = r_mfarray - l_scalar
        return toBool_by_vDSP(diff.sign() + T.from(1))
    }
    
    /// Check left mfarray's elements are greater than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func greater<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = l_scalar - r_mfarray
        return toBool_by_vDSP(diff.clip(minval: T.zero, maxval: nil))
    }
    
    /// Check left mfarray's elements are greater equal than right ones in element-wise. Returned mfarray's type will be bool.
    /// - Parameters:
    ///   - l_scalar: The left scalar
    ///   - r_mfarray: The right mfarray
    /// - Returns: The bool mfarray
    public static func greater_equal<T: MfTypeUsable>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        let diff = l_scalar - r_mfarray
        return toBool_by_vDSP(diff.sign() + T.from(1))
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
