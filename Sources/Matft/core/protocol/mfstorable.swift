//
//  File.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

/// The type comformed to this protocol can use MfArray
public protocol MfStoredTypeUsable: FloatingPoint{
    static func from<T: MfTypeUsable>(_ value: T) -> Self
    static func nealy_equal(_ lhs: Self, _ rhs: Self) -> Bool
    
    //======= vDSP ========//
    static var vDSP_neg_func: vDSP_convert_func<Self, Self>{ get }
    
    static var vDSP_addvv_func: vDSP_biopvv_func<Self>{ get }
    static var vDSP_subvv_func: vDSP_biopvv_func<Self>{ get }
    static var vDSP_mulvv_func: vDSP_biopvv_func<Self>{ get }
    static var vDSP_divvv_func: vDSP_biopvv_func<Self>{ get }
    
    static var vDSP_addvs_func: vDSP_biopvs_func<Self>{ get }
    static var vDSP_mulvs_func: vDSP_biopvs_func<Self>{ get }
    static var vDSP_divvs_func: vDSP_biopvs_func<Self>{ get }
    static var vDSP_divsv_func: vDSP_biopsv_func<Self>{ get }
    
    static var vDSP_vcmprs_func: vDSP_vcmprs_func<Self>{ get }
    
    static var vDSP_vminmg_func: vDSP_vminmg_func<Self>{ get }
    static var vDSP_viclip_func: vDSP_viclip_func<Self>{ get }
    static var vDSP_clip_func: vDSP_clip_func<Self>{ get }
    
    static var vDSP_sort_func: vDSP_sort_func<Self>{ get }
    static var vDSP_argsort_func: vDSP_argsort_func<Self>{ get }
    
    static var vDSP_mean_func: vDSP_stats_func<Self>{ get }
    static var vDSP_sum_func: vDSP_stats_func<Self>{ get }
    static var vDSP_sqsum_func: vDSP_stats_func<Self>{ get }
    
    //======= cblas ========//
    static var cblas_copy_func: cblas_copy_func<Self>{ get }
    
    //======= vForce ========//
    static var vForce_sin_func: vForce_math_func<Self>{ get }
    static var vForce_asin_func: vForce_math_func<Self>{ get }
    static var vForce_sinh_func: vForce_math_func<Self>{ get }
    static var vForce_asinh_func: vForce_math_func<Self>{ get }
    static var vForce_cos_func: vForce_math_func<Self>{ get }
    static var vForce_acos_func: vForce_math_func<Self>{ get }
    static var vForce_cosh_func: vForce_math_func<Self>{ get }
    static var vForce_acosh_func: vForce_math_func<Self>{ get }
    static var vForce_tan_func: vForce_math_func<Self>{ get }
    static var vForce_atan_func: vForce_math_func<Self>{ get }
    static var vForce_tanh_func: vForce_math_func<Self>{ get }
    static var vForce_atanh_func: vForce_math_func<Self>{ get }
    
    static var vForce_sqrt_func: vForce_math_func<Self>{ get }
    static var vForce_rsqrt_func: vForce_math_func<Self>{ get }
    static var vForce_exp_func: vForce_math_func<Self>{ get }
    static var vForce_log_func: vForce_math_func<Self>{ get }
    static var vForce_log2_func: vForce_math_func<Self>{ get }
    static var vForce_log10_func: vForce_math_func<Self>{ get }
    
    static var vForce_copysign_func: vForce_copysign_func<Self>{ get }
    static var vForce_abs_func: vForce_math_func<Self>{ get }
}
