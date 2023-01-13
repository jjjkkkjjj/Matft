//
//  subscript.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension MfArray: MfSubscriptable{
    public subscript(indices: Int...) -> Any{
        get {
            var indices: [Any] = indices
            let ret = self._get_mfarray(indices: &indices)

            if let scalar = ret.scalar{
                return scalar
            }
            else{
                return ret
            }
        }
        set(newValue){
            var indices: [Any] = indices
            
            if let newValue = newValue as? MfArray{
                return self._set_mfarray(indices: &indices, newValue: newValue)
            }
            else{
                return self._set_mfarray(indices: &indices, newValue: MfArray([newValue]))
            }
        }
    }
    public subscript(indices: MfSlice...) -> MfArray{
        get{
            var indices: [Any] = indices
            return self._get_mfarray(indices: &indices)
        }
        set(newValue){
            var indices: [Any] = indices
            return self._set_mfarray(indices: &indices, newValue: newValue)
        }
    }
    
    public subscript(indices: MfArray) -> MfArray{
        get{
            return self._get_mfarray(indices: indices)
        }
        set(newValue){
            return self._set_mfarray(indices: indices, assignedMfarray: newValue)
        }
    }
    
    
    // for fancy indexing
    public subscript(indices: MfArray...) -> MfArray {
        get{
            var indices = indices
            return self._fancygetall_mfarray(indices: &indices)
        }
        set(newValue){
            var indices = indices
            self._fancysetall_mfarray(indices: &indices, assignedMfarray: newValue)
        }
    }
    
    //public subscript<T: MfSlicable>(indices: T...) -> MfArray{
    public subscript(indices: Any...) -> MfArray{
        get{
            var indices = indices
            return self._get_mfarray(indices: &indices)
        }
        set(newValue){
            var indices = indices
            self._set_mfarray(indices: &indices, newValue: newValue)
        }
    }
    
    //Use opaque?
    internal func _get_mfarray(indices: inout [Any]) -> MfArray{
        precondition(indices.count <= self.ndim, "cannot return value because given indices were too many")

        // supplement insufficient slices
        if indices.count < self.ndim{
            for _ in 0..<self.ndim - indices.count{
                indices.append(MfSlice())
            }
        }
        
        var orig_axis = 0
        let orig_shape = self.shape
        let orig_strides = self.strides
        
        var new_axis = 0
        var newshape: [Int] = []
        var newstrides: [Int] = []
        var newsize = 1
        
        var offset = self.offsetIndex
        //Indexing ref: https://docs.scipy.org/doc/numpy/reference/arrays.indexing.html
        var fancy_axes: [Int] = []
        var fancy_ops: [MfArray] = []
        while orig_axis < self.ndim {
            if let _index = indices[orig_axis] as? Int { // normal indexing
                let index = get_positive_index(_index, axissize: orig_shape[orig_axis], axis: orig_axis)

                offset += index * orig_strides[orig_axis]
                orig_axis += 1 // not move
                new_axis += 0
            }
            else if let mfslice = indices[orig_axis] as? MfSlice{// slicing
                let orig_dim = orig_shape[orig_axis]
                //default value is 0(if by >= 0), dim - 1(if by < 0)
                var startIndex = mfslice.start ?? (mfslice.by >= 0 ? 0 : orig_dim - 1)
                //default value is dim(if by >= 0), -dim - 1(if by < 0)
                var toIndex = mfslice.to ?? (mfslice.by >= 0 ? orig_dim : -orig_dim - 1)
                var by = mfslice.by
                /*
                align with proper value
                by > 0
                startIndex <= -orig_dim ==> 0
                startIndex > orig_dim ==> orig_dim
                orig_dim < toIndex ==> orig_dim
                toIndex <= -orig_dim ==> 0
                
                by < 0
                startIndex < -orig_dim ==> -orig_dim-1
                startIndex > orig_dim ==> orig_dim
                orig_dim < toIndex ==> orig_dim
                toIndex < -orig_dim ==> -orig_dim-1
                */
                if by >= 0{
                    if startIndex <= -orig_dim{
                        startIndex = 0
                    }
                    else if startIndex > orig_dim{
                        startIndex = orig_dim
                    }
                    if orig_dim < toIndex{
                        toIndex = orig_dim
                    }
                    else if toIndex < -orig_dim{
                        toIndex = 0
                    }
                }
                else{
                    if startIndex < -orig_dim{
                        startIndex = -orig_dim - 1
                    }
                    else if startIndex > orig_dim{
                        startIndex = orig_dim
                    }
                    if orig_dim < toIndex{
                        toIndex = orig_dim
                    }
                    else if toIndex < -orig_dim{
                        toIndex = -orig_dim - 1
                    }
                }
                 
                // convert negative index to proper positive index
                startIndex = startIndex >= 0 ? startIndex : orig_dim + startIndex
                toIndex = toIndex >= 0 ? toIndex : orig_dim + toIndex
                
                var nsteps = (toIndex - startIndex) / mfslice.by + (toIndex - startIndex) % mfslice.by
                if nsteps <= 0{
                    nsteps = 0
                    by = 1
                    startIndex = 0
                }
                 
                newshape.append(Swift.min(nsteps, orig_dim))
                newstrides.append(orig_strides[orig_axis] * by)
                newsize *= newshape.last!
                offset += startIndex * orig_strides[orig_axis]
                
                orig_axis += 1
                new_axis += 1
            }
            else if let subop = indices[orig_axis] as? SubscriptOps{// expand dim
                switch subop {
                case .newaxis:
                    newshape.append(1)
                    newstrides.append(0)
                    
                    orig_axis += 0 // not move
                    new_axis += 1
                    
                case .all:
                    let orig_dim = orig_shape[orig_axis]
                    
                    newshape.append(orig_dim)
                    newstrides.append(orig_strides[orig_axis] * 1)
                    
                    orig_axis += 1
                    new_axis += 1
                    
                case .reverse:
                    let orig_dim = orig_shape[orig_axis]
                    
                    newshape.append(orig_dim)
                    newstrides.append(orig_strides[orig_axis] * -1)
                    offset += (orig_dim - 1) * orig_strides[orig_axis]
                    
                    orig_axis += 1
                    new_axis += 1
                /*
                default:
                    fatalError("\(subop) is invalid in getter")*/
                }
            }
            else if let subop = indices[orig_axis] as? MfArray{// fancy indexing
                // get all values first, fancyget later
                let orig_dim = orig_shape[orig_axis]
                
                fancy_axes.append(new_axis)
                fancy_ops.append(subop)
                
                newshape.append(orig_dim)
                newstrides.append(orig_strides[orig_axis] * 1)
                
                orig_axis += 1
                new_axis += 1
            }
            else{
                preconditionFailure("\(indices[orig_axis]) is not subscriptable value")
            }
        }
        
        let newstructure = MfStructure(shape: newshape, strides: newstrides)
        //print(newarray.shape, newarray.mfdata._size, newarray.mfdata._storedSize)
        var ret = MfArray(base: self, mfstructure: newstructure, offset: offset)
        let fancy_dim = fancy_axes.count
        if fancy_dim == 0{// don't exist any fancy indexings
            return ret
        }
        
        /* Example
         a: shape = (2,2,2,2,2)
         a[Matft.all, MfArray([[0, 1, 0], [1, 0, 1]]), MfArray([[0, 1, 0], [1, 0, 1]]), Matft.all, MfArray([[0, 1, 0]])]
         fancy_shape = (3,3)
         backed_dim = 1: first 1 axes (0) to first fancy_indexing axis
         
         - first move
         abcde: axis. note b,c,e is fancy_axes
         [a,b,c,d,e] -> [b,c,e,a,d]
         - fancy indexing
         [b,c,e] -> [3,3]
         So,
         [3,3,a,d]
         - backed_dim(1) = a from fancy_dim(2) is backed
         [3,3,a,d] -> [a,3,3,d]
         */
        let backed_dim: Int, fancy_shape: [Int]
        if fancy_dim == 1 {// only 1 fancy indexing
            fancy_shape = fancy_ops[0].shape
            backed_dim = fancy_axes[0]
            
            ret = ret.moveaxis(src: fancy_axes[0], dst: 0)._get_mfarray(indices: fancy_ops[0])
        }
        else{
            // fancy_ops are MfArray array
            // These elements will be broadcasted
            fancy_shape = fancy_ops.reduce(fancy_ops[0]){ biop_broadcast_to($0, $1).r }.shape
            fancy_ops = fancy_ops.map{ $0.broadcast_to(shape: fancy_shape) }
            backed_dim = fancy_axes.min() ?? 0
            
            ret = ret.moveaxis(src: fancy_axes, dst: Array(0..<fancy_dim))._fancygetall_mfarray(indices: &fancy_ops)
        }
        
        if backed_dim == 0{// all of axes are fancy indexed
            return ret
        }
        
        // back to backed_dim
        ret = ret.moveaxis(src: Array(fancy_dim..<fancy_dim+backed_dim), dst: Array(0..<backed_dim))
            
        return ret
        
    }
    
    private func _set_mfarray(indices: inout [Any], newValue: MfArray){
        unsupport_complex(self)
        unsupport_complex(newValue)
        
        indices = indices.map{
            ind in
            if let ind = ind as? SubscriptOps{
                switch ind {
                case .newaxis:
                    fatalError("newaxis must not be passed to setter")
                    
                case .all:
                    return MfSlice(start: 0, to: nil, by: 1)
                    
                case .reverse:
                    return MfSlice(start: nil, to: nil, by: -1)
                }
            }
            return ind
        }
        
        
        //note that this function is alike _binary_operation
        let array = self._get_mfarray(indices: &indices)
        var newValue = newValue

        if array.mftype != newValue.mftype{
            newValue = newValue.astype(array.mftype)
        }
        //TODO: refactor
        if (array.size == newValue.size && array.size == 1){
            func _setscalar<T: MfStorable>(_ type: T.Type){
                array.withUnsafeMutableStartPointer(datatype: T.self){
                    dstptr in
                    newValue.withUnsafeMutableStartPointer(datatype: T.self){
                        dstptr.pointee = $0.pointee
                    }
                }
            }
            switch array.storedType {
            case .Float:
                _setscalar(Float.self)
            case .Double:
                _setscalar(Double.self)
            }
            return
        }
        if array.shape != newValue.shape{
            newValue = newValue.broadcast_to(shape: array.shape)
        }
        
        switch array.storedType {
        case .Float:
            _ = copy_mfarray(newValue, dsttmpMfarray: array, cblas_func: cblas_scopy)
        case .Double:
            _ = copy_mfarray(newValue, dsttmpMfarray: array, cblas_func: cblas_dcopy)
        }
    }
    
    
    private func _get_mfarray(indices: MfArray) -> MfArray{
        unsupport_complex(indices)
        
        switch indices.mftype {
        case .Bool:
            switch self.storedType {
            case .Float:
                return boolget_by_vDSP(self, indices, vDSP_vcmprs)
            case .Double:
                return boolget_by_vDSP(self, indices, vDSP_vcmprsD)
            }
            
        case .Float, .Double:
            preconditionFailure("indices must be bool or interger, but got \(indices.mftype)")
        case .Int:
            switch self.storedType {
            case .Float:
                return self.ndim == 1 ? fancy1dgetcol_by_vDSP(self, indices, vDSP_vgathr) : fancyndget_by_cblas(self, indices, cblas_scopy)
            case .Double:
                return self.ndim == 1 ? fancy1dgetcol_by_vDSP(self, indices, vDSP_vgathrD) : fancyndget_by_cblas(self, indices, cblas_dcopy)
            }

        default:
            preconditionFailure("fancy indexing must be Int only, but got \(indices.mftype)")
        }
        
        
    }
    
    
    private func _fancygetall_mfarray(indices: inout [MfArray]) -> MfArray{
        let _ = indices.map{ unsupport_complex($0) }
        
        switch self.storedType {
        case .Float:
            return fancygetall_by_cblas(self, &indices, cblas_scopy)
        case .Double:
            return fancygetall_by_cblas(self, &indices, cblas_dcopy)
        }
        
    }
    
    private func _fancysetall_mfarray(indices: inout [MfArray], assignedMfarray: MfArray) -> Void{
        unsupport_complex(self)
        unsupport_complex(assignedMfarray)
        
        switch self.storedType {
        case .Float:
            fancysetall_by_cblas(self, &indices, assignedMfarray, cblas_scopy)
        case .Double:
            fancysetall_by_cblas(self, &indices, assignedMfarray, cblas_dcopy)
        }
        
    }
    
    private func _set_mfarray(indices: MfArray, assignedMfarray: MfArray){
        
        switch indices.mftype {
        case .Bool:
            switch self.storedType {
            case .Float:
                _setter(self, indices, assignMfArray: assignedMfarray, type: Float.self)
            case .Double:
                _setter(self, indices, assignMfArray: assignedMfarray, type: Double.self)
            }
            
        case .Float, .Double:
            preconditionFailure("indices must be bool or interger, but got \(indices.mftype)")
        case .Int:
            switch self.storedType {
            case .Float:
                fancyset_by_cblas(self, indices, assignedMfarray, cblas_scopy)
            case .Double:
                fancyset_by_cblas(self, indices, assignedMfarray, cblas_dcopy)
            }
            
        default:
            preconditionFailure("fancy indexing must be Int only, but got \(indices.mftype)")
        }
    }
}


