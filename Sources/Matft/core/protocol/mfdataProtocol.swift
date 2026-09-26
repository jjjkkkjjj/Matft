//
//  File.swift
//  
//
//  Created by AM19A0 on 2023/02/06.
//

import Foundation
#if canImport(CoreML)
import CoreML
#endif

/// A type that can own the memory shared by an `MfData` (an `MfData` itself, or an `MLMultiArray`).
public protocol MfDataBasable {}

extension MfData: MfDataBasable{}

#if canImport(CoreML)
@available(macOS 10.13, *)
@available(iOS 14.0, *)
extension MLMultiArray: MfDataBasable{}
#endif
