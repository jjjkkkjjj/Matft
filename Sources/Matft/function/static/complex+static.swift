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
            return _fix_abs(mfarray, ret, hypotf)
        case .Double:
            let ret = z2r_by_vDSP(mfarray, vDSP_zvabsD)
            ret.mfdata.mftype = .Double
            return _fix_abs(mfarray, ret, { (x: Double, y: Double) in Foundation.hypot(x, y) })
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

/// vDSP_zvabs computes `sqrt(re^2 + im^2)` directly, so the squares overflow or underflow for large or tiny elements, and `|inf + NaN j|` is NaN.
/// Recompute such elements by `hypot` like numpy. They are the results that are not finite or too small for the squares to be exact,
/// so the whole array is copied only when there are such elements (including 0).
/// - Parameters:
///   - mfarray: The complex source
///   - ret: The result of vDSP_zvabs
///   - hypot: `hypot` of T
/// - Returns: `ret`, or a row contiguous copy of it with the elements recomputed
fileprivate func _fix_abs<T: MfStorable & BinaryFloatingPoint>(_ mfarray: MfArray, _ ret: MfArray, _ hypot: (T, T) -> T) -> MfArray{
    // below this, the square of the larger part may lose precision
    let threshold = T.leastNormalMagnitude.squareRoot() / T.ulpOfOne
    func needsFix(_ v: T) -> Bool{
        return !(v.isFinite && v >= threshold)
    }
    // ret is dense (z2r_by_vDSP)
    let hasBad = ret.withUnsafeMutableStartPointer(datatype: T.self){
        ptr in
        (0..<ret.storedSize).contains{ needsFix(ptr[$0]) }
    }
    guard hasBad else { return ret }
    
    let re = mfarray.real.to_contiguous(mforder: .Row)
    let im = mfarray.imag!.to_contiguous(mforder: .Row)
    let ret = ret.to_contiguous(mforder: .Row)
    re.withUnsafeMutableStartPointer(datatype: T.self){
        reptr in
        im.withUnsafeMutableStartPointer(datatype: T.self){
            imptr in
            ret.withUnsafeMutableStartPointer(datatype: T.self){
                dstptr in
                for i in 0..<ret.size where needsFix(dstptr[i]){
                    dstptr[i] = hypot(reptr[i], imptr[i])
                }
            }
        }
    }
    return ret
}
#endif

/// Check it is real or not. if the mfarray is complex, raise precondition failure.
/// - Parameters:
///     - mfarray: A source mfarray
@inline(__always)
internal func unsupport_complex(_ mfarray: MfArray){
    precondition(mfarray.isReal, "")
}
