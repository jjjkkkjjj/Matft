//
//  conversion.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate
import Collections

extension Matft{
    /**
       Create another typed mfarray. Created mfarray will be different object from original one
       - parameters:
            - mfarray: mfarray
            - mftype: the type of mfarray
            - mforder: The order
            - complex: Whether to be complex or not.
    */
    public static func astype(_ mfarray: MfArray, mftype: MfType, mforder: MfOrder = .Row, complex: Bool = false) -> MfArray{
        //let newarray = Matft.shallowcopy(mfarray)
        //newarray.mfdata._mftype = mftype
        if mftype == .Bool{
            return to_Bool(mfarray).to_contiguous(mforder: mforder)
        }
        
        let mfarray = complex && mfarray.isReal ? mfarray.to_complex(false) : mfarray
        
        let newStoredType = MfType.storedType(mftype)
        if mfarray.storedType == newStoredType{
            let ret = mfarray.to_contiguous(mforder: mforder)
            ret.mfdata.mftype = mftype
            return ret
        }
        
        if mfarray.isReal{
            switch newStoredType{
            case .Float://double to float
                return contiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, vDSP_func: vDSP_vdpsp)
                
            case .Double://float to double
                return contiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, vDSP_func: vDSP_vspdp)
            }
        }
        else{
            switch newStoredType{
            case .Float://double to float
                return zcontiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, src_type: DSPDoubleSplitComplex.self, dst_type: DSPSplitComplex.self, vDSP_func: vDSP_vdpsp)
                
            case .Double://float to double
                return zcontiguous_and_astype_by_vDSP(mfarray, mftype: mftype, mforder: mforder, src_type: DSPSplitComplex.self, dst_type: DSPDoubleSplitComplex.self, vDSP_func: vDSP_vspdp)
            }
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
        let origShape = mfarray.shape
        let origStrides = mfarray.strides
        var new_shape = mfarray.shape
        var new_strides = mfarray.strides

        for i in 0..<ndim{
            new_shape[i] = origShape[permutation[i]]
            new_strides[i] = origStrides[permutation[i]]
        }
        let newstructure = MfStructure(shape: new_shape, strides: new_strides)

        return MfArray(base: mfarray, mfstructure: newstructure, offset: mfarray.offsetIndex)
    }
    /**
       Convert new shaped mfarray
       - parameters:
            - mfarray: mfarray
            - shape: the new shape
            - order: (Optional) order, default is nil, which means close to either row or column major if possibe.
       - Important: this function will create copy not view
    */
    public static func reshape(_ mfarray: MfArray, newshape: [Int], order: MfOrder? = nil) -> MfArray{
        var newshape = get_positive_shape(newshape, mfarray.size)
        precondition(mfarray.size == shape2size(&newshape), "new shape's size:\(shape2size(&newshape)) must be same as mfarray's size:\(mfarray.size)")
        
        let order = order ?? .Row
        let mfarray = mfarray.flatten(order)
        
        return MfArray(mfarray.data, mftype: mfarray.mftype, shape: newshape, mforder: order)
        
        /* i wanna implement no copy version
        let new_ndim = newshape.count
        let newarray = Matft.shallowcopy(mfarray)
        
        let newstructure = withDummyShapeStridesMBPtr(new_ndim){
            shapeptr, stridesptr in
            //move from newshape
            shapeptr.baseAddress!.moveUpdate(from: &newshape, count: new_ndim)
            
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
    public static func expand_dims(_ mfarray: MfArray, axis: Int) -> MfArray{
        let newarray = mfarray.shallowcopy()
        
        var newshape = mfarray.shape
        let axis = get_positive_axis_for_expand_dims(axis, ndim: mfarray.ndim)
        
        newshape.insert(1, at: axis)
        var newstrides = mfarray.strides
        newstrides.insert(0, at: axis)
        
        newarray.mfstructure = MfStructure(shape: newshape, strides: newstrides)
        
        return newarray
    }
    /**
       Create mfarray expanded dimension for given axis
       - parameters:
            - mfarray: mfarray
            - axes: the list of expanded axes
    */
    public static func expand_dims(_ mfarray: MfArray, axes: [Int]) -> MfArray{
        let newarray = mfarray.shallowcopy()
        // reorder descending
        let axes = axes.sorted{ $0 < $1 }
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        for axis in axes{
            let axis = get_positive_axis_for_expand_dims(axis, ndim: newshape.count)
            
            newshape.insert(1, at: axis)
            newstrides.insert(0, at: axis)
        }
        
        newarray.mfstructure = MfStructure(shape: newshape, strides: newstrides)
        
        return newarray
    }
    /**
       Create mfarray removed for 1-dimension
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) the removed axis
    */
    public static func squeeze(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        
        if let axis = axis{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
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
        newarray.mfstructure = MfStructure(shape: newshape, strides: newstrides)
        return newarray
        /*
        if mfarray.mfstructure.column_contiguous{
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
    public static func squeeze(_ mfarray: MfArray, axes: [Int]) -> MfArray{
        // reoder descending
        let axes = axes.sorted{ $0 > $1 }
        var newshape = mfarray.shape
        var newstrides = mfarray.strides
        for axis in axes{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
            precondition(newshape.remove(at: axis) == 1, "cannot select an axis to squeeze out which has size not equal to one")
            newstrides.remove(at: axis)
        }
        
        
        let newarray = mfarray.shallowcopy()
        newarray.mfstructure = MfStructure(shape: newshape, strides: newstrides)
        return newarray
    }
    
    /**
       Create broadcasted mfarray.
       - parameters:
            - mfarray: mfarray
            - shape: shape
    */
    public static func broadcast_to(_ mfarray: MfArray, shape: [Int]) -> MfArray{
        var new_shape = shape
        var new_strides = Array(repeating: 0, count: new_shape.count)
        //let newarray = Matft.shallowcopy(mfarray)
        let new_ndim = shape2ndim(&new_shape)
        
        let idim_start = new_ndim  - mfarray.ndim
        
        precondition(idim_start >= 0, "can't broadcast to fewer dimensions")
        
        let orig_strides = mfarray.strides
        let orig_shape = mfarray.shape
        
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

    /**
       Convert order of stored data.
       - parameters:
            - mfarray: mfarray
            - mforder: mforder
    */
    public static func to_contiguous(_ mfarray: MfArray, mforder: MfOrder) -> MfArray{
        if mfarray.isReal{
            switch mfarray.storedType{
            case .Float:
                return contiguous_by_cblas(mfarray, cblas_func: cblas_scopy, mforder: mforder)
            case .Double:
                return contiguous_by_cblas(mfarray, cblas_func: cblas_dcopy, mforder: mforder)
            }
        }
        else{
            switch mfarray.storedType{
            case .Float:
                return zcontiguous_by_vDSP(mfarray, vDSP_zvmov, mforder: mforder)
            case .Double:
                return zcontiguous_by_vDSP(mfarray, vDSP_zvmovD, mforder: mforder)
            }
        }
    }
    /**
       Flatten 1d-mfarray
       - parameters:
            - mfarray: mfarray
            - mforder: (Optional) mforder, default is Row
    */
    public static func flatten(_ mfarray: MfArray, mforder: MfOrder = .Row) -> MfArray{
        let ret = Matft.to_contiguous(mfarray, mforder: mforder)
        
        ret.mfstructure = MfStructure(shape: [ret.size], strides: [1])
        
        return ret
    }
    
    /**
       Reverse the mfarray order along given axis
       - parameters:
            - mfarray: mfarray
            - axis: (optional) the reversed axis
    */
    public static func flip(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        if let axis = axis{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
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
    public static func flip(_ mfarray: MfArray, axes: [Int]? = nil) -> MfArray{
        let axes = axes ?? Array(stride(from: 0, to: mfarray.ndim, by: 1))
        
        var slices = Array<MfSlice>(repeating: MfSlice(start: 0, to: nil, by: 1), count: mfarray.ndim)
        for axis in axes{
            let axis = get_positive_axis(axis, ndim: mfarray.ndim)
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
    public static func clip<T: MfTypable>(_ mfarray: MfArray, min: T? = nil, max: T? = nil) -> MfArray{
        func _clip<U: MfStorable>(_ vDSP_func: vDSP_clip_func<U>) -> MfArray{
            let min = min == nil ? -U.infinity : U.from(min!)
            let max = max == nil ? U.infinity : U.from(max!)
            return clip_by_vDSP(mfarray, min, max, vDSP_func)
        }
        
        switch mfarray.storedType {
        case .Float:
           return  _clip(vDSP_vclipc)
        case .Double:
            return _clip(vDSP_vclipcD)
        }
    }
    
    /**
       Swap given axis1 and axis2
       - parameters:
            - mfarray: mfarray
            - axis1: Int
            - axis2: Int
    */
    public static func swapaxes(_ mfarray: MfArray, axis1: Int, axis2: Int) -> MfArray{
        let axis1 = get_positive_axis(axis1, ndim: mfarray.ndim)
        let axis2 = get_positive_axis(axis2, ndim: mfarray.ndim)
        
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
    public static func moveaxis(_ mfarray: MfArray, src: Int, dst: Int) -> MfArray{
        let src = get_positive_axis(src, ndim: mfarray.ndim)
        let dst = get_positive_axis(dst, ndim: mfarray.ndim)
        
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
    public static func moveaxis(_ mfarray: MfArray, src: [Int], dst: [Int]) -> MfArray{
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
    
    /**
       Get sorted mfarray along given  axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
            - order: (Optional) ascending or descending. default is ascending
    */
    public static func sort(_ mfarray: MfArray, axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        unsupport_complex(mfarray)
        
        let _axis: Int
        let _dst: MfArray
        if axis != nil && mfarray.ndim > 1{// for given axis
            _axis = get_positive_axis(axis!, ndim: mfarray.ndim)
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
    public static func argsort(_ mfarray: MfArray, axis: Int? = -1, order: MfSortOrder = .Ascending) -> MfArray{
        unsupport_complex(mfarray)
        
        let _axis: Int
        let _dst: MfArray
        if axis != nil && mfarray.ndim > 1{// for given axis
            _axis = get_positive_axis(axis!, ndim: mfarray.ndim)
            _dst = mfarray.deepcopy()
        }
        else{// for all elements
            _axis = 0
            _dst = mfarray.flatten()
        }
        switch mfarray.storedType {
        case .Float:
            return argsort_by_vDSP(_dst, _axis, order, vDSP_vsorti)
        case .Double:
            return argsort_by_vDSP(_dst, _axis, order, vDSP_vsortiD)
        }
    }
    
    /**
       Roll array elements along a given axis.
       - parameters:
            - mfarray: mfarray
            - shift: The number of places by which elements are shifted.
            - axis: (Optional) axis, if not given, get summation for all elements
    */
    public static func roll(_ mfarray: MfArray, shift: Int, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        switch mfarray.storedType{
        case .Float:
            return shift_by_cblas(mfarray, shift: shift, axis: axis, cblas_scopy)
        case .Double:
            return shift_by_cblas(mfarray, shift: shift, axis: axis, cblas_dcopy)
        }
    }
    
    /**
       Get ordered unique mfarray  along given axis
       - parameters:
            - mfarray: mfarray
            - axis: (Optional) axis, if not given, get summation for all elements
    */
    public static func orderedUnique(_ mfarray: MfArray, axis: Int? = nil) -> MfArray{
        unsupport_complex(mfarray)
        
        // get stride to calculate unique array
        let stride: Int
        var srcmfarray: MfArray
        var restShape: [Int]
        if let axis = axis{
            srcmfarray = mfarray.moveaxis(src: axis, dst: 0)
            if srcmfarray.ndim == 1{
                stride = 1
                restShape = []
            }
            else{
                restShape = Array(srcmfarray.shape[1..<srcmfarray.ndim])
                stride = shape2size(&restShape)
            }
            srcmfarray = srcmfarray.flatten()
        }
        else{
            srcmfarray = mfarray
            stride = 1
            restShape = []
        }
        
        
        switch mfarray.storedType {
        case .Float:
            var flattendata: [Float]
            
            flattendata = srcmfarray.storedData as! [Float]
            return _unique(&flattendata, restShape: &restShape, mftype: mfarray.mftype, stride: stride, axis: axis)

            
        case .Double:
            var flattendata: [Double]
            flattendata = srcmfarray.storedData as! [Double]
            return _unique(&flattendata, restShape: &restShape, mftype: mfarray.mftype, stride: stride, axis: axis)
        }
    }
}

fileprivate func _unique<T: MfStorable>(_ flattendata: inout [T], restShape: inout [Int], mftype: MfType, stride: Int, axis: Int?) -> MfArray{
    
    var uniquearray: [T]
    if stride == 1{// flatten array
        uniquearray = Array(OrderedSet(flattendata))
    }
    else{
        assert(axis != nil)
        
        var axisarray: [[T]] = []
        for i in 0..<(flattendata.count/stride){
            axisarray += [Array(flattendata[i*stride..<(i+1)*stride])]
        }

        uniquearray = OrderedSet(axisarray).flatMap{ $0 }
    }
    
    let newsize = uniquearray.count
    let newdata = MfData(size: newsize, mftype: mftype)

    newdata.withUnsafeMutableStartPointer(datatype: T.self){
        dstptrT in
        uniquearray.withUnsafeMutableBufferPointer{
            dstptrT.moveUpdate(from: $0.baseAddress!, count: newsize)
        }
    }
    
    restShape.insert(newsize / stride, at: 0)
    let newstructure = MfStructure(shape: restShape, mforder: .Row)
    
    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    
    if let axis = axis{
        return ret.moveaxis(src: axis, dst: 0)
    }
    else{
        return ret
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
        shapeptr.update(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.update(from: mfdata._strides, count: mfdata._ndim)
        
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
