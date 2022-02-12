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
    
    
    /// Create deep copy of mfarray. Deep means copied mfarray will be different object from original one
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - mforder: (Optional) order, default is nil, which means close to either row or column major if possibe.
    /// - Returns: Copied mfarray
    static public func deepcopy<T: MfTypeUsable>(_ mfarray: MfArray<T>, mforder: MfOrder? = nil) -> MfArray<T>{
        if let mforder = mforder {
            return to_contiguous(mfarray, mforder: mforder)
        }
        else{
            if mfarray.mfstructure.row_contiguous || mfarray.mfstructure.column_contiguous{
                return copy_all_mfarray(mfarray)
            }
            else if !isReverse(mfarray) && !mfarray.mfdata._isView{// not contain reverse and is not view, copy all}
                return copy_all_mfarray(mfarray)
            }
            else{
                return to_contiguous(mfarray, mforder: .Row)
            }
        }
        
    }
    
    
    /// Create a mfarray padded with a given value
    /// - Parameters:
    ///   - value: The padded value
    ///   - shape: The shape array
    ///   - mforder: (Optional) The order
    /// - Returns: The result mfarray
    static public func nums<T: MfTypeUsable>(_ value: T, shape: [Int], mforder: MfOrder = .Row) -> MfArray<T>{
        var shape = shape
        let size = shape2size(&shape)
        var new_flattenarray = Array(repeating: value, count: size)
        
        let newdata = MfData(flattenArray: &new_flattenarray)
        let newstructure = MfStructure(shape: shape, mforder: mforder)
        
        return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
    }
    
    /// Create a mfarray padded with a given value, and same structure as a given mfarray
    /// - Parameters:
    ///   - value: The padded value
    ///   - mfarray: The mfarray to be imitated
    ///   - mforder: (Optional) The order
    /// - Returns: The result mfarray
    static public func nums_like<T: MfTypeUsable>(_ value: T, mfarray: MfArray<T>, mforder: MfOrder = .Row) -> MfArray<T>{
        
        return Matft.nums(value, shape: mfarray.shape, mforder: mforder)
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
