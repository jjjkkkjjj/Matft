//
//  infix.swift
//  Matft
//
//  Created by AM19A0 on 2020/02/28.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public func +<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.add(l_mfarray, r_mfarray)
}
public func +<T: MfTypable>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.add(l_mfarray, r_scalar)
}
public func +<T: MfTypable>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.add(l_scalar, r_mfarray)
}

public func -<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.sub(l_mfarray, r_mfarray)
}
public func -<T: MfTypable>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.sub(l_mfarray, r_scalar)
}
public func -<T: MfTypable>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.sub(l_scalar, r_mfarray)
}

public func *<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.mul(l_mfarray, r_mfarray)
}
public func *<T: MfTypable>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.mul(l_mfarray, r_scalar)
}
public func *<T: MfTypable>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.mul(l_scalar, r_mfarray)
}

public func /<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.div(l_mfarray, r_mfarray)
}
public func /<T: MfTypable>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.div(l_mfarray, r_scalar)
}
public func /<T: MfTypable>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.div(l_scalar, r_mfarray)
}

public func ===<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.equal(l_mfarray, r_mfarray)
}
public func ===<T: MfTypable>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<Bool>{
    return Matft.equal(l_mfarray, r_scalar)
}
public func ===<T: MfTypable>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.equal(l_scalar, r_mfarray)
}
public func !==<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.not_equal(l_mfarray, r_mfarray)
}
public func !==<T: MfTypable>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<Bool>{
    return Matft.not_equal(l_mfarray, r_scalar)
}
public func !==<T: MfTypable>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.not_equal(l_scalar, r_mfarray)
}

extension MfArray: Equatable{
    public static func == <T: MfTypable>(lhs: MfArray<T>, rhs: MfArray<T>) -> Bool {
        return Matft.allEqual(lhs, rhs)
    }
}

infix operator *&: MultiplicationPrecedence //matmul
public func *&<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.matmul(l_mfarray, r_mfarray)
}

infix operator *+: MultiplicationPrecedence //inner
public func *+<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.inner(l_mfarray, r_mfarray)
}

infix operator *^: MultiplicationPrecedence //cross
public func *^<T: MfTypable>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.cross(l_mfarray, r_mfarray)
}
