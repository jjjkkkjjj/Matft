//
//  math+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension Matft.math{ // vForce
    
    //
    //================ trigonometric ================//
    //
    //================ sin ================//
    /// Calculate the sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: sin mfarray
    public static func sin<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_sin_func)
    }
    
    /// Calculate the arcsin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arcsin mfarray
    public static func asin<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_asin_func)
    }
    
    /// Calculate the hyperbolic sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic sin mfarray
    public static func sinh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_sinh_func)
    }
    
    /// Calculate the hyperbolic sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic sin mfarray
    public static func asinh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_asinh_func)
    }
    
    //================ cos ================//
    /// Calculate the cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: cos mfarray
    public static func cos<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_cos_func)
    }
    
    /// Calculate the arccos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arccos mfarray
    public static func acos<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_acos_func)
    }
    
    /// Calculate the hyperbolic cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic cos mfarray
    public static func cosh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_cosh_func)
    }
    
    /// Calculate the hyperbolic cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic cos mfarray
    public static func acosh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_acosh_func)
    }
    
    //================ tan ================//
    /// Calculate the tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: tan mfarray
    public static func tan<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_tan_func)
    }
    
    /// Calculate the arctan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arctan mfarray
    public static func atan<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_atan_func)
    }
    
    /// Calculate the hyperbolic tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic tan mfarray
    public static func tanh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_tanh_func)
    }
    
    /// Calculate the hyperbolic tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic tan mfarray
    public static func atanh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_atanh_func)
    }
    
    //
    //================ power ================//
    //
    /// Calculate the sqrt for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: sqrt mfarray
    public static func sqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_sqrt_func)
    }
    
    /// Calculate the rsqrt for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: rsqrt mfarray
    public static func rsqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_rsqrt_func)
    }
    
    /// Calculate the exp for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: exp mfarray
    public static func exp<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_exp_func)
    }
    
    /// Calculate the log for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log mfarray
    public static func log<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_log_func)
    }
    
    /// Calculate the log2 for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log2 mfarray
    public static func log2<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_log2_func)
    }
    
    /// Calculate the log10 for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log10 mfarray
    public static func log10<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_log10_func)
    }
    
    //
    //================ approximation ================//
    //
    /// Calculate the ceil for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: ceil mfarray
    public static func ceil<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int> where T.StoredType == Float{
        return math_by_vForce(mfarray, Int.StoredType.vForce_ceil_func)
    }
    /// Calculate the ceil for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: ceil mfarray
    public static func ceil<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int64> where T.StoredType == Double{
        return math_by_vForce(mfarray, Int64.StoredType.vForce_ceil_func)
    }
    
    /// Calculate the floor for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: floor mfarray
    public static func floor<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int> where T.StoredType == Float{
        return math_by_vForce(mfarray, Int.StoredType.vForce_floor_func)
    }
    /// Calculate the floor for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: floor mfarray
    public static func floor<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int64> where T.StoredType == Double{
        return math_by_vForce(mfarray, Int64.StoredType.vForce_floor_func)
    }
    
    /// Calculate the trunc for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: trunc mfarray
    public static func trunc<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int> where T.StoredType == Float{
        return math_by_vForce(mfarray, Int.StoredType.vForce_trunc_func)
    }
    /// Calculate the trunc for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: trunc mfarray
    public static func trunc<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int64> where T.StoredType == Double{
        return math_by_vForce(mfarray, Int64.StoredType.vForce_trunc_func)
    }
    
    /// Calculate the nearest for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: nearest mfarray
    public static func nearest<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int> where T.StoredType == Float{
        return math_by_vForce(mfarray, Int.StoredType.vForce_nearest_func)
    }
    /// Calculate the nearest for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: nearest mfarray
    public static func nearest<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Int64> where T.StoredType == Double{
        return math_by_vForce(mfarray, Int64.StoredType.vForce_nearest_func)
    }
    
    /// Calculate the round for all elements
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - decimals: (Optional) Int, default is 0, which is equivelent to nearest
    /// - Returns: round mfarray
    public static func round<T: MfTypeUsable>(_ mfarray: MfArray<T>, decimals: Int = 0) -> MfArray<T.StoredType>{
        let powval = T.StoredType.from(pow(10, Double(decimals)))
        return round_by_vForce(mfarray, decimals: decimals, powval: powval)
    }
    
    //
    //================ basic ================//
    //
    /// Calculate the absolute value for all elements
    /// - Parameters:
    ///   - mfarray: An input mfarray
    /// - Returns: abs mfarray
    public static func abs<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_abs_func)
    }
    
    /// Calculate the reciprocal value for all elements
    /// - Parameters:
    ///   - mfarray: An input mfarray
    /// - Returns: abs mfarray
    public static func reciprocal<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T.StoredType>{
        return mathf_by_vForce(mfarray, T.StoredType.vForce_reciprocal_func)
    }
    
    
    /// Calculate the power value for all elements
    /// - Parameters:
    ///   - bases: An input bases value
    ///   - exponents: An input exponents mfarray
    /// - Returns: powered mfarray
    public static func power<T: MfTypeUsable>(bases: T, exponents: MfArray<T>) -> MfArray<T>{
        return Matft.math.power(bases: Matft.nums(bases, shape: [1]), exponents: exponents)
    }
    /// Calculate the power value for all elements
    /// - Parameters:
    ///   - bases: An input bases mfarray
    ///   - exponents: An input exponents value
    /// - Returns: powered mfarray
    public static func power<T: MfTypeUsable>(bases: MfArray<T>, exponents: T) -> MfArray<T>{
        return Matft.math.power(bases: bases, exponents: Matft.nums(exponents, shape: [1]))
    }
    /// Calculate the power value for all elements
    /// - Parameters:
    ///   - bases: An input bases mfarray
    ///   - exponents: An input exponents mfarray
    /// - Returns: powered mfarray
    public static func power<T: MfTypeUsable>(bases: MfArray<T>, exponents: MfArray<T>) -> MfArray<T>{
        let (bases, exponents) = biop_broadcast_to(bases, exponents)
        return math_biop_by_vForce(exponents, bases, T.StoredType.vForce_power_func)
    }
}

extension Matft.math{ // vDSP

    /// Calculate squared mfarray
    /// - Parameter mfarray: An input mfarray
    /// - Returns: The squared mfarray
    public static func square<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        return math_by_vDSP(mfarray, T.StoredType.vDSP_square_func)
    }
    
    /// Calculate sign of mfarray
    /// - Parameter mfarray: An input mfarray
    /// - Returns: The result mfarray
    public static func sign<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        return sign_by_vDSP(mfarray)
    }
}
