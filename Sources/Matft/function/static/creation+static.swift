//
//  creation.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

extension Matft{
    /**
       Return a shallow copy of an array, which is a new `MfArray` object sharing memory with the original one.

       Equivalent to `numpy.ndarray.view`.
       - Parameters:
           - mfarray: The source array.
       - Returns: A view with the same shape and strides.
    */
    static public func shallowcopy(_ mfarray: MfArray) -> MfArray{
        let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
        
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    /**
       Return a deep copy of an array, which does not share memory with the original one.

       Equivalent to `numpy.copy`.
       - Parameters:
            - mfarray: The source array.
            - order: (Optional) The memory layout of the copy. If `nil` (default), a row- or column-contiguous array keeps its layout (strides included); otherwise the copy is row-major.
       - Returns: The copied array.
    */
    static public func deepcopy(_ mfarray: MfArray, order: MfOrder? = nil) -> MfArray{
        if let order = order{
            switch order {
            case .Row:
                return mfarray.to_contiguous(mforder: .Row)
            case .Column:
                return mfarray.to_contiguous(mforder: .Column)
            }
        }
        else{
            if mfarray.mfstructure.column_contiguous || mfarray.mfstructure.row_contiguous{// all including strides will be copied
                return copy_all_mfarray(mfarray)
            }
            // a dense permutation that isn't a view (e.g. the result of an elementwise op on a transposed array) occupies its whole stored data
            if !mfarray.mfdata._isView && mfarray.offsetIndex == 0 && mfarray.size == mfarray.storedSize && _is_dense_permutation(shape: mfarray.shape, strides: mfarray.strides){
                return copy_all_mfarray(mfarray)
            }
            else{//close to row major
                return mfarray.to_contiguous(mforder: .Row)
            }

        }
        
        /*
        let newdata = Matft.mfdata.deepcopy(mfarray.mfdata)
        let newarray = MfArray(mfdata: newdata)
        return newarray*/
    }
    /**
       Return a new array of the given shape filled with `value`.

       Equivalent to `numpy.full`.

       ```swift
       let a = Matft.nums(0, shape: [2, 3])                    // .Int zeros
       let b = Matft.nums(1.5, shape: [3], mftype: .Float)     // .Float
       ```
       - Parameters:
            - value: The fill value.
            - shape: The shape of the new array.
            - mftype: (Optional) The type of the new array. If `nil`, it is inferred from the type of `value`.
            - mforder: (Optional) The memory layout, by default `.Row`.
       - Returns: The filled array.
    */
    static public func nums<T: MfTypable>(_ value: T, shape: [Int], mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        var shape = shape
        let size = shape2size(&shape)
        
        let retmftype = mftype ?? MfType.mftype(value: T.zero)
        let newdata = MfData(uninitializedSize: size, mftype: retmftype)
        switch MfType.storedType(retmftype){
        case .Float:
            // like numpy, the value is truncated toward zero and wraps around the integer type
            var converted_value = cast_to_integer(Float.from(value), mftype: retmftype)
            newdata.withUnsafeMutableStartPointer(datatype: Float.self){
                #if canImport(Accelerate)
                vDSP_vfill(&converted_value, $0, 1, vDSP_Length(size))
                #else
                $0.update(repeating: converted_value, count: size)
                #endif
            }
        case .Double:
            var converted_value = Double.from(value)
            newdata.withUnsafeMutableStartPointer(datatype: Double.self){
                #if canImport(Accelerate)
                vDSP_vfillD(&converted_value, $0, 1, vDSP_Length(size))
                #else
                $0.update(repeating: converted_value, count: size)
                #endif
            }
        }
        
        let newstructure = MfStructure(shape: shape, mforder: mforder)

        return MfArray(mfdata: newdata, mfstructure: newstructure)
    }
    /**
       Return a new array filled with `value`, with the same shape and type as a given array.

       Equivalent to `numpy.full_like`.
       - Parameters:
            - value: The fill value. It is converted into `mfarray.mftype`.
            - mfarray: The array whose shape and `mftype` are used.
            - mforder: (Optional) The memory layout, by default `.Row`.
       - Returns: The filled array.
    */
    static public func nums_like<T: MfTypable>(_ value: T, mfarray: MfArray, mforder: MfOrder = .Row) -> MfArray{
        return Matft.nums(value, shape: mfarray.shape, mftype: mfarray.mftype, mforder: mforder)
    }
    /**
       Return evenly spaced values in the half-open interval `[start, to)`.

       Equivalent to `numpy.arange`.

       ```swift
       let a = Matft.arange(start: 0, to: 6, by: 1)                                  // [0, 1, 2, 3, 4, 5]
       let b = Matft.arange(start: 1, to: 25, by: 1, shape: [2, 3, 4], mftype: .Float)
       ```
       - Parameters:
            - start: The start of the interval (included).
            - to: The end of the interval (not included).
            - by: The spacing between values.
            - shape: (Optional) The shape of the result. Its size must equal the number of generated values. If `nil`, the result is 1-D.
            - mftype: (Optional) The type of the result. If `nil`, it is inferred from `T` (e.g. `.Int` for `Int`).
            - mforder: (Optional) The memory layout, by default `.Row`.
       - Returns: The array of evenly spaced values.
    */
    static public func arange<T: Strideable>(start: T, to: T, by: T.Stride, shape: [Int]? = nil, mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        let values = Array(stride(from: start, to: to, by: by))
        // an empty range has no values to infer the type from: use the type of start (np.arange(0, 0) is int64)
        return MfArray(values, mftype: mftype ?? (values.isEmpty ? MfType.mftype(value: start) : nil), shape: shape, mforder: mforder)
    }
    /**
       Return a 2-D identity matrix of shape `[dim, dim]`.

       Equivalent to `numpy.eye` (square case, `k = 0`).
       - Parameters:
            - dim: The number of rows and columns.
            - mftype: (Optional) The type of the result. If `nil`, `.Double` is used like `numpy.eye` (float64).
            - mforder: (Optional) The memory layout, by default `.Row`.
       - Returns: The identity matrix.
    */
    static public func eye(dim: Int, mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        var eye = Array(repeating: Array(repeating: 0, count: dim), count: dim)
        for i in 0..<dim{
            eye[i][i] = 1
        }
        // with the explicit shape, dim 0 gives shape [0, 0] like numpy
        return MfArray(eye, mftype: mftype ?? .Double, shape: [dim, dim], mforder: mforder)
    }
    /**
       Construct a 2-D array with the given values on a diagonal.

       Equivalent to `numpy.diag` with a 1-D input.
       - Parameters:
            - v: The values placed on the diagonal. The result has shape `[n, n]` where `n = v.count + abs(k)`.
            - k: (Optional) The diagonal offset, by default 0. Positive values refer to diagonals above the main diagonal, negative values to diagonals below.
            - mftype: (Optional) The type of the result. If `nil`, it is inferred from `T`.
            - mforder: (Optional) The memory layout, by default `.Row`.
       - Returns: The 2-D diagonal array.
    */
    static public func diag<T: MfTypable>(v: [T], k: Int = 0, mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        let dim = v.count + abs(k)
        var d = Array(repeating: Array(repeating: T.zero, count: dim), count: dim)
        if k >= 0{
            for i in 0..<v.count{
                d[i][i+k] = v[i]
            }
        }
        else{
            for i in 0..<v.count{
                d[i-k][i] = v[i]
            }
        }

        // with the explicit shape, an empty v gives shape [0, 0] like numpy
        let ret = MfArray(d.flatMap{ $0 }, mftype: mftype ?? MfType.mftype(value: T.zero), shape: [dim, dim])
        return mforder == .Row ? ret : ret.to_contiguous(mforder: mforder)
    }
    /**
       Construct a 2-D array with the elements of a 1-D array on a diagonal.

       Equivalent to `numpy.diag` with a 1-D input. A complex `v` gives a complex result.
       - Parameters:
            - v: A 1-D array of the diagonal values. The result has shape `[n, n]` where `n = v.size + abs(k)`.
            - k: (Optional) The diagonal offset, by default 0. Positive values refer to diagonals above the main diagonal, negative values to diagonals below.
            - mftype: (Optional) The type of the result. If `nil`, `v.mftype` is used.
            - mforder: (Optional) The memory layout, by default `.Row`.
       - Returns: The 2-D diagonal array.
       - Precondition: `v` must be 1-D.
    */
    static public func diag(v: MfArray, k: Int = 0, mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        precondition(v.ndim == 1, "must be 1d")
        if let imag = v.imag{
            // the real and imaginary parts are diagonal matrices of the same layout
            return MfArray(real: Matft.diag(v: v.real, k: k, mftype: mftype, mforder: mforder), imag: Matft.diag(v: imag, k: k, mftype: mftype, mforder: mforder))
        }
        let dim = v.size + abs(k)
        let size = dim*dim
        let retmftype = mftype ?? v.mftype
        // a contiguous copy in the stored type of the result: v may be a view or have another stored type
        let v = v.astype(retmftype)
        let shape = [dim, dim]
        
        let newdata = MfData(uninitializedSize: size, mftype: retmftype)
        func _create<T: MfStorable>(_ type: T.Type){
            var d = Array(repeating: T.zero, count: size)
            v.withUnsafeMutableStartPointer(datatype: T.self){
                if k >= 0{
                    for i in 0..<v.size{
                        d[i*dim+i+k] = $0[i]
                    }
                }
                else{
                    for i in 0..<v.size{
                        d[(i-k)*dim+i] = $0[i]
                    }
                }
            }
            newdata.withUnsafeMutableStartPointer(datatype: T.self){
                ptrT in
                d.withUnsafeMutableBufferPointer{
                    ptrT.moveUpdate(from: $0.baseAddress!, count: size)
                }
            }
        }
        switch MfType.storedType(retmftype){
        case .Float:
            _create(Float.self)
        case .Double:
            _create(Double.self)
        }
        
        // d is in row major order
        let ret = MfArray(mfdata: newdata, mfstructure: MfStructure(shape: shape, mforder: .Row))
        return mforder == .Row ? ret : ret.to_contiguous(mforder: mforder)
        
    }
    /**
       Stack arrays vertically, i.e. concatenate them along the first axis.

       The result type is `MfType.result_type` of the inputs (like `numpy.result_type`). Complex arrays are joined with their imaginary parts (a real array has 0 imaginary part).
       Equivalent to `numpy.vstack`: 1-D inputs of length `N` are treated as rows of shape `[1, N]`.
       - Parameters:
            - mfarrays: The arrays to stack. Their shapes must match except for the first axis.
       - Returns: A new row-major array. If only one array is given, its deep copy is returned.
    */
    static public func vstack(_ mfarrays: [MfArray]) -> MfArray {
        // like np.atleast_2d, 1-D arrays are rows
        return _vstack(mfarrays.map{ $0.ndim == 1 ? $0.reshape([1, $0.size]) : $0 })
    }
    
    /// Concatenate along the first axis
    fileprivate static func _vstack(_ mfarrays: [MfArray]) -> MfArray {
        if mfarrays.count == 1{
            return mfarrays[0].deepcopy()
        }
        if let ret = _join_complex(mfarrays, Matft._vstack){
            return ret
        }
        
        var retShape = mfarrays.first!.shape // shape except for given axis first, return shape later
        var retMfType = mfarrays.first!.mftype
        var concatDim = retShape.remove(at: 0)
        
        //check if argument is valid or not
        for i in 1..<mfarrays.count{
            var shapeExceptAxis = mfarrays[i].shape
            concatDim += shapeExceptAxis.remove(at: 0)
            
            retMfType = MfType.result_type(retMfType, mfarrays[i].mftype)
            
            precondition(retShape == shapeExceptAxis, "all the input array dimensions except for the concatenation axis must match exactly")
        }
        
        retShape.insert(concatDim, at: 0)// return shape
        
        switch MfType.storedType(retMfType){
        case .Float:
            return stack_by_cblas(mfarrays, ret_shape: retShape, ret_mftype: retMfType, mforder: .Row, cblas_scopy)
            
        case .Double:
            return stack_by_cblas(mfarrays, ret_shape: retShape, ret_mftype: retMfType, mforder: .Row, cblas_dcopy)
        }
    }
    /**
       Stack arrays horizontally, i.e. concatenate them along the last axis.

       The result type is `MfType.result_type` of the inputs (like `numpy.result_type`). Complex arrays are joined with their imaginary parts (a real array has 0 imaginary part).
       Similar to `numpy.hstack` (which uses the second axis for arrays with 2 or more dimensions).
       - Parameters:
            - mfarrays: The arrays to stack. Their shapes must match except for the last axis.
       - Returns: A new column-major array. If only one array is given, its deep copy is returned.
    */
    static public func hstack(_ mfarrays: [MfArray]) -> MfArray {
        if mfarrays.count == 1{
            return mfarrays[0].deepcopy()
        }
        if let ret = _join_complex(mfarrays, Matft.hstack){
            return ret
        }
        
        var retShape = mfarrays.first!.shape // shape except for given axis first, return shape later
        var retMfType = mfarrays.first!.mftype
        var concatDim = retShape.remove(at: retShape.count - 1)
        
        //check if argument is valid or not
        for i in 1..<mfarrays.count{
            var shapeExceptAxis = mfarrays[i].shape
            concatDim += shapeExceptAxis.remove(at: shapeExceptAxis.count - 1)
            
            retMfType = MfType.result_type(retMfType, mfarrays[i].mftype)
            
            precondition(retShape == shapeExceptAxis, "all the input array dimensions except for the concatenation axis must match exactly")
        }
        
        retShape.insert(concatDim, at: retShape.endIndex)// return shape
        
        switch MfType.storedType(retMfType){
        case .Float:
            return stack_by_cblas(mfarrays, ret_shape: retShape, ret_mftype: retMfType, mforder: .Column, cblas_scopy)
            
        case .Double:
            return stack_by_cblas(mfarrays, ret_shape: retShape, ret_mftype: retMfType, mforder: .Column, cblas_dcopy)
        }
    }
    /**
       Join arrays along an existing axis.

       The result type is `MfType.result_type` of the inputs (like `numpy.result_type`). Complex arrays are joined with their imaginary parts (a real array has 0 imaginary part).
       Equivalent to `numpy.concatenate`.

       ```swift
       let a = MfArray([[1, 2], [3, 4]])
       let b = MfArray([[5, 6]])
       let c = Matft.concatenate([a, b], axis: 0)   // shape [3, 2]
       ```
       - Parameters:
            - mfarrays: The arrays to join. Their shapes must match except for `axis`.
            - axis: (Optional) The axis along which the arrays are joined, by default 0. Negative values count from the end.
       - Returns: A new array. If only one array is given, its deep copy is returned.
    */
    static public func concatenate(_ mfarrays: [MfArray], axis: Int = 0) -> MfArray{
        if mfarrays.count == 1{
            return mfarrays[0].deepcopy()
        }
        
        var retShape = mfarrays.first!.shape // shape except for given axis first, return shape later
        let retndim = mfarrays.first!.ndim
        let axis = get_positive_axis(axis, ndim: retndim)
        
        if axis == 0{// vstack is faster than this function
            return Matft._vstack(mfarrays)
        }
        else if axis == retndim - 1{// hstack is faster than this function
            return Matft.hstack(mfarrays)
        }
    
        
        if let ret = _join_complex(mfarrays, { Matft.concatenate($0, axis: axis) }){
            return ret
        }
        
        var concatDim = retShape.remove(at: axis)
        
        var retMfType = mfarrays.first!.mftype
        
        //check if argument is valid or not
        for i in 1..<mfarrays.count{
            var shapeExceptAxis = mfarrays[i].shape
            concatDim += shapeExceptAxis.remove(at: axis)
            
            retMfType = MfType.result_type(retMfType, mfarrays[i].mftype)
            
            precondition(retShape == shapeExceptAxis, "all the input array dimensions except for the concatenation axis must match exactly")
        }
        
        retShape.insert(concatDim, at: axis)// return shape
        
        switch MfType.storedType(retMfType){
        case .Float:
            return concat_by_cblas(mfarrays, ret_shape: retShape, ret_mftype: retMfType, axis: axis, cblas_scopy)
        case .Double:
            return concat_by_cblas(mfarrays, ret_shape: retShape, ret_mftype: retMfType, axis: axis, cblas_dcopy)
        }
        
    }
    
    /// Join complex arrays by joining their real and imaginary parts separately (a real array has 0 imaginary part).
    /// - Returns: The joined complex array, or `nil` if all the arrays are real
    fileprivate static func _join_complex(_ mfarrays: [MfArray], _ join: ([MfArray]) -> MfArray) -> MfArray?{
        guard mfarrays.contains(where: { $0.isComplex }) else { return nil }
        let real = join(mfarrays.map{ $0.real })
        let imag = join(mfarrays.map{ $0.imag ?? Matft.nums(0, shape: $0.shape, mftype: $0.mftype) })
        return MfArray(real: real, imag: imag)
    }
    
    /**
       Append values to the end of an array.

       The result is a new array; the input is unchanged.
       Equivalent to `numpy.append`.
       - Parameters:
            - mfarray: The source array.
            - values: The values to append. When `axis` is given, it must have the same shape as `mfarray` except along `axis`.
            - axis: (Optional) The axis along which `values` are appended. If `nil`, both `mfarray` and `values` are flattened first.
       - Returns: The concatenated copy.
    */
    static public func append(_ mfarray: MfArray, values: MfArray, axis: Int? = nil) -> MfArray{
        //https://github.com/numpy/numpy/blob/v1.19.0/numpy/lib/function_base.py#L4616-L4671
        let mfarr: MfArray, vals: MfArray, ax: Int
        if let axis = axis{
            mfarr = mfarray
            vals = values
            ax = axis
        }
        else{
            mfarr = mfarray.ndim != 1 ? mfarray.flatten() : mfarray
            vals = values.flatten()
            ax = mfarr.ndim - 1
        }
        return Matft.concatenate([mfarr, vals], axis: ax)
    }
    /**
       Append a scalar value to the end of an array.

       The value is wrapped into a 1-element array.
       Equivalent to `numpy.append` with a scalar.
       - Parameters:
            - mfarray: The source array.
            - value: The scalar to append.
            - axis: (Optional) The axis along which `value` is appended. If `nil`, `mfarray` is flattened first.
       - Returns: The concatenated copy.
    */
    static public func append<T: MfTypable>(_ mfarray: MfArray, value: T, axis: Int? = nil) -> MfArray{
        return Matft.append(mfarray, values: MfArray([value]), axis: axis)
    }
    
    /**
       Take elements from an array along an axis.

       Equivalent to `numpy.take`. When `axis` is `nil`, the elements are taken from the flattened array.
       - Parameters:
            - mfarray: The source array.
            - indices: An `.Int` array of the indices to take.
            - axis: (Optional) The axis along which to take elements. If `nil` (default), the flattened array is used.
       - Returns: The array of the taken elements.
    */
    static public func take(_ mfarray: MfArray, indices: MfArray, axis: Int? = nil) -> MfArray{
        guard let axis = axis else {
            // like numpy, take from the flattened array
            return mfarray.flatten()[indices]
        }
        // the result shape is shape[..<axis] + indices.shape + shape[(axis+1)...]
        let ax = get_positive_axis(axis, ndim: mfarray.ndim)
        let taken = Matft.moveaxis(mfarray, src: ax, dst: 0)[indices] // indices.shape + the other axes
        let idim = indices.ndim
        let order = Array(idim..<(idim + ax)) + Array(0..<idim) + Array((idim + ax)..<taken.ndim)
        return taken.transpose(axes: order)
    }
    
    /**
       Insert values along the given axis before the given indices.

       Complex arrays are not supported.
       Equivalent to `numpy.insert`.
       - Parameters:
            - mfarray: The source array.
            - indices: The indices before which `values` are inserted. Negative values count from the end, and duplicated indices insert several times.
            - values: The values to insert, broadcast like `np.array(values, ndmin=mfarray.ndim)`. With several indices the i-th value along `axis` goes to the i-th index. With one index, all the values along `axis` are inserted there (e.g. `insert(a, indices: [1], values: [1, 2, 3], axis: 1)` inserts 3 columns).
            - axis: (Optional) The axis along which to insert. If `nil`, `mfarray` is flattened first.
       - Returns: A new array with the values inserted. Its type is `mfarray.mftype`: like numpy, the values are cast into it.
    */
    static public func insert(_ mfarray: MfArray, indices: [Int], values: MfArray, axis: Int? = nil) -> MfArray{
        //https://github.com/numpy/numpy/blob/v1.19.0/numpy/lib/function_base.py#L4421-L4609
        unsupport_complex(mfarray)
        unsupport_complex(values)
        
        var mfarr: MfArray, ax: Int
        if let axis = axis{
            mfarr = mfarray
            ax = get_positive_axis(axis, ndim: mfarr.ndim)
        }
        else{
            mfarr = mfarray.ndim != 1 ? mfarray.flatten() : mfarray
            ax = 0
        }
        
        let dim = mfarr.shape[ax]
        let positive = indices.map{ get_positive_index_for_insert($0, axissize: dim, axis: ax) }
        // values are broadcast to the inserted block like np.array(values, ndmin=arr.ndim)
        var vals = values
        if vals.ndim < mfarr.ndim{
            vals = vals.reshape([Int](repeating: 1, count: mfarr.ndim - vals.ndim) + vals.shape)
        }
        
        let num: Int
        var newpos: [Int]
        if positive.count == 1{
            // like numpy, all the values along the axis are inserted before the index
            num = vals.shape[ax]
            newpos = (0..<num).map{ positive[0] + $0 }
        }
        else{
            // the i-th value goes before the positive[i]-th element. Equal indices keep their order (stable)
            num = positive.count
            let order = (0..<num).sorted{ (positive[$0], $0) < (positive[$1], $1) }
            newpos = [Int](repeating: 0, count: num)
            for (rank, i) in order.enumerated(){
                newpos[i] = positive[i] + rank
            }
        }
        
        var retShape = mfarr.shape
        retShape[ax] += num
        // like numpy, the values are cast into the type of the array
        let retmftype = mfarr.mftype
        
        var blockShape = mfarr.shape
        blockShape[ax] = num
        vals = vals.broadcast_to(shape: blockShape).astype(retmftype)
        
        // swap axis to use indexing for the first axis
        let ret = Matft.swapaxes(Matft.nums(0, shape: retShape, mftype: retmftype), axis1: 0, axis2: ax)
        mfarr = Matft.swapaxes(mfarr, axis1: 0, axis2: ax)
        vals = Matft.swapaxes(vals, axis1: 0, axis2: ax)
        
        var isInserted = [Bool](repeating: false, count: dim + num)
        for i in 0..<num{
            ret[newpos[i]] = vals[i]
            isInserted[newpos[i]] = true
        }
        var src = 0
        for p in 0..<(dim + num) where !isInserted[p]{
            ret[p] = mfarr[src]
            src += 1
        }
        
        // revert axis
        return Matft.swapaxes(ret, axis1: ax, axis2: 0)
    }
    /**
       Insert a scalar value along the given axis before the given indices.

       Complex arrays are not supported.
       Equivalent to `numpy.insert` with a scalar.
       - Parameters:
            - mfarray: The source array.
            - indices: The indices before which `value` is inserted. Negative values count from the end, and duplicated indices insert several times.
            - value: The scalar to insert.
            - axis: (Optional) The axis along which to insert. If `nil`, `mfarray` is flattened first.
       - Returns: A new array with the value inserted.
    */
    static public func insert<T: MfTypable>(_ mfarray: MfArray, indices: [Int], value: T, axis: Int? = nil) -> MfArray{
        return Matft.insert(mfarray, indices: indices, values: MfArray([value]), axis: axis)
    }
}
/*
extension Matft.mfdata{
    /**
       Create deep copy of mfdata. Deep means copied mfdata will be different object from original one
       - parameters:
            - mfdata: mfdata
    */
    static public func deepcopy(_ mfdata: MfData) -> MfData{

        //copy shape
        let shapeptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        shapeptr.update(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.update(from: mfdata._strides, count: mfdata._ndim)
        
        //copy data
        switch mfdata._storedType {
        case .Float:
            let dataptr = create_unsafeMRPtr(type: Float.self, count: mfdata._size)
            dataptr.assumingMemoryBound(to: Float.self).update(from: mfdata._data.assumingMemoryBound(to: Float.self), count: mfdata._storedSize)
            return MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mfdata._mftype, ndim: mfdata._ndim, stridesptr: stridesptr)
        case .Double:
            let dataptr = create_unsafeMRPtr(type: Double.self, count: mfdata._size)
            dataptr.assumingMemoryBound(to: Double.self).update(from: mfdata._data.assumingMemoryBound(to: Double.self), count: mfdata._storedSize)
            return MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mfdata._mftype, ndim: mfdata._ndim, stridesptr: stridesptr)
        }
    }
    /**
       Create shallow copy of mfdata. Shallow means copied mfdata will be  sharing data with original one
       - parameters:
           - mfdata: mfdata
    */
    static public func shallowcopy(_ mfdata: MfData) -> MfData{
        //copy shape
        let shapeptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        shapeptr.update(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.update(from: mfdata._strides, count: mfdata._ndim)
        
        let newdata = MfData(refdata: mfdata, offset: 0, shapeptr: shapeptr, ndim: mfdata._ndim, mforder: mfdata._order, stridesptr: stridesptr)
        
        return newdata
    }
}
*/
