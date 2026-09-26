//
//  infix.swift
//  Matft
//
//  Created by AM19A0 on 2020/02/28.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

/// Element-wise addition of two arrays with broadcasting. Equivalent to `numpy.add` (`a + b` in Numpy).
///
/// Same as `Matft.add(_:_:)`. Complex arrays are supported.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func +(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.add(l_mfarray, r_mfarray)
}
/// Element-wise addition of an array and a scalar. Equivalent to `a + scalar` in Numpy.
///
/// Same as `Matft.add(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new array.
public func +<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.add(l_mfarray, r_scalar)
}
/// Element-wise addition of a scalar and an array. Equivalent to `scalar + a` in Numpy.
///
/// Same as `Matft.add(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func +<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.add(l_scalar, r_mfarray)
}

/// Element-wise subtraction of two arrays with broadcasting. Equivalent to `numpy.subtract` (`a - b` in Numpy).
///
/// Same as `Matft.sub(_:_:)`. Complex arrays are supported.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func -(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.sub(l_mfarray, r_mfarray)
}
/// Element-wise subtraction of an array and a scalar. Equivalent to `a - scalar` in Numpy.
///
/// Same as `Matft.sub(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new array.
public func -<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.sub(l_mfarray, r_scalar)
}
/// Element-wise subtraction of a scalar and an array. Equivalent to `scalar - a` in Numpy.
///
/// Same as `Matft.sub(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func -<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.sub(l_scalar, r_mfarray)
}

/// Element-wise multiplication of two arrays with broadcasting. Equivalent to `numpy.multiply` (`a * b` in Numpy).
///
/// Same as `Matft.mul(_:_:)`. Complex arrays are supported.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func *(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.mul(l_mfarray, r_mfarray)
}
/// Element-wise multiplication of an array and a scalar. Equivalent to `a * scalar` in Numpy.
///
/// Same as `Matft.mul(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new array.
public func *<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.mul(l_mfarray, r_scalar)
}
/// Element-wise multiplication of a scalar and an array. Equivalent to `scalar * a` in Numpy.
///
/// Same as `Matft.mul(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func *<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.mul(l_scalar, r_mfarray)
}

/// Element-wise division of two arrays with broadcasting. Equivalent to `numpy.divide` (`a / b` in Numpy).
///
/// Same as `Matft.div(_:_:)`. Complex arrays are supported.
/// Like Numpy's true division, the result of non-`Double` operands is `.Float` (integer arrays are not floor-divided).
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func /(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.div(l_mfarray, r_mfarray)
}
/// Element-wise division of an array and a scalar. Equivalent to `a / scalar` in Numpy.
///
/// Same as `Matft.div(_:_:)`.
/// Like Numpy's true division, the result of non-`Double` operands is `.Float` (integer arrays are not floor-divided).
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new array.
public func /<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.div(l_mfarray, r_scalar)
}
/// Element-wise division of a scalar and an array. Equivalent to `scalar / a` in Numpy.
///
/// Same as `Matft.div(_:_:)`.
/// Like Numpy's true division, the result of non-`Double` operands is `.Float` (integer arrays are not floor-divided).
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new array.
public func /<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.div(l_scalar, r_mfarray)
}

/// Element-wise `==` comparison of two arrays with broadcasting. Equivalent to `numpy.equal` (`a == b` in Numpy); use `==` to get a single `Bool`.
///
/// Same as `Matft.equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func ===(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.equal(l_mfarray, r_mfarray)
}
/// Element-wise `==` comparison of an array and a scalar. Equivalent to `numpy.equal` (`a == b` in Numpy); use `==` to get a single `Bool`.
///
/// Same as `Matft.equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new `.Bool` array.
public func ===<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.equal(l_mfarray, r_scalar)
}
/// Element-wise `==` comparison of a scalar and an array. Equivalent to `numpy.equal` (`a == b` in Numpy); use `==` to get a single `Bool`.
///
/// Same as `Matft.equal(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func ===<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.equal(l_scalar, r_mfarray)
}
/// Element-wise `!=` comparison of two arrays with broadcasting. Equivalent to `numpy.not_equal` (`a != b` in Numpy).
///
/// Same as `Matft.not_equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func !==(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.not_equal(l_mfarray, r_mfarray)
}
/// Element-wise `!=` comparison of an array and a scalar. Equivalent to `numpy.not_equal` (`a != b` in Numpy).
///
/// Same as `Matft.not_equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new `.Bool` array.
public func !==<T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.not_equal(l_mfarray, r_scalar)
}
/// Element-wise `!=` comparison of a scalar and an array. Equivalent to `numpy.not_equal` (`a != b` in Numpy).
///
/// Same as `Matft.not_equal(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func !==<T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.not_equal(l_scalar, r_mfarray)
}

