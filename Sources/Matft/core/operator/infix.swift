//
//  infix.swift
//  Matft
//
//  Created by AM19A0 on 2020/02/28.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public func +(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mfarray.add(l_mfarray, r_mfarray)
}
public func -(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mfarray.sub(l_mfarray, r_mfarray)
}
public func *(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mfarray.mul(l_mfarray, r_mfarray)
}
public func /(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mfarray.div(l_mfarray, r_mfarray)
}
public func ===(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mfarray.equal(l_mfarray, r_mfarray)
}

extension MfArray: Equatable{
    public static func == (lhs: MfArray, rhs: MfArray) -> Bool {
        return Matft.mfarray.allEqual(lhs, rhs)
    }
}

infix operator *&: MultiplicationPrecedence //matmul
public func *&(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mfarray.matmul(l_mfarray, r_mfarray)
}
