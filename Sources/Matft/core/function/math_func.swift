//
//  math.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate
/*
//ref https://developer.apple.com/documentation/accelerate/veclib/vforce
/*
internal protocol mathProtocol{
    associatedtype StoredType: MfStorable
    associatedtype RetType: MfTypable
    static var vForce_sin_func: vForce_vv_func<StoredType> { get }
    static func sin<T>(_ mfarray: MfArray<T>) -> MfArray<RetType> where T: MfTypable
}
extension mathProtocol{
    static func sin<T>(_ mfarray: MfArray<T>) -> MfArray<RetType> where T: MfTypable{
        let ret: MfArray<RetType> = math_vv_by_vForce(mfarray, Self.vForce_sin_func)
        return ret
    }
}

extension Matft.math: mathProtocol{}

extension Matft.math{
    typealias StoredType = Float
    typealias RetType = Float
    static var vForce_sin_func: vForce_vv_func<Float> = vvsinf
    
    static func sin<T>(_ mfarray: MfArray<T>) -> MfArray<RetType> where T: StoredFloat
}
extension Matft.math{
    typealias StoredType = Double
    typealias RetType = Double
    static var vForce_sin_func: vForce_vv_func<Double> = vvsin
}
*/
extension Matft.math{
    
    //use math_vv_by_vecLib
    //
    // trigonometric
    //
    /**
       Calculate the sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func sin<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvsinf)
    }
    public static func sin<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvsin)
    }
    /**
       Calculate the arcsin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func asin<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvasinf)
    }
    public static func asin<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvasin)
    }
    /**
       Calculate the hyperbolic sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func sinh<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvsinhf)
    }
    public static func sinh<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvsinh)
    }
    /**
       Calculate the archyperbolic sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func asinh<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvasinhf)
    }
    public static func asinh<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvasinh)
    }
    /**
       Calculate the cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func cos<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvcosf)
    }
    public static func cos<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvcos)
    }
    /**
       Calculate the arccos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func acos<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvacosf)
    }
    public static func acos<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvacos)
    }
    /**
       Calculate the hyperbolic cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func cosh<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvcoshf)
    }
    public static func cosh<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvcosh)
    }
    /**
       Calculate the arc hyperbolic cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func acosh<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvacoshf)
    }
    public static func acosh<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvacosh)
    }
    /**
       Calculate the tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func tan<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvtanf)
    }
    public static func tan<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvtan)
    }
    /**
       Calculate the arctan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func atan<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvatanf)
    }
    public static func atan<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvatan)
    }
    /**
       Calculate the hyperbolic tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func tanh<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvtanhf)
    }
    public static func tanh<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvtanh)
    }
    /**
       Calculate the arc hyperbolic tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func atanh<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvatanhf)
    }
    public static func atanh<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvatanh)
    }
    
    
    //
    // power
    //
    /**
       Return the square root of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func sqrt<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvsqrtf)
    }
    public static func sqrt<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvsqrt)
    }
    /**
       Return the reciprocal square root of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func rsqrt<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvrsqrtf)
    }
    public static func rsqrt<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvrsqrt)
    }
    /**
       Calculate the exponetial for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func exp<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvexpf)
    }
    public static func exp<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvexp)
    }
    /**
       Calculate the natural log for all elements. i.e. log_e X
       - parameters:
            - mfarray: mfarray
    */
    public static func log<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvlogf)
    }
    public static func log<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvlog)
    }
    /**
       Calculate the base 2 log for all elements. i.e. log_2 X
       - parameters:
            - mfarray: mfarray
    */
    public static func log2<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvlog2f)
    }
    public static func log2<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvlog2)
    }
    /**
       Calculate the base 10 log for all elements. i.e. log_10 X
       - parameters:
            - mfarray: mfarray
    */
    public static func log10<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvlog10f)
    }
    public static func log10<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvlog10)
    }
    
    
    //
    // approximation
    //
    /**
       Return the ceiling of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func ceil<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Int32>{
        return math_vv_by_vForce(mfarray, vvceilf)
    }
    public static func ceil<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Int64>{
        return math_vv_by_vForce(mfarray, vvceil)
    }
    /**
       Return the floor of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func floor<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Int32>{
        return math_vv_by_vForce(mfarray, vvfloorf)
    }
    public static func floor<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Int64>{
        return math_vv_by_vForce(mfarray, vvfloor)
    }
    /**
       Return the interfer truncation of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func trunc<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Int32>{
        return math_vv_by_vForce(mfarray, vvintf)
    }
    public static func trunc<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Int64>{
        return math_vv_by_vForce(mfarray, vvint)
    }
    /**
       Return the nearest interfer of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func nearest<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Int32>{
        return math_vv_by_vForce(mfarray, vvnintf)
    }
    public static func nearest<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Int64>{
        return math_vv_by_vForce(mfarray, vvnint)
    }
    /**
          Return the round give by number of decimals of each element
          - parameters:
            - decimals: (Optional) Int, default is 0, which is equivelent to nearest
    */
    public static func round<T: StoredFloat>(_ mfarray: MfArray<T>, decimals: Int = 0) -> MfArray<Int32>{
        let pow = Int32(powf(10, Float(decimals)))
        let n: MfArray<Int32> =  math_vv_by_vForce(mfarray * pow, vvnintf)
        return n / pow
    }
    public static func round<T: StoredDouble>(_ mfarray: MfArray<T>, decimals: Int = 0) -> MfArray<Int64>{
        let pow = Int64(powf(10, Float(decimals)))
        let n: MfArray<Int64> =  math_vv_by_vForce(mfarray * pow, vvnintf)
        return n / pow
    }
    
    //
    // basic function
    //
    /**
       Return the absolute value of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func abs<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvfabsf)
    }
    public static func abs<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvfabs)
    }
    /**
       Return the reciprocal value of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func reciprocal<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Float>{
        return math_vv_by_vForce(mfarray, vvrecf)
    }
    public static func reciprocal<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Double>{
        return math_vv_by_vForce(mfarray, vvrec)
    }
}

extension Matft.math{//use math_vv_by_vecLib
    /**
       Calculate power of each element
       - parameters:
            - base: Float
            - exponents: mfarray
    */
    public static func power<T: MfNumeric>(base: T, exponents: MfArray<T>) -> MfArray<T>{
        return Matft.math.power(bases: Matft.nums(base, shape: [1]), exponents: exponents)
    }
    /**
       Calculate power of each element
       - parameters:
            - bases: mfarray
            - exponent: Float
    */
    public static func power<T: MfNumeric>(bases: MfArray<T>, exponent: T) -> MfArray<T>{
        return Matft.math.power(bases: bases, exponents: Matft.nums(exponent, shape: [1]))
    }
    /**
       Calculate power of each element
       - parameters:
            - base: mfarray
            - exponents: mfarray
    */
    public static func power<T: MfNumeric>(bases: MfArray<T>, exponents: MfArray<T>) -> MfArray<T>{
        let (bases, exponents) = biop_broadcast_to(bases, exponents)
        
        switch MfType.storedType(T.self) {
        case .Float:
            return math_biop_vv_by_vForce(exponents, bases, vvpowf)
        case .Double:
            return math_biop_vv_by_vForce(exponents, bases, vvpow)
        }
    }
}

