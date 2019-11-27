//
//  operator.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public func +<T: MfNumeric>(left: Matrix2d<T>, right: Matrix2d<T>) -> Matrix2d<T>{
    return simple_operation_matrix2d(operator_: "+", left: left, right: right)
}

public func -<T: MfNumeric>(left: Matrix2d<T>, right: Matrix2d<T>) -> Matrix2d<T>{
    return simple_operation_matrix2d(operator_: "-", left: left, right: right)
}

//Hadamard product = element-wise product
public func *<T: MfNumeric>(left: Matrix2d<T>, right: Matrix2d<T>) -> Matrix2d<T>{
    return simple_operation_matrix2d(operator_: "*", left: left, right: right)
}

public func /<T: MfNumeric>(left: Matrix2d<T>, right: Matrix2d<T>) -> Matrix2d<T>{
    return simple_operation_matrix2d(operator_: "/", left: left, right: right)
}

private func simple_operation_matrix2d<T: MfNumeric>(operator_: String, left: Matrix2d<T>, right: Matrix2d<T>) -> Matrix2d<T>{
    precondition(_check_same_matrixshape(a: left, b: right), "cannot add due to unsame shape")
    let new = Matft.matrix2d.nums(num: 0, type: T.self, shape: left.shape)
    
    switch operator_ {
    case "+":
        for index in 0..<new.data.count{
            new.data[index] = left.data[index] + right.data[index]
        }
    case "-":
        for index in 0..<new.data.count{
            new.data[index] = left.data[index] - right.data[index]
        }
    case "*":
        for index in 0..<new.data.count{
            new.data[index] = left.data[index] * right.data[index]
        }
    case "/":
        for index in 0..<new.data.count{
            new.data[index] = left.data[index] / right.data[index]
        }
    default:
        precondition(false, "argument \'operator_\' was invalid")
    }
    
    
    return new
}

//transpose
/*
postfix operator ~
public postfix func ~<T: MfNumeric>(matrix: Matrix2d<T>) -> Matrix2d<T>{
    
    return matrix.transpose
}
*/



