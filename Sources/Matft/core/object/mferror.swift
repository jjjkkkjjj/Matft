//
//  exception.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

/// Errors thrown by Matft functions.
public enum MfError: Error{
    /// An error while creating an array.
    case creationError(_ message: String)
    /// An error while converting an array.
    case conversionError(_ message: String)
    /// An error while calculating.
    case calculationError(_ message: String)
    
    /// Errors thrown by the linear algebra functions in `Matft.linalg` (the counterpart of `numpy.linalg.LinAlgError`).
    public enum LinAlgError: Error{
        /// LAPACK reported an illegal argument value during a factorization.
        case factorizationError(_ message: String)
        /// The matrix is singular (e.g. the LU factor `U` is exactly singular), so the result could not be computed.
        case singularMatrix(_ message: String)
        /// An iterative algorithm (e.g. the QR algorithm for eigenvalues, or SVD) failed to converge.
        case notConverge(_ message: String)
        /// A real result was requested but complex values were found.
        case foundComplex(_ message: String)
    }
}
