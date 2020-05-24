//
//  infix.swift
//  Matft
//
//  Created by AM19A0 on 2020/02/28.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

infix operator *&: MultiplicationPrecedence //matmul
infix operator *+: MultiplicationPrecedence //inner
infix operator *^: MultiplicationPrecedence //cross


// MfNumeric
extension MfArray where ArrayType: MfNumeric{
    static public func +(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
        return Matft.add(l_mfarray, r_mfarray)
    }
    static public func +(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray{
        return Matft.add(l_mfarray, r_scalar)
    }
    static public func +(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray{
        return Matft.add(l_scalar, r_mfarray)
    }

    static public func -(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
        return Matft.sub(l_mfarray, r_mfarray)
    }
    static public func -(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray{
        return Matft.sub(l_mfarray, r_scalar)
    }
    static public func -(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray{
        return Matft.sub(l_scalar, r_mfarray)
    }

    static public func *(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
        return Matft.mul(l_mfarray, r_mfarray)
    }
    static public func *(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray{
        return Matft.mul(l_mfarray, r_scalar)
    }
    static public func *(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray{
        return Matft.mul(l_scalar, r_mfarray)
    }

    static public func /(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
        return Matft.div(l_mfarray, r_mfarray)
    }
    static public func /(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray{
        return Matft.div(l_mfarray, r_scalar)
    }
    static public func /(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray{
        return Matft.div(l_scalar, r_mfarray)
    }
    
    static public func ===(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.equal(l_mfarray, r_mfarray)
    }
    static public func ===(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray<Bool>{
        return Matft.equal(l_mfarray, r_scalar)
    }
    static public func ===(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.equal(l_scalar, r_mfarray)
    }
    static public func !==(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.not_equal(l_mfarray, r_mfarray)
    }
    static public func !==(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray<Bool>{
        return Matft.not_equal(l_mfarray, r_scalar)
    }
    static public func !==(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.not_equal(l_scalar, r_mfarray)
    }

    
    static public func *&(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
        return Matft.matmul(l_mfarray, r_mfarray)
    }
    /*
    static public func *+(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
        return Matft.inner(l_mfarray, r_mfarray)
    }*/
    static public func *^(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
        return Matft.cross(l_mfarray, r_mfarray)
    }
}
extension MfArray: Equatable{
    static public func ==(lhs: MfArray, rhs: MfArray) -> Bool{
        return Matft.allEqual(lhs, rhs)
    }
}


// MfBinary
extension MfArray where ArrayType: MfBinary{
    static public func ===(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.equal(l_mfarray, r_mfarray)
    }
    static public func ===(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray<Bool>{
        return Matft.equal(l_mfarray, r_scalar)
    }
    static public func ===(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.equal(l_scalar, r_mfarray)
    }
    static public func !==(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.not_equal(l_mfarray, r_mfarray)
    }
    static public func !==(l_mfarray: MfArray, r_scalar: ArrayType) -> MfArray<Bool>{
        return Matft.not_equal(l_mfarray, r_scalar)
    }
    static public func !==(l_scalar: ArrayType, r_mfarray: MfArray) -> MfArray<Bool>{
        return Matft.not_equal(l_scalar, r_mfarray)
    }
}

