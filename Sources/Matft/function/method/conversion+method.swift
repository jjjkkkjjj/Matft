//
//  conversion_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(CoreML)
import CoreML
#endif

extension MfArray{
    /**
       Return a copy of the array converted to the given type.

       Method version of `Matft.astype(_:mftype:mforder:complex:)`. The result is always a new array (a copy), even when `mftype` equals the current type.
       Equivalent to `numpy.ndarray.astype`.

       ```swift
       let a = MfArray([1, 2, 3])        // .Int
       let b = a.astype(.Float)          // .Float copy
       ```
       - Parameters:
            - mftype: The type of the returned array. Converting to `.Bool` maps non-zero values to `true`.
            - mforder: (Optional) The memory layout of the returned array, by default `.Row`.
       - Returns: A contiguous copy with the given `mftype`. Complex arrays stay complex.
    */
    public func astype(_ mftype: MfType, mforder: MfOrder = .Row) -> MfArray{
        return Matft.astype(self, mftype: mftype, mforder: mforder)
    }

    /**
        Convert real mfarray into complex mfarray
        - Parameters:
            - inplace: Whether to operate in-place
    */
    internal func to_complex(_ inplace: Bool = true) -> MfArray{
        if self.isComplex{
            return self
        }

        let mfarray: MfArray
        if inplace{
            precondition(!self.mfdata._fromOtherDataSource, "Other data source couldn't be converted into Complex.")
            mfarray = self
        }
        else{
            mfarray = self.deepcopy(.Row)
        }

        switch mfarray.storedType{
        case .Float:
            let ptri = allocate_unsafeMRPtr(type: Float.self, count: mfarray.storedSize, zeroed: true) // the imaginary part of a real number is 0
            mfarray.mfdata_base.data_imag = ptri
            mfarray.mfdata.data_imag = ptri
        case .Double:
            let ptri = allocate_unsafeMRPtr(type: Double.self, count: mfarray.storedSize, zeroed: true) // the imaginary part of a real number is 0
            mfarray.mfdata_base.data_imag = ptri
            mfarray.mfdata.data_imag = ptri
        }
        return mfarray
    }

    /**
       Permute the axes of the array.

       Method version of `Matft.transpose(_:axes:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.ndarray.transpose`.

       ```swift
       let a = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4])
       let b = a.transpose(axes: [0, 2, 1])   // shape [2, 4, 3]
       let c = a.transpose()                   // shape [4, 3, 2]
       ```
       - Parameters:
            - axes: (Optional) A permutation of `0..<ndim` (negative values are allowed). If `nil`, the order of the axes is reversed.
       - Returns: The transposed view.
    */
    public func transpose(axes: [Int]? = nil) -> MfArray{
        return Matft.transpose(self, axes: axes)
    }
    /**
       The transposed array (the order of the axes reversed).

       Shorthand for `transpose()`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.ndarray.T`.
    */
    public var T: MfArray{
        return Matft.transpose(self)
    }

    /**
       Return an array with the same data and a new shape.

       Method version of `Matft.reshape(_:newshape:order:)`. Unlike Numpy, the result is always a copy (row-major), not a view.
       Equivalent to `numpy.ndarray.reshape`.

       ```swift
       let a = Matft.arange(start: 0, to: 6, by: 1)
       let b = a.reshape([2, 3])
       let c = a.reshape([-1, 2])   // shape [3, 2]
       ```
       - Parameters:
            - newshape: The new shape. Its size must equal `size`. One element may be `-1`, which is inferred from the remaining dimensions.
       - Returns: A new array with shape `newshape`.
    */
    public func reshape(_ newshape: [Int]) -> MfArray{
        return Matft.reshape(self, newshape: newshape)
    }

    /**
       Convert the array into a (nested) Swift array.

       Equivalent to `numpy.ndarray.tolist`.
       - Returns: A nested `[Any]` whose nesting depth equals `ndim`. The element type corresponds to `mftype`.
    */
    public func toArray() -> [Any]{
        return toSwiftArray(self)
    }

