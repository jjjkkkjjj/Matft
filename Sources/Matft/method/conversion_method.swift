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
    
    /// Convert a given mfarray into a contiguous one
    /// - Parameters:
    ///   - mforder: An order
    /// - Returns: The contiguous mfarray
    public func to_contiguous(mforder: MfOrder) -> MfArray<T>{
        return Matft.to_contiguous(self, mforder: mforder)
    }
}
