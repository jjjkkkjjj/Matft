//
//  conversion.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif
import Collections

extension Matft{
    /**
       Return a copy of the array converted to the given type.

       The result is always a new array (a copy), even when `mftype` equals the current type.
       Converting to `.Bool` maps non-zero values to `true`. A complex array stays complex.
       Converting a real array to an integer type truncates toward zero like numpy, and out of range values of the 8/16 bit integer types wrap around (e.g. 300 -> 44 for `.UInt8`).
       Equivalent to `numpy.ndarray.astype`.

       ```swift
       let a = MfArray([1, 2, 3])                 // .Int
       let b = Matft.astype(a, mftype: .Double)   // .Double copy
       ```
       - Parameters:
            - mfarray: The source array.
            - mftype: The type of the returned array.
            - mforder: (Optional) The memory layout of the returned array, by default `.Row`.
            - complex: (Optional) If `true`, a real array is converted into a complex array (with zero imaginary part), by default `false`.
       - Returns: A contiguous copy with the given `mftype`.
    */
    public static func astype(_ mfarray: MfArray, mftype: MfType, mforder: MfOrder = .Row, complex: Bool = false) -> MfArray{
        //let newarray = Matft.shallowcopy(mfarray)
        //newarray.mfdata._mftype = mftype
        if mftype == .Bool{
            return to_Bool(mfarray).to_contiguous(mforder: mforder)
        }
        
        let mfarray = complex && mfarray.isReal ? mfarray.to_complex(false) : mfarray
        
        let newStoredType = MfType.storedType(mftype)
        // floats may have a fractional part to be truncated when converted into integers
        let truncate = mfarray.mftype == .Float || mfarray.mftype == .Double
        if mfarray.storedType == newStoredType{
            let ret = mfarray.to_contiguous(mforder: mforder)
            ret.mfdata.mftype = mftype
            // like numpy, floats are truncated toward zero and out of range integers wrap around
            return cast_to_integer(ret, truncate: truncate)
        }

        if mfarray.isReal{
            switch newStoredType{
            case .Float://double to float
                return cast_to_integer(contiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, vDSP_func: vDSP_vdpsp), truncate: truncate)
                
            case .Double://float to double
                return contiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, vDSP_func: vDSP_vspdp)
            }
        }
        else{
            #if canImport(Accelerate)
            switch newStoredType{
            case .Float://double to float
                return zcontiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, src_type: DSPDoubleSplitComplex.self, dst_type: DSPSplitComplex.self, vDSP_func: vDSP_vdpsp)
                
            case .Double://float to double
                return zcontiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, src_type: DSPSplitComplex.self, dst_type: DSPDoubleSplitComplex.self, vDSP_func: vDSP_vspdp)
            }
            #else
            // Fallback for WASI: convert complex arrays element by element
            return _zcontiguous_and_astype_fallback(mfarray, mftype: mftype, mforder: mforder)
            #endif
        }
    }
    /**
       Permute the axes of an array.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.transpose`.

       ```swift
       let a = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4])
       let b = Matft.transpose(a)                    // shape [4, 3, 2]
       let c = Matft.transpose(a, axes: [0, 2, 1])   // shape [2, 4, 3]
       ```
       - Parameters:
            - mfarray: The source array.
            - axes: (Optional) A permutation of `0..<ndim` (negative values are allowed). If `nil`, the order of the axes is reversed.
       - Returns: The transposed view.
    */
    public static func transpose(_ mfarray: MfArray, axes: [Int]? = nil) -> MfArray{
        var permutation: [Int] = [], reverse_permutation: [Int] = []
        let ndim =  mfarray.shape.count
        
        if let axes = axes{
            precondition(axes.count == ndim, "axes(\(axes.count) don't match array's dimension(\(ndim)")
            for _ in 0..<ndim{
                reverse_permutation.append(-1)
            }
            for i in 0..<ndim{
                let axis = get_positive_axis(axes[i], ndim: ndim)

                precondition(reverse_permutation[axis] == -1, "repeated axis in transpose")
                reverse_permutation[axis] = i
                permutation.append(axis)
            }
        }
        else {
            for i in 0..<ndim{
                permutation.append(ndim - 1 - i)
            }
        }
        let origShape = mfarray.shape
        let origStrides = mfarray.strides
        var new_shape = mfarray.shape
        var new_strides = mfarray.strides

        for i in 0..<ndim{
            new_shape[i] = origShape[permutation[i]]
            new_strides[i] = origStrides[permutation[i]]
        }
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)

        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    /**
       Return an array with the same data and a new shape.

       Equivalent to `numpy.reshape`.

       ```swift
       let a = Matft.arange(start: 0, to: 6, by: 1)
       let b = Matft.reshape(a, newshape: [2, 3])
       let c = Matft.reshape(a, newshape: [-1, 2])   // shape [3, 2]
       ```
       - Parameters:
            - mfarray: The source array.
            - newshape: The new shape. Its size must equal `mfarray.size`. One element may be `-1`, which is inferred from the remaining dimensions.
            - order: (Optional) The order in which elements are read and placed. If `nil` (default), `.Row` is used.
       - Returns: A new array with shape `newshape`.
       - Important: Unlike Numpy, this function always returns a copy, not a view.
    */
    public static func reshape(_ mfarray: MfArray, newshape: [Int], order: MfOrder? = nil) -> MfArray{
        var newshape = get_positive_shape(newshape, mfarray.size)
        precondition(mfarray.size == shape2size(&newshape), "new shape's size:\(shape2size(&newshape)) must be same as mfarray's size:\(mfarray.size)")
        
        let order = order ?? .Row
        if mfarray.isComplex{
            // reshape the real and imaginary parts separately because complex contiguous conversion is not supported on WASI
            return MfArray(real: Matft.reshape(mfarray.real, newshape: newshape, order: order),
                           imag: Matft.reshape(mfarray.imag!, newshape: newshape, order: order))
        }
        // flatten always copies, so the copy can take the new shape as it is
        let ret = mfarray.flatten(order)
        ret.mfstructure = MfStructure(shape: newshape, mforder: order)

        return ret
        
        /* i wanna implement no copy version
        let new_ndim = newshape.count
        let newarray = Matft.shallowcopy(mfarray)
        
        let newstructure = withDummyShapeStridesMBPtr(new_ndim){
            shapeptr, stridesptr in
            //move from newshape
            shapeptr.baseAddress!.moveUpdate(from: &newshape, count: new_ndim)
            
            for axis in 0..<new_ndim{
                
            }
        }*/
    }
    /**
       Insert a new axis of length 1 at the given position.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.expand_dims`.
       - Parameters:
            - mfarray: The source array.
            - axis: The position of the new axis in the result. Negative values count from the end.
       - Returns: A view with `ndim + 1` dimensions.
    */
    public static func expand_dims(_ mfarray: MfArray, axis: Int) -> MfArray{
        
        return Matft.expand_dims(mfarray, axes: [axis])
    }
    /**
       Insert new axes of length 1 at the given positions.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.expand_dims` with a tuple `axis`.
       - Parameters:
            - mfarray: The source array.
            - axes: The positions of the new axes in the result. Negative values count from the end.
       - Returns: A view with `ndim + axes.count` dimensions.
    */
    public static func expand_dims(_ mfarray: MfArray, axes: [Int]) -> MfArray{
        let newarray = mfarray.shallowcopy()
        let out_ndim = mfarray.ndim + axes.count
        var newshape: [Int] = Array(repeating: 0, count: out_ndim)
        var newstrides: [Int] = Array(repeating: 0, count: out_ndim)
        let orig_shape = mfarray.shape
        let orig_strides = mfarray.strides
        var orig_ax = 0
        let axes = axes.map{ get_positive_axis_for_expand_dims($0, ndim: out_ndim) }
        for ax in (0..<out_ndim){
            if axes.contains(ax) {
                newshape[ax] = 1
                newstrides[ax] = 0
            } else {
                newshape[ax] = orig_shape[orig_ax]
                newstrides[ax] = orig_strides[orig_ax]
                orig_ax += 1
            }
        }
        
        newarray.mfstructure = MfStructure(shape: newshape, strides: newstrides)
        
        return newarray
    }
    /**
       Remove axes of length 1.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.squeeze`.
       - Parameters:
            - mfarray: The source array.
            - axis: (Optional) The axis to remove. Its length must be 1. If `nil`, all axes of length 1 are removed.
       - Returns: The squeezed view.
    */
    public static func squeeze(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        
        if let axis = axis{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
            precondition(newshape.remove(at: axis) == 1, "cannot select an axis to squeeze out which has size not equal to one")
            newstrides.remove(at: axis)
        }
        else{
            var axes: [Int] = []
            
            for i in 0..<mfarray.ndim{
                if newshape[i] == 1{
                    axes.append(i)
                }
            }
            
            for ax in axes.reversed(){// remove all 1-dimension from array
                newshape.remove(at: ax)
                newstrides.remove(at: ax)
            }
        }
        
        let newarray = mfarray.shallowcopy()
        newarray.mfstructure = MfStructure(shape: newshape, strides: newstrides)
        return newarray
        /*
        if mfarray.mfstructure.column_contiguous{
            let flattenArray = mfarray.flatten(.Column)
            return MfArray(flattenArray.data, mftype: mfarray.mftype, shape: newshape, mforder: .Column)
        }
        else{
            let flattenArray = mfarray.flatten(.Row)
            return MfArray(flattenArray.data, mftype: mfarray.mftype, shape: newshape, mforder: .Row)
        }
        // i wanna implement no copy version too
        */
    }
    /**
       Remove the given axes of length 1.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.squeeze` with a tuple `axis`.
       - Parameters:
            - mfarray: The source array.
            - axes: The axes to remove. Each of them must have length 1.
       - Returns: The squeezed view.
    */
    public static func squeeze(_ mfarray: MfArray, axes: [Int]) -> MfArray{
        // remove from the last axis. Negative axes must be made positive before sorting
        let axes = axes.map{ get_positive_axis($0, ndim: mfarray.ndim) }.sorted{ $0 > $1 }
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        for axis in axes{
            precondition(newshape.remove(at: axis) == 1, "cannot select an axis to squeeze out which has size not equal to one")
            newstrides.remove(at: axis)
        }
        
        
        let newarray = mfarray.shallowcopy()
        newarray.mfstructure = MfStructure(shape: newshape, strides: newstrides)
        return newarray
    }
    
    /**
       Broadcast an array to a new shape.

       The result is a view (broadcast axes have stride 0) that shares memory with the original array.
       Equivalent to `numpy.broadcast_to`.
       - Parameters:
            - mfarray: The source array.
            - shape: The shape to broadcast to. It must be compatible with `mfarray.shape` under the Numpy broadcasting rules.
       - Returns: The broadcast view.
    */
    public static func broadcast_to(_ mfarray: MfArray, shape: [Int]) -> MfArray{
        var new_shape = shape
        var new_strides = Array(repeating: 0, count: new_shape.count)
        //let newarray = Matft.shallowcopy(mfarray)
        let new_ndim = shape2ndim(&new_shape)
        
        let idim_start = new_ndim  - mfarray.ndim
        
        precondition(idim_start >= 0, "can't broadcast to fewer dimensions")
        
        let orig_strides = mfarray.strides
        let orig_shape = mfarray.shape
        
        for idim in (idim_start..<new_ndim).reversed(){
            let strides_shape_value = orig_shape[idim - idim_start]
            /* If it doesn't have dimension one, it must match */
            if strides_shape_value == 1{
                new_strides[idim] = 0
            }
            else if strides_shape_value != shape[idim]{
                preconditionFailure("could not broadcast from shape \(orig_shape) into shape \(shape)")
            }
            else{
                new_strides[idim] = orig_strides[idim - idim_start]
            }
        }
        
        /* New dimensions get a zero stride */
        for idim in 0..<idim_start{
            new_strides[idim] = 0
        }
        
        
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        //newarray.mfstructure = newstructure
        //return newarray
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }

    /**
       Return a contiguous copy of an array in the given memory order.

       The result is always a copy.
       Similar to `numpy.ascontiguousarray` (`.Row`) and `numpy.asfortranarray` (`.Column`).
       - Parameters:
            - mfarray: The source array.
            - mforder: The memory layout of the result, `.Row` (C order) or `.Column` (Fortran order).
       - Returns: A contiguous copy.
    */
    public static func to_contiguous(_ mfarray: MfArray, mforder: MfOrder) -> MfArray{
        if mfarray.isReal{
            switch mfarray.storedType{
            case .Float:
                return contiguous_by_cblas(mfarray, cblas_func: cblas_scopy, mforder: mforder)
            case .Double:
                return contiguous_by_cblas(mfarray, cblas_func: cblas_dcopy, mforder: mforder)
            }
        }
        else{
            #if canImport(Accelerate)
            switch mfarray.storedType{
            case .Float:
                return zcontiguous_by_vDSP(mfarray, vDSP_zvmov, mforder: mforder)
            case .Double:
                return zcontiguous_by_vDSP(mfarray, vDSP_zvmovD, mforder: mforder)
            }
            #else
            // Fallback for WASI: copy complex arrays element by element
            return _zcontiguous_fallback(mfarray, mforder: mforder)
            #endif
        }
    }
    /**
       Return a copy of an array collapsed into one dimension.

       The result is always a copy.
       Equivalent to `numpy.ndarray.flatten`.
       - Parameters:
            - mfarray: The source array.
            - mforder: (Optional) The order in which elements are read, `.Row` (default, C order) or `.Column` (Fortran order).
       - Returns: A 1-D copy of size `mfarray.size`.
    */
    public static func flatten(_ mfarray: MfArray, mforder: MfOrder = .Row) -> MfArray{
        let ret = Matft.to_contiguous(mfarray, mforder: mforder)
        
        ret.mfstructure = MfStructure(shape: [ret.size], strides: [1])
        
        return ret
    }
    
    /**
       Reverse the order of elements along the given axis.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.flip`.
       - Parameters:
            - mfarray: The source array.
            - axis: (Optional) The axis to reverse. If `nil`, all axes are reversed.
       - Returns: The flipped view.
    */
    public static func flip(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        if let axis = axis{
            return Matft.flip(mfarray, axes: [axis])
        }
        else{
            return Matft.flip(mfarray, axes: Array(stride(from: 0, to: mfarray.ndim, by: 1)))
        }
    }
    /**
       Reverse the order of elements along the given axes.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.flip` with a tuple `axis`.
       - Parameters:
            - mfarray: The source array.
            - axes: The axes to reverse.
       - Returns: The flipped view.
    */
    public static func flip(_ mfarray: MfArray, axes: [Int]) -> MfArray{
        var slices: [Any] = Array(repeating: MfSlice(), count: mfarray.ndim)
        for axis in axes{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
            slices[axis] = MfSlice(by: -1)
        }
        return mfarray._get_mfarray(indices: &slices)
    }
    
    /**
       Clip (limit) the values in an array.

       The result is a new array with the same `mftype`.
       Equivalent to `numpy.clip`.
       - Parameters:
            - mfarray: The source array.
            - min: (Optional) The minimum value. If `nil`, it is treated as `-inf`.
            - max: (Optional) The maximum value. If `nil`, it is treated as `inf`.
       - Returns: The clipped array. The bounds are "weak" scalars like numpy's Python scalars (NEP 50): the array keeps its type unless the bounds are a higher kind, e.g. an `.Int` array with `0.5` gives `.Float` (numpy: float64) and a `.Bool` array with `1` gives `.Int`.
       - Note: Only the real part is processed; the result of a complex array is real.
    */
    public static func clip<T: MfTypable>(_ mfarray: MfArray, min: T? = nil, max: T? = nil) -> MfArray{
        // the bounds are weak scalars like the arithmetic operators (e.g. an .Int array with 0.5 gives .Float)
        let rettype = MfType.scalar_result_type(array: mfarray.mftype, scalar: MfType.mftype(value: T.zero))
        let mfarray = rettype == mfarray.mftype || !mfarray.isReal ? mfarray : mfarray.astype(rettype)
        func _clip<U: MfStorable>(_ vDSP_func: vDSP_clip_func<U>) -> MfArray{
            let max = max == nil ? U.infinity : U.from(max!)
            // like numpy (minimum(maximum(a, min), max)), max wins when min > max
            let min = min == nil ? -U.infinity : Swift.min(U.from(min!), max)
            return clip_by_vDSP(mfarray, min, max, vDSP_func)
        }

        // vDSP_vclip keeps NaN like numpy (vDSP_vclipcD turns it into min)
        switch mfarray.storedType {
        case .Float:
           return  _clip(vDSP_vclip)
        case .Double:
            return _clip(vDSP_vclipD)
        }
    }
    
    /**
       Interchange two axes of an array.

       The result is a view that shares memory with the original array.
       Equivalent to `numpy.swapaxes`.
       - Parameters:
            - mfarray: The source array.
            - axis1: The first axis. Negative values count from the end.
            - axis2: The second axis. Negative values count from the end.
       - Returns: The view with `axis1` and `axis2` swapped.
    */
    public static func swapaxes(_ mfarray: MfArray, axis1: Int, axis2: Int) -> MfArray{
        let axis1 = get_positive_axis(axis1, ndim: mfarray.ndim)
        let axis2 = get_positive_axis(axis2, ndim: mfarray.ndim)
        
        var axes = Array(stride(from: 0, to: mfarray.ndim, by: 1))
        //swap
        axes.swapAt(axis1, axis2)
        
        return mfarray.transpose(axes: axes)
    }
   
    /**
       Move an axis of an array to a new position.

       The other axes keep their relative order. The result is a view that shares memory with the original array.
       Equivalent to `numpy.moveaxis`.
       - Parameters:
            - mfarray: The source array.
            - src: The original position of the axis to move.
            - dst: The destination position of the axis.
       - Returns: The view with the axis moved.
    */
    public static func moveaxis(_ mfarray: MfArray, src: Int, dst: Int) -> MfArray{
        let src = get_positive_axis(src, ndim: mfarray.ndim)
        let dst = get_positive_axis(dst, ndim: mfarray.ndim)
        
        var axes = Array(stride(from: 0, to: mfarray.ndim, by: 1))
        //move
        axes.remove(at: src)
        axes.insert(src, at: dst)
        
        return mfarray.transpose(axes: axes)
    }
    /**
       Move axes of an array to new positions.

       The other axes keep their relative order. The result is a view that shares memory with the original array.
       Equivalent to `numpy.moveaxis` with sequences.
       - Parameters:
            - mfarray: The source array.
            - src: The original positions of the axes to move.
            - dst: The destination positions of the axes. It must have the same count as `src`.
       - Returns: The view with the axes moved.
    */
    public static func moveaxis(_ mfarray: MfArray, src: [Int], dst: [Int]) -> MfArray{
        precondition(src.count == dst.count, "must be same size")
        var sources: [Int] = [], dstinations: [Int] = []
        for (s, d) in zip(src, dst){
            sources += [get_positive_axis(s, ndim: mfarray.ndim)]
            dstinations += [get_positive_axis(d, ndim: mfarray.ndim)]
        }
        
        var order = Array(0..<mfarray.ndim).filter{ !sources.contains($0) }
        
        for (s, d) in zip(sources, dstinations).sorted(by: { $0.1 < $1.1 }){
            if d == order.count{
                order.append(s)
            }
            else{
                order.insert(s, at: d)
            }
        }
        
        return mfarray.transpose(axes: order)
    }
    
    /**
       Return a sorted copy of an array.

       Complex arrays are not supported.
       Equivalent to `numpy.sort`.
       - Parameters:
            - mfarray: The source array.
            - axis: (Optional) The axis along which to sort, by default `-1` (the last axis). If `nil`, the flattened array is sorted.
            - order: (Optional) `.Ascending` (default) or `.Descending`.
       - Returns: A sorted copy with the same `mftype`.
    */
    public static func sort(_ mfarray: MfArray, axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        unsupport_complex(mfarray)
        
        let _axis: Int
        let _dst: MfArray
        if axis != nil && mfarray.ndim > 1{// for given axis
            _axis = get_positive_axis(axis!, ndim: mfarray.ndim)
            _dst = mfarray // the kernel copies it into a contiguous array
        }
        else{// for all elements
            _axis = 0
            _dst = mfarray.flatten()
        }
        switch mfarray.storedType {
        case .Float:
            return sort_by_vDSP(_dst, _axis, order, vDSP_vsort)
        case .Double:
            return sort_by_vDSP(_dst, _axis, order, vDSP_vsortD)
        }
    }
    /**
       Return the indices that would sort an array.

       Complex arrays are not supported.
       Equivalent to `numpy.argsort`.
       - Parameters:
            - mfarray: The source array.
            - axis: (Optional) The axis along which to sort, by default `-1` (the last axis). If `nil`, the flattened array is used.
            - order: (Optional) `.Ascending` (default) or `.Descending`.
       - Returns: An `.Int` array of indices.
    */
    public static func argsort(_ mfarray: MfArray, axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        unsupport_complex(mfarray)
        
        let _axis: Int
        let _dst: MfArray
        if axis != nil && mfarray.ndim > 1{// for given axis
            _axis = get_positive_axis(axis!, ndim: mfarray.ndim)
            _dst = mfarray // the kernel copies it into a contiguous array
        }
        else{// for all elements
            _axis = 0
            _dst = mfarray.flatten()
        }
        switch mfarray.storedType {
        case .Float:
            return argsort_by_vDSP(_dst, _axis, order, vDSP_vsorti)
        case .Double:
            return argsort_by_vDSP(_dst, _axis, order, vDSP_vsortiD)
        }
    }
    
    /**
       Roll array elements along a given axis.

       Elements that roll beyond the last position are re-introduced at the first. Complex arrays are not supported.
       Equivalent to `numpy.roll`.
       - Parameters:
            - mfarray: The source array.
            - shift: The number of places by which elements are shifted. Negative values shift backwards.
            - axis: (Optional) The axis along which elements are shifted. If `nil`, the array is flattened before shifting and the original shape is restored.
       - Returns: The rolled copy.
    */
    public static func roll(_ mfarray: MfArray, shift: Int, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        if mfarray.size == 0{
            return mfarray.deepcopy()
        }
        
        switch mfarray.storedType{
        case .Float:
            return shift_by_cblas(mfarray, shift: shift, axis: axis, cblas_scopy)
        case .Double:
            return shift_by_cblas(mfarray, shift: shift, axis: axis, cblas_dcopy)
        }
    }
    
    /**
       Find the unique elements (or sub-arrays) of an array, keeping their first-occurrence order.

       Unlike `numpy.unique`, the result is not sorted. Complex arrays are not supported.
       - Parameters:
            - mfarray: The source array.
            - axis: (Optional) The axis along which unique sub-arrays are searched. If `nil`, unique elements of the whole array are returned as a 1-D array.
       - Returns: The unique elements.
    */
    public static func orderedUnique(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        // get stride to calculate unique array
        let stride: Int
        var srcmfarray: MfArray
        var restShape: [Int]
        if let axis = axis{
            srcmfarray = mfarray.moveaxis(src: axis, dst: 0)
            if srcmfarray.ndim == 1{
                stride = 1
                restShape = []
            }
            else{
                restShape = Array(srcmfarray.shape[1..<srcmfarray.ndim])
                stride = shape2size(&restShape)
            }
            srcmfarray = srcmfarray.flatten()
        }
        else{
            // storedData is in the memory order of the (possibly non-contiguous) array
            srcmfarray = mfarray.flatten()
            stride = 1
            restShape = []
        }
        
        
        switch mfarray.storedType {
        case .Float:
            var flattendata: [Float]
            
            flattendata = srcmfarray.storedData as! [Float]
            return _unique(&flattendata, restShape: &restShape, mftype: mfarray.mftype, stride: stride, axis: axis)

            
        case .Double:
            var flattendata: [Double]
            flattendata = srcmfarray.storedData as! [Double]
            return _unique(&flattendata, restShape: &restShape, mftype: mfarray.mftype, stride: stride, axis: axis)
        }
    }
}