    /**
       Convert the array into a flat Swift array, applying `body` to each element.

       Elements are visited in the order of the array's contiguous storage.
       - Parameters:
            - datatype: The Swift type of the elements. It must correspond to `mftype` (e.g. `Float.self` for `.Float`).
            - body: A closure applied to each element. Its results make up the returned array.
       - Returns: The array of the values returned by `body`.
       - Throws: Rethrows any error thrown by `body`.
       - Precondition: `datatype` must match `mftype`.
       - Important: If you just want a flatten array, use `a.flatten().data as! [T]`.
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


    #if canImport(CoreML)
    /// Convert the array into a Core ML `MLMultiArray`.
    ///
    /// The stored data is copied. Float-stored types become `.float32` and Double-stored types become `.double`, keeping the shape and strides.
    /// Only the real part is copied for complex arrays.
    /// - Returns: The converted `MLMultiArray`.
    /// - Throws: An error thrown by the `MLMultiArray` initializer.
    @available(macOS 12.0, *)
    @available(iOS 14.0, *)
    public func toMLMultiArray() throws -> MLMultiArray {
        // copy the stored data linearly, so views (offsets, negative strides, ...) must be made dense
        let x = check_dense(self)
        switch x.storedType {
        case .Float:
            let ptrF = allocate_unsafeMRPtr(type: Float.self, count: x.storedSize, zeroed: false)
            memcpy(ptrF, x.mfdata.data_real, x.storedByteSize)
            return try MLMultiArray(dataPointer: ptrF, shape: x.shape.map{ NSNumber(value: $0) } , dataType: MLMultiArrayDataType.float32, strides: x.strides.map{ NSNumber(value: $0) }, deallocator: _deallocator_MLMultiArray_pointer)
        case .Double:
            let ptrD = allocate_unsafeMRPtr(type: Double.self, count: x.storedSize, zeroed: false)
            memcpy(ptrD, x.mfdata.data_real, x.storedByteSize)
            return try MLMultiArray(dataPointer: ptrD, shape: x.shape.map{ NSNumber(value: $0) } , dataType: MLMultiArrayDataType.double, strides: x.strides.map{ NSNumber(value: $0) }, deallocator: _deallocator_MLMultiArray_pointer)
        }
    }
    #endif

    /**
       Broadcast the array to a new shape.

       Method version of `Matft.broadcast_to(_:shape:)`. The result is a view (broadcast axes have stride 0) that shares memory with the original array.
       Equivalent to `numpy.broadcast_to`.
       - Parameters:
            - shape: The shape to broadcast to. It must be compatible with the current shape under the Numpy broadcasting rules.
       - Returns: The broadcast view.
    */
    public func broadcast_to(shape: [Int]) -> MfArray{
        return Matft.broadcast_to(self, shape: shape)
    }

    /**
       Insert a new axis of length 1 at the given position.

       Method version of `Matft.expand_dims(_:axis:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.expand_dims`.
       - Parameters:
            - axis: The position of the new axis in the result. Negative values count from the end.
       - Returns: A view with `ndim + 1` dimensions.
    */
    public func expand_dims(axis: Int) -> MfArray{
        return Matft.expand_dims(self, axis: axis)
    }
    /**
       Insert new axes of length 1 at the given positions.

       Method version of `Matft.expand_dims(_:axes:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.expand_dims` with a tuple `axis`.
       - Parameters:
            - axes: The positions of the new axes in the result. Negative values count from the end.
       - Returns: A view with `ndim + axes.count` dimensions.
    */
    public func expand_dims(axes: [Int]) -> MfArray{
        return Matft.expand_dims(self, axes: axes)
    }

    /**
       Remove axes of length 1.

       Method version of `Matft.squeeze(_:axis:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.squeeze`.
       - Parameters:
            - axis: (Optional) The axis to remove. Its length must be 1. If `nil`, all axes of length 1 are removed.
       - Returns: The squeezed view.
    */
    public func squeeze(axis: Int? = nil) -> MfArray{
        return Matft.squeeze(self, axis: axis)
    }
    /**
       Remove the given axes of length 1.

       Method version of `Matft.squeeze(_:axes:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.squeeze` with a tuple `axis`.
       - Parameters:
            - axes: The axes to remove. Each of them must have length 1.
       - Returns: The squeezed view.
    */
    public func squeeze(axes: [Int]) -> MfArray{
        return Matft.squeeze(self, axes: axes)
    }
    /**
       Return a contiguous copy of the array in the given memory order.

       Method version of `Matft.to_contiguous(_:mforder:)`. The result is always a copy.
       Similar to `numpy.ascontiguousarray` (`.Row`) and `numpy.asfortranarray` (`.Column`).
       - Parameters:
            - mforder: The memory layout of the result, `.Row` (C order) or `.Column` (Fortran order).
       - Returns: A contiguous copy.
    */
    public func to_contiguous(mforder: MfOrder) -> MfArray{
        return Matft.to_contiguous(self, mforder: mforder)
    }

    /**
       Reverse the order of elements along the given axis.

       Method version of `Matft.flip(_:axis:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.flip`.
       - Parameters:
            - axis: (Optional) The axis to reverse. If `nil`, all axes are reversed.
       - Returns: The flipped view.
    */
    public func flip(axis: Int? = nil) -> MfArray{
        return Matft.flip(self, axis: axis)
    }
    /**
       Reverse the order of elements along the given axes.

       Method version of `Matft.flip(_:axes:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.flip` with a tuple `axis`.
       - Parameters:
            - axes: The axes to reverse.
       - Returns: The flipped view.
    */
    public func flip(axes: [Int]) -> MfArray{
        return Matft.flip(self, axes: axes)
    }

