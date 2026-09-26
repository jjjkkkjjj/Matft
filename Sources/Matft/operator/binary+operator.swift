//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation

/// Element-wise addition assignment with an array (`a += b`).
///
/// Same as `l_mfarray = Matft.add(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right operand, broadcast to `l_mfarray`.
public func +=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.add(l_mfarray, r_mfarray)
}
/// Element-wise addition assignment with a scalar (`a += scalar`).
///
/// Same as `l_mfarray = Matft.add(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right scalar operand.
public func +=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.add(l_mfarray, r_mfarray)
}

/// Element-wise subtraction assignment with an array (`a -= b`).
///
/// Same as `l_mfarray = Matft.sub(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right operand, broadcast to `l_mfarray`.
public func -=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.sub(l_mfarray, r_mfarray)
}
/// Element-wise subtraction assignment with a scalar (`a -= scalar`).
///
/// Same as `l_mfarray = Matft.sub(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right scalar operand.
public func -=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.sub(l_mfarray, r_mfarray)
}

/// Element-wise multiplication assignment with an array (`a *= b`).
///
/// Same as `l_mfarray = Matft.mul(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right operand, broadcast to `l_mfarray`.
public func *=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.mul(l_mfarray, r_mfarray)
}
/// Element-wise multiplication assignment with a scalar (`a *= scalar`).
///
/// Same as `l_mfarray = Matft.mul(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right scalar operand.
public func *=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.mul(l_mfarray, r_mfarray)
}

/// Element-wise division assignment with an array (`a /= b`).
///
/// Same as `l_mfarray = Matft.div(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right operand, broadcast to `l_mfarray`.
public func /=(l_mfarray: inout MfArray, r_mfarray: MfArray){
    l_mfarray = Matft.div(l_mfarray, r_mfarray)
}
/// Element-wise division assignment with a scalar (`a /= scalar`).
///
/// Same as `l_mfarray = Matft.div(l_mfarray, r)`.
/// - Note: Unlike Numpy, this is not in-place: a new array is assigned to `l_mfarray`,
///   so other references and views of the original array are not modified.
/// - Parameters:
///   - l_mfarray: The array to update.
///   - r_mfarray: The right scalar operand.
public func /=<T: MfTypable>(l_mfarray: inout MfArray, r_mfarray: T){
    l_mfarray = Matft.div(l_mfarray, r_mfarray)
}
