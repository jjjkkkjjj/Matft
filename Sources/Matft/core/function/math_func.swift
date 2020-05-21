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
    public static func sin(_ mfarray: MfArray) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            let ret = math_vv_by_vForce(mfarray, vvsinf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vForce(mfarray, vvsin)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate the arcsin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func asin(_ mfarray: MfArray) -> MfArray{
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
    public static func sinh(_ mfarray: MfArray) -> MfArray{
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
    public static func asinh(_ mfarray: MfArray) -> MfArray{
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
    public static func cos(_ mfarray: MfArray) -> MfArray{
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
    public static func acos(_ mfarray: MfArray) -> MfArray{
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
    public static func cosh(_ mfarray: MfArray) -> MfArray{
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
    public static func acosh(_ mfarray: MfArray) -> MfArray{
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
    public static func tan(_ mfarray: MfArray) -> MfArray{
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
    public static func atan(_ mfarray: MfArray) -> MfArray{
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
    public static func tanh(_ mfarray: MfArray) -> MfArray{
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
    public static func atanh(_ mfarray: MfArray) -> MfArray{
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
    public static func sqrt(_ mfarray: MfArray) -> MfArray{
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
    public static func rsqrt(_ mfarray: MfArray) -> MfArray{
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
    public static func exp(_ mfarray: MfArray) -> MfArray{
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
    public static func log(_ mfarray: MfArray) -> MfArray{
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
    public static func log2(_ mfarray: MfArray) -> MfArray{
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
    public static func log10(_ mfarray: MfArray) -> MfArray{
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
    public static func ceil(_ mfarray: MfArray) -> MfArray{
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
    public static func floor(_ mfarray: MfArray) -> MfArray{
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
    public static func trunc(_ mfarray: MfArray) -> MfArray{
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
    public static func nearest(_ mfarray: MfArray) -> MfArray{
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
    public static func abs(_ mfarray: MfArray) -> MfArray{
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
    public static func reciprocal(_ mfarray: MfArray) -> MfArray{
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
    public static func power(base: Float, exponents: MfArray) -> MfArray{
        switch exponents.storedType {
        case .Float:
            var bases = Array<Float>(repeating: base, count: exponents.storedSize)
            let ret = math_1arg_vv_by_vForce(exponents, &bases, vvpowf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            var bases = Array<Double>(repeating: Double(base), count: exponents.storedSize)
            let ret = math_1arg_vv_by_vForce(exponents, &bases, vvpow)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    /**
       Calculate power of each element
       - parameters:
            - base: mfarray
            - exponents: mfarray
    */
    public static func power(bases: MfArray, exponents: MfArray) -> MfArray{
        var bases = bases.broadcast_to(shape: exponents.shape)
        
        var exponents = exponents

        if exponents.mftype != bases.mftype{
            if exponents.mftype == MfType.priority(exponents.mftype, bases.mftype){
                bases = bases.astype(exponents.mftype)
            }
            else{
                exponents = exponents.astype(bases.mftype)
            }
        }
        
        switch exponents.storedType {
        case .Float:
            let ret = bases.withDataUnsafeMBPtrT(datatype: Float.self){
                math_1arg_vv_by_vForce(exponents, $0.baseAddress!, vvpowf)
            }
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = bases.withDataUnsafeMBPtrT(datatype: Double.self){
                math_1arg_vv_by_vForce(exponents, $0.baseAddress!, vvpow)
            }
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
    public static func square(_ mfarray: MfArray) -> MfArray{
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
    public static func sign(_ mfarray: MfArray) -> MfArray{
        var ssq: MfArray // signed squared values
        switch mfarray.storedType {
        case .Float:
            ssq = math_by_vDSP(mfarray, vDSP_vssq)
        case .Double:
            ssq = math_by_vDSP(mfarray, vDSP_vssqD)
        }

        return (ssq / Matft.math.square(mfarray)).nearest()
    }
}
