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
    */
    public func astype(_ mftype: MfType) -> MfArray{
        return Matft.astype(self, mftype: mftype)
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
    public func conv_order(mforder: MfOrder) -> MfArray{
        return Matft.conv_order(self, mforder: mforder)
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
            - mfarray: mfarray
            - src: Int
            - dst: Int
    */
    public func moveaxis(src: Int, dst: Int) -> MfArray{
        return Matft.moveaxis(self, src: src, dst: dst)
    }
    
    /**
       Get sorted mfarray along given  axis
       - parameters:
            - axis: (Optional) axis, if not given, get summation for all elements
            - order: (Optional) ascending or descending. default is ascending
    */
    public func sort(axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        Matft.sort(self, axis: axis, order: order)
    }
    /**
       Get sorted mfarray's indices along given  axis
       - parameters:
            - axis: (Optional) axis, if not given, get summation for all elements
            - order: (Optional) ascending or descending. default is ascending
    */
    public func argsort(axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        Matft.argsort(self, axis: axis, order: order)
    }
}
