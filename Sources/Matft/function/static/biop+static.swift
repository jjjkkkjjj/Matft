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
       Add arguments element-wise.

       The two arrays are broadcast together. The result type is the higher-priority `mftype` of the two, and complex arrays are supported. This is what `l + r` calls.
       Equivalent to `numpy.add`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the sum.
    */
    public static func add(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                return wrap_integer_overflow(biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vadd))
            case .Double:
                return wrap_integer_overflow(biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vaddD))
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
       Add an array and a scalar element-wise.

       The scalar is a "weak" scalar like numpy's Python scalars (NEP 50): the result keeps the type of `l_mfarray` unless the scalar is a higher kind (Bool < integer < floating point), e.g. `.UInt8` + `1` -> `.UInt8` (out of range values wrap around), `.Float` * `2.5` -> `.Float`. An integer or `.Bool` array with a floating point scalar gives `.Float` (numpy: float64), and a `.Bool` array with an integer scalar gives `.Int`. Complex arrays are supported and stay complex. This is what `l + scalar` calls.
       Equivalent to `numpy.add`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new array of the sum.
    */
    public static func add<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.scalar_result_type(array: l_mfarray.mftype, scalar: r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = astype_or_view(l_mfarray, retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return wrap_integer_overflow(biopvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsadd))
            case .Double:
                return wrap_integer_overflow(biopvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsaddD))
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
       Add a scalar and an array element-wise.

       The scalar is a "weak" scalar like numpy's Python scalars (NEP 50): the result keeps the type of `r_mfarray` unless the scalar is a higher kind (Bool < integer < floating point), e.g. `1` + `.UInt8` -> `.UInt8` (out of range values wrap around), `2.5` * `.Float` -> `.Float`. An integer or `.Bool` array with a floating point scalar gives `.Float` (numpy: float64), and a `.Bool` array with an integer scalar gives `.Int`. Complex arrays are supported and stay complex. This is what `scalar + r` calls.
       Equivalent to `numpy.add`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the sum.
    */
    public static func add<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.scalar_result_type(array: r_mfarray.mftype, scalar: l_mfype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = astype_or_view(r_mfarray, retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return wrap_integer_overflow(biopvs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_vsadd))
            case .Double:
                return wrap_integer_overflow(biopvs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_vsaddD))
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
       Subtract arguments element-wise.

       The two arrays are broadcast together. The result type is the higher-priority `mftype` of the two, and complex arrays are supported. This is what `l - r` calls.
       Equivalent to `numpy.subtract`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the difference.
    */
    public static func sub(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                return wrap_integer_overflow(biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsub))
            case .Double:
                return wrap_integer_overflow(biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsubD))
            }
        }
        else{
            #if canImport(Accelerate)
            switch MfType.storedType(rettype){
            case .Float:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvsub_)
            case .Double:
                return biopzvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_zvsubD_)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Subtract an array and a scalar element-wise.

       The scalar is a "weak" scalar like numpy's Python scalars (NEP 50): the result keeps the type of `l_mfarray` unless the scalar is a higher kind (Bool < integer < floating point), e.g. `.UInt8` + `1` -> `.UInt8` (out of range values wrap around), `.Float` * `2.5` -> `.Float`. An integer or `.Bool` array with a floating point scalar gives `.Float` (numpy: float64), and a `.Bool` array with an integer scalar gives `.Int`. Complex arrays are supported and stay complex. This is what `l - scalar` calls.
       Equivalent to `numpy.subtract`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new array of the difference.
    */
    public static func sub<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.scalar_result_type(array: l_mfarray.mftype, scalar: r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = astype_or_view(l_mfarray, retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return wrap_integer_overflow(biopvs_by_vDSP(l_mfarray, -Float.from(r_scalar), vDSP_vsadd))
            case .Double:
                return wrap_integer_overflow(biopvs_by_vDSP(l_mfarray, -Double.from(r_scalar), vDSP_vsaddD))
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
       Subtract a scalar and an array element-wise.

       The scalar is a "weak" scalar like numpy's Python scalars (NEP 50): the result keeps the type of `r_mfarray` unless the scalar is a higher kind (Bool < integer < floating point), e.g. `1` + `.UInt8` -> `.UInt8` (out of range values wrap around), `2.5` * `.Float` -> `.Float`. An integer or `.Bool` array with a floating point scalar gives `.Float` (numpy: float64), and a `.Bool` array with an integer scalar gives `.Int`. Complex arrays are supported and stay complex. This is what `scalar - r` calls.
       Equivalent to `numpy.subtract`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the difference.
    */
    public static func sub<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.scalar_result_type(array: r_mfarray.mftype, scalar: l_mfype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = astype_or_view(r_mfarray, retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return wrap_integer_overflow(biopvs_by_vDSP(-r_mfarray, Float.from(l_scalar), vDSP_vsadd))
            case .Double:
                return wrap_integer_overflow(biopvs_by_vDSP(-r_mfarray, Double.from(l_scalar), vDSP_vsaddD))
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
       Multiply arguments element-wise.

       The two arrays are broadcast together. The result type is the higher-priority `mftype` of the two, and complex arrays are supported. This is what `l * r` calls.
       Equivalent to `numpy.multiply`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the product.
    */
    public static func mul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                return wrap_integer_overflow(biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmul))
            case .Double:
                return wrap_integer_overflow(biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmulD))
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
       Multiply an array and a scalar element-wise.

       The scalar is a "weak" scalar like numpy's Python scalars (NEP 50): the result keeps the type of `l_mfarray` unless the scalar is a higher kind (Bool < integer < floating point), e.g. `.UInt8` + `1` -> `.UInt8` (out of range values wrap around), `.Float` * `2.5` -> `.Float`. An integer or `.Bool` array with a floating point scalar gives `.Float` (numpy: float64), and a `.Bool` array with an integer scalar gives `.Int`. Complex arrays are supported and stay complex. This is what `l * scalar` calls.
       Equivalent to `numpy.multiply`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new array of the product.
    */
    public static func mul<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.scalar_result_type(array: l_mfarray.mftype, scalar: r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = astype_or_view(l_mfarray, retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return wrap_integer_overflow(biopvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsmul))
            case .Double:
                return wrap_integer_overflow(biopvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsmulD))
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
       Multiply a scalar and an array element-wise.

       The scalar is a "weak" scalar like numpy's Python scalars (NEP 50): the result keeps the type of `r_mfarray` unless the scalar is a higher kind (Bool < integer < floating point), e.g. `1` + `.UInt8` -> `.UInt8` (out of range values wrap around), `2.5` * `.Float` -> `.Float`. An integer or `.Bool` array with a floating point scalar gives `.Float` (numpy: float64), and a `.Bool` array with an integer scalar gives `.Int`. Complex arrays are supported and stay complex. This is what `scalar * r` calls.
       Equivalent to `numpy.multiply`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the product.
    */
    public static func mul<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.scalar_result_type(array: r_mfarray.mftype, scalar: l_mfype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = astype_or_view(r_mfarray, retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                return wrap_integer_overflow(biopvs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_vsmul))
            case .Double:
                return wrap_integer_overflow(biopvs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_vsmulD))
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
       Divide arguments element-wise.

       The two arrays are broadcast together, and complex arrays are supported. This is what `l / r` calls.
       The result type is `.Float` when the higher-priority `mftype` of the two is stored as Float (e.g. `.Int / .Int` gives `.Float`), and `.Double` for Double-stored types.
       Equivalent to `numpy.divide`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the quotient.
    */
    public static func div(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
        
        if isReal{
            switch MfType.storedType(rettype){
            case .Float:
                let ret = biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdiv)
                ret.mfdata.mftype = .Float
                #if arch(x86_64)
                return fix_nan_elements(l_mfarray, r_mfarray, ret, datatype: Float.self){ $0 / $1 }
                #else
                return ret
                #endif
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
       Divide an array and a scalar element-wise.

       Complex arrays are supported. This is what `l / scalar` calls.
       Like the array-array version, the result type is `.Float` when `l_mfarray` is stored as Float (e.g. an `.Int` array divided by an `Int` gives `.Float`; numpy: float64); the scalar doesn't change the type (NEP 50), and `.Double` for Double-stored types.
       Equivalent to `numpy.divide`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new array of the quotient.
    */
    public static func div<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.scalar_result_type(array: l_mfarray.mftype, scalar: r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = astype_or_view(l_mfarray, retmftype)
        }
        
        if l_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                let ret = biopvs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsdiv)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                return biopvs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsdivD)
            }
        }
        else{
            #if canImport(Accelerate)
            // Divide the real and imaginary parts separately like numpy.
            // vDSP_zrvdiv is not exact on x86_64 (e.g. 1 / 2 -> 0.49999997)
            switch MfType.storedType(retmftype) {
            case .Float:
                return biopzvs_separately_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsdiv)
            case .Double:
                return biopzvs_separately_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsdivD)
            }
            #else
            fatalError("Complex array operations are not supported on this platform")
            #endif
        }
    }
    /**
       Divide a scalar and an array element-wise.

       Complex arrays are supported. This is what `scalar / r` calls.
       Like the array-array version, the result type is `.Float` when `r_mfarray` is stored as Float (e.g. an `Int` divided by an `.Int` array gives `.Float`; numpy: float64); the scalar doesn't change the type (NEP 50), and `.Double` for Double-stored types.
       Equivalent to `numpy.divide`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new array of the quotient.
    */
    public static func div<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.scalar_result_type(array: r_mfarray.mftype, scalar: l_mfype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = astype_or_view(r_mfarray, retmftype)
        }
        
        if r_mfarray.isReal{
            switch MfType.storedType(retmftype) {
            case .Float:
                let l_scalar = Float.from(l_scalar)
                let ret = biopsv_by_vDSP(l_scalar, r_mfarray, vDSP_svdiv)
                ret.mfdata.mftype = .Float
                #if arch(x86_64)
                return fix_nan_elements(r_mfarray, r_mfarray, ret, datatype: Float.self){ l_scalar / $1 }
                #else
                return ret
                #endif
            case .Double:
                return biopsv_by_vDSP(Double.from(l_scalar), r_mfarray, vDSP_svdivD)
            }
        }
        else{
            // vDSP_ztrans computes `complex / real`, so divide by the complex array of the scalar instead
            let l_mfarray = MfArray(real: Matft.nums(l_scalar, shape: r_mfarray.shape, mftype: retmftype), imag: nil)
            return Matft.div(l_mfarray, r_mfarray)
        }
    }
    
    /**
       Matrix product of two arrays.

       Both arrays must have at least 2 dimensions; the last two axes are multiplied as matrices and the leading axes are broadcast (a stack of matrices).
       The result type is the higher-priority `mftype` of the two. This is what `l *& r` calls.
       Equivalent to `numpy.matmul` (1-D inputs are not supported).

       ```swift
       let a = MfArray([[1, 2], [3, 4]])
       let b = MfArray([[5, 6], [7, 8]])
       let c = Matft.matmul(a, b)   // same as a *& b
       ```
       - Parameters:
           - l_mfarray: The left array of shape `(..., n, k)`.
           - r_mfarray: The right array of shape `(..., k, m)`.
       - Returns: A new array of shape `(..., n, m)`.
    */
    public static func matmul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _matmul_operation(l_mfarray, r_mfarray)
    }
    
    /**
       Dot product of two arrays.

       - If both arrays are 1-D, it is the inner product of vectors (without complex conjugation).
       - If both arrays are 2-D, it is matrix multiplication, but using `matmul` or `a *& b` is preferred.
       - If `r_mfarray` is 1-D, it is a sum product over the last axis of `l_mfarray` and `r_mfarray` (see `inner`).
       - Otherwise, a sum product is computed by `vDSP_dotpr`; note that this case requires `l_mfarray.shape[0] == r_mfarray.shape[1]` and does not follow Numpy's rule (sum over the last axis of `l_mfarray` and the second-to-last axis of `r_mfarray`).

       Similar to `numpy.dot`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: The dot product.
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
       Inner product of two arrays: a sum product over their last axes.

       The result shape is `l.shape[:-1] + r.shape[:-1]`, and `[1]` (not a scalar) when both inputs are 1-D. The result type is `l_mfarray.mftype`.
       Equivalent to `numpy.inner`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand. Its last dimension must equal that of `l_mfarray`.
       - Returns: A new array of the inner products.
    */
    public static func inner(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _inner_operation(l_mfarray, r_mfarray)
    }
    /**
       Cross product of two arrays of 2- or 3-element vectors.

       The arrays are broadcast together, and the vectors are taken along the last axis. Complex arrays are not supported.
       For 3-element vectors the result has the broadcast shape; for 2-element vectors the z-component `l[0]*r[1] - l[1]*r[0]` is returned as a 1-D array (one value per vector).
       Equivalent to `numpy.cross`.
       - Parameters:
           - l_mfarray: The left operand. Its last dimension must be 2 or 3.
           - r_mfarray: The right operand. Its last dimension must be 2 or 3.
       - Returns: A new array of the cross products.
    */
    public static func cross(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _cross_operation(l_mfarray, r_mfarray)
    }
    
    /**
       Return the truth value of `l == r`, element-wise.

       The two arrays are broadcast together. This is what `l === r` calls.
       Equivalent to `numpy.equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
       - Note: The comparison is computed from `l - r`, so comparing `inf` with `inf` gives `false`.
    */
    public static func equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _compare_operation(l_mfarray, r_mfarray, .equal)
    }
    /**
       Return the truth value of `l == r` for an array and a scalar, element-wise.

       This is what `l === scalar` calls.
       Equivalent to `numpy.equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return compare_mfarray(l_mfarray, .equal, r_scalar)
    }
    /**
       Return the truth value of `l == r` for a scalar and an array, element-wise.

       This is what `scalar === r` calls.
       Equivalent to `numpy.equal`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return compare_mfarray(r_mfarray, .equal.flipped, l_scalar)
    }
    
    /**
       Return the truth value of `l != r`, element-wise.

       The two arrays are broadcast together. This is what `l !== r` calls.
       Equivalent to `numpy.not_equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func not_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _compare_operation(l_mfarray, r_mfarray, .notEqual)
    }
    /**
       Return the truth value of `l != r` for an array and a scalar, element-wise.

       This is what `l !== scalar` calls.
       Equivalent to `numpy.not_equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func not_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return compare_mfarray(l_mfarray, .notEqual, r_scalar)
    }
    /**
       Return the truth value of `l != r` for a scalar and an array, element-wise.

       This is what `scalar !== r` calls.
       Equivalent to `numpy.not_equal`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func not_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return compare_mfarray(r_mfarray, .notEqual.flipped, l_scalar)
    }
    
    /**
       Return the truth value of `l < r`, element-wise.

       The two arrays are broadcast together. This is what `l < r` calls.
       Equivalent to `numpy.less`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func less(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _compare_operation(l_mfarray, r_mfarray, .less)
    }
    /**
       Return the truth value of `l < r` for an array and a scalar, element-wise.

       This is what `l < scalar` calls.
       Equivalent to `numpy.less`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func less<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return compare_mfarray(l_mfarray, .less, r_scalar)
    }
    /**
       Return the truth value of `l < r` for a scalar and an array, element-wise.

       This is what `scalar < r` calls.
       Equivalent to `numpy.less`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func less<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return compare_mfarray(r_mfarray, .less.flipped, l_scalar)
    }
    /**
       Return the truth value of `l <= r`, element-wise.

       The two arrays are broadcast together. This is what `l <= r` calls.
       Equivalent to `numpy.less_equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
       - Note: The comparison is computed from `l - r`, so comparing `inf` with `inf` gives `false`.
    */
    public static func less_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _compare_operation(l_mfarray, r_mfarray, .lessEqual)
    }
    /**
       Return the truth value of `l <= r` for an array and a scalar, element-wise.

       This is what `l <= scalar` calls.
       Equivalent to `numpy.less_equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func less_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return compare_mfarray(l_mfarray, .lessEqual, r_scalar)
    }
    /**
       Return the truth value of `l <= r` for a scalar and an array, element-wise.

       This is what `scalar <= r` calls.
       Equivalent to `numpy.less_equal`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func less_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return compare_mfarray(r_mfarray, .lessEqual.flipped, l_scalar)
    }
    
    /**
       Return the truth value of `l > r`, element-wise.

       The two arrays are broadcast together. This is what `l > r` calls.
       Equivalent to `numpy.greater`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func greater(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _compare_operation(l_mfarray, r_mfarray, .greater)
    }
    /**
       Return the truth value of `l > r` for an array and a scalar, element-wise.

       This is what `l > scalar` calls.
       Equivalent to `numpy.greater`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func greater<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return compare_mfarray(l_mfarray, .greater, r_scalar)
    }
    /**
       Return the truth value of `l > r` for a scalar and an array, element-wise.

       This is what `scalar > r` calls.
       Equivalent to `numpy.greater`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func greater<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return compare_mfarray(r_mfarray, .greater.flipped, l_scalar)
    }
    /**
       Return the truth value of `l >= r`, element-wise.

       The two arrays are broadcast together. This is what `l >= r` calls.
       Equivalent to `numpy.greater_equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
       - Note: The comparison is computed from `l - r`, so comparing `inf` with `inf` gives `false`.
    */
    public static func greater_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _compare_operation(l_mfarray, r_mfarray, .greaterEqual)
    }
    /**
       Return the truth value of `l >= r` for an array and a scalar, element-wise.

       This is what `l >= scalar` calls.
       Equivalent to `numpy.greater_equal`.
       - Parameters:
           - l_mfarray: The left operand.
           - r_scalar: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func greater_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return compare_mfarray(l_mfarray, .greaterEqual, r_scalar)
    }
    /**
       Return the truth value of `l >= r` for a scalar and an array, element-wise.

       This is what `scalar >= r` calls.
       Equivalent to `numpy.greater_equal`.
       - Parameters:
           - l_scalar: The left operand.
           - r_mfarray: The right operand.
       - Returns: A new `.Bool` array.
    */
    public static func greater_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return compare_mfarray(r_mfarray, .greaterEqual.flipped, l_scalar)
    }
    
    /**
       Return whether two arrays have the same shape and equal elements.

       Floating-point elements are compared with an absolute tolerance (`1e-5` for Float-stored and `1e-10` for Double-stored types), and NaN is never equal. This is what `l == r` calls.
       Similar to `numpy.array_equal` (or `numpy.allclose` for floating-point types).
       - Parameters:
           - l_mfarray: The left array.
           - r_mfarray: The right array.
       - Returns: `true` if the shapes match and all elements are equal, otherwise `false`.
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
            lmfarray = astype_or_view(lmfarray, returnedType)
        }
        else{
            rmfarray = astype_or_view(rmfarray, returnedType)
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

    // an empty operand: BLAS rejects zero leading dimensions. The sum over an empty inner dimension is 0 like Numpy
    if lmfarray.size == 0 || rmfarray.size == 0{
        let retshape = Array(lmfarray.shape.dropLast()) + [rmfarray.shape[rmfarray.ndim - 1]]
        return Matft.nums(0, shape: retshape, mftype: lmfarray.mftype)
    }

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
    
    //convert shape to calculate (the number of rows is given explicitly because -1 can't be inferred when lastdim is 0)
    let l_calcsize = l_mfarray.shape.dropLast().reduce(1, *)
    let l_mfarray = l_mfarray.reshape([l_calcsize, lastdim])
    let r_calcsize = r_mfarray.shape.dropLast().reduce(1, *)
    let r_mfarray = r_mfarray.reshape([r_calcsize, lastdim])
    
    let ret = Matft.nums(0, shape: [l_calcsize*r_calcsize], mftype: rettype)
    for lind in 0..<l_calcsize{
        for rind in 0..<r_calcsize{
            ret[lind*r_calcsize + rind] = (l_mfarray[lind] * r_mfarray[rind]).sum()
        }
    }
    
    return ret.reshape(retShape.count != 0 ? retShape : [1])
}



/// Compare two mfarrays in element-wise by comparing `l - r` with 0.
/// Note that `inf` vs `inf` gives `inf - inf = NaN`, so `==`, `>=` and `<=` return false for it.
fileprivate func _compare_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ op: MfCompareOp) -> MfArray{
    let (l_mfarray, r_mfarray, rettype, isReal) = biop_broadcast_to(l_mfarray, r_mfarray)
    guard isReal else {
        return compare_mfarray(l_mfarray - r_mfarray, op, 0)
    }
    // the difference must not wrap around (e.g. UInt8: 0 - 1 is -1, not 255)
    // and the same infinities must be equal (inf - inf is NaN)
    switch MfType.storedType(rettype){
    case .Float:
        let diff = biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsub)
        return compare_mfarray(fix_nonfinite_elements(l_mfarray, r_mfarray, diff, datatype: Float.self){ $0 == $1 ? 0 : $0 - $1 }, op, 0)
    case .Double:
        let diff = biopvv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsubD)
        return compare_mfarray(fix_nonfinite_elements(l_mfarray, r_mfarray, diff, datatype: Double.self){ $0 == $1 ? 0 : $0 - $1 }, op, 0)
    }
}

fileprivate func _equalAll_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> Bool{
    if l_mfarray.shape != r_mfarray.shape{
        return false
    }
    let diff = l_mfarray - r_mfarray
    
    // floating point: every |l - r| must be within the threshold. NaN is never equal
    switch diff.mftype {
    case .Float, .ComplexFloat:
        return maxmg_by_vDSP(diff) <= Double(thresholdF)
    case .Double, .ComplexDouble:
        return maxmg_by_vDSP(diff) <= thresholdD
    default:
        break
    }
    
    // integer and Bool: every difference must be 0 after conversion into the type,
    // which rounds and wraps around (e.g. -5 and 251 are the same UInt8)
    if maxmg_by_vDSP(diff) < 0.5{
        return true
    }
    func isZero(_ value: Any) -> Bool{
        if let value = value as? Bool{
            return !value
        }
        // only 0 has as many trailing zero bits as its bit width
        let value = value as! any BinaryInteger
        return value.trailingZeroBitCount == value.bitWidth
    }
    return diff.data.allSatisfy(isZero) && (diff.isReal || diff.data_imag!.allSatisfy(isZero))
}
