//
//  bioperator.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

extension Matft{
    //infix
    /**
       Element-wise addition of  two mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func add(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vadd)
            case .Double:
                return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vaddD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(rettype){
            case .Float:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvadd)
            case .Double:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvaddD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }

    /**
       Element-wise addition of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func add<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsadd)
            case .Double:
                return biopvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsaddD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_zrvadd)
            case .Double:
                return biopzvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_zrvaddD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise addition of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func add<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopvs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_vsadd)
            case .Double:
                return biopvs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_vsaddD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_zrvadd)
            case .Double:
                return biopzvs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_zrvaddD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise subtraction right mfarray from left mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func sub(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsub)
            case .Double:
                return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsubD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(rettype){
            case .Float:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvsub)
            case .Double:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvsubD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise subtraction of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func sub<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopvs_by_vDSP(l_mfarray, -Float.from(r_scalar), vDSP_vsadd)
            case .Double:
                return biopvs_by_vDSP(l_mfarray, -Double.from(r_scalar), vDSP_vsaddD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_zrvsub)
            case .Double:
                return biopzvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_zrvsubD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise subtraction of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func sub<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopvs_by_vDSP(-r_mfarray, Float.from(l_scalar), vDSP_vsadd)
            case .Double:
                return biopvs_by_vDSP(-r_mfarray, Double.from(l_scalar), vDSP_vsaddD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_by_vDSP(-r_mfarray, Float.from(l_scalar), vDSP_zrvadd)
            case .Double:
                return biopzvs_by_vDSP(-r_mfarray, Double.from(l_scalar), vDSP_zrvaddD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise multiplication of two mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func mul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmul)
            case .Double:
                return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmulD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(rettype){
            case .Float:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvmul_)
            case .Double:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvmulD_)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise multiplication of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func mul<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsmul)
            case .Double:
                return biopvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsmulD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_zrvmul)
            case .Double:
                return biopzvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_zrvmulD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise multiplication of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func mul<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopvs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_vsmul)
            case .Double:
                return biopvs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_vsmulD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_zrvmul)
            case .Double:
                return biopzvs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_zrvmulD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise division left mfarray by right mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func div(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                let ret = biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdiv)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                return biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdivD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(rettype){
            case .Float:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvdiv)
            case .Double:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvdivD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise division of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func div<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsdiv)
            case .Double:
                return biopvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsdivD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_zrvdiv)
            case .Double:
                return biopzvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_zrvdivD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Element-wise division of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func div<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopsv_by_vDSP(Float.from(l_scalar), r_mfarray, vDSP_svdiv)
            case .Double:
                return biopsv_by_vDSP(Double.from(l_scalar), r_mfarray, vDSP_svdivD)
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzsv_by_vDSP(Float.from(l_scalar), r_mfarray, vDSP_ztrans)
            case .Double:
                return biopzsv_by_vDSP(Double.from(l_scalar), r_mfarray, vDSP_ztransD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    
    /**
       Matrix multiplication
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func matmul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _matmul_operation(l_mfarray, r_mfarray)
    }
    
    /**
       Dot product.
        - If both a and b are 1-D arrays, it is inner product of vectors (without complex conjugation).
        - If both a and b are 2-D arrays, it is matrix multiplication, but using matmul or `a *& b` is preferred.
        - If a is an N-D array and b is a 1-D array, it is a sum product over the last axis of a and b.
        - If a is an N-D array and b is an M-D array (where M>=2), it is a sum product over the last axis of a and the second-to-last axis of b:
     
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func dot(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{

        if l_mfarray.ndim == r_mfarray.ndim && l_mfarray.ndim == 1{
            // inner product
            return Matft.inner(l_mfarray, r_mfarray)
        }
        else if l_mfarray.ndim == r_mfarray.ndim && l_mfarray.ndim == 2{
            // matrix multiplication
            return Matft.matmul(l_mfarray, r_mfarray)
        }
        else if r_mfarray.ndim == 1{
            return Matft.inner(l_mfarray, r_mfarray)
        }
        else{
            // r_mfarray.ndim > 1
            var l_shape = l_mfarray.shape
            var r_shape = r_mfarray.shape
            
            var l_mfarray = l_mfarray
            var r_mfarray = r_mfarray
            if l_shape[0] == 1 && r_shape[1] > 1{
                l_shape[0] = r_shape[1]
                l_mfarray = l_mfarray.broadcast_to(shape: l_shape)
                l_shape[0] = 1 // revert for error message
            }
            else if r_shape[1] == 1 && l_shape[0] > 1{
                r_shape[1] = r_shape[0]
                r_mfarray = r_mfarray.broadcast_to(shape: r_shape)
                r_shape[1] = 1 // revert for error message
            }
            
            precondition(l_shape[0] == r_shape[1], "shapes \(l_shape) and \(r_shape) not aligned: \(l_shape[0]) (dim 0) != \(r_shape[1]) (dim 1)")
            
            let retmftype = MfType.priority(l_mfarray.mftype, r_mfarray.mftype)
            l_mfarray = l_mfarray.mftype == retmftype ? l_mfarray : l_mfarray.astype(retmftype, mforder: .Row)
            r_mfarray = r_mfarray.mftype == retmftype ? r_mfarray : r_mfarray.astype(retmftype, mforder: .Row)
            
            switch MfType.storedType(retmftype) {
            case .Float:
                return dotpr_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_dotpr)
            case .Double:
                return dotpr_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_dotprD)
            }
        }
    }
    
    /**
       Inner product
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func inner(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _inner_operation(l_mfarray, r_mfarray)
    }
    /**
       Cross product
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func cross(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _cross_operation(l_mfarray, r_mfarray)
    }
    
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _equal_operation(l_mfarray, r_mfarray)
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return _equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1]))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return _equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray)
    }
    
    /**
        Check NOT equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func not_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return Matft.logical_not(_equal_operation(l_mfarray, r_mfarray))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func not_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return Matft.logical_not(_equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1])))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func not_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return Matft.logical_not(_equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray))
    }
    
    /**
        Check left mfarray's elements are less than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func less(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left mfarray's elements are less than right scalar in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func less<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let diff = r_scalar - l_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left scalar is less than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func less<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_scalar
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left mfarray's elements are less equal than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func less_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_mfarray
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left mfarray's elements are less equal than right scalar in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func less_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let diff = r_scalar - l_mfarray
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left scalar is less equal than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func less_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_scalar
        return to_Bool(diff.sign() + Float(1))
    }
    
    /**
        Check left mfarray's elements are greater than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func greater(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_mfarray - r_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left scalar is greater than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func greater<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let diff = l_mfarray - r_scalar
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left scalar is greater than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func greater<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_scalar - r_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left mfarray's elements are greater equal than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func greater_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_mfarray - r_mfarray
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left scalar is greater equal than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func greater_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let diff = l_mfarray - r_scalar
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left scalar is greater equal than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func greater_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_scalar - r_mfarray
        return to_Bool(diff.sign() + Float(1))
    }
    
    /**
        Check equality in element-wise, and then when all of elements are true, return true, otherwise false
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func allEqual(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> Bool{
        return _equalAll_operation(l_mfarray, r_mfarray)
    }
    
}


/*
 >>> a = np.arange(100).reshape(10,2,5)
 >>> b = np.arange(135).reshape(5,3,9)
 >>> np.matmul(a,b)
 Traceback (most recent call last):
   File "<stdin>", line 1, in <module>
 ValueError: matmul: Input operand 1 has a mismatch in its core dimension 0, with gufunc signature (n?,k),(k,m?)->(n?,m?) (size 3 is different from 5)
 
 >>> a = np.arange(100).reshape(10,2,5)
 >>> b = np.arange(135).reshape(3,5,9)
 >>> np.matmul(a,b)
 Traceback (most recent call last):
   File "<stdin>", line 1, in <module>
 ValueError: operands could not be broadcast together with remapped shapes [original->remapped]: (10,2,5)->(10,newaxis,newaxis) (3,5,9)->(3,newaxis,newaxis) and requested shape (2,9)
 
 For N dimensions it is a sum product over the last axis of a and the second-to-last of b:
 
 >>> a = np.arange(2 * 2 * 4).reshape((2, 2, 4))
 >>> b = np.arange(2 * 2 * 4).reshape((2, 4, 2))
 >>> np.matmul(a,b).shape
 (2, 2, 2)
 >>> np.matmul(a, b)[0, 1, 1]
 98
 >>> sum(a[0, 1, :] * b[0 , :, 1])
 98
 
 
 //nice reference: https://stackoverflow.com/questions/34142485/difference-between-numpy-dot-and-python-3-5-matrix-multiplication
>>>From the above two definitions, you can see the requirements to use those two operations. Assume a.shape=(s1,s2,s3,s4) and b.shape=(t1,t2,t3,t4)

To use dot(a,b) you need
    t3=s4;

To use matmul(a,b) you need
    t3=s4
    t2=s2, or one of t2 and s2 is 1 // <- for broadcast
    t1=s1, or one of t1 and s1 is 1 // <- for broadcast

 */

//very dirty code....
fileprivate func _matmul_operation(_ lmfarray: MfArray, _ rmfarray: MfArray) -> MfArray{
    precondition(lmfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(rmfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    
    //preprocessing
    //type
    var lmfarray = lmfarray
    var rmfarray = rmfarray
    if lmfarray.mftype != rmfarray.mftype{
        let returnedType = MfType.priority(lmfarray.mftype, rmfarray.mftype)
        if returnedType != lmfarray.mftype{
            lmfarray = lmfarray.astype(returnedType)
        }
        else{
            rmfarray = rmfarray.astype(returnedType)
        }
    }
    
    
    
    // order
    // must be row or column major
    //let retorder = _matmul_convorder(&lmfarray, &rmfarray)
    
    //broadcast
    _matmul_broadcast_to(&lmfarray, &rmfarray)
    /*
    print(lmfarray.shape, lmfarray.strides)
    print(lmfarray.data)
    print(rmfarray.shape, rmfarray.strides)
    print(rmfarray.data)
    print(lmfarray)
    print(rmfarray)*/
    
    
    //run
    switch MfType.storedType(lmfarray.mftype) {
    case .Float:
        return matmul_by_cblas(&lmfarray, &rmfarray, cblas_func: cblas_sgemm)
        
    case .Double:
        return matmul_by_cblas(&lmfarray, &rmfarray, cblas_func: cblas_dgemm)
    }
    
}

//Note that this function is slighly different from biobiop_broadcast_to for precondition and checked axis
//TODO: gather this function and biobiop_broadcast_to
fileprivate func _matmul_broadcast_to(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray){
    var lshape = lmfarray.shape
    var lstrides = lmfarray.strides
    var rshape = rmfarray.shape
    var rstrides = rmfarray.strides
    
    precondition(lshape[lmfarray.ndim - 1] == rshape[rmfarray.ndim - 2], "Last 2 dimensions of the input mfarray must be lmfarray:(...,l,m) and rmfarray:(...,m,n)")
    
    // broadcast
    let retndim: Int
    
    if lmfarray.ndim < rmfarray.ndim{ // l has smaller dim
        retndim = rmfarray.ndim
        lshape = Array<Int>(repeating: 1, count: rmfarray.ndim - lmfarray.ndim) + lshape // the 1 concatenated elements means broadcastable
        lstrides = Array<Int>(repeating: 0, count: rmfarray.ndim - lmfarray.ndim) + lstrides// the 0 concatenated elements means broadcastable
    }
    else if lmfarray.ndim > rmfarray.ndim{// r has smaller dim
        retndim = lmfarray.ndim
        rshape = Array<Int>(repeating: 1, count: lmfarray.ndim - rmfarray.ndim) + rshape // the 1 concatenated elements means broadcastable
        rstrides = Array<Int>(repeating: 0, count: lmfarray.ndim - rmfarray.ndim) + rstrides// the 0 concatenated elements means broadcastable
    }
    else{
        retndim = lmfarray.ndim
    }

    for axis in (0..<retndim-2).reversed(){
        if lshape[axis] == rshape[axis]{
            continue
        }
        else if lshape[axis] == 1{
            lshape[axis] = rshape[axis] // aligned to r
            lstrides[axis] = 0 // broad casted 0
        }
        else if rshape[axis] == 1{
            rshape[axis] = lshape[axis] // aligned to l
            rstrides[axis] = 0 // broad casted 0
        }
        else{
            preconditionFailure("Broadcast error: cannot calculate matrix multiplication due to broadcasting error. hint: For all dim < ndim-2, left.shape[dim] or right.shape[dim] is one, or left.shape[dim] == right.shape[dim]")
        }
    }
    let l_mfstructure = MfStructure(shape: lshape, strides: lstrides)
    let r_mfstructure = MfStructure(shape: rshape, strides: rstrides)
    
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: l_mfstructure._shape, count: l_mfstructure._ndim)))
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: r_mfstructure._shape, count: r_mfstructure._ndim)))
    
    lmfarray = MfArray(base: lmfarray, mfstructure: l_mfstructure, offset: lmfarray.offsetIndex)
    rmfarray = MfArray(base: rmfarray, mfstructure: r_mfstructure, offset: rmfarray.offsetIndex)
}


