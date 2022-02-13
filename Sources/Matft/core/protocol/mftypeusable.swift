//
//  type.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/05.
//

import Foundation
import Accelerate

/// The type comformed to this protocol can use MfArray
public protocol MfTypeUsable: Equatable{
    associatedtype StoredType: MfStoredTypeUsable
    
    /// Return zero with this type
    static var zero: Self { get }
    
    /// Convert a given value into this type's one
    /// - Parameter value: The value comformed to MfInterger
    static func from<T: MfInterger>(_ value: T) -> Self
    
    /// Convert a given value into this type's one
    /// - Parameter value: The value comformed to MfFloatingPoint
    static func from<T: MfFloatingPoint>(_ value: T) -> Self
    
    /// Convert a given value into this type's one
    /// - Parameter value: The value comformed to MfBinary
    static func from<T: MfBinary>(_ value: T) -> Self
}

/// The numeric protocol for Matft
public protocol MfNumeric: Numeric, Strideable{}
/// The interger protocol for Matft
public protocol MfInterger: MfNumeric, BinaryInteger{}
/// The floating point protocol for Matft
public protocol MfFloatingPoint: MfNumeric, BinaryFloatingPoint{}
/// The binary (boolean) protocol for Matft
public protocol MfBinary: Equatable{
    /// Return zero with this type
    static var zero: Self { get }
}

/// The signed numeric protocol for Matft
public protocol MfSignedNumeric: SignedNumeric {}

/// The protocol to store raw data as Float type
public protocol StoredFloat: MfTypeUsable{
    associatedtype StoredType = Float
}
/// The protocol to store raw data as Double type
public protocol StoredDouble: MfTypeUsable{
    associatedtype StoredType = Double
}


extension UInt8: MfInterger, StoredFloat {
    public static func from<T>(_ value: T) -> UInt8 where T : MfInterger {
        return UInt8(value)
    }
    public static func from<T>(_ value: T) -> UInt8 where T : MfFloatingPoint {
        return UInt8(value)
    }
    public static func from<T>(_ value: T) -> UInt8 where T : MfBinary {
        return value != T.zero ? UInt8(1) : UInt8.zero
    }
}
extension UInt16: MfInterger, StoredFloat {
    public static func from<T>(_ value: T) -> UInt16 where T : MfInterger {
        return UInt16(value)
    }
    public static func from<T>(_ value: T) -> UInt16 where T : MfFloatingPoint {
        return UInt16(value)
    }
    public static func from<T>(_ value: T) -> UInt16 where T : MfBinary {
        return value != T.zero ? UInt16(1) : UInt16.zero
    }
}
extension UInt32: MfInterger, StoredDouble {
    public static func from<T>(_ value: T) -> UInt32 where T : MfInterger {
        return UInt32(value)
    }
    public static func from<T>(_ value: T) -> UInt32 where T : MfFloatingPoint {
        return UInt32(value)
    }
    public static func from<T>(_ value: T) -> UInt32 where T : MfBinary {
        return value != T.zero ? UInt32(1) : UInt32.zero
    }
}
extension UInt64: MfInterger, StoredDouble {
    public static func from<T>(_ value: T) -> UInt64 where T : MfInterger {
        return UInt64(value)
    }
    public static func from<T>(_ value: T) -> UInt64 where T : MfFloatingPoint {
        return UInt64(value)
    }
    public static func from<T>(_ value: T) -> UInt64 where T : MfBinary {
        return value != T.zero ? UInt64(1) : UInt64.zero
    }
}
extension UInt: MfInterger, StoredDouble {
    public static func from<T>(_ value: T) -> UInt where T : MfInterger {
        return UInt(value)
    }
    public static func from<T>(_ value: T) -> UInt where T : MfFloatingPoint {
        return UInt(value)
    }
    public static func from<T>(_ value: T) -> UInt where T : MfBinary {
        return value != T.zero ? UInt(1) : UInt.zero
    }
}

extension Int8: MfInterger, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int8 where T : MfInterger {
        return Int8(value)
    }
    public static func from<T>(_ value: T) -> Int8 where T : MfFloatingPoint {
        return Int8(value)
    }
    public static func from<T>(_ value: T) -> Int8 where T : MfBinary {
        return value != T.zero ? Int8(1) : Int8.zero
    }
}
extension Int16: MfInterger, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int16 where T : MfInterger {
        return Int16(value)
    }
    public static func from<T>(_ value: T) -> Int16 where T : MfFloatingPoint {
        return Int16(value)
    }
    public static func from<T>(_ value: T) -> Int16 where T : MfBinary {
        return value != T.zero ? Int16(1) : Int16.zero
    }
}
extension Int32: MfInterger, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int32 where T : MfInterger {
        return Int32(value)
    }
    public static func from<T>(_ value: T) -> Int32 where T : MfFloatingPoint {
        return Int32(value)
    }
    public static func from<T>(_ value: T) -> Int32 where T : MfBinary {
        return value != T.zero ? Int32(1) : Int32.zero
    }
}

