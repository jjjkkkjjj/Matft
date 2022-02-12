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
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
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
    
    
    /// Create identity matrix. The size is (dim, dim)
    /// - Parameters:
    ///   - dim: The dimension, returned mfarray's shape is (dim, dim)
    ///   - mforder: (Optional) The order, default is nil, which means close to row major
    /// - Returns: The created mfarray
    static public func eye<T: MfTypeUsable>(dim: Int, mforder: MfOrder = .Row) -> MfArray<T>{
        var eye = Array(repeating: T.StoredType.zero, count: dim*dim)
        for i in 0..<dim{
            eye[i*dim+i] = T.StoredType.from(1)
        }
        let newdata = MfData(T.self, storedFlattenArray: &eye)
        let newstructure = MfStructure(shape: [dim, dim], mforder: mforder)
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
    /// Create diagonal matrix. The size is (dim, dim)
    /// - Parameters:
    ///   - v: the diagonal values, returned mfarray's shape is (dim, dim), whose dim is length of v
    ///   - k: Diagonal position.
    ///   - mforder: (Optional) The order, default is nil, which means close to row major
    /// - Returns: The created mfarray
    static public func diag<T: MfTypeUsable>(v: [T], k: Int = 0, mforder: MfOrder = .Row) -> MfArray<T>{
        let dim = v.count + abs(k)
        var d = Array(repeating: T.zero, count: dim*dim)
        if k >= 0{
            for i in 0..<v.count{
                d[i*dim+(i+k)] = v[i]
            }
        }
        else{
            for i in 0..<v.count{
                d[(i-k)*dim+i] = v[i]
            }
        }
        
        return MfArray(d, shape: [dim, dim], mforder: mforder)
    }
    
    /// Create diagonal matrix. The size is (dim, dim)
    /// - Parameters:
    ///   - v: the diagonal values, returned mfarray's shape is (dim, dim), whose dim is length of v
    ///   - k: Diagonal position.
    ///   - mforder: (Optional) The order, default is nil, which means close to row major
    /// - Returns: The created mfarray
    static public func diag<T: MfTypeUsable>(v: MfArray<T>, k: Int = 0, mforder: MfOrder = .Row) -> MfArray<T>{
        let dim = v.size + abs(k)
        var d = Array(repeating: T.StoredType.zero, count: dim*dim)
        let _v = v.mfdata.storedData
        if k >= 0{
            for i in 0..<_v.count{
                d[i*dim+(i+k)] = _v[i]
            }
        }
        else{
            for i in 0..<_v.count{
                d[(i-k)*dim+i] = _v[i]
            }
        }
        
        let newdata = MfData(T.self, storedFlattenArray: &d)
        let newstructure = MfStructure(shape: [dim, dim], mforder: mforder)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
}
