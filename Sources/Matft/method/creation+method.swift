//
//  File.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation

extension MfArray{
    /// Create shallow copy of mfarray. Shallow means copied mfarray will be  sharing data with original one
    /// - Returns: The VIEW mfarray based on an input mfarray
    public func shallowcopy() -> MfArray<MfArrayType>{
        return Matft.shallowcopy(self)
    }
    
    /// Create deep copy of mfarray. Deep means copied mfarray will be different object from original one
    /// - Parameters:
    ///   - mforder: (Optional) order, default is nil, which means close to either row or column major if possibe.
    /// - Returns: Copied mfarray
    public func deepcopy(mforder: MfOrder? = nil) -> MfArray<MfArrayType>{
        return Matft.deepcopy(self, mforder: mforder)
    }
}
