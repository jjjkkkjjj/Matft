//
//  creation.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

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
                return to_row_major(mfarray)
            case .Column:
                return to_column_major(mfarray)
            }
        }
        else{
            if mfarray.mfstructure.column_contiguous || mfarray.mfstructure.row_contiguous{// all including strides will be copied
                return copyAll(mfarray)
            }
            var strides = mfarray.strides
            if !isReverse(&strides) && !mfarray.mfdata._isView{// not contain reverse and is not view, copy all
                return copyAll(mfarray)
            }
            else{//close to row major
                return to_row_major(mfarray)
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
        let newdata = MfData(size: size, mftype: retmftype)
        func _create<U: MfStorable>(_ converted_value: U){
            var arr = Array(repeating: converted_value, count: size)
            let ptrU = newdata.data.bindMemory(to: U.self, capacity: size)
            arr.withUnsafeMutableBufferPointer{
                ptrU.moveAssign(from: $0.baseAddress!, count: size)
            }
        }
        
        switch MfType.storedType(retmftype){
        case .Float:
            _create(Float.from(value))
        case .Double:
            _create(Double.from(value))
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
        
        let newdata = MfData(size: size, mftype: retmftype)
        func _create<T: MfStorable>(_ type: T.Type){
            let ptrT = newdata.data.bindMemory(to: T.self, capacity: size)
            var d = Array(repeating: T.zero, count: size)
            v.withDataUnsafeMBPtrT(datatype: T.self){
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
            d.withUnsafeMutableBufferPointer{
                ptrT.moveAssign(from: $0.baseAddress!, count: size)
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
            
            precondition(retShape == shapeExceptAxis, "all the input array dimensions except for the concatenation axis must match exactly")
        }
        
        retShape.insert(concatDim, at: 0)// return shape
        
        let rmajorArrays = mfarrays.map{ Matft.conv_order($0, mforder: .Row) }
        let retSize = shape2size(&retShape)
        
        let newdata = MfData(size: retSize, mftype: retMfType)
        func _stack<T: MfStorable>(_ cblas_func: cblas_convorder_func<T>){
            let dstptrT = newdata.data.bindMemory(to: T.self, capacity: retSize)
            var offset = 0
            for array in rmajorArrays{
                array.withDataUnsafeMBPtrT(datatype: T.self){
                    [unowned array] in
                    copy_unsafeptrT(array.storedSize, $0.baseAddress!, 1, dstptrT + offset, 1, cblas_func)
                }
                offset += array.storedSize
            }
        }
        switch MfType.storedType(retMfType){
        case .Float:
            _stack(cblas_scopy)
            
        case .Double:
            _stack(cblas_dcopy)
        }
        
        let newstructure = MfStructure(shape: retShape, mforder: .Row)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
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
            
            precondition(retShape == shapeExceptAxis, "all the input array dimensions except for the concatenation axis must match exactly")
        }
        
        retShape.insert(concatDim, at: retShape.endIndex)// return shape
        
        let cmajorArrays = mfarrays.map{ Matft.conv_order($0, mforder: .Column) }
        let retSize = shape2size(&retShape)
        
        let newdata = MfData(size: retSize, mftype: retMfType)
        func _stack<T: MfStorable>(_ cblas_func: cblas_convorder_func<T>){
            let dstptrT = newdata.data.bindMemory(to: T.self, capacity: retSize)
            var offset = 0
            for array in cmajorArrays{
                array.withDataUnsafeMBPtrT(datatype: T.self){
                    [unowned array] in
                    copy_unsafeptrT(array.storedSize, $0.baseAddress!, 1, dstptrT + offset, 1, cblas_func)
                }
                offset += array.storedSize
            }
        }
        switch MfType.storedType(retMfType){
        case .Float:
            _stack(cblas_scopy)
            
        case .Double:
            _stack(cblas_dcopy)
        }
        
        let newstructure = MfStructure(shape: retShape, mforder: .Column)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
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
        let axis = get_axis(axis, ndim: retndim)
        
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
            
            precondition(retShape == shapeExceptAxis, "all the input array dimensions except for the concatenation axis must match exactly")
        }
        
        retShape.insert(concatDim, at: axis)// return shape
        
        var columnShape = retShape // the left side shape splited by axis, must have more than one elements
        columnShape.removeSubrange(axis..<retShape.count)
        let columnSize = shape2size(&columnShape)
        var rowShape = retShape// the right side shape splited by axis, must have more than one elements
        rowShape.removeSubrange(0...axis)
        let rowSize = shape2size(&rowShape)
        
        let fasterOrder = rowSize >= columnSize ? MfOrder.Row : MfOrder.Column
        let fasterBlockSize = rowSize >= columnSize ? rowSize : columnSize
        let slowerBlockSize = rowSize >= columnSize ? columnSize : rowSize
        
        let majorArrays = mfarrays.map{ Matft.conv_order($0, mforder: fasterOrder).astype(retMfType) }
        let retSize = shape2size(&retShape)
        
        let newdata = MfData(size: retSize, mftype: retMfType)
        func _concat<T: MfStorable>(_ cblas_func: cblas_convorder_func<T>){
            let dstptrT = newdata.data.bindMemory(to: T.self, capacity: retSize)

            var dst_offset = 0
            for sb in 0..<slowerBlockSize{
                for array in majorArrays{
                    let concatSize = array.shape[axis]
                    
                    array.withDataUnsafeMBPtrT(datatype: T.self){
                        copy_unsafeptrT(fasterBlockSize * concatSize, $0.baseAddress! + sb * fasterBlockSize * concatSize, 1, dstptrT + dst_offset, 1, cblas_func)
                    }
                    dst_offset += fasterBlockSize * concatSize
                }
            }
        }
        switch MfType.storedType(retMfType){
        case .Float:
            _concat(cblas_scopy)
            
        case .Double:
            _concat(cblas_dcopy)
        }
        
        let newstructure = MfStructure(shape: retShape, mforder: fasterOrder)
        
        return MfArray(mfdata: newdata, mfstructure: newstructure)
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
        let axis = axis ?? 0
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
        // convert corrext index, sort index and then remove duplicated index
        var mfarr: MfArray, vals: MfArray, ax: Int
        if let axis = axis{
            mfarr = mfarray
            ax = get_axis(axis, ndim: mfarr.ndim)
        }
        else{
            mfarr = mfarray.ndim != 1 ? mfarray.flatten() : mfarray
            ax = mfarr.ndim - 1
        }
        vals = values.squeeze()
    
        let dim = mfarr.shape[ax] //Inserted values number for each index
        var retShape = mfarr.shape
        retShape[ax] += indices.count
        let sortedIndices = Array(Set(indices.map{ get_index_for_insert($0, dim: dim, axis: ax) }).sorted(by: <))

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
        shapeptr.assign(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.assign(from: mfdata._strides, count: mfdata._ndim)
        
        //copy data
        switch mfdata._storedType {
        case .Float:
            let dataptr = create_unsafeMRPtr(type: Float.self, count: mfdata._size)
            dataptr.assumingMemoryBound(to: Float.self).assign(from: mfdata._data.assumingMemoryBound(to: Float.self), count: mfdata._storedSize)
            return MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mfdata._mftype, ndim: mfdata._ndim, stridesptr: stridesptr)
        case .Double:
            let dataptr = create_unsafeMRPtr(type: Double.self, count: mfdata._size)
            dataptr.assumingMemoryBound(to: Double.self).assign(from: mfdata._data.assumingMemoryBound(to: Double.self), count: mfdata._storedSize)
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
        shapeptr.assign(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.assign(from: mfdata._strides, count: mfdata._ndim)
        
        let newdata = MfData(refdata: mfdata, offset: 0, shapeptr: shapeptr, ndim: mfdata._ndim, mforder: mfdata._order, stridesptr: stridesptr)
        
        return newdata
    }
}
*/
