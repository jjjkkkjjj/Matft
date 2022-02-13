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
    
    /// Append values to the end of an array.
    /// - Parameters:
    ///   - values: The mfarray to be appended
    ///   - axis: (Optional) An axis index
    /// - Returns: The appended mfarray
    public func append(values: MfArray<T>, axis: Int? = nil) -> MfArray<T>{
        return Matft.append(self, values: values, axis: axis)
    }
    
    // Append values to the end of an array.
    /// - Parameters:
    ///   - value: The value to be appended
    ///   - axis: (Optional) An axis index
    /// - Returns: The appended mfarray
    public func append(value: T, axis: Int? = nil) -> MfArray<T>{
        return Matft.append(self, value: value, axis: axis)
    }
    
    /// Take mfarray on given indices
    /// - Parameters:
    ///   - indices: The indices mfarray
    ///   - axis: (Optional) An axis index
    /// - Returns: The taken mfarray
    public func take(indices: MfArray<Int>, axis: Int? = nil) -> MfArray<T>{
        return Matft.take(self, indices: indices, axis: axis)
    }
}
