//
//  exception.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
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
