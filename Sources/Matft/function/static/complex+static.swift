//
//  complex+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/18.
//

import Foundation
#if canImport(Accelerate)
import Accelerate

extension Matft.complex{
    
    /**
       Return the angle (argument) of each complex element, in radians.

       A real array is treated as complex with zero imaginary part.
       Equivalent to `numpy.angle`.
       - Parameters:
           - mfarray: The source array.
       - Returns: A new real array of type `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public static func angle(_ mfarray: MfArray) -> MfArray{
        let src_mfarray: MfArray
        if mfarray.isReal{
            src_mfarray = mfarray.to_complex(false)
        }
        else{
            src_mfarray = mfarray
        }
        
        switch src_mfarray.storedType{
        case .Float:
            let ret = z2r_by_vDSP(src_mfarray, vDSP_zvphas)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = z2r_by_vDSP(src_mfarray, vDSP_zvphasD)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    
    /**
       Return the complex conjugate, element-wise.

       For a real array, a row-major copy is returned.
       Equivalent to `numpy.conjugate`.
       - Parameters:
           - mfarray: The source array.
       - Returns: A new array of the conjugates.
    */
    public static func conjugate(_ mfarray: MfArray) -> MfArray{
        if mfarray.isReal{
            return mfarray.deepcopy(.Row)
        }
        
        switch mfarray.storedType{
        case .Float:
            return conjugate_by_vDSP(mfarray, vDSP_zvconj)
        case .Double:
            return conjugate_by_vDSP(mfarray, vDSP_zvconjD)
        }
    }
    
    /**
       Return the absolute value (magnitude) of each element.

       For a real array, this is the same as `Matft.math.abs(_:)`.
       Equivalent to `numpy.abs`.
       - Parameters:
           - mfarray: The source array.
       - Returns: A new real array. For complex input, its type is `.Float` (Float-stored input) or `.Double` (Double-stored input).
    */
    public static func abs(_ mfarray: MfArray) -> MfArray{
        if mfarray.isReal{
            return Matft.math.abs(mfarray)
        }
        
        switch mfarray.storedType{
        case .Float:
            let ret = z2r_by_vDSP(mfarray, vDSP_zvabs)
            ret.mfdata.mftype = .Float
            return ret
        case .Double:
            let ret = z2r_by_vDSP(mfarray, vDSP_zvabsD)
            ret.mfdata.mftype = .Double
            return ret
        }
    }
    
    /**
       Return the absolute value and the angle of each element at once.

       For a real array, the angle is filled with 0 (Numpy's `angle` would return `pi` for negative values).
       - Parameters:
           - mfarray: The source array.
       - Returns: A tuple of the absolute values (`abs`) and the angles in radians (`arg`).
    */
    public static func absarg(_ mfarray: MfArray) -> (abs: MfArray, arg: MfArray){
        if mfarray.isReal{
            switch mfarray.storedType{
            case .Float:
                return (Matft.math.abs(mfarray), Matft.nums_like(Float.zero, mfarray: mfarray))
            case .Double:
                return (Matft.math.abs(mfarray), Matft.nums_like(Double.zero, mfarray: mfarray))
            }
        }
        
        return (Matft.complex.abs(mfarray), Matft.complex.angle(mfarray))
    }
}
#endif

/// Check it is real or not. if the mfarray is complex, raise precondition failure.
/// - Parameters:
///     - mfarray: A source mfarray
@inline(__always)
internal func unsupport_complex(_ mfarray: MfArray){
    precondition(mfarray.isReal, "")
}
