//
//  subscript.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation
import Accelerate

extension MfArray: MfSubscriptable{
    
    public subscript(indices: Int...) -> MfArray<MfArrayType>{
        get {
            var indices: [Any] = indices
            let ret = self._get_mfarray(indices: &indices)

            return ret
        }
        set(new_array){
            var indices: [Any] = indices
                        
            return self._set_mfarray(indices: &indices, new_array: new_array)
        }
    }
    public subscript(indices: MfSlice...) -> MfArray<MfArrayType>{
        get{
            var indices: [Any] = indices
            return self._get_mfarray(indices: &indices)
        }
        set(new_array){
            var indices: [Any] = indices
            return self._set_mfarray(indices: &indices, new_array: new_array)
        }
    }
    /*
    public subscript(indices: MfArray<Bool>) -> MfArray<MfArrayType>{
        get{
            return self._get_mfarray(indices: indices)
        }
        set(new_array){
            self._set_mfarray(indices: indices, assignedMfarray: new_array)
        }
    }*/
    
    //public subscript<T: MfSlicable>(indices: T...) -> MfArray{
    public subscript(indices: Any...) -> MfArray<MfArrayType>{
        get{
            var indices = indices
            return self._get_mfarray(indices: &indices)
        }
        set(new_array){
            var indices = indices
            self._set_mfarray(indices: &indices, new_array: new_array)
        }
    }
    
    
    
    /// Getter function for the normal indexing on a given indices.
    /// - Parameter indices: An input indices array
    /// - Returns: The VIEW mfarray
    internal func _get_mfarray(indices: inout [Any]) -> MfArray{
        precondition(indices.count <= self.ndim, "cannot return value because given indices were too many")

        // supplement insufficient slices
        if indices.count < self.ndim{
            for _ in 0..<self.ndim - indices.count{
                indices.append(MfSlice())
            }
        }
        
        var orig_axis = 0
        var new_axis = 0
        var new_shape: [Int] = []
        var new_strides: [Int] = []
        var new_size = 1
        
        var offset = self.offsetIndex
        let (orig_shape, orig_strides) = (self.shape, self.strides)

        //Indexing ref: https://docs.scipy.org/doc/numpy/reference/arrays.indexing.html
        while orig_axis < self.ndim {
            if let _index = indices[orig_axis] as? Int { // normal indexing
                let index = get_positive_index(_index, dim: orig_shape[orig_axis], axis: orig_axis)

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
                 
                new_shape.append(Swift.min(nsteps, orig_dim))
                new_strides.append(orig_strides[orig_axis] * by)
                new_size *= new_shape.last!
                offset += startIndex * orig_strides[orig_axis]
                
                orig_axis += 1
                new_axis += 1
            }
            else if let subop = indices[orig_axis] as? SubscriptOps{// expand dim
                switch subop {
                case .newaxis:
                    new_shape.append(1)
                    new_strides.append(0)
                /*
                default:
                    fatalError("\(subop) is invalid in getter")*/
                }
                
                orig_axis += 0 // not move
                new_axis += 1
            }
            else{
                preconditionFailure("\(indices[orig_axis]) is not subscriptable value")
            }
        }
        

        let newstructure = MfStructure(shape: new_shape, strides: new_strides)
        
        //newarray.mfdata._storedSize = get_storedSize(newarray.shapeptr, newarray.stridesptr)
        //print(newarray.shape, newarray.mfdata._size, newarray.mfdata._storedSize)
        return MfArray(base: self, mfstructure: newstructure, offset: offset)
    }
    
    private func _set_mfarray(indices: inout [Any], new_array: MfArray){
        for index in indices{
            if let _ = index as? SubscriptOps{
                fatalError("SubscriptOps must not be passed to setter")
            }
        }
        
        //note that this function is alike _binary_operation
        let dst_array = self._get_mfarray(indices: &indices)
        var new_array = new_array
        
        //TODO: refactor
        // 1 value assignment
        if (dst_array.size == new_array.size && dst_array.size == 1){
            
            dst_array.withUnsafeMutableStartPointer{
                dstptr in
                new_array.withUnsafeMutableStartPointer{
                    srcptr in
                    dstptr.pointee = srcptr.pointee
                }
            }
            
            return
        }
        if dst_array.shape != new_array.shape{
            new_array = new_array.broadcast_to(shape: dst_array.shape)
        }
        
        _ = copy_by_cblas(new_array, dst_array, cblas_func: MfArrayStoredType.cblas_copy_func)
    }
    
    // fancy indexing
    // note that if not assignment, returned copy value not view.
    /*
     >>> a = np.arange(9).reshape(3,3)
     >>> a
     array([[0, 1, 2],
            [3, 4, 5],
            [6, 7, 8]])
     >>> a[[1,2],[2,2]].base
     None
     */
    // boolean indexing
    // note that if not assignment, returned copy value not view.
    /*
     a = np.arange(5)
     >>> a[a==1]
     array([1])
     >>> a[a==1].base
     None
     */
    /*
    private func _get_mfarray(indices: MfArray<Bool>) -> MfArray<MfArrayType>{
        
        switch self.storedType {
        case .Float:
            return boolget_by_vDSP(self, indices, vDSP_vcmprs)
        case .Double:
            return boolget_by_vDSP(self, indices, vDSP_vcmprsD)
        }
    }
    
    private func _set_mfarray(indices: MfArray<Bool>, assignedMfarray: MfArray<MfArrayType>){
        switch self.storedType {
        case .Float:
            _setter(self, indices, assignMfArray: assignedMfarray, type: Float.self)
        case .Double:
            _setter(self, indices, assignMfArray: assignedMfarray, type: Double.self)
        }
    }*/
}
/*
fileprivate func _setter<T: MfTypable, U: MfStorable>(_ mfarray: MfArray<T>, _ indices: MfArray<Bool>, assignMfArray: MfArray<T>, type: U.Type){
    let true_num = Float.toInt(indices.sum().scalar!)
    let orig_ind_dim = indices.ndim
    
    // broadcast
    let indices = bool_broadcast_to(indices, shape: mfarray.shape)
    
    // must be row major
    let indicesU: MfArray<U> = check_contiguous(indices.astype(U.self), .Row)
    
    // calculate assignMfarray's size
    let lastShape = Array(mfarray.shape.suffix(mfarray.ndim - orig_ind_dim))
    let assignShape = [true_num] + lastShape
    //let assignSize = shape2size(&assignShape)
    
    let assignMfArray = assignMfArray.broadcast_to(shape: assignShape).flatten(.Row).astype(T.self)
    
    var srcoffset = 0
    var indoffset = 0
    
    indicesU.withDataUnsafeMBPtrT(datatype: U.self){
        indptr in
        let indptr = indptr.baseAddress!
        assignMfArray.withDataUnsafeMBPtrT(datatype: U.self){
            assptr in
            let srcptr = assptr.baseAddress!
            mfarray.withContiguousDataUnsafeMPtrT(datatype: U.self){
                if (indptr + indoffset).pointee != U.zero{
                    $0.assign(from: srcptr + srcoffset, count: 1)
                    srcoffset += 1
                    //print(srcptr.pointee)
                }
                indoffset += 1
            }
        }
    }
    
}*/

fileprivate func _inner_product(_ left: UnsafeMutableBufferPointer<Int>, _ right: UnsafeMutableBufferPointer<Int>) -> Int{
    
    assert(left.count == right.count, "cannot calculate inner product due to unsame dim")
    
    return zip(left, right).map(*).reduce(0, +)
}

