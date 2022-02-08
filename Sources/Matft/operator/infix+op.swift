//
//  infix+op.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation

// 2 mfarray operation
public func +<T: MfNumeric>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.add(l_mfarray, r_mfarray)
}
public func -<T: MfNumeric>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.sub(l_mfarray, r_mfarray)
}
public func *<T: MfNumeric>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.mul(l_mfarray, r_mfarray)
}
public func /<T: MfNumeric>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.div(l_mfarray, r_mfarray)
}
public func ===<T>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.equal(l_mfarray, r_mfarray)
}
public func !==<T>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.not_equal(l_mfarray, r_mfarray)
}


// left mfarray, right scalar operation
public func +<T: MfNumeric>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.add(l_mfarray, r_scalar)
}
public func -<T: MfNumeric>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.sub(l_mfarray, r_scalar)
}
public func *<T: MfNumeric>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.mul(l_mfarray, r_scalar)
}
public func /<T: MfNumeric>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<T>{
    return Matft.div(l_mfarray, r_scalar)
}
public func ===<T>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<Bool>{
    return Matft.equal(l_mfarray, r_scalar)
}
public func !==<T>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<Bool>{
    return Matft.not_equal(l_mfarray, r_scalar)
}

// right mfarray, left scalar operation
public func +<T: MfNumeric>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.add(l_scalar, r_mfarray)
}
public func -<T: MfNumeric>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.sub(l_scalar, r_mfarray)
}
public func *<T: MfNumeric>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.mul(l_scalar, r_mfarray)
}
public func /<T: MfNumeric>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.div(l_scalar, r_mfarray)
}
public func ===<T>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.equal(l_scalar, r_mfarray)
}
public func !==<T>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.not_equal(l_scalar, r_mfarray)
}

extension MfArray: Equatable{
    public static func == (lhs: MfArray, rhs: MfArray) -> Bool {
        return Matft.equalAll(lhs, rhs)
    }
}
