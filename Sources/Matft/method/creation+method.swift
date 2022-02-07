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
}