fileprivate func _unique<T: MfStorable>(_ flattendata: inout [T], restShape: inout [Int], mftype: MfType, stride: Int, axis: Int?) -> MfArray{
    
    var uniquearray: [T]
    if stride == 1{// flatten array
        uniquearray = Array(OrderedSet(flattendata))
    }
    else{
        assert(axis != nil)
        
        var axisarray: [[T]] = []
        for i in 0..<(flattendata.count/stride){
            axisarray += [Array(flattendata[i*stride..<(i+1)*stride])]
        }

        uniquearray = OrderedSet(axisarray).flatMap{ $0 }
    }
    
    let newsize = uniquearray.count
    let newdata = MfData(uninitializedSize: newsize, mftype: mftype)

    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        uniquearray.withUnsafeMutableBufferPointer{
            dstptrT.moveUpdate(from: $0.baseAddress!, count: newsize)
        }
    }
    
    restShape.insert(newsize / stride, at: 0)
    let newstructure = MfStructure(shape: restShape, mforder: .Row)
    
    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    
    if let axis = axis{
        return ret.moveaxis(src: axis, dst: 0)
    }
    else{
        return ret
    }

}

// MARK: - WASI Fallbacks for complex array operations
#if !canImport(Accelerate)

/// Fallback for zcontiguous_and_astype_by_vDSP on WASI. The real and imaginary parts are converted separately
internal func _zcontiguous_and_astype_fallback(_ mfarray: MfArray, mftype: MfType, mforder: MfOrder) -> MfArray {
    return MfArray(real: mfarray.real.astype(mftype, mforder: mforder), imag: mfarray.imag!.astype(mftype, mforder: mforder))
}

