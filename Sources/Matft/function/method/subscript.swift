//
//  subscript.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

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
        // newaxis doesn't consume an axis
        let consumed = indices.filter{ ($0 as? SubscriptOps) != .newaxis }.count
        precondition(consumed <= self.ndim, "cannot return value because given indices were too many")

        // supplement insufficient slices
        if consumed < self.ndim{
            for _ in 0..<self.ndim - consumed{
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
        for index in indices {
            if let _index = index as? Int { // normal indexing
                let index = get_positive_index(_index, axissize: orig_shape[orig_axis], axis: orig_axis)

                offset += index * orig_strides[orig_axis]
                orig_axis += 1 // not move
                new_axis += 0
            }
            else if let mfslice = index as? MfSlice{// slicing
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
                
                // ceil((toIndex - startIndex) / by). It's non-positive when the signs of the range and by differ
                let distance = toIndex - startIndex
                var nsteps = (distance + by - (by > 0 ? 1 : -1)) / by
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
            else if let subop = index as? SubscriptOps{// expand dim
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
            else if let subop = index as? MfArray{// fancy indexing
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
                preconditionFailure("\(index) is not subscriptable value")
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
        
        self._to_complex_if_needed(newValue)
        
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
                if array.isComplex{
                    array.withUnsafeMutableStartImagPointer(datatype: T.self){
                        dstptr in
                        newValue.withUnsafeMutableStartImagPointer(datatype: T.self){
                            // imaginary part of the real newValue is regarded as zero
                            dstptr!.pointee = $0?.pointee ?? T.zero
                        }
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
        
        // imaginary part of the real newValue is regarded as zero
        let newValueImag = newValue.imag ?? MfArray([0]).astype(array.mftype).broadcast_to(shape: array.shape)
        switch array.storedType {
        case .Float:
            _ = copy_mfarray(newValue, dsttmpMfarray: array, cblas_func: cblas_scopy)
            if array.isComplex{
                _ = copy_mfarray(newValueImag, dsttmpMfarray: array.imag!, cblas_func: cblas_scopy)
            }
        case .Double:
            _ = copy_mfarray(newValue, dsttmpMfarray: array, cblas_func: cblas_dcopy)
            if array.isComplex{
                _ = copy_mfarray(newValueImag, dsttmpMfarray: array.imag!, cblas_func: cblas_dcopy)
            }
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
        let _ = indices.map{ unsupport_complex($0) }
        
        self._set_realimag(assignedMfarray: assignedMfarray){
            (dst, src) in
            switch dst.storedType {
            case .Float:
                fancysetall_by_cblas(dst, &indices, src, cblas_scopy)
            case .Double:
                fancysetall_by_cblas(dst, &indices, src, cblas_dcopy)
            }
        }
    }
    
    private func _set_mfarray(indices: MfArray, assignedMfarray: MfArray){
        unsupport_complex(indices)
        
        switch indices.mftype {
        case .Bool:
            self._set_realimag(assignedMfarray: assignedMfarray){
                (dst, src) in
                switch dst.storedType {
                case .Float:
                    _setter(dst, indices, assignMfArray: src, type: Float.self)
                case .Double:
                    _setter(dst, indices, assignMfArray: src, type: Double.self)
                }
            }
            
        case .Float, .Double:
            preconditionFailure("indices must be bool or interger, but got \(indices.mftype)")
        case .Int:
            self._set_realimag(assignedMfarray: assignedMfarray){
                (dst, src) in
                switch dst.storedType {
                case .Float:
                    fancyset_by_cblas(dst, indices, src, cblas_scopy)
                case .Double:
                    fancyset_by_cblas(dst, indices, src, cblas_dcopy)
                }
            }
            
        default:
            preconditionFailure("fancy indexing must be Int only, but got \(indices.mftype)")
        }
    }
    
    /// Convert self into complex in-place if the assigned mfarray is complex
    /// - Parameters:
    ///   - assignedMfarray: The assigned mfarray
    private func _to_complex_if_needed(_ assignedMfarray: MfArray){
        if assignedMfarray.isComplex && self.isReal{
            // Note: in-place operation
            let _ = self.to_complex(true)
            assert(self.isComplex, "Not converted complex!")
        }
    }
    
    /// Apply a real setter to the real and imaginary parts respectively
    /// - Parameters:
    ///   - assignedMfarray: The assigned mfarray
    ///   - setter: The real setter. Arguments are (destination mfarray, source mfarray)
    private func _set_realimag(assignedMfarray: MfArray, _ setter: (MfArray, MfArray) -> Void){
        self._to_complex_if_needed(assignedMfarray)
        
        if self.isReal{
            setter(self, assignedMfarray)
        }
        else{
            setter(self.real, assignedMfarray.real)
            // imaginary part of the real assigned mfarray is regarded as zero
            setter(self.imag!, assignedMfarray.imag ?? MfArray([0]))
        }
    }
}


fileprivate func _setter<T: MfStorable>(_ mfarray: MfArray, _ indices: MfArray, assignMfArray: MfArray, type: T.Type){
    let true_num = Float.toInt(indices.sum().scalar(Float.self)!)
    let orig_ind_dim = indices.ndim
    
    // row contiguous mask of mfarray's shape. It's only read, so the Float mask can be used as it is
    let indices = bool_broadcast_to(indices, shape: mfarray.shape)
    let maskT: MfArray
    switch mfarray.storedType {
    case .Float:
        maskT = indices
    case .Double:
        maskT = indices.astype(.Double)
    }
    
    // the assigned values in row major order, in mfarray's stored type
    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    let assignShape = [true_num] + lastShape
    let isScalar = assignMfArray.size == 1
    var values = isScalar ? assignMfArray : assignMfArray.broadcast_to(shape: assignShape)
    if values.storedType != mfarray.storedType{
        values = values.astype(mfarray.mftype)
    }
    values = check_contiguous(values, .Row)
    
    let size = mfarray.size
    guard size > 0 else { return }
    maskT.withUnsafeMutableStartPointer(datatype: T.self){
        maskptr in
        values.withUnsafeMutableStartPointer(datatype: T.self){
            valptr in
            let scalar = valptr.pointee
            var k = 0
            mfarray.withUnsafeMutableStartPointer(datatype: T.self){
                dstptr in
                if mfarray.mfstructure.row_contiguous{
                    if isScalar{
                        for i in 0..<size where maskptr[i] != T.zero{
                            dstptr[i] = scalar
                        }
                    }
                    else{
                        for i in 0..<size where maskptr[i] != T.zero{
                            dstptr[i] = valptr[k]
                            k += 1
                        }
                    }
                    return
                }
                
                // row major order over a strided layout: the last axis is the inner loop
                let lastDim = mfarray.shape[mfarray.ndim - 1]
                let lastStride = mfarray.strides[mfarray.ndim - 1]
                var outerShape = Array(mfarray.shape.dropLast())
                var outerStrides = Array(mfarray.strides.dropLast())
                var i = 0
                func assignRow(_ rowptr: UnsafeMutablePointer<T>){
                    for j in 0..<lastDim{
                        if maskptr[i] != T.zero{
                            rowptr[j * lastStride] = isScalar ? scalar : valptr[k]
                            k += 1
                        }
                        i += 1
                    }
                }
                if outerShape.isEmpty{
                    assignRow(dstptr)
                }
                else{
                    for ind in FlattenIndSequence(shape: &outerShape, strides: &outerStrides){
                        assignRow(dstptr + ind.flattenIndex)
                    }
                }
            }
        }
    }
}

fileprivate func _inner_product(_ left: UnsafeMutableBufferPointer<Int>, _ right: UnsafeMutableBufferPointer<Int>) -> Int{
    
    assert(left.count == right.count, "cannot calculate inner product due to unsame dim")
    
    return zip(left, right).map(*).reduce(0, +)
}
