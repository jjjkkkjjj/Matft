//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/11.
//

import Foundation

/// Errors used internally by Matft.
/// - Note: This is an implementation detail of Matft and may change.
public enum MfInternalError: Error{
    /// An invalid axis.
    case axisError(_ message: String)
    /// An error while creating an array.
    case creationError(_ message: String)
    /// An error while converting an array.
    case conversionError(_ message: String)
    /// An error while calculating.
    case calculationError(_ message: String)
}
