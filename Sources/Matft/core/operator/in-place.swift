//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation

public func +=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: MfArray<T>){
    l_mfarray = Matft.add(l_mfarray, r_mfarray)
}
public func +=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: T){
    l_mfarray = Matft.add(l_mfarray, r_mfarray)
}

public func -=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: MfArray<T>){
    l_mfarray = Matft.sub(l_mfarray, r_mfarray)
}
public func -=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: T){
    l_mfarray = Matft.sub(l_mfarray, r_mfarray)
}

public func *=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: MfArray<T>){
    l_mfarray = Matft.mul(l_mfarray, r_mfarray)
}
public func *=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: T){
    l_mfarray = Matft.mul(l_mfarray, r_mfarray)
}

public func /=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: MfArray<T>){
    l_mfarray = Matft.div(l_mfarray, r_mfarray)
}
public func /=<T: MfNumeric>(l_mfarray: inout MfArray<T>, r_mfarray: T){
    l_mfarray = Matft.div(l_mfarray, r_mfarray)
}