    /**
       Clip (limit) the values in the array.

       Method version of `Matft.clip(_:min:max:)`. The result is a new array with the same `mftype`.
       Equivalent to `numpy.clip`.
       - Parameters:
            - min: (Optional) The minimum value. If `nil`, it is treated as `-inf`.
            - max: (Optional) The maximum value. If `nil`, it is treated as `inf`.
       - Returns: The clipped array.
    */
    public func clip<T: MfTypable>(min: T? = nil, max: T? = nil) -> MfArray{
        return Matft.clip(self, min: min, max: max)
    }

    /**
       Interchange two axes of the array.

       Method version of `Matft.swapaxes(_:axis1:axis2:)`. The result is a view that shares memory with the original array.
       Equivalent to `numpy.swapaxes`.
       - Parameters:
            - axis1: The first axis. Negative values count from the end.
            - axis2: The second axis. Negative values count from the end.
       - Returns: The view with `axis1` and `axis2` swapped.
    */
    public func swapaxes(axis1: Int, axis2: Int) -> MfArray{
        return Matft.swapaxes(self, axis1: axis1, axis2: axis2)
    }

    /**
       Move an axis to a new position.

       Method version of `Matft.moveaxis(_:src:dst:)`. The other axes keep their relative order. The result is a view that shares memory with the original array.
       Equivalent to `numpy.moveaxis`.
       - Parameters:
            - src: The original position of the axis to move.
            - dst: The destination position of the axis.
       - Returns: The view with the axis moved.
    */
    public func moveaxis(src: Int, dst: Int) -> MfArray{
        return Matft.moveaxis(self, src: src, dst: dst)
    }
    /**
       Move axes to new positions.

       Method version of `Matft.moveaxis(_:src:dst:)`. The other axes keep their relative order. The result is a view that shares memory with the original array.
       Equivalent to `numpy.moveaxis` with sequences.
       - Parameters:
            - src: The original positions of the axes to move.
            - dst: The destination positions of the axes. It must have the same count as `src`.
       - Returns: The view with the axes moved.
    */
    public func moveaxis(src: [Int], dst: [Int]) -> MfArray{
        return Matft.moveaxis(self, src: src, dst: dst)
    }

    /**
       Return a sorted copy of the array.

       Method version of `Matft.sort(_:axis:order:)`. Complex arrays are not supported.
       Equivalent to `numpy.sort`.
       - Parameters:
            - axis: (Optional) The axis along which to sort, by default `-1` (the last axis). If `nil`, the flattened array is sorted.
            - order: (Optional) `.Ascending` (default) or `.Descending`.
       - Returns: A sorted copy with the same `mftype`.
    */
    public func sort(axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        return Matft.sort(self, axis: axis, order: order)
    }
    /**
       Return the indices that would sort the array.

       Method version of `Matft.argsort(_:axis:order:)`. Complex arrays are not supported.
       Equivalent to `numpy.argsort`.
       - Parameters:
            - axis: (Optional) The axis along which to sort, by default `-1` (the last axis). If `nil`, the flattened array is used.
            - order: (Optional) `.Ascending` (default) or `.Descending`.
       - Returns: An `.Int` array of indices.
    */
    public func argsort(axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        return Matft.argsort(self, axis: axis, order: order)
    }

    /**
       Roll array elements along a given axis.

       Method version of `Matft.roll(_:shift:axis:)`. Elements that roll beyond the last position are re-introduced at the first. Complex arrays are not supported.
       Equivalent to `numpy.roll`.
       - Parameters:
            - shift: The number of places by which elements are shifted. Negative values shift backwards.
            - axis: (Optional) The axis along which elements are shifted. If `nil`, the array is flattened before shifting and the original shape is restored.
       - Returns: The rolled copy.
    */
    public func roll(shift: Int, axis: Int? = nil) -> MfArray{
        return Matft.roll(self, shift: shift, axis: axis)
    }

    /**
       Find the unique elements (or sub-arrays) of the array, keeping their first-occurrence order.

       Method version of `Matft.orderedUnique(_:axis:)`. Unlike `numpy.unique`, the result is not sorted. Complex arrays are not supported.
       - Parameters:
            - axis: (Optional) The axis along which unique sub-arrays are searched. If `nil`, unique elements of the flattened array are returned.
       - Returns: The unique elements (1-D when `axis` is `nil`).
    */
    public func orderedUnique(axis: Int? = nil) -> MfArray{
        return Matft.orderedUnique(self, axis: axis)
    }
}

#if canImport(CoreML)
fileprivate func _deallocator_MLMultiArray_pointer(_ ptr: UnsafeMutableRawPointer) -> Void {
    ptr.deallocate()
}
#endif