fileprivate func _cross_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
    var (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
    
    precondition(isReal, "Complex is not supported")
    
    let orig_shape_for3d = l_mfarray.shape
    let lastdim = orig_shape_for3d[l_mfarray.ndim - 1]
    
    //convert shape to calculate
    l_mfarray = l_mfarray.reshape([-1, lastdim])
    r_mfarray = r_mfarray.reshape([-1, lastdim])

    if lastdim == 2{
        let ret = l_mfarray[0~<,0] * r_mfarray[0~<,1] - l_mfarray[0~<,1]*r_mfarray[0~<,0]
        return ret
    }
    else if lastdim == 3{
        let ret = Matft.nums(0, shape: [l_mfarray.shape[0], lastdim], mftype: rettype)
        
        ret[0~<,0] = l_mfarray[0~<,1] * r_mfarray[0~<,2] - l_mfarray[0~<,2]*r_mfarray[0~<,1]
        ret[0~<,1] = l_mfarray[0~<,2] * r_mfarray[0~<,0] - l_mfarray[0~<,0]*r_mfarray[0~<,2]
        ret[0~<,2] = l_mfarray[0~<,0] * r_mfarray[0~<,1] - l_mfarray[0~<,1]*r_mfarray[0~<,0]
        
        return ret.reshape(orig_shape_for3d)
    }
    else{
        preconditionFailure("Last dimension must be 2 or 3")
    }
}