extension Int64: MfInterger, StoredDouble, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int64 where T : MfInterger {
        return Int64(value)
    }
    public static func from<T>(_ value: T) -> Int64 where T : MfFloatingPoint {
        return Int64(value)
    }
    public static func from<T>(_ value: T) -> Int64 where T : MfBinary {
        return value != T.zero ? Int64(1) : Int64.zero
    }
}
extension Int: MfInterger, StoredFloat, MfSignedNumeric {
    public static func from<T>(_ value: T) -> Int where T : MfInterger {
        return Int(value)
    }
    public static func from<T>(_ value: T) -> Int where T : MfFloatingPoint {
        return Int(value)
    }
    public static func from<T>(_ value: T) -> Int where T : MfBinary {
        return value != T.zero ? Int(1) : Int.zero
    }
}


extension Float: MfNumeric, StoredFloat, MfSignedNumeric, MfStoredTypeUsable {
    //======= vDSP ========//
    public static var vDSP_neg_func: vDSP_convert_func<Float, Float> = vDSP_vneg
    
    public static var vDSP_addvv_func: vDSP_biopvv_func<Float> = vDSP_vadd
    public static var vDSP_subvv_func: vDSP_biopvv_func<Float> = vDSP_vsub
    public static var vDSP_mulvv_func: vDSP_biopvv_func<Float> = vDSP_vmul
    public static var vDSP_divvv_func: vDSP_biopvv_func<Float> = vDSP_vdiv
    
    public static var vDSP_addvs_func: vDSP_biopvs_func<Float> = vDSP_vsadd
    public static var vDSP_mulvs_func: vDSP_biopvs_func<Float> = vDSP_vsmul
    public static var vDSP_divvs_func: vDSP_biopvs_func<Float> = vDSP_vsdiv
    public static var vDSP_divsv_func: vDSP_biopsv_func<Float> = vDSP_svdiv
    
    public static var vDSP_minimum_func: vDSP_biopvv_func<Float> = vDSP_vmin
    public static var vDSP_maximum_func: vDSP_biopvv_func<Float> = vDSP_vmax
    
    public static var vDSP_vcmprs_func: vDSP_vcmprs_func<Float> = vDSP_vcmprs
    public static var vDSP_vgathr_func: vDSP_vgathr_func<Float> = vDSP_vgathr
    
    public static var vDSP_vminmg_func: vDSP_vminmg_func<Float> = vDSP_vminmg
    public static var vDSP_viclip_func: vDSP_viclip_func<Float> = vDSP_viclip
    public static var vDSP_clip_func: vDSP_clip_func<Float> = vDSP_vclipc
    
    public static var vDSP_sort_func: vDSP_sort_func<Float> = vDSP_vsort
    public static var vDSP_argsort_func: vDSP_argsort_func<Float> = vDSP_vsorti
    
    public static var vDSP_mean_func: vDSP_stats_func<Float> = vDSP_meanv
    public static var vDSP_sum_func: vDSP_stats_func<Float> = vDSP_sve
    public static var vDSP_sqsum_func: vDSP_stats_func<Float> = vDSP_svesq
    
    public static var vDSP_min_func: vDSP_stats_func<Float> = vDSP_minv
    public static var vDSP_max_func: vDSP_stats_func<Float> = vDSP_maxv
    public static var vDSP_mini_func: vDSP_stats_index_func<Float> = vDSP_minvi
    public static var vDSP_maxi_func: vDSP_stats_index_func<Float> = vDSP_maxvi
    
    
    public static var vDSP_square_func: vDSP_math_func<Float, Float> = vDSP_vsq
    
    //======= cblas ========//
    public static var cblas_copy_func: cblas_copy_func<Float> = cblas_scopy
    
    public static var cblas_matmul_func: cblas_matmul_func<Float> = cblas_sgemm
    
    //======= vForce ========//
    public static var vForce_sin_func: vForce_math_func<Float> = vvsinf
    public static var vForce_asin_func: vForce_math_func<Float> = vvasinf
    public static var vForce_sinh_func: vForce_math_func<Float> = vvsinhf
    public static var vForce_asinh_func: vForce_math_func<Float> = vvasinhf
    public static var vForce_cos_func: vForce_math_func<Float> = vvcosf
    public static var vForce_acos_func: vForce_math_func<Float> = vvacosf
    public static var vForce_cosh_func: vForce_math_func<Float> = vvcoshf
    public static var vForce_acosh_func: vForce_math_func<Float> = vvacoshf
    public static var vForce_tan_func: vForce_math_func<Float> = vvtanf
    public static var vForce_atan_func: vForce_math_func<Float> = vvatanf
    public static var vForce_tanh_func: vForce_math_func<Float> = vvtanhf
    public static var vForce_atanh_func: vForce_math_func<Float> = vvtanhf
    
