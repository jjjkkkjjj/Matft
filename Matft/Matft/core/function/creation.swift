//
//  creation.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

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
                shapeptr.assign(from: $0, count: mfarray.ndim)
            }
            mfarray.withStridesUnsafeMPtr{
                stridesptr.assign(from: $0, count: mfarray.ndim)
            }
        }
        return MfArray(base: mfarray, mfstructure: newstructure, offset: 0)
    }
    /**
       Create deep copy of mfarray. Deep means copied mfarray will be different object from original one
       - parameters:
            - mfarray: mfarray
    */
    static public func deepcopy(_ mfarray: MfArray) -> MfArray{
        let newmfdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.storedSize){
            dstptr in
            mfarray.withDataUnsafeMRPtr{
                dstptr.copyMemory(from: $0, byteCount: mfarray.storedByteSize)
            }
        }
        let newmfstructure = withDummyShapeStridesMPtr(mfarray.ndim){
            (dstshapeptr, dststridesptr) in
            mfarray.withShapeUnsafeMPtr{
                dstshapeptr.assign(from: $0, count: mfarray.ndim)
            }
            mfarray.withStridesUnsafeMPtr{
                dststridesptr.assign(from: $0, count: mfarray.ndim)
            }
        }
        return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
        /*
        let newdata = Matft.mfarray.mfdata.deepcopy(mfarray.mfdata)
        let newarray = MfArray(mfdata: newdata)
        return newarray*/
    }
    /**
       Create same value's mfarray
       - parameters:
            - value: the value of T, which must conform to Numeric protocol
            - shape: shape
            - mftype: (Optional) the type of mfarray
    */
    static public func nums<T: Numeric>(_ value: T, shape: [Int], mftype: MfType? = nil) -> MfArray{
        var shape = shape
        let size = shape.withUnsafeMutableBufferPointer{
            shape2size($0)
        }
        return MfArray(Array(repeating: value, count: size), mftype: mftype, shape: shape)
    }
    /**
       Create arithmetic sequence mfarray
       - parameters:
            - start: the start term of arithmetic sequence
            - stop: the end term of arithmetic sequence, which is not included.
            - shape: (Optional) shape
            - mftype: (Optional) the type of mfarray
    */
    static public func arange<T: Strideable>(start: T, stop: T, step: T.Stride, shape: [Int]? = nil, mftype: MfType? = nil) -> MfArray{
        return MfArray(Array(stride(from: start, to: stop, by: step)), mftype: mftype, shape: shape)
    }
    /**
       Create identity matrix. The size is (dim, dim)
       - parameters:
            - dim: the dimension, returned mfarray's shape is (dim, dim)
            - mftype: (Optional) the type of mfarray
    */
    static public func eye(dim: Int, mftype: MfType? = nil) -> MfArray{
        var eye = Array(repeating: Array(repeating: 0, count: dim), count: dim)
        for i in 0..<dim{
            eye[i][i] = 1
        }
        return MfArray(eye, mftype: mftype)
    }
    /**
       Concatenate given arrays vertically(for row)
       - parameters:
            - mfarrays: the array of MfArray.
    */
    static public func vstack(_ mfarrays: [MfArray]) {
        Matft.mfarray.concatenate(mfarrays, axis: 0)
    }
    /**
       Concatenate given arrays horizontally(for column)
       - parameters:
            - mfarrays: the array of MfArray.
    */
    static public func hstack(_ mfarrays: [MfArray]) {
        Matft.mfarray.concatenate(mfarrays, axis: 1)
    }
    /**
       Concatenate given arrays for arbitrary axis
       - parameters:
            - mfarrays: the array of MfArray.
            - axis: the axis to concatenate
    */
    static public func concatenate(_ mfarrays: [MfArray], axis: Int = 0){
        precondition(mfarrays.count >= 2, "inputs mfarrays must consist of more than 2")
        
        let basearray = mfarrays.first!
        var concatShape = basearray.shape
        concatShape.remove(at: axis)
        
        var retStoredType = basearray.storedType
        
        //check if argument is valid or not
        for i in 1..<mfarrays.count{
            var shapeExceptAxis = mfarrays[i].shape
            shapeExceptAxis.remove(at: axis)
            
            retStoredType = StoredType.priority(retStoredType, mfarrays[i].storedType)
            
            precondition(concatShape == shapeExceptAxis, "all the input array dimensions except for the concatenation axis must match exactly")
        }
        
        let retsize = concatShape.reduce(1, *) * mfarrays.count
        
        switch retStoredType {
        case .Float:
            let dstptr = create_unsafeMPtrT(type: Float.self, count: retsize)
            for mfarray in mfarrays{
                
            }
            
        case .Double:
            let dstptr = create_unsafeMPtrT(type: Double.self, count: retsize)
        }
        
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
