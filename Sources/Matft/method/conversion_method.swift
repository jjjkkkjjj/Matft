//
//  conversion_method.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension MfArray{
    
    /// Create broadcasted mfarray.
    /// - Parameters:
    ///   - shape: A new shape
    /// - Returns: The broadcasted mfarray
    public func broadcast_to(shape: [Int]) -> MfArray{
        return Matft.broadcast_to(self, shape: shape)
    }
}