//uncompleted
fileprivate func _inner_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
    let lastdim = l_mfarray.shape[l_mfarray.ndim - 1]
    precondition(lastdim == r_mfarray.shape[r_mfarray.ndim - 1], "Last dimension must be same")
    let retShape = Array(l_mfarray.shape.prefix(l_mfarray.ndim - 1) + r_mfarray.shape.prefix(r_mfarray.ndim - 1))
    let rettype = l_mfarray.mftype
    
    //convert shape to calculate
    let l_mfarray = l_mfarray.reshape([-1, lastdim])
    let l_calcsize = l_mfarray.shape[0]
    let r_mfarray = r_mfarray.reshape([-1, lastdim])
    let r_calcsize = r_mfarray.shape[0]
    
    let ret = Matft.nums(0, shape: [l_calcsize*r_calcsize], mftype: rettype)
    for lind in 0..<l_calcsize{
        for rind in 0..<r_calcsize{
            ret[lind*r_calcsize + rind] = (l_mfarray[lind] * r_mfarray[rind]).sum()
        }
    }
    
    return ret.reshape(retShape.count != 0 ? retShape : [1])
}



fileprivate func _equal_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray{
    let diff = l_mfarray - r_mfarray
    //print(diff)
    
    /*
    let diff = l_mfarray - r_mfarray
    print(diff)
    diff.withDataUnsafeMRPtr{
        dataptr in
        var bytes = UnsafeMutableRawBufferPointer(start: dataptr, count: diff.storedByteSize).map{ ~<$0 }
        bytes.withUnsafeMutableBufferPointer{
            dataptr.copyMemory(from: $0.baseAddress!, byteCount: diff.storedByteSize)
        }
    }
    print(diff)*/
    return to_IBool(diff, thresholdF: thresholdF, thresholdD: thresholdD)
}

