//
//  error.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/05.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public enum MfError: Error{
    case NotSupportedError(String)
    
    enum LinAlgError: Error {
        case FactorizationError
        case SingularMatrix
    }
}
