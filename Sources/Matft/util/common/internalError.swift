//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/11.
//

import Foundation

public enum MfInternalError: Error{
    case axisError(_ message: String)
    case creationError(_ message: String)
    case conversionError(_ message: String)
    case calculationError(_ message: String)
}
