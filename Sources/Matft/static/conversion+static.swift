//
//  conversion+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation
import Accelerate

extension Matft{
    
    
    /// Create another typed mfarray. Created mfarray will be different object from original one
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - newtype: A new type
    ///   - mforder: (Optional) An order
    /// - Returns: New typed mfarray
    public static func astype<T: MfTypeUsable, U: MfTypeUsable>(_ mfarray: MfArray<T>, newtype: U.Type, mforder: MfOrder = .Row) -> MfArray<U>{

        if U.self is Bool.Type{
           return toBool_by_vDSP(mfarray) as! MfArray<U>
        }
        
        if U.self is T.Type{
            return mfarray.deepcopy() as! MfArray<U>
        }
        
        let mfarray = check_contiguous(mfarray, mforder)
        let ret_size = mfarray.storedSize
        let newdata: MfData<U> = MfData(size: ret_size)
        let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
        let dst_mfarray = MfArray(mfdata: newdata, mfstructure: newstructure)
        //if T.StoredType.self is U.StoredType.Type{
        if let srcptr = mfarray.mfdata.storedPtr.baseAddress! as? UnsafeMutablePointer<U.StoredType>{
            wrap_cblas_copy(ret_size, srcptr, 1, newdata.storedPtr.baseAddress!, 1, U.StoredType.cblas_copy_func)
        }
        else{
            if let srcptr = mfarray.mfdata.storedPtr.baseAddress! as? UnsafeMutablePointer<Float>, let dstptr = newdata.storedPtr.baseAddress! as? UnsafeMutablePointer<Double>{
                wrap_vDSP_convert(ret_size, srcptr, 1, dstptr, 1, vDSP_vspdp)
            }
            else if let srcptr = mfarray.mfdata.storedPtr.baseAddress! as? UnsafeMutablePointer<Double>, let dstptr = newdata.storedPtr.baseAddress! as? UnsafeMutablePointer<Float>{
                wrap_vDSP_convert(ret_size, srcptr, 1, dstptr, 1, vDSP_vdpsp)
            }
            else{
                fatalError("Unsupported!")
            }
        }

        return dst_mfarray
    }
    
    /// Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    /// - Returns: A transposed mfarray
    public static func transpose<T: MfTypeUsable>(_ mfarray: MfArray<T>, axes: [Int]? = nil) -> MfArray<T>{
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
        let orig_shape = mfarray.shape
        let orig_strides = mfarray.strides
        var new_shape = mfarray.shape
        var new_strides = mfarray.strides

        for i in 0..<ndim{
            new_shape[i] = orig_shape[permutation[i]]
            new_strides[i] = orig_strides[permutation[i]]
        }
        
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    
    /// Convert into new shaped mfarray
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - new_shape: A new shape
    ///   - mforder: (Optional) order
    /// - Returns: The broadcasted mfarray
    public static func reshape<T: MfTypeUsable>(_ mfarray: MfArray<T>, new_shape: [Int], mforder: MfOrder = .Row) -> MfArray<T>{
        var new_shape = get_positive_shape(new_shape, size: mfarray.size)
        precondition(mfarray.size == shape2size(&new_shape), "new shape's size:\(shape2size(&new_shape)) must be same as mfarray's size:\(mfarray.size)")
        
        var flatten_array = mfarray.flatten(mforder: mforder).mfdata.storedData
        let newdata = MfData(T.self, storedFlattenArray: &flatten_array)
        let newstructure = MfStructure(shape: new_shape, mforder: mforder)
        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    
    /// Create mfarray expanded dimension for a given axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis: A new axis index to be expanded
    /// - Returns: The expanded mfarray
    public static func expand_dims<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int) -> MfArray<T>{
        let new_mfarray = mfarray.shallowcopy()
        
        var new_shape = mfarray.shape
        let axis = get_positive_axis_for_expand_dims(axis, ndim: mfarray.ndim)
        
        new_shape.insert(1, at: axis)
        var new_strides = mfarray.strides
        new_strides.insert(0, at: axis)
        
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        new_mfarray.mfstructure = newstructure
        
        return new_mfarray
    }
    
    /// Create mfarray expanded dimension for given axes
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axes: A new axes array to be expanded
    /// - Returns: The expanded mfarray
    public static func expand_dims<T: MfTypeUsable>(_ mfarray: MfArray<T>, axes: [Int]) -> MfArray<T>{
        let new_mfarray = mfarray.shallowcopy()
        // reorder descending
        let axes = axes.sorted{ $0 < $1 }
        var new_shape = mfarray.shape
        var new_strides = mfarray.strides
        for axis in axes{
            let axis = get_positive_axis_for_expand_dims(axis, ndim: new_shape.count)
            
            new_shape.insert(1, at: axis)
            new_strides.insert(0, at: axis)
        }
        
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        new_mfarray.mfstructure = newstructure
        
        return new_mfarray
    }
    
    /// Create mfarray removed for 1-dimension
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis: (Optional) the axis index to be squeezed
    /// - Returns: The squeezed mfarray
    public static func squeeze<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil) -> MfArray<T>{
        var new_shape = mfarray.shape
        var new_strides = mfarray.strides
        
        if let axis = axis{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
            precondition(new_shape.remove(at: axis) == 1, "cannot select an axis to squeeze out which has size not equal to one")
            new_strides.remove(at: axis)
        }
        else{
            var axes: [Int] = []
            
            for i in 0..<mfarray.ndim{
                if new_shape[i] == 1{
                    axes.append(i)
                }
            }
            
            for ax in axes.reversed(){// remove all 1-dimension from array
                new_shape.remove(at: ax)
                new_strides.remove(at: ax)
            }
        }
        
        let new_mfarray = mfarray.shallowcopy()
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        new_mfarray.mfstructure = newstructure
        return new_mfarray
    }
    
