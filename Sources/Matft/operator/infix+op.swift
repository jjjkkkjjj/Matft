//
//  infix+op.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation

public func ===<T>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.equal(l_mfarray, r_mfarray)
}
public func ===<T>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<Bool>{
    return Matft.equal(l_mfarray, r_scalar)
}
public func ===<T>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.equal(l_scalar, r_mfarray)
}

public func !==<T>(l_mfarray: MfArray<T>, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.not_equal(l_mfarray, r_mfarray)
}
public func !==<T>(l_mfarray: MfArray<T>, r_scalar: T) -> MfArray<Bool>{
    return Matft.not_equal(l_mfarray, r_scalar)
}
public func !==<T>(l_scalar: T, r_mfarray: MfArray<T>) -> MfArray<Bool>{
    return Matft.not_equal(l_scalar, r_mfarray)
}

extension MfArray: Equatable{
    public static func == (lhs: MfArray, rhs: MfArray) -> Bool {
        return Matft.equalAll(lhs, rhs)
    }
}