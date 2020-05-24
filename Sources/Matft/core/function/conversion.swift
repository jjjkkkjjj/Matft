//
//  conversion.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft{
    /**
       Create another typed mfarray. Created mfarray will be different object from original one
       - parameters:
            - mfarray: mfarray
            - mftype: the type of mfarray
    */
    public static func astype<T: MfTypable, U: MfTypable>(_ mfarray: MfArray<T>, mftype: U.Type) -> MfArray<U>{
        //let newarray = Matft.shallowcopy(mfarray)
        //newarray.mfdata._mftype = mftype
        if U.self is Bool.Type{
            return to_Bool(mfarray) as! MfArray<U>
        }
        
        let newStoredType = MfType.storedType(U.self)
        
        //copy shape and strides
        let newmfstructure: MfStructure
        var mfarray = mfarray
        if !(mfarray.mfflags.column_contiguous || mfarray.mfflags.row_contiguous){// close to row major
            mfarray = to_row_major(mfarray)
        }
        newmfstructure = copy_mfstructure(mfarray.mfstructure)
        
        if mfarray.storedType == newStoredType{
            switch newStoredType{
            case .Float://double to float
                let newdata = withDummyDataMRPtr(U.self, storedSize: mfarray.storedSize){
                    let dstptr = $0.bindMemory(to:  Float.self, capacity: mfarray.storedSize)
                    mfarray.withDataUnsafeMBPtrT(datatype: Float.self){
                        [unowned mfarray] in
                        dstptr.assign(from: $0.baseAddress!, count: mfarray.storedSize)
                    }
                }
                
                return MfArray(mfdata: newdata, mfstructure: newmfstructure)
                
            case .Double://float to double
                let newdata = withDummyDataMRPtr(U.self, storedSize: mfarray.storedSize){
                    let dstptr = $0.bindMemory(to:  Double.self, capacity: mfarray.storedSize)
                    mfarray.withDataUnsafeMBPtrT(datatype: Double.self){
                        [unowned mfarray] in
                         dstptr.assign(from: $0.baseAddress!, count: mfarray.storedSize)
                    }
                }
                
                return MfArray(mfdata: newdata, mfstructure: newmfstructure)
            }
        }
        else{
            switch newStoredType{
            case .Float://double to float
                let newdata = withDummyDataMRPtr(U.self, storedSize: mfarray.storedSize){
                    let dstptr = $0.bindMemory(to:  Float.self, capacity: mfarray.storedSize)
                    mfarray.withDataUnsafeMBPtrT(datatype: Double.self){
                        [unowned mfarray] in
                        unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptr, vDSP_vdpsp, mfarray.storedSize)
                    }
                }
                
                return MfArray(mfdata: newdata, mfstructure: newmfstructure)
                
            case .Double://float to double
                let newdata = withDummyDataMRPtr(U.self, storedSize: mfarray.storedSize){
                    let dstptr = $0.bindMemory(to:  Double.self, capacity: mfarray.storedSize)
                    mfarray.withDataUnsafeMBPtrT(datatype: Float.self){
                        [unowned mfarray] in
                         unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptr, vDSP_vspdp, mfarray.storedSize)
                    }
                }
                
                return MfArray(mfdata: newdata, mfstructure: newmfstructure)
            }
        }
    }
    /**
       Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
            - mfarray: mfarray
            - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    */
    public static func transpose<T: MfTypable>(_ mfarray: MfArray<T>, axes: [Int]? = nil) -> MfArray<T>{
        var permutation: [Int] = [], reverse_permutation: [Int] = []
        let ndim =  mfarray.shape.count
        
        let newarray = Matft.shallowcopy(mfarray)
        
        if let axes = axes{
            precondition(axes.count == ndim, "axes(\(axes.count) don't match array's dimension(\(ndim)")
            for _ in 0..<ndim{
                reverse_permutation.append(-1)
            }
            for i in 0..<ndim{
                let axis = get_axis(axes[i], ndim: ndim)

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
       Convert new shaped mfarray
       - parameters:
            - mfarray: mfarray
            - shape: the new shape
            - order: (Optional) order, default is nil, which means close to either row or column major if possibe.
       - Important: this function will create copy not view
    */
    public static func reshape<T: MfTypable>(_ mfarray: MfArray<T>, newshape: [Int], order: MfOrder? = nil) -> MfArray<T>{
        var newshape = get_shape(newshape, mfarray.size)
        precondition(mfarray.size == shape2size(&newshape), "new shape's size:\(shape2size(&newshape)) must be same as mfarray's size:\(mfarray.size)")
        
        var order = order ?? .Row
        if mfarray.mfflags.column_contiguous{
            order = .Column
        }
        
        switch order {
        case .Row:
            let flattenArray = mfarray.flatten(.Row)
            return MfArray(flattenArray.data, shape: newshape, mforder: .Row)
        case .Column:
            let flattenArray = mfarray.flatten(.Column)
            return MfArray(flattenArray.data, shape: newshape, mforder: .Row)
        }
        
        /* i wanna implement no copy version
        let new_ndim = newshape.count
        let newarray = Matft.shallowcopy(mfarray)
        
        let newstructure = withDummyShapeStridesMBPtr(new_ndim){
            shapeptr, stridesptr in
            //move from newshape
            shapeptr.baseAddress!.moveAssign(from: &newshape, count: new_ndim)
            
            for axis in 0..<new_ndim{
                
            }
        }*/
    }
    /**
       Create mfarray expanded dimension for given axis
       - parameters:
            - mfarray: mfarray
            - axis: the expanded axis
    */
    public static func expand_dims<T: MfTypable>(_ mfarray: MfArray<T>, axis: Int) -> MfArray<T>{
        let newarray = mfarray.shallowcopy()
        
        var newshape = mfarray.shape
        let axis = get_axis_for_expand_dims(axis, ndim: mfarray.ndim)
        
        newshape.insert(1, at: axis)
        var newstrides = mfarray.strides
        newstrides.insert(0, at: axis)
        
        let newmfstructure = create_mfstructure(&newshape, &newstrides)
        newarray.mfstructure = newmfstructure
        
        return newarray
    }
    /**
       Create mfarray expanded dimension for given axis
       - parameters:
            - mfarray: mfarray
            - axes: the list of expanded axes
    */
    public static func expand_dims<T: MfTypable>(_ mfarray: MfArray<T>, axes: [Int]) -> MfArray<T>{
        let newarray = mfarray.shallowcopy()
        // reorder descending
        let axes = axes.sorted{ $0 < $1 }
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        for axis in axes{
            let axis = get_axis_for_expand_dims(axis, ndim: newshape.count)
            
            newshape.insert(1, at: axis)
            newstrides.insert(0, at: axis)
        }
        
        let newmfstructure = create_mfstructure(&newshape, &newstrides)
        newarray.mfstructure = newmfstructure
        
        return newarray
    }
    /**
       Create mfarray removed for 1-dimension
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) the removed axis
    */
    public static func squeeze<T: MfTypable>(_ mfarray: MfArray<T>, axis: Int? = nil) -> MfArray<T>{
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        
        if let axis = axis{
            let axis = get_axis(axis, ndim: mfarray.ndim)
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
        let newmfstructure = create_mfstructure(&newshape, &newstrides)
        newarray.mfstructure = newmfstructure
        return newarray
        /*
        if mfarray.mfflags.column_contiguous{
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
       Create mfarray removed for 1-dimension
       - parameters:
            - mfarray: mfarray
            - axes: the list of  removed axes
    */
    public static func squeeze<T: MfTypable>(_ mfarray: MfArray<T>, axes: [Int]) -> MfArray<T>{
        // reoder descending
        let axes = axes.sorted{ $0 > $1 }
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        for axis in axes{
            let axis = get_axis(axis, ndim: mfarray.ndim)
            precondition(newshape.remove(at: axis) == 1, "cannot select an axis to squeeze out which has size not equal to one")
            newstrides.remove(at: axis)
        }
        
        
        let newarray = mfarray.shallowcopy()
        let newmfstructure = create_mfstructure(&newshape, &newstrides)
        newarray.mfstructure = newmfstructure
        return newarray
    }
    
    /**
       Create broadcasted mfarray.
       - parameters:
            - mfarray: mfarray
            - shape: shape
    */
    public static func broadcast_to<T: MfTypable>(_ mfarray: MfArray<T>, shape: [Int]) -> MfArray<T>{
        var new_shape = shape
        //let newarray = Matft.shallowcopy(mfarray)
        let new_ndim = shape2ndim(&new_shape)
        
        let idim_start = new_ndim  - mfarray.ndim
        
        precondition(idim_start >= 0, "can't broadcast to fewer dimensions")
        
        let orig_strides = mfarray.strides
        let orig_shape = mfarray.shape
        let newstructure = withDummyShapeStridesMBPtr(new_ndim){
            shapteptr, stridesptr in
            
            for idim in (idim_start..<new_ndim).reversed(){
                let strides_shape_value = orig_shape[idim - idim_start]
                /* If it doesn't have dimension one, it must match */
                if strides_shape_value == 1{
                    stridesptr[idim] = 0
                }
                else if strides_shape_value != shape[idim]{
                    preconditionFailure("could not broadcast from shape \(mfarray.ndim), \(orig_shape) into shape \(new_ndim), \(shape)")
                }
                else{
                    stridesptr[idim] = orig_strides[idim - idim_start]
                }
            }
            
            /* New dimensions get a zero stride */
            for idim in 0..<idim_start{
                stridesptr[idim] = 0
            }
            
            new_shape.withUnsafeMutableBufferPointer{
                shapteptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: new_ndim)
            }
        }
        
        //newarray.mfstructure = newstructure
        //return newarray
        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }

    /**
       Convert order of stored data.
       - parameters:
            - mfarray: mfarray
            - mforder: mforder
    */
    public static func conv_order<T: MfTypable>(_ mfarray: MfArray<T>, mforder: MfOrder) -> MfArray<T>{
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
    public static func flatten<T: MfTypable>(_ mfarray: MfArray<T>, mforder: MfOrder = .Row) -> MfArray<T>{
        let ret = Matft.conv_order(mfarray, mforder: mforder)
        
        //shape
        let newstructure = withDummyShapeStridesMBPtr(1){
            shapeptr, stridesptr in
            shapeptr[0] = ret.size
            stridesptr[0] = 1
        }
        
        ret.mfstructure = newstructure
        
        return ret
    }
    
    /**
       Reverse the mfarray order along given axis
       - parameters:
            - mfarray: mfarray
            - axis: (optional) the reversed axis
    */
    public static func flip<T: MfTypable>(_ mfarray: MfArray<T>, axis: Int? = nil) -> MfArray<T>{
        if let axis = axis{
            let axis = get_axis(axis, ndim: mfarray.ndim)
            var slices = Array<MfSlice>(repeating: MfSlice(start: 0, to: nil, by: 1), count: mfarray.ndim)
            slices[axis] = MfSlice(start: 0, to: nil, by: -1)
            return mfarray[slices]
        }
        else{
            return Matft.flip(mfarray, axes: nil)
        }
    }
    /**
       Reverse the mfarray order along given axes
       - parameters:
            - mfarray: mfarray
            - axes: (optional) the reversed axis of list
    */
    public static func flip<T: MfTypable>(_ mfarray: MfArray<T>, axes: [Int]? = nil) -> MfArray<T>{
        let axes = axes ?? Array(stride(from: 0, to: mfarray.ndim, by: 1))
        
        var slices = Array<MfSlice>(repeating: MfSlice(start: 0, to: nil, by: 1), count: mfarray.ndim)
        for axis in axes{
            let axis = get_axis(axis, ndim: mfarray.ndim)
            slices[axis] = MfSlice(start: 0, to: nil, by: -1)
        }
        return mfarray[slices]
    }
    
    /**
       Clip the mfarray
       - parameters:
            - mfarray: mfarray
            - min: (optional) Minimum value. If nil is passed, handled as -inf
            - max: (optional) Maximum value. If nil is passed, handled as inf
    */
    public static func clip<T: MfTypable>(_ mfarray: MfArray<T>, min: T? = nil, max: T? = nil) -> MfArray<T>{
        switch mfarray.storedType {
        case .Float:
            let min = min == nil ? -Float.infinity : Float.from(min!)
            let max = max == nil ? Float.infinity : Float.from(max!)
            return clip_by_vDSP(mfarray, min, max, vDSP_vclipc)
        case .Double:
            let min = min == nil ? -Double.infinity : Double.from(min!)
            let max = max == nil ? Double.infinity : Double.from(max!)
            return clip_by_vDSP(mfarray, min, max, vDSP_vclipcD)
        }
    }
    
    /**
       Swap given axis1 and axis2
       - parameters:
            - mfarray: mfarray
            - axis1: Int
            - axis2: Int
    */
    public static func swapaxes<T: MfTypable>(_ mfarray: MfArray<T>, axis1: Int, axis2: Int) -> MfArray<T>{
        let axis1 = get_axis(axis1, ndim: mfarray.ndim)
        let axis2 = get_axis(axis2, ndim: mfarray.ndim)
        
        var axes = Array(stride(from: 0, to: mfarray.ndim, by: 1))
        //swap
        axes.swapAt(axis1, axis2)
        
        return mfarray.transpose(axes: axes)
    }
   
    /**
       move from given axis to dstination axis
       - parameters:
            - mfarray: mfarray
            - src: Int
            - dst: Int
    */
    public static func moveaxis<T: MfTypable>(_ mfarray: MfArray<T>, src: Int, dst: Int) -> MfArray<T>{
        let src = get_axis(src, ndim: mfarray.ndim)
        let dst = get_axis(dst, ndim: mfarray.ndim)
        
        var axes = Array(stride(from: 0, to: mfarray.ndim, by: 1))
        //move
        axes.remove(at: src)
        axes.insert(src, at: dst)
        
        return mfarray.transpose(axes: axes)
    }
    /**
       move from given axis to dstination axis
       - parameters:
            - mfarray: mfarray
            - src: [Int]
            - dst: [Int]
    */
    public static func moveaxis<T: MfTypable>(_ mfarray: MfArray<T>, src: [Int], dst: [Int]) -> MfArray<T>{
        precondition(src.count == dst.count, "must be same size")
        var sources: [Int] = [], dstinations: [Int] = []
        for (s, d) in zip(src, dst){
            sources += [get_axis(s, ndim: mfarray.ndim)]
            dstinations += [get_axis(d, ndim: mfarray.ndim)]
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
       Get sorted mfarray along given  axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - order: (Optional) ascending or descending. default is ascending
    */
    public static func sort<T: MfTypable>(_ mfarray: MfArray<T>, axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray<T>{
        
        let _axis: Int
        let _dst: MfArray<T>
        if axis != nil && mfarray.ndim > 1{// for given axis
            _axis = get_axis(axis!, ndim: mfarray.ndim)
            _dst = mfarray.deepcopy()
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
       Get sorted mfarray's indices along given  axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - order: (Optional) ascending or descending. default is ascending
    */
    public static func argsort<T: MfTypable>(_ mfarray: MfArray<T>, axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray<Int>{
        
        let _axis: Int
        let _dst: MfArray<T>
        if axis != nil && mfarray.ndim > 1{// for given axis
            _axis = get_axis(axis!, ndim: mfarray.ndim)
            _dst = mfarray.deepcopy()
        }
        else{// for all elements
            _axis = 0
            _dst = mfarray.flatten()
        }
        switch mfarray.storedType {
        case .Float:
            return sort_index_by_vDSP(_dst, _axis, order, vDSP_vsorti)
        case .Double:
            return sort_index_by_vDSP(_dst, _axis, order, vDSP_vsortiD)
        }
    }
}

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
