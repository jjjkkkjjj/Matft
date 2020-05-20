//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation

public func +=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.add(l_mfarray, r_mfarray)
}
public func +=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.add(l_mfarray, r_mfarray)
}

public func -=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.sub(l_mfarray, r_mfarray)
}
public func -=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.sub(l_mfarray, r_mfarray)
}

public func *=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.mul(l_mfarray, r_mfarray)
}
public func *=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.mul(l_mfarray, r_mfarray)
}

public func /=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.div(l_mfarray, r_mfarray)
}
public func /=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.div(l_mfarray, r_mfarray)
}