fileprivate func _setter<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, assignMfArray: MfArray, type: T.Type){
    let true_num = Float.toInt(indices.sum().scalar(Float.self)!)
    let orig_ind_dim = indices.ndim
    
    // broadcast
    let indices = bool_broadcast_to(indices, shape: mfarray.shape)
    
    // must be row major
    let indicesT: MfArray
    switch mfarray.storedType {
    case .Float:
        indicesT = check_contiguous(indices.astype(.Float), .Row)
    case .Double:
        indicesT = check_contiguous(indices.astype(.Double), .Row)
    }
    
    // calculate assignMfarray's size
    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    let assignShape = [true_num] + lastShape
    //let assignSize = shape2size(&assignShape)
    
    let assignMfArray = assignMfArray.broadcast_to(shape: assignShape).flatten(.Row).astype(mfarray.mftype)
    
    var srcoffset = 0
    var indoffset = 0
    
    indicesT.withUnsafeMutableStartPointer(datatype: T.self){
        indptr in
        let indptr = indptr
        assignMfArray.withUnsafeMutableStartPointer(datatype: T.self){
            assptr in
            let srcptr = assptr
            mfarray.withContiguousDataUnsafeMPtrT(datatype: T.self){
                if (indptr + indoffset).pointee != T.zero{
                    $0.assign(from: srcptr + srcoffset, count: 1)
                    srcoffset += 1
                    //print(srcptr.pointee)
                }
                indoffset += 1
            }
        }
    }
    
}

fileprivate func _inner_product(_ left: UnsafeMutableBufferPointer<Int>, _ right: UnsafeMutableBufferPointer<Int>) -> Int{
    
    assert(left.count == right.count, "cannot calculate inner product due to unsame dim")
    
    return zip(left, right).map(*).reduce(0, +)
}
