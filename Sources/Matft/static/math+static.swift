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
    public static func sin<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_sin_func)
    }
    /// Calculate the sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: sin mfarray
    public static func sin<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_sin_func)
    }
    
    /// Calculate the arcsin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arcsin mfarray
    public static func asin<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_asin_func)
    }
    /// Calculate the arcsin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arcsin mfarray
    public static func asin<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_asin_func)
    }
    
    /// Calculate the hyperbolic sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic sin mfarray
    public static func sinh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_sinh_func)
    }
    /// Calculate the hyperbolic sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic sin mfarray
    public static func sinh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_sinh_func)
    }
    
    /// Calculate the hyperbolic sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic sin mfarray
    public static func asinh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_asinh_func)
    }
    /// Calculate the arc hyperbolic sin for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arc hyperbolic sin mfarray
    public static func asinh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_asinh_func)
    }
    
    //================ cos ================//
    /// Calculate the cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: cos mfarray
    public static func cos<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_cos_func)
    }
    /// Calculate the cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: cos mfarray
    public static func cos<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_cos_func)
    }
    
    /// Calculate the arccos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arccos mfarray
    public static func acos<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_acos_func)
    }
    /// Calculate the arccos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arccos mfarray
    public static func acos<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_acos_func)
    }
    
    /// Calculate the hyperbolic cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic cos mfarray
    public static func cosh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_cosh_func)
    }
    /// Calculate the hyperbolic cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic cos mfarray
    public static func cosh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_cosh_func)
    }
    
    /// Calculate the hyperbolic cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic cos mfarray
    public static func acosh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_acosh_func)
    }
    /// Calculate the arc hyperbolic cos for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arc hyperbolic cos mfarray
    public static func acosh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_acosh_func)
    }
    
    //================ tan ================//
    /// Calculate the tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: tan mfarray
    public static func tan<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_tan_func)
    }
    /// Calculate the tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: tan mfarray
    public static func tan<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_tan_func)
    }
    
    /// Calculate the arctan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arctan mfarray
    public static func atan<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_atan_func)
    }
    /// Calculate the arctan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arctan mfarray
    public static func atan<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_atan_func)
    }
    
    /// Calculate the hyperbolic tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic tan mfarray
    public static func tanh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_tanh_func)
    }
    /// Calculate the hyperbolic tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic tan mfarray
    public static func tanh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_tanh_func)
    }
    
    /// Calculate the hyperbolic tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: hyperbolic tan mfarray
    public static func atanh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_atanh_func)
    }
    /// Calculate the arc hyperbolic tan for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: arc hyperbolic tan mfarray
    public static func atanh<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_atanh_func)
    }
    
    //
    //================ power ================//
    //
    /// Calculate the sqrt for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: sqrt mfarray
    public static func sqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_sqrt_func)
    }
    /// Calculate the sqrt for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: sqrt mfarray
    public static func sqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_sqrt_func)
    }
    
    /// Calculate the rsqrt for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: rsqrt mfarray
    public static func rsqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_rsqrt_func)
    }
    /// Calculate the rsqrt for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: rsqrt mfarray
    public static func rsqrt<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_rsqrt_func)
    }
    
    /// Calculate the exp for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: exp mfarray
    public static func exp<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_exp_func)
    }
    /// Calculate the exp for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: exp mfarray
    public static func exp<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_exp_func)
    }
    
    /// Calculate the log for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log mfarray
    public static func log<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_log_func)
    }
    /// Calculate the log for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log mfarray
    public static func log<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_log_func)
    }
    
    /// Calculate the log2 for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log2 mfarray
    public static func log2<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_log2_func)
    }
    /// Calculate the log2 for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log2 mfarray
    public static func log2<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_log2_func)
    }
    
    /// Calculate the log10 for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log10 mfarray
    public static func log10<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Float> where T.StoredType == Float{
        return math_vv_by_vForce(mfarray, Float.StoredType.vForce_log10_func)
    }
    /// Calculate the log10 for all elements
    /// - Parameter mfarray: An input mfarray
    /// - Returns: log10 mfarray
    public static func log10<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<Double> where T.StoredType == Double{
        return math_vv_by_vForce(mfarray, Double.StoredType.vForce_log10_func)
    }
    
    //
    //================ approximation ================//
    //
    
}

extension Matft.math{ // vDSP

    /// Calculate sign of mfarray
    /// - Parameter mfarray: An input mfarray
    /// - Returns: The result mfarray
    public static func sign<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        return sign_by_vDSP(mfarray)
    }
}
