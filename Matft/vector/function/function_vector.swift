//
//  function_vector.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/06.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension Matft.vector{
    public static func nums<T: MfNumeric>(num: T, type: T.Type, size: Int, columned: Bool = false) -> Vector<T>{
        return Vector(vector: Array<T>(repeating: num, count: size), columned: columned)
    }
    
    //inner product
    public static func inner<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> T{
        return left ~* right
    }
    public static func inner<T: MfNumeric>(left: Vector<T>, right: T) -> T{
        return left ~* right
    }
    public static func inner<T: MfNumeric>(left: T, right: Vector<T>) -> T{
        return left ~* right
    }
    
    // cross product
    public static func cross2d<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> T{
        precondition(left.size == right.size && right.size == 2, "dimension must be 2")
        return left.data.pointee * (right.data + 1).pointee - (left.data + 1).pointee * right.data.pointee
    }
    public static func cross3d<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> Vector<T>{
        precondition(left.size == right.size && right.size == 3, "dimension must be 3")
        precondition(_check_same_vectorshape(a: left, b: right), "2 vector must be same shape")
        
        typealias TPointer = UnsafeMutablePointer<T>
        let newDataPointer = TPointer.allocate(capacity: left.size)
        newDataPointer.initialize(repeating: 0, count: left.size)
        
        let ly_rz = (left.data + 1).pointee * (right.data + 2).pointee
        let lz_ry = (left.data + 2).pointee * (right.data + 1).pointee
        newDataPointer.pointee = ly_rz - lz_ry
        
        let lz_rx = (left.data + 2).pointee * right.data.pointee
        let lx_rz = left.data.pointee * (right.data + 2).pointee
        (newDataPointer + 1).pointee = lz_rx - lx_rz
        
        let lx_ry = left.data.pointee * (right.data + 1).pointee
        let ly_rx = (left.data + 1).pointee * right.data.pointee
        (newDataPointer + 2).pointee = lx_ry - ly_rx
        
        return Vector(data: newDataPointer, size: left.size, columned: left.columned)
    }
    
    //outer product
    public static func outer<T: MfNumeric>(left: Vector<T>, right: Vector<T>) -> Vector<T>{
        return left * right
    }
    public static func outer<T: MfNumeric>(left: Vector<T>, right: T) -> Vector<T>{
        return left * right
    }
}