fileprivate func _equalAll_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> Bool{
   //print(diff)
   if l_mfarray.shape != r_mfarray.shape{
       return false
   }
    let diff = l_mfarray - r_mfarray
    
    // diff must be 0 if all of elements are same
    switch diff.storedType {
    case .Float:
        if let data = diff.data as? [UInt8]{
            let ret = data.allSatisfy{ $0 == UInt8.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [UInt8]
                return ret && data_img.allSatisfy{ $0 == UInt8.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [UInt16]{
            let ret = data.allSatisfy{ $0 == UInt16.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [UInt16]
                return ret && data_img.allSatisfy{ $0 == UInt16.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [UInt32]{
            let ret = data.allSatisfy{ $0 == UInt32.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [UInt32]
                return ret && data_img.allSatisfy{ $0 == UInt32.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [UInt64]{
            let ret = data.allSatisfy{ $0 == UInt64.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [UInt64]
                return ret && data_img.allSatisfy{ $0 == UInt64.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [UInt]{
            let ret = data.allSatisfy{ $0 == UInt.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [UInt]
                return ret && data_img.allSatisfy{ $0 == UInt.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [Int8]{
            let ret = data.allSatisfy{ $0 == Int8.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Int8]
                return ret && data_img.allSatisfy{ $0 == Int8.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [Int16]{
            let ret = data.allSatisfy{ $0 == Int16.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Int16]
                return ret && data_img.allSatisfy{ $0 == Int16.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [Int32]{
            let ret = data.allSatisfy{ $0 == Int32.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Int32]
                return ret && data_img.allSatisfy{ $0 == Int32.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [Int64]{
            let ret = data.allSatisfy{ $0 == Int64.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Int64]
                return ret && data_img.allSatisfy{ $0 == Int64.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [Int]{
            let ret = data.allSatisfy{ $0 == Int.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Int]
                return ret && data_img.allSatisfy{ $0 == Int.zero }
            }
            else{
                return ret
            }
        }
        else if let data = diff.data as? [Float]{
            let ret = data.allSatisfy{ abs($0) <= thresholdF }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Float]
                return ret && data_img.allSatisfy{ abs($0) <= thresholdF }
            }
            else{
                return ret
            }
        }
        else{
            // bool
            guard let data = diff.astype(.Float).data as? [Float] else{
                return false
            }
            
            let ret = data.allSatisfy{ $0 == Float.zero }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Float]
                return ret && data_img.allSatisfy{ abs($0) <= thresholdF }
            }
            else{
                return ret
            }
        }
    case .Double:
        if let data = diff.data as? [Double]{
            let ret = data.allSatisfy{ abs($0) <= thresholdD }
            if diff.isComplex{
                let data_img = diff.data_imag as! [Double]
                return ret && data_img.allSatisfy{ abs($0) <= thresholdD }
            }
            else{
                return ret
            }
        }
        else{
            return false
        }
    }
    
}
