//
//  math+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension Matft.math{

    /// Calculate sign of mfarray
    /// - Parameter mfarray: An input mfarray
    /// - Returns: The result mfarray
    public static func sign<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        return sign_by_vDSP(mfarray)
    }
}
