//
//  operator_mfarray.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/08.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation
import Accelerate

//basic vector calculation
public func +<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.add(left: left, right: right)
}
public func -<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.sub(left: left, right: right)
}
public func *<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.mul(left: left, right: right)
}
public func /<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.div(left: left, right: right)
}
//standard vector calculation
//broadcast
//add
public func +<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
    return Matft.mfarray.add(left: left, right: right)
}
public func +<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.add(left: left, right: right)
}
//minus
public func -<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
    return Matft.mfarray.sub(left: left, right: right)
}
public func -<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.sub(left: left, right: right)
}
//multiply
//Note that this operation is Hadamard Product
public func *<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
    return Matft.mfarray.mul(left: left, right: right)
}
public func *<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.mul(left: left, right: right)
}
//divide
public func /<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
    return Matft.mfarray.div(left: left, right: right)
}
public func /<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.div(left: left, right: right)
}

//assignment operator
//basic vector calculation
public func +=<T: MfNumeric>(left: inout MfArray<T>, right: MfArray<T>){
    left = Matft.mfarray.add(left: left, right: right)
}
public func -=<T: MfNumeric>(left: inout MfArray<T>, right: MfArray<T>){
    left = Matft.mfarray.sub(left: left, right: right)
}
public func *=<T: MfNumeric>(left: inout MfArray<T>, right: MfArray<T>){
    left = Matft.mfarray.mul(left: left, right: right)
}
public func /=<T: MfNumeric>(left: inout MfArray<T>, right: MfArray<T>){
    left = Matft.mfarray.div(left: left, right: right)
}
//broadcast
public func +=<T: MfNumeric>(left: inout MfArray<T>, right: T){
    left = left + right
}
public func -=<T: MfNumeric>(left: inout MfArray<T>, right: T){
    left = left - right
}
public func *=<T: MfNumeric>(left: inout MfArray<T>, right: T){
    left = left * right
}
public func /=<T: MfNumeric>(left: inout MfArray<T>, right: T){
    left = left / right
}

// mutiple two matrices
infix operator ~*
public func ~*<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.dot(left: left, right: right)
}
public func ~*<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
    return Matft.mfarray.dot(left: left, right: right)
}
public func ~*<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
    return Matft.mfarray.dot(left: left, right: right)
}
