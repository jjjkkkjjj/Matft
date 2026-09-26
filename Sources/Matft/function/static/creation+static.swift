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
       Create shallow copy of mfarray. Shallow means copied mfarray will be  sharing data with original one
       - parameters:
           - mfarray: mfarray
    */
    static public func shallowcopy(_ mfarray: MfArray) -> MfArray{
        let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
        
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    /**
       Create deep copy of mfarray. Deep means copied mfarray will be different object from original one
       - parameters:
            - mfarray: mfarray
            - order: (Optional) order, default is nil, which means close to either row or column major if possibe.
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
       Create same value's mfarray
       - parameters:
            - value: the value of T, which must conform to MfTypable protocol
            - shape: shape
            - mftype: (Optional) the type of mfarray
            - order: (Optional) order, default is nil, which means close to row major
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
       Create same value with passed mfarray's structure
       - parameters:
            - value: the value of T, which must conform to MfTypable protocol
            - mfarray: mfarray
    */
    static public func nums_like<T: MfTypable>(_ value: T, mfarray: MfArray, mforder: MfOrder = .Row) -> MfArray{
        return Matft.nums(value, shape: mfarray.shape, mftype: mfarray.mftype, mforder: mforder)
    }
    /**
       Create arithmetic sequence mfarray
       - parameters:
            - start: the start term of arithmetic sequence
            - stop: the end term of arithmetic sequence, which is not included.
            - shape: (Optional) shape
            - mftype: (Optional) the type of mfarray
            - order: (Optional) order, default is nil, which means close to row major
    */
    static public func arange<T: Strideable>(start: T, to: T, by: T.Stride, shape: [Int]? = nil, mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        return MfArray(Array(stride(from: start, to: to, by: by)), mftype: mftype, shape: shape, mforder: mforder)
    }
    /**
       Create identity matrix. The size is (dim, dim)
       - parameters:
            - dim: the dimension, returned mfarray's shape is (dim, dim)
            - mftype: (Optional) the type of mfarray
            - order: (Optional) order, default is nil, which means close to row major
    */
    static public func eye(dim: Int, mftype: MfType? = nil, mforder: MfOrder = .Row) -> MfArray{
        var eye = Array(repeating: Array(repeating: 0, count: dim), count: dim)
        for i in 0..<dim{
            eye[i][i] = 1
        }
        return MfArray(eye, mftype: mftype, mforder: mforder)
    }
    /**
       Create diagonal matrix. The size is (dim, dim)
       - parameters:
            - v: the diagonal values, returned mfarray's shape is (dim, dim), whose dim is length of v
            - k: Int. Diagonal position.
            - mftype: (Optional) the type of mfarray
            - order: (Optional) order, default is nil, which means close to row major
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
       Create diagonal matrix. The size is (dim, dim)
       - parameters:
            - v: the diagonal values, returned mfarray's shape is (dim, dim), whose dim is length of v
            - k: Int. Diagonal position.
            - mftype: (Optional) the type of mfarray
            - order: (Optional) order, default is nil, which means close to row major
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
       Concatenate given arrays vertically(for row)
       - parameters:
            - mfarrays: the array of MfArray.
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
       Concatenate given arrays horizontally(for column)
       - parameters:
            - mfarrays: the array of MfArray.
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
       Concatenate given arrays for arbitrary axis
       - parameters:
            - mfarrays: the array of MfArray.
            - axis: the axis to concatenate
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
       - parameters:
            - mfarrays: the array of MfArray.
            - values: appended mfarray
            - axis: the axis to append
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
       Append values to the end of an array.
       - parameters:
            - mfarrays: the array of MfArray.
            - value: appended value
            - axis: the axis to append
    */
    static public func append<T: MfTypable>(_ mfarray: MfArray, value: T, axis: Int? = nil) -> MfArray{
        return Matft.append(mfarray, values: MfArray([value]), axis: axis)
    }
    
    /**
       Take elements from an array along an axis.
       - parameters:
            - mfarrays: the array of MfArray.
            - indices: indices mfarray
            - axis: the axis to append
    */
    static public func take(_ mfarray: MfArray, indices: MfArray, axis: Int? = nil) -> MfArray{
        guard let axis = axis else {
            // like numpy, take from the flattened array
            return mfarray.flatten()[indices]
        }
        return Matft.swapaxes(mfarray, axis1: axis, axis2: 0)[indices].swapaxes(axis1: 0, axis2: axis)
    }
    
    /**
       Insert values along the given axis before the given indices.
       - parameters:
            - mfarrays: the array of MfArray.
            - indices: Index sequence
            - values: appended mfarray
            - axis: the axis to insert
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
        let retmftype = MfType.priority(mfarr.mftype, values.mftype)
        
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
       Insert values along the given axis before the given indices.
       - parameters:
            - mfarrays: the array of MfArray.
            - indices: Index sequence
            - value: mftypable value
            - axis: the axis to insert
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
