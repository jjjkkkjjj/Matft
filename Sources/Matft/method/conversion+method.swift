//
//  conversion+method.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension MfArray{
    
    /// Create another typed mfarray. Created mfarray will be different object from original one
    /// - Parameters:
    ///   - newtype: A new type
    ///   - mforder: (Optional) An order
    /// - Returns: New typed mfarray
    public func astype<U: MfTypeUsable>(newtype: U.Type, mforder: MfOrder = .Row) -> MfArray<U>{
        return Matft.astype(self, newtype: newtype, mforder: mforder)
    }
    
    /// Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
    /// - Parameters:
    ///   - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    /// - Returns: A transposed mfarray
    public func transpose(axes: [Int]? = nil) -> MfArray<T>{
        return Matft.transpose(self, axes: axes)
    }
    /// Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
    /// - Parameters:
    /// - Returns: A transposed mfarray
    public var T: MfArray<T>{
        return Matft.transpose(self)
    }
    
    /// Convert into new shaped mfarray
    /// - Parameters:
    ///   - new_shape: A new shape
    ///   - mforder: (Optional) order
    /// - Returns: The broadcasted mfarray
    public func reshape(_ new_shape: [Int], mforder: MfOrder = .Row) -> MfArray<T>{
        return Matft.reshape(self, new_shape: new_shape, mforder: mforder)
    }
    
    /// Create mfarray expanded dimension for a given axis
    /// - Parameter axis: The axis index to be expanded
    /// - Returns: The expanded mfarray
    public func expand_dims(axis: Int) -> MfArray<T>{
        return Matft.expand_dims(self, axis: axis)
    }
    
    /// Create mfarray expanded dimension for given axes
    /// - Parameter axes: The axes array to be expanded
    /// - Returns: The expanded mfarray
    public func expand_dims(axes: [Int]) -> MfArray<T>{
        return Matft.expand_dims(self, axes: axes)
    }
    
    /// Create mfarray removed for 1-dimension
    /// - Parameters:
    ///   - axis: (Optional) the removed axis
    /// - Returns: The squeezed mfarray
    public func squeeze(axis: Int? = nil) -> MfArray<T>{
        return Matft.squeeze(self, axis: axis)
    }
    
    /// Create mfarray removed for 1-dimension
    /// - Parameters:
    ///   - axes: (Optional) the removed axes array
    /// - Returns: The squeezed mfarray
    public func squeeze(axes: [Int]) -> MfArray<T>{
        return Matft.squeeze(self, axes: axes)
    }
    
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
    
    /// Flatten to 1d-mfarray
    /// - Parameters:
    ///   - mforder: An order
    /// - Returns: The flatten mfarray
    public func flatten(mforder: MfOrder = .Row) -> MfArray<T>{
        return Matft.flatten(self, mforder: mforder)
    }
    
    /// Reverse the mfarray order along given axis
    /// - Parameters:
    ///   - axis: (Optional) the axis index to be reversed
    /// - Returns: The flipped mfarray
    public func flip(axis: Int? = nil) -> MfArray<T>{
        return Matft.flip(self, axis: axis)
    }
    
    /// Reverse the mfarray order along given axis
    /// - Parameters:
    ///   - axes: (Optional) the axes array to be reversed
    /// - Returns: The flipped mfarray
    public func flip(axes: [Int]) -> MfArray<T>{
        return Matft.flip(self, axes: axes)
    }
}
