//
//  creation_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    /**
       Return a deep copy of the array, which does not share memory with the original one.

       Method version of `Matft.deepcopy(_:order:)`.
       Equivalent to `numpy.copy`.
       - Parameters:
            - order: (Optional) The memory layout of the copy. If `nil` (default), a row- or column-contiguous array keeps its layout (strides included); otherwise the copy is row-major.
       - Returns: The copied array.
    */
    public func deepcopy(_ order: MfOrder? = nil) -> MfArray{
        return Matft.deepcopy(self, order: order)
    }
    /**
       Return a shallow copy of the array, which is a new `MfArray` object sharing memory with the original one.

       Method version of `Matft.shallowcopy(_:)`. Equivalent to `numpy.ndarray.view`.
       - Returns: A view with the same shape and strides.
    */
    public func shallowcopy() -> MfArray{
        return Matft.shallowcopy(self)
    }

    /**
       Return a copy of the array collapsed into one dimension.

       Method version of `Matft.flatten(_:mforder:)`. The result is always a copy.
       Equivalent to `numpy.ndarray.flatten`.
       - Parameters:
            - mforder: (Optional) The order in which elements are read, `.Row` (default, C order) or `.Column` (Fortran order).
       - Returns: A 1-D copy of size `size`.
    */
    public func flatten(_ mforder: MfOrder = .Row) -> MfArray{
        return Matft.flatten(self, mforder: mforder)
    }

    /**
       Append values to the end of the array.

       Method version of `Matft.append(_:values:axis:)`. The result is a new array; the original is unchanged.
       Equivalent to `numpy.append`.
       - Parameters:
            - values: The values to append. When `axis` is given, it must have the same shape as the array except along `axis`.
            - axis: (Optional) The axis along which `values` are appended. If `nil`, both the array and `values` are flattened first.
       - Returns: The concatenated copy.
    */
    public func append(values: MfArray, axis: Int? = nil) -> MfArray{
        return Matft.append(self, values: values, axis: axis)
    }
    /**
       Append a scalar value to the end of the array.

       Method version of `Matft.append(_:value:axis:)`. The value is wrapped into a 1-element array.
       Equivalent to `numpy.append` with a scalar.
       - Parameters:
            - value: The scalar to append.
            - axis: (Optional) The axis along which `value` is appended. If `nil`, the array is flattened first.
       - Returns: The concatenated copy.
    */
    public func append<T: MfTypable>(value: T, axis: Int? = nil) -> MfArray{
        return Matft.append(self, values: MfArray([value]), axis: axis)
    }

    /**
       Take elements from the array along an axis.

       Method version of `Matft.take(_:indices:axis:)`.
       Similar to `numpy.take`, but when `axis` is `nil` the elements are taken along axis 0 instead of from the flattened array.
       - Parameters:
            - indices: An `.Int` array of the indices to take.
            - axis: (Optional) The axis along which to take elements, by default axis 0.
       - Returns: The array of the taken elements.
    */
    public func take(indices: MfArray, axis: Int? = nil) -> MfArray{
        return Matft.take(self, indices: indices, axis: axis)
    }

    /**
       Insert values along the given axis before the given indices.

       Method version of `Matft.insert(_:indices:values:axis:)`. Complex arrays are not supported.
       Equivalent to `numpy.insert`.
       - Parameters:
            - indices: The indices before which `values` are inserted.
            - values: The values to insert. It is squeezed and assigned to every inserted position.
            - axis: (Optional) The axis along which to insert. If `nil`, the array is flattened first.
       - Returns: A new array with the values inserted.
    */
    public func insert(indices: [Int], values: MfArray, axis: Int? = nil) -> MfArray{
        return Matft.insert(self, indices: indices, values: values, axis: axis)
    }
    /**
       Insert a scalar value along the given axis before the given indices.

       Method version of `Matft.insert(_:indices:value:axis:)`. Complex arrays are not supported.
       Equivalent to `numpy.insert` with a scalar.
       - Parameters:
            - indices: The indices before which `value` is inserted.
            - value: The scalar to insert.
            - axis: (Optional) The axis along which to insert. If `nil`, the array is flattened first.
       - Returns: A new array with the value inserted.
    */
    public func insert<T: MfTypable>(indices: [Int], value: T, axis: Int? = nil) -> MfArray{
        return Matft.insert(self, indices: indices, values: MfArray([value]), axis: axis)
    }
}
 /*
extension MfData{
    /**
       Create deep copy of mfdata. Deep means copied mfdata will be different object from original one
       - parameters:
    */
    public func deepcopy() -> MfData{
        return Matft.mfdata.deepcopy(self)
    }
    /**
       Create shallow copy of mfdata. Shallow means copied mfdata will be  sharing data with original one
       - parameters:
    */
    public func shallowcopy() -> MfData{
        return Matft.mfdata.shallowcopy(self)
    }
}
*/
