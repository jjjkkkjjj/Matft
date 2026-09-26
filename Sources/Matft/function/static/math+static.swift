//
//  math.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/04.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

//ref https://developer.apple.com/documentation/accelerate/veclib/vforce

#if canImport(Accelerate)
extension Matft.math{//use math_vv_by_vecLib
    //
    // trigonometric
    //
    /**
       Compute the trigonometric sine element-wise.

       Equivalent to `numpy.sin`.

       ```swift
       let a = Matft.arange(start: 0, to: 15, by: 1, shape: [3, 5], mftype: .Float)
       let b = Matft.math.sin(a) // element-wise sine, shape [3, 5]
       ```

       - Parameters:
            - mfarray: The input array of angles in radians.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`). Complex input is supported and returns a complex array.
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
       Compute the inverse sine element-wise.

       Equivalent to `numpy.arcsin`.

       - Parameters:
            - mfarray: The input array. Values outside [-1, 1] produce NaN.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the hyperbolic sine element-wise.

       Equivalent to `numpy.sinh`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the inverse hyperbolic sine element-wise.

       Equivalent to `numpy.arcsinh`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the trigonometric cosine element-wise.

       Equivalent to `numpy.cos`.

       - Parameters:
            - mfarray: The input array of angles in radians.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`). Complex input is supported and returns a complex array.
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
       Compute the inverse cosine element-wise.

       Equivalent to `numpy.arccos`.

       - Parameters:
            - mfarray: The input array. Values outside [-1, 1] produce NaN.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the hyperbolic cosine element-wise.

       Equivalent to `numpy.cosh`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the inverse hyperbolic cosine element-wise.

       Equivalent to `numpy.arccosh`.

       - Parameters:
            - mfarray: The input array. Values less than 1 produce NaN.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the trigonometric tangent element-wise.

       Equivalent to `numpy.tan`.

       - Parameters:
            - mfarray: The input array of angles in radians.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`). Complex input is supported and returns a complex array.
       - Note: For complex input `x + iy`, the current implementation computes the imaginary part as `cosh(x) * sinh(y) / (cos(x)^2 + sinh(y)^2)`, whereas the mathematical definition uses `sinh(y) * cosh(y)`. Complex results may therefore differ from `numpy.tan`.
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
       Compute the inverse tangent element-wise.

       Equivalent to `numpy.arctan`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the hyperbolic tangent element-wise.

       Equivalent to `numpy.tanh`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the inverse hyperbolic tangent element-wise.

       Equivalent to `numpy.arctanh`.

       - Parameters:
            - mfarray: The input array. Values outside [-1, 1] produce NaN.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the non-negative square root element-wise.

       Equivalent to `numpy.sqrt`.

       - Parameters:
            - mfarray: The input array. Negative values produce NaN (they are not promoted to complex).
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the reciprocal square root, `1 / sqrt(x)`, element-wise.

       Equivalent to `1 / numpy.sqrt(x)`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the exponential, `e^x`, element-wise.

       Equivalent to `numpy.exp`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`). Complex input is supported and returns a complex array.
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
       Compute the natural logarithm, `log_e(x)`, element-wise.

       Equivalent to `numpy.log`.

       - Parameters:
            - mfarray: The input array. Negative values produce NaN for real input.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`). Complex input is supported and returns a complex array. For complex input the result is `log|z| + i*arg(z)`.
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
       Compute the base-2 logarithm, `log_2(x)`, element-wise.

       Equivalent to `numpy.log2`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Compute the base-10 logarithm, `log_10(x)`, element-wise.

       Equivalent to `numpy.log10`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Return the ceiling of each element, the smallest integer not less than it.

       Equivalent to `numpy.ceil`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Return the floor of each element, the largest integer not greater than it.

       Equivalent to `numpy.floor`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Truncate each element toward zero, discarding the fractional part.

       Equivalent to `numpy.trunc`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Round each element to the nearest integer.

       Equivalent to `numpy.rint`.

       Computed with vForce `vvnint`. The values keep a floating-point type.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Round each element to the given number of decimals.

       Equivalent to `numpy.round`. Implemented as `nearest(mfarray * 10^decimals) / 10^decimals`, where the scaling factor is a `Float`.

       - Parameters:
            - mfarray: The input array.
            - decimals: The number of decimal places to round to. Default is 0, which is equivalent to `nearest(_:)`. A negative value rounds to the left of the decimal point.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
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
       Compute the absolute value element-wise.

       Equivalent to `numpy.abs`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`). Complex input is supported and returns the real magnitude `|z|` (same as `Matft.complex.abs`).
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
       Compute the reciprocal, `1 / x`, element-wise.

       Equivalent to `numpy.reciprocal`.

       Unlike Numpy, integer input is not computed with integer division; it is converted to `.Float` first.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape as `mfarray`. The result is `.Double` for `.Double` input and `.Float` otherwise (integer and `.Bool` inputs are converted to `.Float`).
       - Precondition: Complex arrays are not supported.
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
       Raise a scalar base to the powers given by an array, element-wise.

       Equivalent to `numpy.power(bases, exponents)` with a scalar base.

       - Parameters:
            - bases: The scalar base.
            - exponents: The array of exponents.
       - Returns: A new array with the same shape as `exponents`. For real `exponents` the result is `.Double` if `exponents` is `.Double` and `.Float` otherwise. Complex `exponents` are supported and computed as `exp(exponents * log|bases|)`.
       - Note: For complex `exponents`, the phase of a negative `bases` is ignored (only `|bases|` is used).
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
       Raise each element of an array to a scalar power.

       Equivalent to `numpy.power(bases, exponents)` with a scalar exponent. An exponent of 2 is computed with a fast squaring kernel.

       - Parameters:
            - bases: The array of bases.
            - exponents: The scalar exponent.
       - Returns: A new array with the same shape as `bases`. For real `bases` the result is `.Double` for `.Double` input and `.Float` otherwise. Complex `bases` are supported and computed in polar form.
    */
    public static func power(bases: MfArray, exponents: Float) -> MfArray{
        if bases.isReal{
            // not broadcasting the scalar into an array
            return pows_by_vForce(bases, exponents)
        }
        else{
            let b = Matft.complex.absarg(bases)
            assert(b.abs.isReal)
            let argj = MfArray(real: nil, imag: b.arg)
            return Matft.math.power(bases: b.abs, exponents: exponents)*Matft.math.exp(argj*exponents)
        }
    }
    /**
       Raise the elements of `bases` to the powers in `exponents`, element-wise with broadcasting.

       Equivalent to `numpy.power`.

       - Parameters:
            - bases: The array of bases.
            - exponents: The array of exponents. It is broadcast against `bases`.
       - Returns: A new array with the broadcast shape. For real inputs the result is `.Double` if the promoted type is stored as `Double` and `.Float` otherwise. Complex inputs are supported and computed as `exp(exponents * log(bases))`.
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
       Compute the element-wise arc tangent of `x1 / x2`, choosing the quadrant correctly.

       Equivalent to `numpy.arctan2`. The result is in radians, in the range [-pi, pi].

       - Parameters:
            - x1: The y-coordinates.
            - x2: The x-coordinates. It is broadcast against `x1`.
       - Returns: A new array with the broadcast shape. The result is `.Double` if the promoted type is stored as `Double` and `.Float` otherwise.
       - Precondition: Complex arrays are not supported.
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
       Compute the square of each element.

       Equivalent to `numpy.square`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape and the same `mftype` as `mfarray`.
       - Precondition: Complex arrays are not supported.
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
       Return an element-wise indication of the sign of a number: -1 for negative, 0 for zero and 1 for positive values.

       Equivalent to `numpy.sign`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A new array with the same shape and the same `mftype` as `mfarray`.
       - Precondition: Complex arrays are not supported.
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
            return sign_by_vDSP(mfarray, vDSP_vthrsc, vDSP_vadd, vDSP_sve)
        case .Double:
            return sign_by_vDSP(mfarray, vDSP_vthrscD, vDSP_vaddD, vDSP_sveD)
        }
    }
}
#else
// WASI fallback: Math operations using pure Swift implementations
extension Matft.math {
    /// Compute the trigonometric sine element-wise (WASI fallback; complex input is not supported).
    public static func sin(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
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

    /// Compute the inverse sine element-wise (WASI fallback).
    public static func asin(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the hyperbolic sine element-wise (WASI fallback).
    public static func sinh(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the inverse hyperbolic sine element-wise (WASI fallback).
    public static func asinh(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the trigonometric cosine element-wise (WASI fallback; complex input is not supported).
    public static func cos(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
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

    /// Compute the inverse cosine element-wise (WASI fallback).
    public static func acos(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the hyperbolic cosine element-wise (WASI fallback).
    public static func cosh(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the inverse hyperbolic cosine element-wise (WASI fallback).
    public static func acosh(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the trigonometric tangent element-wise (WASI fallback; complex input is not supported).
    public static func tan(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
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

    /// Compute the inverse tangent element-wise (WASI fallback).
    public static func atan(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the hyperbolic tangent element-wise (WASI fallback).
    public static func tanh(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the inverse hyperbolic tangent element-wise (WASI fallback).
    public static func atanh(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the non-negative square root element-wise (WASI fallback).
    public static func sqrt(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the reciprocal square root element-wise (WASI fallback).
    public static func rsqrt(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the exponential element-wise (WASI fallback; complex input is not supported).
    public static func exp(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
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

    /// Compute `2^x` element-wise (WASI fallback only; not available on Apple platforms).
    public static func exp2(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvexp2f)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvexp2)
            ret.mfdata.mftype = .Double
            return ret
        }
    }

    /// Compute `exp(x) - 1` element-wise (WASI fallback only; not available on Apple platforms).
    public static func expm1(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
        switch mfarray.storedType {
        case .Float:
            let ret = mathf_by_vForce(mfarray, vvexpm1f)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = mathf_by_vForce(mfarray, vvexpm1)
            ret.mfdata.mftype = .Double
            return ret
        }
    }

    /// Compute the natural logarithm element-wise (WASI fallback; complex input is not supported).
    public static func log(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
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

    /// Compute the base-2 logarithm element-wise (WASI fallback).
    public static func log2(_ mfarray: MfArray) -> MfArray {
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

    /// Compute the base-10 logarithm element-wise (WASI fallback).
    public static func log10(_ mfarray: MfArray) -> MfArray {
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

    /// Compute `log(1 + x)` element-wise (WASI fallback only; not available on Apple platforms).
    public static func log1p(_ mfarray: MfArray) -> MfArray {
        // log1p is not in vForce, implement using log(1+x)
        return Matft.math.log(mfarray + 1)
    }

    /// Compute the absolute value element-wise (WASI fallback; complex input is not supported).
    public static func abs(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
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

    /// Compute the reciprocal element-wise (WASI fallback).
    public static func reciprocal(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
        switch mfarray.storedType {
        case .Float:
            return biopsv_by_vDSP(Float(1), mfarray, vDSP_svdiv)
        case .Double:
            return biopsv_by_vDSP(Double(1), mfarray, vDSP_svdivD)
        }
    }

    /// Raise a scalar base to the powers in `exponents` (WASI fallback).
    public static func power(bases: Float, exponents: MfArray) -> MfArray {
        return Matft.math.power(bases: Matft.nums(bases, shape: [1]), exponents: exponents)
    }

    /// Raise each element of `bases` to a scalar power (WASI fallback; complex input is not supported).
    public static func power(bases: MfArray, exponents: Float) -> MfArray {
        unsupport_complex(bases)
        return pows_by_vForce(bases, exponents)
    }

    /// Raise `bases` to the powers in `exponents` with broadcasting (WASI fallback; complex input is not supported).
    public static func power(bases: MfArray, exponents: MfArray) -> MfArray {
        unsupport_complex(bases)
        unsupport_complex(exponents)
        let (baseBc, exponentsBc, _, _) = biop_broadcast_to(bases, exponents)
        switch baseBc.storedType {
        case .Float:
            return math_biop_by_vForce(baseBc, exponentsBc, vvpowf)
        case .Double:
            return math_biop_by_vForce(baseBc, exponentsBc, vvpow)
        }
    }

    /// Compute the element-wise arc tangent of `x1 / x2` choosing the quadrant correctly (WASI fallback).
    public static func arctan2(x1 mfarrayY: MfArray, x2 mfarrayX: MfArray) -> MfArray {
        // arctan2 not in our vForce fallback, use element-wise atan2
        unsupport_complex(mfarrayY)
        unsupport_complex(mfarrayX)
        let (y, x, _, _) = biop_broadcast_to(mfarrayY, mfarrayX)
        let yData = y.to_contiguous(mforder: MfOrder.Row)
        let xData = x.to_contiguous(mforder: MfOrder.Row)

        switch y.storedType {
        case .Float:
            let newdata = MfData(uninitializedSize: y.size, mftype: .Float)
            newdata.withUnsafeMutableStartPointer(datatype: Float.self) { dstptr in
                yData.withUnsafeMutableStartPointer(datatype: Float.self) { yptr in
                    xData.withUnsafeMutableStartPointer(datatype: Float.self) { xptr in
                        for i in 0..<y.size {
                            dstptr[i] = atan2f(yptr[i], xptr[i])
                        }
                    }
                }
            }
            return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: y.shape, mforder: .Row))
        case .Double:
            let newdata = MfData(uninitializedSize: y.size, mftype: .Double)
            newdata.withUnsafeMutableStartPointer(datatype: Double.self) { dstptr in
                yData.withUnsafeMutableStartPointer(datatype: Double.self) { yptr in
                    xData.withUnsafeMutableStartPointer(datatype: Double.self) { xptr in
                        for i in 0..<y.size {
                            dstptr[i] = atan2(yptr[i], xptr[i])
                        }
                    }
                }
            }
            return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: y.shape, mforder: .Row))
        }
    }

    /// Return the floor of each element (WASI fallback).
    public static func floor(_ mfarray: MfArray) -> MfArray {
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

    /// Return the ceiling of each element (WASI fallback).
    public static func ceil(_ mfarray: MfArray) -> MfArray {
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

    /// Round each element to the given number of decimals (WASI fallback).
    public static func round(_ mfarray: MfArray, decimals: Int = 0) -> MfArray {
        unsupport_complex(mfarray)
        if decimals == 0 {
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
        } else {
            let factor = pow(10.0, Double(decimals))
            switch mfarray.storedType {
            case .Float:
                let scaled = mfarray * Float(factor)
                let rounded = mathf_by_vForce(scaled, vvnintf)
                rounded.mfdata.mftype = .Float
                return rounded / Float(factor)
            case .Double:
                let scaled = mfarray * factor
                let rounded = mathf_by_vForce(scaled, vvnint)
                rounded.mfdata.mftype = .Double
                return rounded / factor
            }
        }
    }

    /// Truncate each element toward zero (WASI fallback).
    public static func trunc(_ mfarray: MfArray) -> MfArray {
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

    /// Round each element to the nearest integer (WASI fallback).
    public static func nearest(_ mfarray: MfArray) -> MfArray {
        return Matft.math.round(mfarray)
    }

    /// Return the sign (-1, 0 or 1) of each element (WASI fallback).
    public static func sign(_ mfarray: MfArray) -> MfArray {
        unsupport_complex(mfarray)
        switch mfarray.storedType {
        case .Float:
            return sign_by_vDSP(mfarray, Float.self)
        case .Double:
            return sign_by_vDSP(mfarray, Double.self)
        }
    }
}
#endif

extension Matft.math{
    /**
       Test element-wise for NaN.

       Equivalent to `numpy.isnan`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A `.Bool` array with the same shape as `mfarray`.
       - Precondition: Complex arrays are not supported.
    */
    public static func isnan(_ mfarray: MfArray) -> MfArray{
        return _bool_map(mfarray, { $0.isNaN }, { $0.isNaN })
    }

