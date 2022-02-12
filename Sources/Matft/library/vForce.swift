//
//  vForce.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/08.
//

import Foundation

public typealias vForce_copysign_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void

public typealias vForce_math_func<T> = (UnsafeMutablePointer<T>, UnsafePointer<T>, UnsafePointer<Int32>) -> Void