extension Matft.math{//use vDSP
    /**
       Calculate squared MfArray
       - parameters:
            - mfarray: mfarray
    */
    public static func square<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            return math_by_vDSP(mfarray, vDSP_vsq)
        case .Double:
            return math_by_vDSP(mfarray, vDSP_vsqD)
        }
    }
    
    /**
       Calculate signed MfArray
       - parameters:
            - mfarray: mfarray
    */
    public static func sign<T: StoredFloat>(_ mfarray: MfArray<T>) -> MfArray<Int32>{
        let ssq: MfArray<Float> = math_by_vDSP(mfarray, vDSP_vssq)
        let sq: MfArray<Float> = Matft.math.square(mfarray)
        return (ssq / sq).nearest()
    }
    public static func reciprocal<T: StoredDouble>(_ mfarray: MfArray<T>) -> MfArray<Int64>{
        return math_vv_by_vForce(mfarray, vvrec)
    }
    public static func sign<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        var ssq: MfArray<T> // signed squared values
        switch mfarray.storedType {
        case .Float:
            ssq = math_by_vDSP(mfarray, vDSP_vssq)
        case .Double:
            ssq = math_by_vDSP(mfarray, vDSP_vssqD)
        }

        return (ssq / Matft.math.square(mfarray)).nearest()
    }
}
*/