    /// Create mfarray removed for 1-dimension
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axes: (Optional) the axes array to be squeezed
    /// - Returns: The squeezed mfarray
    public static func squeeze<T: MfTypeUsable>(_ mfarray: MfArray<T>, axes: [Int]) -> MfArray<T>{
        // reoder descending
        let axes = axes.sorted{ $0 > $1 }
        var new_shape = mfarray.shape
        var new_strides = mfarray.strides
        for axis in axes{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
            precondition(new_shape.remove(at: axis) == 1, "cannot select an axis to squeeze out which has size not equal to one")
            new_strides.remove(at: axis)
        }
        
        
        let new_mfarray = mfarray.shallowcopy()
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        new_mfarray.mfstructure = newstructure
        return new_mfarray
    }
    
    /// Create broadcasted mfarray.
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - shape: A new shape
    /// - Returns: The broadcasted mfarray
    public static func broadcast_to<T: MfTypeUsable>(_ mfarray: MfArray<T>, shape: [Int]) -> MfArray<T>{
        var new_shape = shape
        //let newarray = Matft.shallowcopy(mfarray)
        let new_ndim = shape2ndim(&new_shape)
        
        let idim_start = new_ndim  - mfarray.ndim
        
        precondition(idim_start >= 0, "can't broadcast to fewer dimensions")
        
        let orig_strides = mfarray.strides
        let orig_shape = mfarray.shape
        
        var new_strides = Array<Int>(repeating: 0, count: new_ndim)
        
        // Calculate a new strides for a given a new shape
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
    
    
    /// Convert a given mfarray into a contiguous one
    /// - Parameters:
    ///   - mfarray: The source mfarray
    ///   - mforder: An order
    /// - Returns: The contiguous mfarray
    public static func to_contiguous<T: MfTypeUsable>(_ mfarray: MfArray<T>, mforder: MfOrder) -> MfArray<T>{
        return contiguous_by_cblas(mfarray, cblas_func: T.StoredType.cblas_copy_func, mforder: mforder)
    }
    
    /// Flatten to 1d-mfarray
    /// - Parameters:
    ///   - mfarray: The source mfarray
    ///   - mforder: An order
    /// - Returns: The flatten mfarray
    public static func flatten<T: MfTypeUsable>(_ mfarray: MfArray<T>, mforder: MfOrder = .Row) -> MfArray<T>{
        let ret = Matft.to_contiguous(mfarray, mforder: mforder)
        assert(ret.size == ret.storedSize, "bug was occurred!!")
        ret.mfstructure = MfStructure(shape: [ret.size], mforder: mforder)
        
        return ret
    }
    
    /// Reverse the mfarray order along given axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis: (Optional) the axis index to be reversed
    /// - Returns: The flipped mfarray
    public static func flip<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = nil) -> MfArray<T>{
        if let axis = axis{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
            var slices: [Any] = Array<MfSlice>(repeating: MfSlice(start: nil, to: nil, by: 1), count: mfarray.ndim)
            slices[axis] = MfSlice(start: nil, to: nil, by: -1)
            return mfarray._get_mfarray(indices: &slices)
        }
        else{
            return Matft.flip(mfarray, axes: Array(stride(from: 0, to: mfarray.ndim, by: 1)))
        }
    }
    