/// Fallback for zcontiguous_by_vDSP on WASI. The real and imaginary parts are converted separately
internal func _zcontiguous_fallback(_ mfarray: MfArray, mforder: MfOrder) -> MfArray {
    return MfArray(real: mfarray.real.to_contiguous(mforder: mforder), imag: mfarray.imag!.to_contiguous(mforder: mforder))
}

#endif


/*
extension Matft.mfdata{
    /**
       Create another typed mfdata. Created mfdata will be different object from original one
       - parameters:
            - mfdata: mfdata
            - mftype: the type of mfarray
    */
    public static func astype(_ mfdata: MfData, mftype: MfType) -> MfData{
        
        let newStoredType = MfType.storedType(mftype)
        if mfdata._storedType == newStoredType{
            var ret = mfdata.deepcopy()
            ret._mftype = mftype
            return ret
        }
        
        //copy shape
        let shapeptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        shapeptr.update(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.update(from: mfdata._strides, count: mfdata._ndim)
        
        switch newStoredType{
        case .Float://double to float
            let ptrD = mfdata._data.bindMemory(to: Double.self, capacity: mfdata._storedSize)
            let ptrF = create_unsafeMPtrT(type: Float.self, count: mfdata._storedSize)
            
            unsafePtrT2UnsafeMPtrU(ptrD, ptrF, vDSP_vdpsp, mfdata._storedSize)
            
            let dataptr = UnsafeMutableRawPointer(ptrF)
            
            return MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mftype, ndim: mfdata._ndim, stridesptr: stridesptr)
            
        case .Double://float to double
            let ptrF = mfdata._data.bindMemory(to: Float.self, capacity: mfdata._storedSize)
            let ptrD = create_unsafeMPtrT(type: Double.self, count: mfdata._storedSize)
            
            unsafePtrT2UnsafeMPtrU(ptrF, ptrD, vDSP_vspdp, mfdata._storedSize)

            let dataptr = UnsafeMutableRawPointer(ptrD)

            return MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mftype, ndim: mfdata._ndim, stridesptr: stridesptr)
        }
    }
}
*/

