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
        let newdata = mfarray.mfdata.astype(mftype)
        return MfArray(mfdata: newdata)
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
        
        for i in 0..<ndim{
            newarray.shapeptr[i] = mfarray.shapeptr[permutation[i]]
            newarray.stridesptr[i] = mfarray.stridesptr[permutation[i]]
        }
        newarray.mfdata.updateContiguous()
        
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
        var shape = shape
        let newarray = Matft.mfarray.shallowcopy(mfarray)
        newarray.mfdata._shape.assign(from: &shape, count: shape.count)
        newarray.mfdata._ndim = shape2ndim(&shape)
        newarray.mfdata._size = shape2size(&shape)
        
        let idim_start = newarray.ndim  - mfarray.ndim
        
        
        if idim_start < 0{
            throw MfError.conversionError("can't broadcast to fewer dimensions")
        }
        
        for idim in (idim_start..<newarray.ndim ).reversed(){
            let strides_shape_value = mfarray.shape[idim - idim_start]
            /* If it doesn't have dimension one, it must match */
            if strides_shape_value == 1{
                newarray.stridesptr[idim] = 0
            }
            else if strides_shape_value != shape[idim]{
                throw MfError.conversionError("could not broadcast from shape \(mfarray.ndim), \(mfarray.shape) into shape \(newarray.ndim), \(shape)")
            }
            else{
                newarray.stridesptr[idim] = mfarray.stridesptr[idim - idim_start]
            }
        }
        
        /* New dimensions get a zero stride */
        for idim in 0..<idim_start{
            newarray.stridesptr[idim] = 0
        }
        newarray.mfdata.updateContiguous()
        
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
        var newshape = [ret.size]
        var newstrides = [1]
        
        //shape
        ret.mfdata.free_shape()
        let newshapeptr = create_unsafeMPtrT(type: Int.self, count: 1)
        newshape.withUnsafeMutableBufferPointer{
            newshapeptr.assign(from: $0.baseAddress!, count: 1)
        }
        ret.mfdata._shape = newshapeptr
        
        //strides
        ret.mfdata.free_strides()
        let newstridesptr = create_unsafeMPtrT(type: Int.self, count: 1)
        newstrides.withUnsafeMutableBufferPointer{
            newstridesptr.assign(from: $0.baseAddress!, count: 1)
        }
        ret.mfdata._strides = newstridesptr
        ret.mfdata._ndim = 1
        return ret
    }
}

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
