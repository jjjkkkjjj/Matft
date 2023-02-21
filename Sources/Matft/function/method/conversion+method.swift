//
//  conversion_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    /**
       Create another typed mfarray. Created mfarray will be different object from original one
       - parameters:
            - mftype: the type of mfarray
            - mforder: The order
    */
    public func astype(_ mftype: MfType, mforder: MfOrder = .Row) -> MfArray{
        return Matft.astype(self, mftype: mftype, mforder: mforder)
    }
    
    /**
        Convert real mfarray into complex mfarray
        - parameters:
            - isplace: Whether to operate in-place
    */
    internal func to_complex(_ inplace: Bool = true) -> MfArray{
        precondition(!self.mfdata._fromOtherDataSource, "Other data source couldn't be converted into Complex.")
        
        if self.isComplex{
            return self
        }
        
        let mfarray: MfArray
        if inplace{
            mfarray = self
        }
        else{
            mfarray = self.deepcopy(.Row)
        }
        
        switch mfarray.storedType{
        case .Float:
            let ptri = allocate_unsafeMRPtr(type: Float.self, count: mfarray.storedSize)
            mfarray.mfdata_base.data_imag = ptri
            mfarray.mfdata.data_imag = ptri
        case .Double:
            let ptri = allocate_unsafeMRPtr(type: Double.self, count: mfarray.storedSize)
            mfarray.mfdata_base.data_imag = ptri
            mfarray.mfdata.data_imag = ptri
        }
        return mfarray
    }
    
    /**
       Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
            - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    */
    public func transpose(axes: [Int]? = nil) -> MfArray{
        return Matft.transpose(self, axes: axes)
    }
    /**
       Create transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
    */
    public var T: MfArray{
        return Matft.transpose(self)
    }
    
    /**
       Convert new shaped mfarray
       - parameters:
            - newshape: the new shape
    */
    public func reshape(_ newshape: [Int]) -> MfArray{
        return Matft.reshape(self, newshape: newshape)
    }
    
    /**
       Convert MfArray to Swift's Array
       - parameters:
    */
    public func toArray() -> [Any]{
        return toSwiftArray(self)
    }
    
    /**
       Convert MfArray to flatten swift's array.
        - Parameters:
            - datatype: MfTypable Type. This must be same as corresponding MfType
        - Important:
            If you want flatten array, use `a.flatten().data as! [T]`
     */
    public func toFlattenArray<T: MfTypable, R>(datatype: T.Type, _ body: (T) throws -> R) rethrows -> [R]{
        precondition(MfType.mftype(value: T.zero) == self.mftype, "datatype must be '\(self.mftype).self', but got '\(T.self)'")
        
        var ret: [R] = []
        switch self.storedType {
        case .Float:
            try self.withContiguousDataUnsafeMPtrT(datatype: Float.self){
                ret.append(try body(T.from($0.pointee)))
            }
        case .Double:
            try self.withContiguousDataUnsafeMPtrT(datatype: Double.self){
                ret.append(try body(T.from($0.pointee)))
            }
        }
        
        return ret
    }
    
    /**
       Create broadcasted mfarray.
       - parameters:
            - shape: shape
    */
    public func broadcast_to(shape: [Int]) -> MfArray{
        return Matft.broadcast_to(self, shape: shape)
    }
    
    /**
       Create mfarray expanded dimension for given axis
       - parameters:
            - axis: the expanded axis
    */
    public func expand_dims(axis: Int) -> MfArray{
        return Matft.expand_dims(self, axis: axis)
    }
    /**
       Create mfarray expanded dimension for given axis
       - parameters:
            - axes: the list of expanded axes
    */
    public func expand_dims(axes: [Int]) -> MfArray{
        return Matft.expand_dims(self, axes: axes)
    }
    
    /**
       Create mfarray removed for 1-dimension
       - parameters:
            - axis: (Optional) the removed axis
    */
    public func squeeze(axis: Int? = nil) -> MfArray{
        return Matft.squeeze(self, axis: axis)
    }
    /**
       Create mfarray removed for 1-dimension
       - parameters:
            - mfarray: mfarray
            - axes: the list of  removed axes
    */
    public func squeeze(axes: [Int]) -> MfArray{
        return Matft.squeeze(self, axes: axes)
    }
    /**
       Convert order of stored data.
       - parameters:
            - mforder: mforder
    */
    public func to_contiguous(mforder: MfOrder) -> MfArray{
        return Matft.to_contiguous(self, mforder: mforder)
    }
    
    /**
       Reverse the mfarray order along given axis
       - parameters:
            - axis: (optional) the reversed axis
    */
    public func flip(axis: Int? = nil) -> MfArray{
        return Matft.flip(self, axis: axis)
    }
    /**
       Reverse the mfarray order along given axes
       - parameters:
            - axes: (optional) the reversed axis of list
    */
    public func flip(_ mfarray: MfArray, axes: [Int]? = nil) -> MfArray{
        return Matft.flip(self, axes: axes)
    }
    
    /**
       Clip the mfarray
       - parameters:
            - min: (optional) Minimum value. If nil is passed, handled as -inf
            - max: (optional) Maximum value. If nil is passed, handled as inf
    */
    public func clip<T: MfTypable>(min: T? = nil, max: T? = nil) -> MfArray{
        return Matft.clip(self, min: min, max: max)
    }
    
    /**
       Swap given axis1 and axis2
       - parameters:
            - axes: (optional) the reversed axis of list
    */
    public func swapaxes(axis1: Int, axis2: Int) -> MfArray{
        return Matft.swapaxes(self, axis1: axis1, axis2: axis2)
    }
    
    /**
       move from given axis to dstination axis
       - parameters:
            - src: Int
            - dst: Int
    */
    public func moveaxis(src: Int, dst: Int) -> MfArray{
        return Matft.moveaxis(self, src: src, dst: dst)
    }
    /**
       move from given axis to dstination axis
       - parameters:
            - src: [Int]
            - dst: [Int]
    */
    public func moveaxis(src: [Int], dst: [Int]) -> MfArray{
        return Matft.moveaxis(self, src: src, dst: dst)
    }
    
    /**
       Get sorted mfarray along given  axis
       - parameters:
            - axis: (Optional) axis, if not given, get summation for all elements
            - order: (Optional) ascending or descending. default is ascending
    */
    public func sort(axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        return Matft.sort(self, axis: axis, order: order)
    }
    /**
       Get sorted mfarray's indices along given  axis
       - parameters:
            - axis: (Optional) axis, if not given, get summation for all elements
            - order: (Optional) ascending or descending. default is ascending
    */
    public func argsort(axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        return Matft.argsort(self, axis: axis, order: order)
    }
    
    /**
       Roll array elements along a given axis.
       - parameters:
            - shift: The number of places by which elements are shifted.
            - axis: (Optional) axis, if not given, get summation for all elements
    */
    public func roll(shift: Int, axis: Int? = nil) -> MfArray{
        return Matft.roll(self, shift: shift, axis: axis)
    }
    
    /**
       Get ordered unique mfarray  along given axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
    */
    public func orderedUnique(axis: Int? = nil) -> MfArray{
        return Matft.orderedUnique(self, axis: axis)
    }
}