    public static var vForce_sqrt_func: vForce_math_func<Float> = vvsqrtf
    public static var vForce_rsqrt_func: vForce_math_func<Float> = vvrsqrtf
    public static var vForce_exp_func: vForce_math_func<Float> = vvexpf
    public static var vForce_log_func: vForce_math_func<Float> = vvlogf
    public static var vForce_log2_func: vForce_math_func<Float> = vvlog2f
    public static var vForce_log10_func: vForce_math_func<Float> = vvlog10f
    
    public static var vForce_ceil_func: vForce_math_func<Float> = vvceilf
    public static var vForce_floor_func: vForce_math_func<Float> = vvfloorf
    public static var vForce_trunc_func: vForce_math_func<Float> = vvintf
    public static var vForce_nearest_func: vForce_math_func<Float> = vvnintf
    
    public static var vForce_copysign_func: vForce_copysign_func<Float> = vvcopysignf
    public static var vForce_abs_func: vForce_math_func<Float> = vvfabsf
    public static var vForce_reciprocal_func: vForce_math_func<Float> = vvrecf
    
    public static var vForce_power_func: vForce_math_biop_func<Float> = vvpowf
    
    public static func from<T>(_ value: T) -> Float where T : MfInterger {
        return Float(value)
    }
    public static func from<T>(_ value: T) -> Float where T : MfFloatingPoint {
        return Float(value)
    }
    public static func from<T>(_ value: T) -> Float where T : MfBinary {
        return value != T.zero ? Float(1) : Float.zero
    }
    
    public static func from<T: MfTypeUsable>(_ value: T) -> Float{
        switch value {
        case is UInt8:
            return Float(value as! UInt8)
        case is UInt16:
            return Float(value as! UInt16)
        case is UInt32:
            return Float(value as! UInt32)
        case is UInt64:
            return Float(value as! UInt64)
        case is UInt:
            return Float(value as! UInt)
        case is Int8:
            return Float(value as! Int8)
        case is Int16:
            return Float(value as! Int16)
        case is Int32:
            return Float(value as! Int32)
        case is Int64:
            return Float(value as! Int64)
        case is Int:
            return Float(value as! Int)
        case is Float:
            return value as! Float
        case is Double:
            return Float(value as! Double)
        default:
            fatalError("cannot convert value to Float")
        }
    }
    
    public static func nealy_equal(_ lhs: Float, _ rhs: Float) -> Bool{
        return fabsf(lhs - rhs) < 1e-5
    }
}
extension Double: MfNumeric, StoredDouble, MfSignedNumeric, MfStoredTypeUsable {
    //======= vDSP ========//
    public static var vDSP_neg_func: vDSP_convert_func<Double, Double> = vDSP_vnegD
    
    public static var vDSP_addvv_func: vDSP_biopvv_func<Double> = vDSP_vaddD
    public static var vDSP_subvv_func: vDSP_biopvv_func<Double> = vDSP_vsubD
    public static var vDSP_mulvv_func: vDSP_biopvv_func<Double> = vDSP_vmulD
    public static var vDSP_divvv_func: vDSP_biopvv_func<Double> = vDSP_vdivD
    
    public static var vDSP_addvs_func: vDSP_biopvs_func<Double> = vDSP_vsaddD
    public static var vDSP_mulvs_func: vDSP_biopvs_func<Double> = vDSP_vsmulD
    public static var vDSP_divvs_func: vDSP_biopvs_func<Double> = vDSP_vsdivD
    public static var vDSP_divsv_func: vDSP_biopsv_func<Double> = vDSP_svdivD
    
    public static var vDSP_minimum_func: vDSP_biopvv_func<Double> = vDSP_vminD
    public static var vDSP_maximum_func: vDSP_biopvv_func<Double> = vDSP_vmaxD
    
    public static var vDSP_vcmprs_func: vDSP_vcmprs_func<Double> = vDSP_vcmprsD
    public static var vDSP_vgathr_func: vDSP_vgathr_func<Double> = vDSP_vgathrD
    
    public static var vDSP_vminmg_func: vDSP_vminmg_func<Double> = vDSP_vminmgD
    public static var vDSP_viclip_func: vDSP_viclip_func<Double> = vDSP_viclipD
    public static var vDSP_clip_func: vDSP_clip_func<Double> = vDSP_vclipcD
    
    public static var vDSP_sort_func: vDSP_sort_func<Double> = vDSP_vsortD
    public static var vDSP_argsort_func: vDSP_argsort_func<Double> = vDSP_vsortiD
    
