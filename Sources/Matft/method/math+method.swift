//
//  math+method.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension MfArray{
    
    
    /// Calculate sign of mfarray
    /// - Returns: The result mfarray
    public func sign() -> MfArray<MfArrayType>{
        return Matft.math.sign(self)
    }
}