    /**
       Test element-wise for positive or negative infinity.

       Equivalent to `numpy.isinf`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A `.Bool` array with the same shape as `mfarray`.
       - Precondition: Complex arrays are not supported.
    */
    public static func isinf(_ mfarray: MfArray) -> MfArray{
        return _bool_map(mfarray, { $0.isInfinite }, { $0.isInfinite })
    }

    /**
       Test element-wise for finiteness (neither infinity nor NaN).

       Equivalent to `numpy.isfinite`.

       - Parameters:
            - mfarray: The input array.
       - Returns: A `.Bool` array with the same shape as `mfarray`.
       - Precondition: Complex arrays are not supported.
    */
    public static func isfinite(_ mfarray: MfArray) -> MfArray{
        return _bool_map(mfarray, { $0.isFinite }, { $0.isFinite })
    }
}

/// Apply the predicate element-wise and return the Bool mfarray (row major)
fileprivate func _bool_map(_ mfarray: MfArray, _ predicateF: (Float) -> Bool, _ predicateD: (Double) -> Bool) -> MfArray{
    unsupport_complex(mfarray)

    let ret = Matft.nums(Float.zero, shape: mfarray.shape, mftype: .Bool)
    ret.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptr in
        var i = 0
        switch mfarray.storedType {
        case .Float:
            mfarray.withContiguousDataUnsafeMPtrT(datatype: Float.self){
                (dstptr + i).pointee = predicateF($0.pointee) ? 1 : 0
                i += 1
            }
        case .Double:
            mfarray.withContiguousDataUnsafeMPtrT(datatype: Double.self){
                (dstptr + i).pointee = predicateD($0.pointee) ? 1 : 0
                i += 1
            }
        }
    }
    return ret
}