    public static var vDSP_mean_func: vDSP_stats_func<Double> = vDSP_meanvD
    public static var vDSP_sum_func: vDSP_stats_func<Double> = vDSP_sveD
    public static var vDSP_sqsum_func: vDSP_stats_func<Double> = vDSP_svesqD
    
    public static var vDSP_min_func: vDSP_stats_func<Double> = vDSP_minvD
    public static var vDSP_max_func: vDSP_stats_func<Double> = vDSP_maxvD
    public static var vDSP_mini_func: vDSP_stats_index_func<Double> = vDSP_minviD
    public static var vDSP_maxi_func: vDSP_stats_index_func<Double> = vDSP_maxviD
    
    public static var vDSP_square_func: vDSP_math_func<Double, Double> = vDSP_vsqD
    
    //======= cblas ========//
    public static var cblas_copy_func: cblas_copy_func<Double> = cblas_dcopy
    
    public static var cblas_matmul_func: cblas_matmul_func<Double> = cblas_dgemm
    
    //======= vForce ========//
    public static var vForce_sin_func: vForce_math_func<Double> = vvsin
    public static var vForce_asin_func: vForce_math_func<Double> = vvasin
    public static var vForce_sinh_func: vForce_math_func<Double> = vvsinh
    public static var vForce_asinh_func: vForce_math_func<Double> = vvasinh
    public static var vForce_cos_func: vForce_math_func<Double> = vvcos
    public static var vForce_acos_func: vForce_math_func<Double> = vvacos
    public static var vForce_cosh_func: vForce_math_func<Double> = vvcosh
    public static var vForce_acosh_func: vForce_math_func<Double> = vvacosh
    public static var vForce_tan_func: vForce_math_func<Double> = vvtan
    public static var vForce_atan_func: vForce_math_func<Double> = vvatan
    public static var vForce_tanh_func: vForce_math_func<Double> = vvtanh
    public static var vForce_atanh_func: vForce_math_func<Double> = vvtanh
    
    public static var vForce_sqrt_func: vForce_math_func<Double> = vvsqrt
    public static var vForce_rsqrt_func: vForce_math_func<Double> = vvrsqrt
    public static var vForce_exp_func: vForce_math_func<Double> = vvexp
    public static var vForce_log_func: vForce_math_func<Double> = vvlog
    public static var vForce_log2_func: vForce_math_func<Double> = vvlog2
    public static var vForce_log10_func: vForce_math_func<Double> = vvlog10
    
    public static var vForce_ceil_func: vForce_math_func<Double> = vvceil
    public static var vForce_floor_func: vForce_math_func<Double> = vvfloor
    public static var vForce_trunc_func: vForce_math_func<Double> = vvint
    public static var vForce_nearest_func: vForce_math_func<Double> = vvnint
    
    public static var vForce_copysign_func: vForce_copysign_func<Double> = vvcopysign
    public static var vForce_abs_func: vForce_math_func<Double> = vvfabs
    public static var vForce_reciprocal_func: vForce_math_func<Double> = vvrec
    
    public static var vForce_power_func: vForce_math_biop_func<Double> = vvpow
    
    public static func from<T>(_ value: T) -> Double where T : MfInterger {
        return Double(value)
    }
    public static func from<T>(_ value: T) -> Double where T : MfFloatingPoint {
        return Double(value)
    }
    public static func from<T>(_ value: T) -> Double where T : MfBinary {
        return value != T.zero ? Double(1) : Double.zero
    }
    public static func from<T: MfTypeUsable>(_ value: T) -> Double{
        switch value {
        case is UInt8:
            return Double(value as! UInt8)
        case is UInt16:
            return Double(value as! UInt16)
        case is UInt32:
            return Double(value as! UInt32)
        case is UInt64:
            return Double(value as! UInt64)
        case is UInt:
            return Double(value as! UInt)
        case is Int8:
            return Double(value as! Int8)
        case is Int16:
            return Double(value as! Int16)
        case is Int32:
            return Double(value as! Int32)
        case is Int64:
            return Double(value as! Int64)
        case is Int:
            return Double(value as! Int)
        case is Float:
            return Double(value as! Float)
        case is Double:
            return value as! Double
        default:
            fatalError("cannot convert value to Double")
        }
    }
    
    public static func nealy_equal(_ lhs: Double, _ rhs: Double) -> Bool{
        return fabs(lhs - rhs) < 1e-10
    }
}

extension Bool: MfBinary, StoredFloat {
    public static func from<T>(_ value: T) -> Bool where T : MfInterger {
        return value != T.zero
    }
    public static func from<T>(_ value: T) -> Bool where T : MfFloatingPoint {
        return value != T.zero
    }
    public static func from<T>(_ value: T) -> Bool where T : MfBinary {
        return value != T.zero ? true : false
    }
    public static var zero: Bool {
        return false
    }
}
