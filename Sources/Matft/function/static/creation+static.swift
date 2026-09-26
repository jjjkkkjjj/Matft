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
            var strides = mfarray.strides
            if !isReverse(&strides) && !mfarray.mfdata._isView{// not contain reverse and is not view, copy all
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
            var converted_value = Float.from(value)
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
        return MfArray(Array(stride(from: start, to: to, by: by)), mftype: mftype, shape: shape, mforder: mforder)
    }
    /**
       Return a 2-D identity matrix of shape `[dim, dim]`.

       Equivalent to `numpy.eye` (square case, `k = 0`).
       - Parameters:
            - dim: The number of rows and columns.
            - mftype: (Optional) The type of the result. If `nil`, `.Int` is used.
            - mforder: (Optional) The memory layout, by default `.Row`.
       - Returns: The identity matrix.
    */
    static public func eye(dim: Int, mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        var eye = Array(repeating: Array(repeating: 0, count: dim), count: dim)
        for i in 0..<dim{
            eye[i][i] = 1
        }
        return MfArray(eye, mftype: mftype, mforder: mforder)
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
        
        return MfArray(d, mftype: mftype, mforder: mforder)
    }
    /**
       Construct a 2-D array with the elements of a 1-D array on a diagonal.

       Equivalent to `numpy.diag` with a 1-D input.
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
        let dim = v.size + abs(k)
        let size = dim*dim
        let retmftype = mftype ?? v.mftype
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
        
        let newstructure = MfStructure(shape: shape, mforder: mforder)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
        
    }
    /**
       Stack arrays vertically, i.e. concatenate them along the first axis.

       The result type is the highest-priority `mftype` among the inputs. Complex arrays are not supported.
       Similar to `numpy.vstack`, but 1-D inputs are concatenated as they are (they are not promoted to shape `[1, N]`).
       - Parameters:
            - mfarrays: The arrays to stack. Their shapes must match except for the first axis.
       - Returns: A new row-major array. If only one array is given, its deep copy is returned.
    */
    static public func vstack(_ mfarrays: [MfArray]) -> MfArray {
        if mfarrays.count == 1{
            return mfarrays[0].deepcopy()
        }
        
        var retShape = mfarrays.first!.shape // shape except for given axis first, return shape later
        var retMfType = mfarrays.first!.mftype
        var concatDim = retShape.remove(at: 0)
        
        //check if argument is valid or not
        for i in 1..<mfarrays.count{
            var shapeExceptAxis = mfarrays[i].shape
            concatDim += shapeExceptAxis.remove(at: 0)
            
            retMfType = MfType.priority(retMfType, mfarrays[i].mftype)
            
            unsupport_complex(mfarrays[i])
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

       The result type is the highest-priority `mftype` among the inputs. Complex arrays are not supported.
       Similar to `numpy.hstack` (which uses the second axis for arrays with 2 or more dimensions).
       - Parameters:
            - mfarrays: The arrays to stack. Their shapes must match except for the last axis.
       - Returns: A new column-major array. If only one array is given, its deep copy is returned.
    */
    static public func hstack(_ mfarrays: [MfArray]) -> MfArray {
        if mfarrays.count == 1{
            return mfarrays[0].deepcopy()
        }
        
        var retShape = mfarrays.first!.shape // shape except for given axis first, return shape later
        var retMfType = mfarrays.first!.mftype
        var concatDim = retShape.remove(at: retShape.count - 1)
        
        //check if argument is valid or not
        for i in 1..<mfarrays.count{
            var shapeExceptAxis = mfarrays[i].shape
            concatDim += shapeExceptAxis.remove(at: shapeExceptAxis.count - 1)
            
            retMfType = MfType.priority(retMfType, mfarrays[i].mftype)
            
            unsupport_complex(mfarrays[i])
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

       The result type is the highest-priority `mftype` among the inputs. Complex arrays are not supported.
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
            return Matft.vstack(mfarrays)
        }
        else if axis == retndim - 1{// hstack is faster than this function
            return Matft.hstack(mfarrays)
        }
    
        
        var concatDim = retShape.remove(at: axis)
        
        var retMfType = mfarrays.first!.mftype
        
        //check if argument is valid or not
        for i in 1..<mfarrays.count{
            var shapeExceptAxis = mfarrays[i].shape
            concatDim += shapeExceptAxis.remove(at: axis)
            
            retMfType = MfType.priority(retMfType, mfarrays[i].mftype)
            
            unsupport_complex(mfarrays[i])
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

       Similar to `numpy.take`, but when `axis` is `nil` the elements are taken along axis 0 instead of from the flattened array.
       - Parameters:
            - mfarray: The source array.
            - indices: An `.Int` array of the indices to take.
            - axis: (Optional) The axis along which to take elements, by default axis 0.
       - Returns: The array of the taken elements.
    */
    static public func take(_ mfarray: MfArray, indices: MfArray, axis: Int? = nil) -> MfArray{
        let axis = axis ?? 0
        return Matft.swapaxes(mfarray, axis1: axis, axis2: 0)[indices].swapaxes(axis1: 0, axis2: axis)
    }
    
    /**
       Insert values along the given axis before the given indices.

       Complex arrays are not supported.
       Equivalent to `numpy.insert`.
       - Parameters:
            - mfarray: The source array.
            - indices: The indices before which `values` are inserted. Negative values count from the end.
            - values: The values to insert. It is squeezed and assigned to every inserted position.
            - axis: (Optional) The axis along which to insert. If `nil`, `mfarray` is flattened first.
       - Returns: A new array with the values inserted.
    */
    static public func insert(_ mfarray: MfArray, indices: [Int], values: MfArray, axis: Int? = nil) -> MfArray{
        //https://github.com/numpy/numpy/blob/v1.19.0/numpy/lib/function_base.py#L4421-L4609
        // convert corrext index, sort index and then remove duplicated index
        unsupport_complex(mfarray)
        unsupport_complex(values)
        
        var mfarr: MfArray, vals: MfArray, ax: Int
        if let axis = axis{
            mfarr = mfarray
            ax = get_positive_axis(axis, ndim: mfarr.ndim)
        }
        else{
            mfarr = mfarray.ndim != 1 ? mfarray.flatten() : mfarray
            ax = mfarr.ndim - 1
        }
        vals = values.squeeze()
    
        let dim = mfarr.shape[ax] //Inserted values number for each index
        var retShape = mfarr.shape
        retShape[ax] += indices.count
        let sortedIndices = Array(Set(indices.map{ get_positive_index_for_insert($0, axissize: dim, axis: ax) }).sorted(by: <))

        var ret = Matft.nums(0, shape: retShape, mftype: mfarr.mftype)
        
        // swap axis to use fancy indexing for first axis
        ret = Matft.swapaxes(ret, axis1: 0, axis2: ax)
        mfarr = Matft.swapaxes(mfarr, axis1: 0, axis2: ax)
        
        var startInd = 0
        for (n, ind) in sortedIndices.enumerated(){
            // fill mfarray first
            ret[(startInd+n)~<(ind+n)] = mfarr[startInd~<ind]
            // fill inserted value next
            ret[ind+n] = vals
            
            // update start index
            startInd = ind
        }
        if startInd < mfarr.shape[0]{
            // assign rest mfarray
            ret[(startInd + sortedIndices.count)~<] = mfarr[startInd~<]
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
            - indices: The indices before which `value` is inserted. Negative values count from the end.
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
