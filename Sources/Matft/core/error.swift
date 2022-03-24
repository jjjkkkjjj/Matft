//
//  error.swift
//  
//
//  Created by Junnosuke Kado on 2022/03/24.
//

import Foundation

public enum MfError: Error{
    case creationError(_ message: String)
    case conversionError(_ message: String)
    case calculationError(_ message: String)
    
    public enum LinAlgError: Error{
        case factorizationError(_ message: String)
        case singularMatrix(_ message: String)
        case notConverge(_ message: String)
        case foundComplex(_ message: String)
    }
}