extension MfArray: Equatable{
    /// Returns whether two arrays have the same shape and the same elements. Equivalent to `numpy.array_equal`.
    ///
    /// Same as `Matft.allEqual(_:_:)`. The element types do not have to match.
    /// Floating point elements are compared with a tolerance (`1e-5` for non-`Double`, `1e-10` for `Double`),
    /// and NaN is never equal. Use `===` for an element-wise comparison.
    /// - Parameters:
    ///   - lhs: The left array.
    ///   - rhs: The right array.
    /// - Returns: `true` if the shapes are equal and all elements are equal.
    public static func == (lhs: MfArray, rhs: MfArray) -> Bool {
        return Matft.allEqual(lhs, rhs)
    }
}
// Not inherit Comparable!
/// Element-wise `<` comparison of two arrays with broadcasting. Equivalent to `numpy.less` (`a < b` in Numpy).
///
/// Same as `Matft.less(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func <(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.less(l_mfarray, r_mfarray)
}
/// Element-wise `<` comparison of an array and a scalar. Equivalent to `numpy.less` (`a < b` in Numpy).
///
/// Same as `Matft.less(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new `.Bool` array.
public func < <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.less(l_mfarray, r_scalar)
}
/// Element-wise `<` comparison of a scalar and an array. Equivalent to `numpy.less` (`a < b` in Numpy).
///
/// Same as `Matft.less(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func < <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.less(l_scalar, r_mfarray)
}
/// Element-wise `<=` comparison of two arrays with broadcasting. Equivalent to `numpy.less_equal` (`a <= b` in Numpy).
///
/// Same as `Matft.less_equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func <=(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.less_equal(l_mfarray, r_mfarray)
}
/// Element-wise `<=` comparison of an array and a scalar. Equivalent to `numpy.less_equal` (`a <= b` in Numpy).
///
/// Same as `Matft.less_equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new `.Bool` array.
public func <= <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.less_equal(l_mfarray, r_scalar)
}
/// Element-wise `<=` comparison of a scalar and an array. Equivalent to `numpy.less_equal` (`a <= b` in Numpy).
///
/// Same as `Matft.less_equal(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func <= <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.less_equal(l_scalar, r_mfarray)
}

/// Element-wise `>` comparison of two arrays with broadcasting. Equivalent to `numpy.greater` (`a > b` in Numpy).
///
/// Same as `Matft.greater(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func >(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.greater(l_mfarray, r_mfarray)
}
/// Element-wise `>` comparison of an array and a scalar. Equivalent to `numpy.greater` (`a > b` in Numpy).
///
/// Same as `Matft.greater(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new `.Bool` array.
public func > <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.greater(l_mfarray, r_scalar)
}
/// Element-wise `>` comparison of a scalar and an array. Equivalent to `numpy.greater` (`a > b` in Numpy).
///
/// Same as `Matft.greater(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func > <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.greater(l_scalar, r_mfarray)
}
/// Element-wise `>=` comparison of two arrays with broadcasting. Equivalent to `numpy.greater_equal` (`a >= b` in Numpy).
///
/// Same as `Matft.greater_equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func >=(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.greater_equal(l_mfarray, r_mfarray)
}
/// Element-wise `>=` comparison of an array and a scalar. Equivalent to `numpy.greater_equal` (`a >= b` in Numpy).
///
/// Same as `Matft.greater_equal(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left operand.
///   - r_scalar: The right scalar operand.
/// - Returns: A new `.Bool` array.
public func >= <T: MfTypable>(l_mfarray: MfArray, r_scalar: T) -> MfArray{
    return Matft.greater_equal(l_mfarray, r_scalar)
}
/// Element-wise `>=` comparison of a scalar and an array. Equivalent to `numpy.greater_equal` (`a >= b` in Numpy).
///
/// Same as `Matft.greater_equal(_:_:)`.
/// - Parameters:
///   - l_scalar: The left scalar operand.
///   - r_mfarray: The right operand.
/// - Returns: A new `.Bool` array.
public func >= <T: MfTypable>(l_scalar: T, r_mfarray: MfArray) -> MfArray{
    return Matft.greater_equal(l_scalar, r_mfarray)
}

infix operator *&: MultiplicationPrecedence //matmul
/// Matrix product of two arrays. Equivalent to `numpy.matmul` (the `@` operator in Numpy).
///
/// Same as `Matft.matmul(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left array.
///   - r_mfarray: The right array.
/// - Returns: A new array holding the matrix product.
public func *&(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.matmul(l_mfarray, r_mfarray)
}

infix operator *+: MultiplicationPrecedence //inner
/// Inner product of two arrays. Equivalent to `numpy.inner`.
///
/// Same as `Matft.inner(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left array.
///   - r_mfarray: The right array.
/// - Returns: A new array holding the inner product.
public func *+(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.inner(l_mfarray, r_mfarray)
}

infix operator *^: MultiplicationPrecedence //cross
/// Cross product of two arrays of 2- or 3-element vectors. Equivalent to `numpy.cross`.
///
/// Same as `Matft.cross(_:_:)`.
/// - Parameters:
///   - l_mfarray: The left array.
///   - r_mfarray: The right array.
/// - Returns: A new array holding the cross product.
public func *^(l_mfarray: MfArray, r_mfarray: MfArray) -> MfArray{
    return Matft.cross(l_mfarray, r_mfarray)
}

infix operator +++ : AdditionPrecedence
internal func +++<T: vDSP_ComplexTypable>(lhs: UnsafeMutablePointer<T>, rhs: Int) -> T {
    return T(realp: lhs.pointee.realp + rhs, imagp: lhs.pointee.imagp + rhs)
}
