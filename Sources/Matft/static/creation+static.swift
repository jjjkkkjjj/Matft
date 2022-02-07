//
//  creation+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/07.
//

import Foundation

extension Matft{

    /// Create shallow copy of mfarray. Shallow means copied mfarray will be  sharing data with original one
    /// - Parameter mfarray: An input mfarray
    /// - Returns: The VIEW mfarray based on an input mfarray
    static public func shallowcopy<T: MfTypeUsable>(_ mfarray: MfArray<T>) -> MfArray<T>{
        let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
        
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    

    /// Create arithmetic sequence mfarray
    /// - Parameters:
    ///   - start: the start term of arithmetic sequence
    ///   - to: the end term of arithmetic sequence, which is not included.
    ///   - by: the stride value
    ///   - shape: (Optional) shape
    ///   - mforder: (Optional) order, default is nil, which means close to row major
    /// - Returns: The created mfarray
    static public func arange<T: MfNumeric>(start: T, to: T, by: T.Stride, shape: [Int]? = nil, mforder: MfOrder = .Row) -> MfArray<T>{
        
        var new_flattenarray = Array(stride(from: start, to: to, by: by))
        let newdata = MfData(flattenArray: &new_flattenarray)
        let newstructure = MfStructure(shape: shape ?? [new_flattenarray.count], mforder: mforder)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}
