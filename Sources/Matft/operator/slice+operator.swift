//
//  mfslice_op.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/01.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
/*
precedencegroup MfSlicing {
  associativity: left
}*/

prefix operator ~< //a[~<2] = a[:2]
/// Creates a slice from the beginning up to `to` (exclusive): `a[~<2]` is `a[:2]` in Numpy.
///
/// ```swift
/// let b = Matft.arange(start: 0, to: 10, by: 1)
/// b[~<3]       // b[:3]
/// b[2~<]       // b[2:]
/// b[1~<8~<3]   // b[1:8:3] -> [1, 4, 7]
/// b[~<<3]      // b[::3]   -> [0, 3, 6, 9]
/// b[8~<1~<-3]  // b[8:1:-3] -> [8, 5, 2]
/// ```
/// - Parameters:
///   - to: The end index (exclusive). Negative values count from the end.
/// - Returns: The slice `:to`.
public prefix func ~<(to: Int) -> MfSlice{
    return MfSlice(to: to)
}
prefix operator ~<- //a[~<-2] = a[:-2]
/// Creates a slice up to a negative end index: `a[~<-2]` is `a[:-2]` in Numpy.
/// - Parameters:
///   - to: The end index without its sign; the slice ends at `-to` (exclusive).
/// - Returns: The slice `:-to`.
public prefix func ~<-(to: Int) -> MfSlice{
    return MfSlice(to: -to)
}

//a[0~<] = a[:]
//a[2~<] = a[2:]
//a[-2~<] = a[-2:]
postfix operator ~<
/// Creates a slice from `start` to the end: `a[2~<]` is `a[2:]` and `a[0~<]` is `a[:]` in Numpy.
/// - Parameters:
///   - start: The start index. Negative values count from the end (write `(-2)~<`).
/// - Returns: The slice `start:`.
public postfix func ~<(start: Int) -> MfSlice{
    return MfSlice(start: start)
}

prefix operator ~<~< //a[~<~<2] = a[::2]
/// Creates a slice over the whole axis with step `by`: `a[~<~<2]` is `a[::2]` in Numpy. Same as `~<<`.
/// - Parameters:
///   - by: The step.
/// - Returns: The slice `::by`.
public prefix func ~<~<(by: Int) -> MfSlice{
    return MfSlice(by: by)
}
prefix operator ~<~<- //a[~<~<-2] = a[::-2]
/// Creates a slice over the whole axis with a negative step: `a[~<~<-2]` is `a[::-2]` in Numpy. Same as `~<<-`.
/// - Parameters:
///   - by: The step without its sign; the step is `-by`.
/// - Returns: The slice `::-by`.
public prefix func ~<~<-(by: Int) -> MfSlice{
    return MfSlice(by: -by)
}
// abbr ver. alias
prefix operator ~<< //a[~<~<2] = a[::2]
/// Creates a slice over the whole axis with step `by`: `a[~<<2]` is `a[::2]` in Numpy (short form of `~<~<`).
/// - Parameters:
///   - by: The step.
/// - Returns: The slice `::by`.
public prefix func ~<<(by: Int) -> MfSlice{
    return MfSlice(by: by)
}
prefix operator ~<<- //a[~<~<-2] = a[::-2]
/// Creates a slice over the whole axis with a negative step: `a[~<<-2]` is `a[::-2]` in Numpy (short form of `~<~<-`).
/// - Parameters:
///   - by: The step without its sign; the step is `-by`.
/// - Returns: The slice `::-by`.
public prefix func ~<<-(by: Int) -> MfSlice{
    return MfSlice(by: -by)
}

