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
    /// Access an element or a sub-array by integer indices.
    ///
    /// Like `a[1, 2]` in Numpy. Missing trailing indices select the whole axis, and negative indices count from the end.
    ///
    /// ```swift
    /// let a = MfArray([[1, 2, 3], [4, 5, 6]])
    /// let v = a[1, 2] as! Int      // a scalar when all axes are indexed
    /// let row = a[0] as! MfArray   // otherwise a view of the sub-array
    /// a[0, 0] = 10
    /// ```
    /// - Parameters:
    ///   - indices: One integer per axis (at most `ndim`).
    /// - Returns: A Swift scalar (boxed in `Any`) when the result has a single element, otherwise an `MfArray` view that shares memory with the original array.
    ///   When setting, a scalar or an `MfArray` broadcastable to the selected region can be assigned.
    ///   Like numpy, the assigned value may have extra leading dimensions of size 1, and a complex value assigned into a real array
    ///   is cast to its real part (the array stays real). The same applies to the other subscripts.
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
    /// Access a sub-array by slices.
    ///
    /// Like `a[1:, ::2]` in Numpy. Slices are usually written with the `~<` operator (e.g. `a[1~<, 0~<3]`) or with `MfSlice(start:to:by:)`.
    /// Missing trailing slices select the whole axis.
    /// - Parameters:
    ///   - indices: One slice per axis (at most `ndim`).
    /// - Returns: A view that shares memory with the original array. When setting, the assigned `MfArray` is broadcast to the selected region.
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
    
    /// Access elements by a boolean mask or by integer (fancy) indices.
    ///
    /// Like `a[mask]` or `a[[0, 2]]` in Numpy.
    /// - A `.Bool` array selects the elements where the mask is `true`.
    /// - An `.Int` array selects entries along the first axis.
    ///
    /// Float and complex index arrays are not allowed.
    /// - Parameters:
    ///   - indices: A `.Bool` mask or an `.Int` index array.
    /// - Returns: A new array (a copy) of the selected elements. When setting, the assigned values are written to the selected positions of this array.
    public subscript(indices: MfArray) -> MfArray{
        get{
            return self._get_mfarray(indices: indices)
        }
        set(newValue){
            return self._set_mfarray(indices: indices, assignedMfarray: newValue)
        }
    }
    
    
    // for fancy indexing
    /// Access elements by integer (fancy) index arrays, one per axis.
    ///
    /// Like `a[[0, 1], [2, 0]]` in Numpy: the index arrays are broadcast together and each combination selects one element.
    /// - Parameters:
    ///   - indices: `.Int` index arrays for the leading axes. Complex index arrays are not allowed.
    /// - Returns: A new array (a copy) of the selected elements. When setting, the assigned values are written to the selected positions of this array.
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
    /// Access a sub-array by a mix of integers, slices, `.Int` index arrays and special indices.
    ///
    /// Each element of `indices` may be an `Int`, an `MfSlice` (e.g. `1~<`), an `MfArray` of `.Int` indices,
    /// or one of `Matft.all`, `Matft.reverse` and `Matft.newaxis` (the last one is not allowed when setting).
    /// Missing trailing indices select the whole axis.
    ///
    /// ```swift
    /// let a = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4])
    /// let b = a[0, 1~<, Matft.reverse]
    /// let c = a[Matft.newaxis, Matft.all, 0]
    /// ```
    /// - Parameters:
    ///   - indices: The indices, at most one per axis (plus any `Matft.newaxis`).
    /// - Returns: A view that shares memory with the original array, or a copy if an index array is included.
    ///   When setting, the assigned `MfArray` is broadcast to the selected region.
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
        // positions in `indices` of the integers and index arrays (numpy's advanced indices)
        var advanced_positions: [Int] = []
        for (position, index) in indices.enumerated() {
            if let _index = index as? Int { // normal indexing
                advanced_positions.append(position)
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
                startIndex >= orig_dim ==> orig_dim-1
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
                    else if startIndex >= orig_dim{
                        // like Python, the first element of a negative step is the last one at most
                        startIndex = orig_dim - 1
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
                
                advanced_positions.append(position)
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
        
        // like numpy, the index dimensions stay in place only when the advanced indices (integers and index arrays) are next to each other,
        // otherwise they come first
        let adjacent = zip(advanced_positions, advanced_positions.dropFirst()).allSatisfy{ $1 == $0 + 1 }
        if backed_dim == 0 || !adjacent{
            return ret
        }
        
        // back to backed_dim. The index dimensions are the broadcast shape of the index arrays
        let fancy_ndim = fancy_shape.count
        ret = ret.moveaxis(src: Array(fancy_ndim..<fancy_ndim+backed_dim), dst: Array(0..<backed_dim))
            
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
        
        if indices.contains(where: { $0 is MfArray }){
            return self._fancymixedset_mfarray(indices: indices, newValue: newValue)
        }
        
        //note that this function is alike _binary_operation
        let array = self._get_mfarray(indices: &indices)
        var newValue = self._unaliased(self._castable_value(newValue))

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
            newValue = setter_broadcast_to(newValue, shape: array.shape)
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
    
    /// Setter for index arrays mixed with integers and slices, e.g. `a[1~<, MfArray([2, 0])] = v`.
    /// The index arrays are applied to the view selected by the other indices
    /// - Parameters:
    ///   - indices: The indices including at least one `.Int` index array. `newaxis` must not be included
    ///   - newValue: The assigned mfarray. It is broadcast to the shape of the selection like numpy
    private func _fancymixedset_mfarray(indices: [Any], newValue: MfArray){
        var viewIndices: [Any] = []
        var fancy_axes: [Int] = [] // the axes of the view
        var fancy_ops: [MfArray] = []
        // positions in `indices` of the integers and index arrays (numpy's advanced indices)
        var advanced_positions: [Int] = []
        var view_axis = 0
        for (position, index) in indices.enumerated(){
            if let op = index as? MfArray{
                precondition(op.mftype == .Int, "fancy indexing must be Int only, but got \(op.mftype)")
                advanced_positions.append(position)
                fancy_axes.append(view_axis)
                fancy_ops.append(op)
                viewIndices.append(MfSlice())
                view_axis += 1
            }
            else if index is Int{
                advanced_positions.append(position)
                viewIndices.append(index)
            }
            else{
                viewIndices.append(index)
                view_axis += 1
            }
        }
        
        let view = self._get_mfarray(indices: &viewIndices)
        // the indexed axes come first, which is the layout the fancy setters take
        let moved = view.moveaxis(src: fancy_axes, dst: Array(0..<fancy_axes.count))
        
        // like the getter, the index dimensions of the selection stay in place only when the advanced indices are next to each other
        var value = newValue
        let adjacent = zip(advanced_positions, advanced_positions.dropFirst()).allSatisfy{ $1 == $0 + 1 }
        if adjacent && fancy_axes[0] > 0{
            let fancy_shape = fancy_ops.reduce(fancy_ops[0]){ biop_broadcast_to($0, $1).r }.shape
            let rest_shape = Array(moved.shape.suffix(from: fancy_axes.count))
            let k = fancy_axes[0]
            let selection_shape = Array(rest_shape.prefix(k)) + fancy_shape + Array(rest_shape.suffix(from: k))
            value = setter_broadcast_to(value, shape: selection_shape).moveaxis(src: Array(k..<k + fancy_shape.count), dst: Array(0..<fancy_shape.count))
        }
        
        if fancy_ops.count == 1{
            moved[fancy_ops[0]] = value
        }
        else{
            moved._fancysetall_mfarray(indices: &fancy_ops, assignedMfarray: value)
        }
    }
    
    /// A copy of the assigned mfarray if it shares memory with self, because a setter reading from the overwritten memory would
    /// see the new values (numpy copies an overlapping right-hand side too, e.g. `a[1:] = a[:-1]`)
    /// - Parameters:
    ///   - assignedMfarray: The assigned mfarray
    private func _unaliased(_ assignedMfarray: MfArray) -> MfArray{
        if assignedMfarray.mfdata.data_real == self.mfdata.data_real{
            return assignedMfarray.to_contiguous(mforder: .Row)
        }
        return assignedMfarray
    }
    
    /// The assigned mfarray as it can be written into self. Like numpy, a complex value assigned into a real array
    /// is cast to its real part (numpy warns with ComplexWarning), and self keeps its type
    /// - Parameters:
    ///   - assignedMfarray: The assigned mfarray
    private func _castable_value(_ assignedMfarray: MfArray) -> MfArray{
        if assignedMfarray.isComplex && self.isReal{
            return assignedMfarray.real
        }
        return assignedMfarray
    }
    
    /// Apply a real setter to the real and imaginary parts respectively
    /// - Parameters:
    ///   - assignedMfarray: The assigned mfarray
    ///   - setter: The real setter. Arguments are (destination mfarray, source mfarray)
    private func _set_realimag(assignedMfarray: MfArray, _ setter: (MfArray, MfArray) -> Void){
        var assignedMfarray = self._unaliased(self._castable_value(assignedMfarray))
        if self.isReal && assignedMfarray.mftype != self.mftype{
            // convert like numpy, e.g. 300 into .UInt8 wraps around to 44 and 2.7 into .Int is truncated to 2
            assignedMfarray = assignedMfarray.astype(self.mftype)
        }
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


/// Broadcast the value assigned by a setter to the shape of the selection.
/// Like numpy, the value may have more dimensions than the selection as long as the extra leading ones have size 1
/// (e.g. `a[0] = MfArray([[1, 2, 3, 4]])` for `a` of shape [3, 4])
/// - Parameters:
///   - value: The assigned mfarray
///   - shape: The shape of the selection
/// - Returns: The broadcast view
internal func setter_broadcast_to(_ value: MfArray, shape: [Int]) -> MfArray{
    let extra = value.ndim - shape.count
    guard extra > 0 && value.shape.prefix(extra).allSatisfy({ $0 == 1 }) else{
        return value.broadcast_to(shape: shape)
    }
    let structure = MfStructure(shape: Array(value.shape.suffix(from: extra)), strides: Array(value.strides.suffix(from: extra)))
    return MfArray(base: value, mfstructure: structure, offset: value.offsetIndex).broadcast_to(shape: shape)
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
    var values = isScalar ? assignMfArray : setter_broadcast_to(assignMfArray, shape: assignShape)
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
