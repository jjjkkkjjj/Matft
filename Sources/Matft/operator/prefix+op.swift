//
//  prefix+op.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation

prefix operator -
public prefix func -<T>(_ mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.neg(mfarray)
}

prefix operator !
public prefix func !(_ mfarray: MfArray<Bool>) -> MfArray<Bool>{
    return Matft.logical_not(mfarray)
}
