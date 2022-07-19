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
        if mfarray.isReal{
            switch mfarray.storedType {
            case .Float:
                let ret = mathf_by_vForce(mfarray, vvsinf)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                let ret = mathf_by_vForce(mfarray, vvsin)
                ret.mfdata.mftype = .Double
                return ret
            }
        }
        else{
            let x = mfarray.real
            let y = mfarray.imag!
            return MfArray(real: Matft.math.sin(x)*Matft.math.cosh(y), imag: Matft.math.cos(x)*Matft.math.sinh(y))
        }
    }
    /**
       Calculate the arcsin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func asin(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvasinf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvasin)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the hyperbolic sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func sinh(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvsinhf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvsinh)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the archyperbolic sin for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func asinh(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvasinhf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvasinh)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func cos(_ mfarray: MfArray) -> MfArray{
        if mfarray.isReal{
            switch mfarray.storedType {
            case .Float:
                let ret = mathf_by_vForce(mfarray, vvcosf)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                let ret = mathf_by_vForce(mfarray, vvcos)
                ret.mfdata.mftype = .Double
                return ret
            }
        }
        else{
            let x = mfarray.real
            let y = mfarray.imag!
            return MfArray(real: Matft.math.cos(x)*Matft.math.cosh(y), imag: -Matft.math.sin(x)*Matft.math.sinh(y))
        }
    }
    /**
       Calculate the arccos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func acos(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvacosf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvacos)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the hyperbolic cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func cosh(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvcoshf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvcosh)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the arc hyperbolic cos for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func acosh(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvacoshf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvacosh)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func tan(_ mfarray: MfArray) -> MfArray{
        if mfarray.isReal{
            switch mfarray.storedType {
            case .Float:
                let ret = mathf_by_vForce(mfarray, vvtanf)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                let ret = mathf_by_vForce(mfarray, vvtan)
                ret.mfdata.mftype = .Double
                return ret
            }
        }
        else{
            let x = mfarray.real
            let y = mfarray.imag!
            let cosx = Matft.math.cos(x)
            let sinhy = Matft.math.sinh(y)
            let denomitar = cosx*cosx + sinhy*sinhy
            return MfArray(real: Matft.math.sin(x)*cosx/denomitar, imag: Matft.math.cosh(x)*sinhy/denomitar)
        }
    }
    /**
       Calculate the arctan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func atan(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvatanf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvatan)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the hyperbolic tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func tanh(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvtanhf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvtanh)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the arc hyperbolic tan for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func atanh(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvatanhf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvatanh)
            ret.mfdata.mftype = .Double
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
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvsqrtf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvsqrt)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Return the reciprocal square root of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func rsqrt(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvrsqrtf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvrsqrt)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the exponetial for all elements
       - parameters:
            - mfarray: mfarray
    */
    public static func exp(_ mfarray: MfArray) -> MfArray{
        if mfarray.isReal{
            switch mfarray.storedType {
            case .Float:
                let ret = mathf_by_vForce(mfarray, vvexpf)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                let ret = mathf_by_vForce(mfarray, vvexp)
                ret.mfdata.mftype = .Double
                return ret
            }
        }
        else{
            let x = mfarray.real
            let y = mfarray.imag!
            let expx = Matft.math.exp(x)
            
            return MfArray(real: expx*Matft.math.cos(y), imag: expx*Matft.math.sin(y))
        }
    }
    /**
       Calculate the natural log for all elements. i.e. log_e X
       - parameters:
            - mfarray: mfarray
    */
    public static func log(_ mfarray: MfArray) -> MfArray{
        if mfarray.isReal{
            switch mfarray.storedType {
            case .Float:
                let ret = mathf_by_vForce(mfarray, vvlogf)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                let ret = mathf_by_vForce(mfarray, vvlog)
                ret.mfdata.mftype = .Double
                return ret
            }
        }
        else{
            return MfArray(real: Matft.math.log(Matft.complex.abs(mfarray)), imag: Matft.complex.angle(mfarray))
        }
    }
    /**
       Calculate the base 2 log for all elements. i.e. log_2 X
       - parameters:
            - mfarray: mfarray
    */
    public static func log2(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvlog2f)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvlog2)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Calculate the base 10 log for all elements. i.e. log_10 X
       - parameters:
            - mfarray: mfarray
    */
    public static func log10(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvlog10f)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvlog10)
            ret.mfdata.mftype = .Double
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
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvceilf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvceil)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Return the floor of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func floor(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvfloorf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvfloor)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Return the interfer truncation of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func trunc(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvintf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvint)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
       Return the nearest interfer of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func nearest(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvnintf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvnint)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    /**
          Return the round give by number of decimals of each element
          - parameters:
            - decimals: (Optional) Int, default is 0, which is equivelent to nearest
    */
    public static func round(_ mfarray: MfArray, decimals: Int = 0) -> MfArray{
        unsupport_complex(mfarray)
        
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
        if mfarray.isReal{
            switch mfarray.storedType {
            case .Float:
                let ret = mathf_by_vForce(mfarray, vvfabsf)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                let ret = mathf_by_vForce(mfarray, vvfabs)
                ret.mfdata.mftype = .Double
                return ret
            }
        }
        else{
            return Matft.complex.abs(mfarray)
        }
    }
    /**
       Return the reciprocal value of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func reciprocal(_ mfarray: MfArray) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvrecf)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvrec)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
}

extension Matft.math{//use math_vv_by_vecLib
    /**
       Calculate power of each element
       - parameters:
            - bases: Float
            - exponents: mfarray
    */
    public static func power(bases: Float, exponents: MfArray) -> MfArray{
        if exponents.isReal{
            return Matft.math.power(bases: Matft.nums(bases, shape: [1]), exponents: exponents)
        }
        else{
            // a^b = exp(b*log(a)) = exp{blog|a|+j*b*arg(a)}
            return Matft.math.exp(exponents*logf(fabsf(bases)))
        }
    }
    /**
       Calculate power of each element
       - parameters:
            - bases: mfarray
            - exponents: Float
    */
    public static func power(bases: MfArray, exponents: Float) -> MfArray{
        if bases.isReal{
            return Matft.math.power(bases: bases, exponents: Matft.nums(exponents, shape: [1]))
        }
        else{
            let b = Matft.complex.absarg(bases)
            assert(b.abs.isReal)
            let argj = MfArray(real: nil, imag: b.arg)
            return Matft.math.power(bases: b.abs, exponents: exponents)*Matft.math.exp(argj*exponents)
        }
    }
    /**
       Calculate power of each element
       - parameters:
            - base: mfarray
            - exponents: mfarray
    */
    public static func power(bases: MfArray, exponents: MfArray) -> MfArray{
        let (bases, exponents, rettype, isReal) = biop_broadcast_to(bases, exponents)
        
        if isReal{
            switch MfType.storedType(rettype) {
            case .Float:
                let ret = math_biop_by_vForce(exponents, bases, vvpowf)
                ret.mfdata.mftype = .Float
                return ret
            case .Double:
                let ret = math_biop_by_vForce(exponents, bases, vvpow)
                ret.mfdata.mftype = .Double
                return ret
            }
        }
        else{
            // a^b = exp(b*log(a)) = exp{blog|a|+j*b*arg(a)}
            let a = Matft.complex.absarg(bases)
            return Matft.math.exp(exponents*MfArray(real: Matft.math.log(a.abs), imag: a.arg))
        }
    }
    
    /**
       Calculate the arc tangent of x1/x2 choosing the quadrant correctly
       - parameters:
            - x1: y coordinates mfarray
            - x2: x coordinates mfarray
    */
    public static func arctan2(x1: MfArray, x2: MfArray) -> MfArray{
        let (x1, x2, rettype, isReal) = biop_broadcast_to(x1, x2)
        
        precondition(isReal, "Complex is not supported")
        
        switch MfType.storedType(rettype) {
        case .Float:
            let ret = math_biop_by_vForce(x1, x2, vvatan2f)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = math_biop_by_vForce(x1, x2, vvatan2)
            ret.mfdata.mftype = .Double
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
        unsupport_complex(mfarray)
        
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
        /*
        let ret = mfarray.deepcopy()
        func _sign<T: MfStorable>(low: T, high: T) -> MfArray{
            ret.withContiguousDataUnsafeMPtrT(datatype: T.self){
                if $0.pointee > .zero{
                    $0.pointee = high
                }
                else if $0.pointee < .zero{
                    $0.pointee = low
                }
            }
            return ret
        }
        switch mfarray.storedType {
        case .Float:
            return _sign(low: Float(-1), high: Float(1))
        case .Double:
            return _sign(low: Double(-1), high: Double(1))
        }*/
        unsupport_complex(mfarray)
        
        switch mfarray.storedType {
        case .Float:
            return sign_by_vDSP(mfarray, vDSP_vminmg_func: vDSP_vminmg, vDSP_viclip_func: vDSP_viclip, vForce_copysign_func: vvcopysignf)
        case .Double:
            return sign_by_vDSP(mfarray, vDSP_vminmg_func: vDSP_vminmgD, vDSP_viclip_func: vDSP_viclipD, vForce_copysign_func: vvcopysign)
        }
    }
}
