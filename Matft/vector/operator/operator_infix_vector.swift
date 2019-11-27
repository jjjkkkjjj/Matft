//
//  operator_vector.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

//basic vector calculation
public func +<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> Vector<T>{
    return simple_operation_vector(operator_: "+", left: left, right: right)
}
public func -<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> Vector<T>{
    return simple_operation_vector(operator_: "-", left: left, right: right)
}
//Hadamard product = element-wise product
public func *<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> Vector<T>{
    return simple_operation_vector(operator_: "*", left: left, right: right)
}
public func /<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> Vector<T>{
    return simple_operation_vector(operator_: "/", left: left, right: right)
}
//standard vector calculation
//broadcast
public func +<T: MfNumeric>(left: Vector<T>, right: T) -> Vector<T>{
    let broadcastedVector = Matft.vector.nums(num: right, type: T.self, size: left.size, columned: left.columned)
    return simple_operation_vector(operator_: "+", left: left, right: broadcastedVector)
}
public func -<T: MfNumeric>(left: Vector<T>, right: T) -> Vector<T>{
    let broadcastedVector = Matft.vector.nums(num: right, type: T.self, size: left.size, columned: left.columned)
    return simple_operation_vector(operator_: "-", left: left, right: broadcastedVector)
}
public func *<T: MfNumeric>(left: Vector<T>, right: T) -> Vector<T>{
    let broadcastedVector = Matft.vector.nums(num: right, type: T.self, size: left.size, columned: left.columned)
    return simple_operation_vector(operator_: "*", left: left, right: broadcastedVector)
}
public func /<T: MfNumeric>(left: Vector<T>, right: T) -> Vector<T>{
    let broadcastedVector = Matft.vector.nums(num: right, type: T.self, size: left.size, columned: left.columned)
    return simple_operation_vector(operator_: "/", left: left, right: broadcastedVector)
}

//assignment operator
//basic vector calculation
public func +=<T: MfNumeric>(left: inout Vector<T>, right: Vector<T>){
    left = simple_operation_vector(operator_: "+", left: left, right: right)
}
public func -=<T: MfNumeric>(left: inout Vector<T>, right: Vector<T>){
    left = simple_operation_vector(operator_: "-", left: left, right: right)
}
public func *=<T: MfNumeric>(left: inout Vector<T>, right: Vector<T>){
    left = simple_operation_vector(operator_: "*", left: left, right: right)
}
public func /=<T: MfNumeric>(left: inout Vector<T>, right: Vector<T>){
    left = simple_operation_vector(operator_: "/", left: left, right: right)
}
//broadcast
public func +=<T: MfNumeric>(left: inout Vector<T>, right: T){
    left = left + right
}
public func -=<T: MfNumeric>(left: inout Vector<T>, right: T){
    left = left - right
}
public func *=<T: MfNumeric>(left: inout Vector<T>, right: T){
    left = left * right
}
public func /=<T: MfNumeric>(left: inout Vector<T>, right: T){
    left = left / right
}

//function for above calculation
private func simple_operation_vector<T: MfNumeric>(operator_: String, left: Vector<T>, right: Vector<T>) -> Vector<T>{
    precondition(_check_same_vectorshape(a: left, b: right), "cannot operate due to unsame size")
    typealias TPointer = UnsafeMutablePointer<T>
    let newDataPointer = TPointer.allocate(capacity: left.size)
    newDataPointer.initialize(repeating: 0, count: left.size)
    
    switch operator_ {
    case "+":
        for index in 0..<left.size{
            (newDataPointer + index).pointee = (left.data + index).pointee + (right.data + index).pointee
        }
    case "-":
        for index in 0..<left.size{
            (newDataPointer + index).pointee = (left.data + index).pointee - (right.data + index).pointee
        }
    case "*":
        for index in 0..<left.size{
            (newDataPointer + index).pointee = (left.data + index).pointee * (right.data + index).pointee
        }
    case "/":
        for index in 0..<left.size{
            (newDataPointer + index).pointee = (left.data + index).pointee / (right.data + index).pointee
        }
        /*
        do{
            
        }catch MfError.ZeroDivisionError()*/
        
    default:
        precondition(false, "argument \'operator_\' was invalid")
    }
    
    
    return Vector(data: newDataPointer, size: left.size, columned: left.columned)
}


//vector operation
//inner product
infix operator ~*
public func ~*<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> T{
    precondition(!left.columned && right.columned, "inner product is defined between columned vector(=left) and row vector(=right)")
    var innerValue = T.zero()
    for index in 0..<left.size{
        innerValue += (left.data + index).pointee * (right.data + index).pointee
    }
    return innerValue
}
public func ~*<T: MfNumeric>(left: T, right: Vector<T>) -> T{
    var innerValue = T.zero()
    for index in 0..<right.size{
        innerValue += left * (right.data + index).pointee
    }
    return innerValue
}
public func ~*<T: MfNumeric>(left: Vector<T>, right: T) -> T{
    var innerValue = T.zero()
    for index in 0..<left.size{
        innerValue += (left.data + index).pointee * right
    }
    return innerValue
}
