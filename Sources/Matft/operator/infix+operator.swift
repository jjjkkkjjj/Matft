//
//  infix.swift
//  Matft
//
//  Created by AM19A0 on 2020/02/28.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public func +(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.add(l_mfarray, r_mfarray)
}
public func +<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.add(l_mfarray, r_scalar)
}
public func +<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.add(l_scalar, r_mfarray)
}

public func -(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.sub(l_mfarray, r_mfarray)
}
public func -<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.sub(l_mfarray, r_scalar)
}
public func -<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.sub(l_scalar, r_mfarray)
}

public func *(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mul(l_mfarray, r_mfarray)
}
public func *<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.mul(l_mfarray, r_scalar)
}
public func *<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.mul(l_scalar, r_mfarray)
}

public func /(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.div(l_mfarray, r_mfarray)
}
public func /<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.div(l_mfarray, r_scalar)
}
public func /<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.div(l_scalar, r_mfarray)
}

public func ===(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.equal(l_mfarray, r_mfarray)
}
public func ===<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.equal(l_mfarray, r_scalar)
}
public func ===<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.equal(l_scalar, r_mfarray)
}
public func !==(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.not_equal(l_mfarray, r_mfarray)
}
public func !==<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.not_equal(l_mfarray, r_scalar)
}
public func !==<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.not_equal(l_scalar, r_mfarray)
}

extension MfArray: Equatable{
    public static func == (lhs: MfArray, rhs: MfArray) -> Bool {
        return Matft.allEqual(lhs, rhs)
    }
}
// Not inherit Comparable!
public func <(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.less(l_mfarray, r_mfarray)
}
public func < <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.less(l_mfarray, r_scalar)
}
public func < <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.less(l_scalar, r_mfarray)
}
public func <=(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.less_equal(l_mfarray, r_mfarray)
}
public func <= <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.less_equal(l_mfarray, r_scalar)
}
public func <= <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.less_equal(l_scalar, r_mfarray)
}

public func >(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.greater(l_mfarray, r_mfarray)
}
public func > <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.greater(l_mfarray, r_scalar)
}
public func > <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.greater(l_scalar, r_mfarray)
}
public func >=(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.greater_equal(l_mfarray, r_mfarray)
}
public func >= <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.greater_equal(l_mfarray, r_scalar)
}
public func >= <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.greater_equal(l_scalar, r_mfarray)
}

infix operator *&: MultiplicationPrecedence //matmul
public func *&(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.matmul(l_mfarray, r_mfarray)
}

infix operator *+: MultiplicationPrecedence //inner
public func *+(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.inner(l_mfarray, r_mfarray)
}

infix operator *^: MultiplicationPrecedence //cross
public func *^(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.cross(l_mfarray, r_mfarray)
}

infix operator +++ : AdditionPrecedence
internal func +++<T: vDSP_ComplexTypable>(lhs: UnsafeMutablePointer<T>, rhs: Int) -> T {
    return T(realp: lhs.pointee.realp + rhs, imagp: lhs.pointee.imagp + rhs)
}
