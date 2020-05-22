//
//  math.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

//ref https://developer.apple.com/documentation/accelerate/veclib/vforce

extension Matft.math{//use math_vv_by_vecLib
    //
    // trigonometric
    //
    /**
       Calculate the sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func sin<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvsinf)
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvsin)
            return ret
        }
    }
    /**
       Calculate the arcsin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func asin<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvasinf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvasin)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the hyperbolic sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func sinh<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvsinhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvsinh)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the archyperbolic sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func asinh<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvasinhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvasinh)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func cos<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvcosf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvcos)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the arccos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func acos<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvacosf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvacos)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the hyperbolic cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func cosh<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvcoshf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvcosh)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the arc hyperbolic cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func acosh<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvacoshf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvacosh)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func tan<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvtanf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvtan)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the arctan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func atan<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvatanf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvatan)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the hyperbolic tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func tanh<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvtanhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvtanh)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the arc hyperbolic tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func atanh<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvatanhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvatanh)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    
    
    //
    // power
    //
    /**
       Return the square root of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func sqrt<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvsqrtf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvsqrt)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Return the reciprocal square root of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func rsqrt<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvrsqrtf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvrsqrt)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the exponetial for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func exp<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvexpf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvexp)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the natural log for all elements. i.e. log_e X
       - parameters:
            - mfarray: mfarray
    */
    public static func log<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvlogf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvlog)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the base 2 log for all elements. i.e. log_2 X
       - parameters:
            - mfarray: mfarray
    */
    public static func log2<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvlog2f)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvlog2)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the base 10 log for all elements. i.e. log_10 X
       - parameters:
            - mfarray: mfarray
    */
    public static func log10<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvlog10f)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvlog10)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    
    
    //
    // approximation
    //
    /**
       Return the ceiling of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func ceil<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvceilf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvceil)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Return the floor of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func floor<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvfloorf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvfloor)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Return the interfer truncation of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func trunc<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvintf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvint)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Return the nearest interfer of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func nearest<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvnintf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvnint)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
          Return the round give by number of decimals of each element
          - parameters:
            - decimals: (Optional) Int, default is 0, which is equivelent to nearest
    */
    public static func round(_ mfarray: MfArray, decimals: Int = 0) -> MfArray{
        let pow = powf(10, Float(decimals))
        let n =  Matft.math.nearest(mfarray * pow)
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
    public static func abs<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvfabsf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvfabs)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Return the reciprocal value of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func reciprocal<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvrecf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvrec)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
}

extension Matft.math{//use math_vv_by_vecLib
    /**
       Calculate power of each element
       - parameters:
            - base: Float
            - exponents: mfarray
    */
    public static func power<T: MfTypable>(base: T, exponents: MfArray<T>) -> MfArray<T>{
        return Matft.math.power(bases: Matft.nums(base, shape: [1]), exponents: exponents)
    }
    /**
       Calculate power of each element
       - parameters:
            - bases: mfarray
            - exponent: Float
    */
    public static func power<T: MfTypable>(bases: MfArray<T>, exponent: T) -> MfArray<T>{
        return Matft.math.power(bases: bases, exponents: Matft.nums(exponent, shape: [1]))
    }
    /**
       Calculate power of each element
       - parameters:
            - base: mfarray
            - exponents: mfarray
    */
    public static func power<T: MfTypable>(bases: MfArray<T>, exponents: MfArray<T>) -> MfArray<T>{
        let (bases, exponents, rettype) = biop_broadcast_to(bases, exponents)
        
        switch MfType.storedType(rettype) {
        case .Float:
            let ret = math_biop_vv_by_vForce(exponents, bases, vvpowf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_biop_vv_by_vForce(exponents, bases, vvpow)
            ret.mfdata._mftype = .Double
            return ret
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
