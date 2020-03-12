//
//  conversion.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray{
    /**
       Create another typed mfarray. Created mfarray will be different object from original one
       - parameters:
            - mfarray: mfarray
            - mftype: the type of mfarray
    */
    public static func astype(_ mfarray: MfArray, mftype: MfType) -> MfArray{
        //let newarray = Matft.mfarray.shallowcopy(mfarray)
        //newarray.mfdata._mftype = mftype
        let newStoredType = MfType.storedType(mftype)
        if mfarray.storedType == newStoredType{
            let ret = mfarray.deepcopy()
            ret.mfdata._mftype = mftype
            return ret
        }
        
        //copy shape and strides
        let newmfstructure = withDummyShapeStridesMPtr(mfarray.ndim){
            (dstshapeptr, dststridesptr) in
            mfarray.withShapeUnsafeMPtr{
                dstshapeptr.assign(from: $0, count: mfarray.ndim)
            }
            mfarray.withStridesUnsafeMPtr{
                dststridesptr.assign(from: $0, count: mfarray.ndim)
            }
        }

        switch newStoredType{
        case .Float://double to float
            let newdata = withDummyDataMRPtr(mftype, storedSize: mfarray.storedSize){
                let dstptr = $0.assumingMemoryBound(to: Float.self)
                mfarray.withDataUnsafeMBPtrT(datatype: Double.self){
                    unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptr, vDSP_vdpsp, mfarray.storedSize)
                }
            }
            
            return MfArray(mfdata: newdata, mfstructure: newmfstructure)
            
        case .Double://float to double
            let newdata = withDummyDataMRPtr(mftype, storedSize: mfarray.storedSize){
                let dstptr = $0.assumingMemoryBound(to: Double.self)
                mfarray.withDataUnsafeMBPtrT(datatype: Float.self){
                     unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptr, vDSP_vspdp, mfarray.storedSize)
                }
            }
            
            return MfArray(mfdata: newdata, mfstructure: newmfstructure)
        }
    }
    /**
       Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
            - mfarray: mfarray
            - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    */
    public static func transpose(_ mfarray: MfArray, axes: [Int]? = nil) -> MfArray{
        var permutation: [Int] = [], reverse_permutation: [Int] = []
        let ndim =  mfarray.shape.count
        
        let newarray = Matft.mfarray.shallowcopy(mfarray)
        
        if let axes = axes{
            precondition(axes.count == ndim, "axes don't match array")
            for _ in 0..<ndim{
                reverse_permutation.append(-1)
            }
            for i in 0..<ndim{
                let axis = axes[i]
                precondition(axis < ndim, "invalid axes")
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

        newarray.withShapeStridesUnsafeMBPtr{
            shapeptr, stridesptr in
            for i in 0..<ndim{
                shapeptr[i] = origShape[permutation[i]]
                stridesptr[i] = origStrides[permutation[i]]
            }
        }

        return newarray
    }
    /**
       Create broadcasted mfarray.
       - parameters:
            - mfarray: mfarray
            - shape: shape
       - throws:
        An error of type `MfError.conversionError`
    */
    public static func broadcast_to(_ mfarray: MfArray, shape: [Int]) throws -> MfArray{
        var new_shape = shape
        let newarray = Matft.mfarray.shallowcopy(mfarray)
        let new_ndim = shape2ndim(&new_shape)
        
        let idim_start = new_ndim  - mfarray.ndim
        
        
        if idim_start < 0{
            throw MfError.conversionError("can't broadcast to fewer dimensions")
        }
        
        let orig_strides = mfarray.strides
        let orig_shape = mfarray.shape
        let newstructure =  try withDummyShapeStridesMBPtr(new_ndim){
            shapteptr, stridesptr in
            
            for idim in (idim_start..<new_ndim).reversed(){
                let strides_shape_value = orig_shape[idim - idim_start]
                /* If it doesn't have dimension one, it must match */
                if strides_shape_value == 1{
                    stridesptr[idim] = 0
                }
                else if strides_shape_value != shape[idim]{
                    throw MfError.conversionError("could not broadcast from shape \(mfarray.ndim), \(orig_shape) into shape \(new_ndim), \(shape)")
                }
                else{
                    stridesptr[idim] = orig_strides[idim - idim_start]
                }
            }
            
            /* New dimensions get a zero stride */
            for idim in 0..<idim_start{
                stridesptr[idim] = 0
            }
            
            shapteptr.baseAddress!.moveAssign(from: &new_shape, count: new_ndim)
        }
        
        newarray.mfstructure = newstructure
        
        return newarray
    }

    /**
       Convert order of stored data.
       - parameters:
            - mfarray: mfarray
            - mforder: mforder
    */
    public static func conv_order(_ mfarray: MfArray, mforder: MfOrder) -> MfArray{
        switch mforder {
        case .Row:
            return to_row_major(mfarray)
        case .Column:
            return to_column_major(mfarray)
        }
    }
    /**
       Flatten 1d-mfarray
       - parameters:
            - mfarray: mfarray
            - mforder: (Optional) mforder, default is Row
    */
    public static func flatten(_ mfarray: MfArray, mforder: MfOrder = .Row) -> MfArray{
        let ret = Matft.mfarray.conv_order(mfarray, mforder: mforder)
        
        //shape
        let newstructure = withDummyShapeStridesMBPtr(1){
            shapeptr, stridesptr in
            shapeptr[0] = ret.size
            stridesptr[0] = 1
        }
        
        ret.mfstructure = newstructure
        
        return ret
    }
}

/*
extension Matft.mfarray.mfdata{
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
        shapeptr.assign(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.assign(from: mfdata._strides, count: mfdata._ndim)
        
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
