//
//  prefix.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/29.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

prefix operator -
public prefix func -<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.neg(mfarray)
}

prefix operator !
public prefix func !<T: MfTypable>(_ mfarray: MfArray<T>) -> MfArray<T>{
    return Matft.logical_not(mfarray)
}
