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

extension Matft.mfarray{//use math_vv_by_vecLib
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
            let ret = math_vv_by_vecLib(mfarray, vvsinf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvsin)
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
            let ret = math_vv_by_vecLib(mfarray, vvasinf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvasin)
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
            let ret = math_vv_by_vecLib(mfarray, vvsinhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvsinh)
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
            let ret = math_vv_by_vecLib(mfarray, vvasinhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvasinh)
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
            let ret = math_vv_by_vecLib(mfarray, vvcosf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvcos)
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
            let ret = math_vv_by_vecLib(mfarray, vvacosf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvacos)
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
            let ret = math_vv_by_vecLib(mfarray, vvcoshf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvcosh)
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
            let ret = math_vv_by_vecLib(mfarray, vvacoshf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvacosh)
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
            let ret = math_vv_by_vecLib(mfarray, vvtanf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvtan)
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
            let ret = math_vv_by_vecLib(mfarray, vvatanf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvatan)
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
            let ret = math_vv_by_vecLib(mfarray, vvtanhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvtanh)
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
            let ret = math_vv_by_vecLib(mfarray, vvatanhf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvatanh)
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
            let ret = math_vv_by_vecLib(mfarray, vvsqrtf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvsqrt)
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
            let ret = math_vv_by_vecLib(mfarray, vvrsqrtf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvrsqrt)
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
            let ret = math_vv_by_vecLib(mfarray, vvexpf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvexp)
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
            let ret = math_vv_by_vecLib(mfarray, vvlogf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvlog)
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
            let ret = math_vv_by_vecLib(mfarray, vvlog2f)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvlog2)
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
            let ret = math_vv_by_vecLib(mfarray, vvlog10f)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvlog10)
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
            let ret = math_vv_by_vecLib(mfarray, vvceilf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvceil)
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
            let ret = math_vv_by_vecLib(mfarray, vvfloorf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvfloor)
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
            let ret = math_vv_by_vecLib(mfarray, vvintf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvint)
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
            let ret = math_vv_by_vecLib(mfarray, vvnintf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvnint)
            ret.mfdata._mftype = .Double
            return ret
        }
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
            let ret = math_vv_by_vecLib(mfarray, vvfabsf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvfabs)
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
            let ret = math_vv_by_vecLib(mfarray, vvrecf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = math_vv_by_vecLib(mfarray, vvrec)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
}

extension Matft.mfarray{//use math_vv_by_vecLib
    /**
       Calculate power of each element
       - parameters:
            - mfarray: mfarray
    */
    public static func power(_ mfarray: MfArray, exponents: Float) -> MfArray{
        switch mfarray.storedType {
        case .Float:
            var exp = Array<Float>(repeating: exponents, count: mfarray.storedSize)
            let ret = math_1arg_vv_by_vecLib(mfarray, &exp, vvpowf)
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            var exp = Array<Double>(repeating: Double(exponents), count: mfarray.storedSize)
            let ret = math_1arg_vv_by_vecLib(mfarray, &exp, vvpow)
            ret.mfdata._mftype = .Double
            return ret
        }
    }
    public static func power(_ mfarray: MfArray, exponents: MfArray) -> MfArray{
        guard let exponents = try? exponents.broadcast_to(shape: mfarray.shape)
            else{
                fatalError("cannot align given shape of mfarray and exponents")
        }
        
        switch mfarray.storedType {
        case .Float:
            let ret = exponents.withDataUnsafeMBPtrT(datatype: Float.self){
                math_1arg_vv_by_vecLib(mfarray, $0.baseAddress!, vvpowf)
            }
            ret.mfdata._mftype = .Float
            return ret
        case .Double:
            let ret = exponents.withDataUnsafeMBPtrT(datatype: Double.self){
                math_1arg_vv_by_vecLib(mfarray, $0.baseAddress!, vvpow)
            }
            ret.mfdata._mftype = .Double
            return ret
        }
    }
}