//a[2~<~<2] = a[2::2]
//a[-2~<~<2] = a[-2::2]
infix operator ~<~<: AdditionPrecedence
/// Creates a slice from `start` to the end with step `by`: `a[2~<~<2]` is `a[2::2]` in Numpy. Same as `~<<`.
/// - Parameters:
///   - start: The start index.
///   - by: The step.
/// - Returns: The slice `start::by`.
public func ~<~<(start: Int, by: Int) -> MfSlice{
    return MfSlice(start: start, by: by)
}
//a[2~<~<-2] = a[2::-2]
//a[-2~<~<-2] = a[-2::-2]
infix operator ~<~<-: AdditionPrecedence
/// Creates a slice from `start` with a negative step: `a[2~<~<-2]` is `a[2::-2]` in Numpy. Same as `~<<-`.
/// - Parameters:
///   - start: The start index.
///   - by: The step without its sign; the step is `-by`.
/// - Returns: The slice `start::-by`.
public func ~<~<-(start: Int, by: Int) -> MfSlice{
    return MfSlice(start: start, by: -by)
}
// abbr ver. alias
//a[2~<<2] = a[2::2]
//a[-2~<<2] = a[-2::2]
infix operator ~<<: AdditionPrecedence
/// Creates a slice from `start` to the end with step `by`: `a[2~<<2]` is `a[2::2]` in Numpy (short form of `~<~<`).
/// - Parameters:
///   - start: The start index.
///   - by: The step.
/// - Returns: The slice `start::by`.
public func ~<<(start: Int, by: Int) -> MfSlice{
    return MfSlice(start: start, by: by)
}
//a[2~<<-2] = a[2::-2]
//a[-2~<<-2] = a[-2::-2]
infix operator ~<<-: AdditionPrecedence
/// Creates a slice from `start` with a negative step: `a[2~<<-2]` is `a[2::-2]` in Numpy (short form of `~<~<-`).
/// - Parameters:
///   - start: The start index.
///   - by: The step without its sign; the step is `-by`.
/// - Returns: The slice `start::-by`.
public func ~<<-(start: Int, by: Int) -> MfSlice{
    return MfSlice(start: start, by: -by)
}

//a[1~<3] = a[1:3]
//a[-1~<3] = a[-1:3]
infix operator ~<: AdditionPrecedence
/// Creates a slice from `start` to `to` (exclusive): `a[1~<3]` is `a[1:3]` in Numpy.
/// - Parameters:
///   - start: The start index.
///   - to: The end index (exclusive).
/// - Returns: The slice `start:to`.
public func ~< (start: Int, to: Int) -> MfSlice {
    return MfSlice(start: start, to: to)
}
//a[1~<-3] = a[1:-3]
//a[-1~<-3] = a[-1:-3]
infix operator ~<-: AdditionPrecedence
/// Creates a slice from `start` to a negative end index: `a[1~<-3]` is `a[1:-3]` in Numpy.
/// - Parameters:
///   - start: The start index.
///   - to: The end index without its sign; the slice ends at `-to` (exclusive).
/// - Returns: The slice `start:-to`.
public func ~<- (start: Int, to: Int) -> MfSlice {
    return MfSlice(start: start, to: -to)
}

//a[1~<9~<2] = a[1:9:2]
/// Adds a step to a `start~<to` slice: `a[1~<9~<2]` is `a[1:9:2]` in Numpy.
/// - Parameters:
///   - mfslice: A slice created by `start~<to`. Its step is replaced.
///   - by: The step.
/// - Returns: The slice `start:to:by`.
public func ~< (mfslice: MfSlice, by: Int) -> MfSlice{
    return MfSlice(start: mfslice.start, to: mfslice.to, by: by)
}
//a[1~<9~<-2] = a[1:9:-2]
/// Adds a negative step to a `start~<to` slice: `a[8~<1~<-3]` is `a[8:1:-3]` in Numpy.
/// - Parameters:
///   - mfslice: A slice created by `start~<to`. Its step is replaced.
///   - by: The step without its sign; the step is `-by`.
/// - Returns: The slice `start:to:-by`.
public func ~<- (mfslice: MfSlice, by: Int) -> MfSlice{
    return MfSlice(start: mfslice.start, to: mfslice.to, by: -by)
}