    /// Reverse the mfarray order along given axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axes: (Optional) the axes array to be reversed
    /// - Returns: The flipped mfarray
    public static func flip<T: MfTypeUsable>(_ mfarray: MfArray<T>, axes: [Int]) -> MfArray<T>{

        var slices: [Any] = Array<MfSlice>(repeating: MfSlice(start: 0, to: nil, by: 1), count: mfarray.ndim)
        for axis in axes{
           let axis = get_positive_axis(axis, ndim: mfarray.ndim)
           slices[axis] = MfSlice(start: nil, to: nil, by: -1)
        }
        return mfarray._get_mfarray(indices: &slices)
    }
    
    /// Clip the mfarray
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - minval: (Optional) The minimum value
    ///   - maxval: (Optional) The maximum value
    /// - Returns: The clipped mfarray
    public static func clip<T: MfTypeUsable>(_ mfarray: MfArray<T>, minval: T? = nil, maxval: T? = nil) -> MfArray<T>{
        let minval = minval == nil ? -T.StoredType.infinity : T.StoredType.from(minval!)
        let maxval = maxval == nil ? T.StoredType.infinity : T.StoredType.from(maxval!)
        
        return clip_by_vDSP(mfarray, minval, maxval, vDSP_func: T.StoredType.vDSP_clip_func)
    }
    
    
    /// Swap given axis1 and axis2
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis1: The axis index to be swapped
    ///   - axis2: The axis index to be swapped
    /// - Returns: The swapped mfarray
    public static func swapaxes<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis1: Int, axis2: Int) -> MfArray<T>{
        let axis1 = get_positive_axis(axis1, ndim: mfarray.ndim)
        let axis2 = get_positive_axis(axis2, ndim: mfarray.ndim)
        
        var axes = Array(stride(from: 0, to: mfarray.ndim, by: 1))
        //swap
        axes.swapAt(axis1, axis2)
        
        return mfarray.transpose(axes: axes)
    }
    
    
    /// Move from given axis to dstination axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - src: The source axis index
    ///   - dst: The destination axis index
    /// - Returns: The moved mfarray
    public static func moveaxis<T: MfTypeUsable>(_ mfarray: MfArray<T>, src: Int, dst: Int) -> MfArray<T>{
        let src = get_positive_axis(src, ndim: mfarray.ndim)
        let dst = get_positive_axis(dst, ndim: mfarray.ndim)

        var axes = Array(stride(from: 0, to: mfarray.ndim, by: 1))
        //move
        axes.remove(at: src)
        axes.insert(src, at: dst)

        return mfarray.transpose(axes: axes)
    }
    
    /// Move from given axis to dstination axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - src: The source axis array
    ///   - dst: The destination axis array
    /// - Returns: The moved mfarray
    public static func moveaxis<T: MfTypeUsable>(_ mfarray: MfArray<T>, src: [Int], dst: [Int]) -> MfArray<T>{
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
    
    /// Sort mfarray along a given axis
    /// - Parameters:
    ///   - mfarray: An input mfarray
    ///   - axis: The axis index
    ///   - order: The order to be sorted
    /// - Returns: The sorted mfarray
    public static func sort<T: MfTypeUsable>(_ mfarray: MfArray<T>, axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray<T>{
        
        let _axis: Int
        let _dst: MfArray<T>
        if axis != nil && mfarray.ndim > 1{// for given axis
            _axis = get_positive_axis(axis!, ndim: mfarray.ndim)
            _dst = mfarray.deepcopy()
        }
        else{// for all elements
            _axis = 0
            _dst = mfarray.flatten()
        }
        
        return sort_by_vDSP(_dst, axis: _axis, order: order, vDSP_func: T.StoredType.vDSP_sort_func)
    }
}
