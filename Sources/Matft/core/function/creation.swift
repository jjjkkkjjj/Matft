//
//  creation.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray{
    /**
       Create shallow copy of mfarray. Shallow means copied mfarray will be  sharing data with original one
       - parameters:
           - mfarray: mfarray
    */
    static public func shallowcopy(_ mfarray: MfArray) -> MfArray{
        let newstructure = withDummyShapeStridesMPtr(mfarray.ndim){
            shapeptr, stridesptr in
            mfarray.withShapeUnsafeMPtr{
                [unowned mfarray] in
                shapeptr.assign(from: $0, count: mfarray.ndim)
            }
            mfarray.withStridesUnsafeMPtr{
                [unowned mfarray] in
                stridesptr.assign(from: $0, count: mfarray.ndim)
            }
        }
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
            if mfarray.mfflags.column_contiguous || mfarray.mfflags.row_contiguous{// all including strides will be copied
                return copyAll(mfarray)
            }
            if !(mfarray.withStridesUnsafeMBPtr{ isReverse($0) }) && !mfarray.mfdata._isView{// not contain reverse and is not view, copy all
                return copyAll(mfarray)
            }
            else{//close to row major
                return to_row_major(mfarray)
            }

        }
        
        /*
        let newdata = Matft.mfarray.mfdata.deepcopy(mfarray.mfdata)
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
        let size = shape.withUnsafeMutableBufferPointer{
            shape2size($0)
        }
        return MfArray(Array(repeating: value, count: size), mftype: mftype, shape: shape, mforder: mforder)
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
        
        let rmajorArrays = mfarrays.map{ Matft.mfarray.conv_order($0, mforder: .Row) }
        let retSize = shape2size(&retShape)
        
        let newmfdata = withDummyDataMRPtr(retMfType, storedSize: retSize){
            dstptr in
            switch MfType.storedType(retMfType){
            case .Float:
                let dstptrF = dstptr.bindMemory(to: Float.self, capacity: retSize)
                var offset = 0
                for array in rmajorArrays{
                    array.withDataUnsafeMBPtrT(datatype: Float.self){
                        [unowned array] in
                        copy_unsafeptrT(array.storedSize, $0.baseAddress!, 1, dstptrF + offset, 1, cblas_scopy)
                    }
                    offset += array.storedSize
                }
                
            case .Double:
                let dstptrD = dstptr.bindMemory(to: Double.self, capacity: retSize)
                var offset = 0
                for array in rmajorArrays{
                    array.withDataUnsafeMBPtrT(datatype: Double.self){
                        [unowned array] in
                        copy_unsafeptrT(array.storedSize, $0.baseAddress!, 1, dstptrD + offset, 1, cblas_dcopy)
                    }
                    offset += array.storedSize
                }
            }
        }
        
        let retndim = retShape.count
        let newmfstructure = withDummyShapeStridesMBPtr(retndim){
            shapeptr, stridesptr in
            retShape.withUnsafeMutableBufferPointer{
                shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
            }
            
            let newstrides = shape2strides(shapeptr, mforder: .Row)
            stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: retndim)
            
            newstrides.deallocate()
        }
        return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
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
        
        let cmajorArrays = mfarrays.map{ Matft.mfarray.conv_order($0, mforder: .Column) }
        let retSize = shape2size(&retShape)
        
        let newmfdata = withDummyDataMRPtr(retMfType, storedSize: retSize){
            dstptr in
            switch MfType.storedType(retMfType){
            case .Float:
                let dstptrF = dstptr.bindMemory(to: Float.self, capacity: retSize)
                var offset = 0
                for array in cmajorArrays{
                    array.withDataUnsafeMBPtrT(datatype: Float.self){
                        [unowned array] in
                        copy_unsafeptrT(array.storedSize, $0.baseAddress!, 1, dstptrF + offset, 1, cblas_scopy)
                    }
                    offset += array.storedSize
                }
                
            case .Double:
                let dstptrD = dstptr.bindMemory(to: Double.self, capacity: retSize)
                var offset = 0
                for array in cmajorArrays{
                    array.withDataUnsafeMBPtrT(datatype: Double.self){
                        [unowned array] in
                        copy_unsafeptrT(array.storedSize, $0.baseAddress!, 1, dstptrD + offset, 1, cblas_dcopy)
                    }
                    offset += array.storedSize
                }
            }
        }
        
        let retndim = retShape.count
        let newmfstructure = withDummyShapeStridesMBPtr(retndim){
            shapeptr, stridesptr in
            retShape.withUnsafeMutableBufferPointer{
                shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
            }
            
            let newstrides = shape2strides(shapeptr, mforder: .Column)
            stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: retndim)
            
            newstrides.deallocate()
        }
        return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
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
        let axis = axis >= 0 ? axis : retndim + axis
        precondition(axis >= 0 && axis < retndim, "Invalid axis")
        if axis == 0{// vstack is faster than this function
            return Matft.mfarray.vstack(mfarrays)
        }
        else if axis == retndim - 1{// hstack is faster than this function
            return Matft.mfarray.hstack(mfarrays)
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
        
        let majorArrays = mfarrays.map{ Matft.mfarray.conv_order($0, mforder: fasterOrder).astype(retMfType) }
        let retSize = shape2size(&retShape)
        
        let newmfdata = withDummyDataMRPtr(retMfType, storedSize: retSize){
            dstptr in
            switch MfType.storedType(retMfType){
            case .Float:
                let dstptrF = dstptr.bindMemory(to: Float.self, capacity: retSize)
    
                var dst_offset = 0
                for sb in 0..<slowerBlockSize{
                    for array in majorArrays{
                        let concatSize = array.shape[axis]
                        
                        array.withDataUnsafeMBPtrT(datatype: Float.self){
                            copy_unsafeptrT(fasterBlockSize * concatSize, $0.baseAddress! + sb * fasterBlockSize * concatSize, 1, dstptrF + dst_offset, 1, cblas_scopy)
                        }
                        dst_offset += fasterBlockSize * concatSize
                    }
                }
                
            case .Double:
                let dstptrD = dstptr.bindMemory(to: Double.self, capacity: retSize)
                var dst_offset = 0
                for sb in 0..<slowerBlockSize{
                    for array in majorArrays{
                        let concatSize = array.shape[axis]
                        
                        array.withDataUnsafeMBPtrT(datatype: Double.self){
                            copy_unsafeptrT(fasterBlockSize * concatSize, $0.baseAddress! + sb * fasterBlockSize * concatSize, 1, dstptrD + dst_offset, 1, cblas_dcopy)
                        }
                        dst_offset += fasterBlockSize * concatSize
                    }
                }
            }
        }
        
        let newmfstructure = withDummyShapeStridesMBPtr(retndim){
            shapeptr, stridesptr in
            retShape.withUnsafeMutableBufferPointer{
                shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
            }
            
            let newstrides = shape2strides(shapeptr, mforder: fasterOrder)
            stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: retndim)
            
            newstrides.deallocate()
        }
        
        return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
    }
}
/*
extension Matft.mfarray.mfdata{
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
        
        let newmfdata = MfData(refdata: mfdata, offset: 0, shapeptr: shapeptr, ndim: mfdata._ndim, mforder: mfdata._order, stridesptr: stridesptr)
        
        return newmfdata
    }
}
*/
