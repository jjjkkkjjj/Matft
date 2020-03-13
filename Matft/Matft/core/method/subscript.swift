//
//  subscript.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension MfArray{
    public subscript(indices: Int...) -> MfArray{
        get {
            var mfslices = indices.map{ MfSlice(to: $0 + 1) }
            
            return self.get_mfarray(mfslices: &mfslices)
        }
        //set(newValue){
        //    self[indices] = newValue
        //}
    }
    //public subscript<T: MfSlicable>(indices: T...) -> MfArray{
    public subscript(indices: Any...) -> MfArray{
        get{
            var axes: [Int] = []
            var mfslices: [MfSlice] = []
            for (axis, index) in indices.enumerated(){
                if let index = index as? Int{
                    mfslices.append(MfSlice(to: index + 1))
                }
                else if let index = index as? MfSlice{
                    mfslices.append(index)
                }
                else if let _ = index as? Matft.mfarray.newaxis{
                    axes.append(axis)
                    mfslices.append(MfSlice())
                }
                else{
                    fatalError("\(index) is not subscriptable value")
                }
            }
            
            if axes.count > 0{
                return self.get_mfarray(mfslices: &mfslices, newaxes: axes)
            }
            else{
                return self.get_mfarray(mfslices: &mfslices)
            }
        }
    }
    public subscript(indices: [MfSlice]) -> MfArray{
        get{
            var mfslices = indices
            return self.get_mfarray(mfslices: &mfslices)
        }
    }
    
    public subscript(indices: [Int]) -> Any{
        
        get{
            var indices = indices
            precondition(indices.count == self.ndim, "cannot return value because given indices were invalid")
            let flattenIndex = self.withStridesUnsafeMBPtr{
                stridesptr in
                indices.withUnsafeMutableBufferPointer{
                    _inner_product($0, stridesptr)
                }
            }

            precondition(flattenIndex < self.size, "indices \(indices) is out of bounds")
            if self.mftype == .Double{
                return self.data[flattenIndex]
            }
            else{
                return self.data[flattenIndex]
            }
        }
        set(newValue){
            var indices = indices
            precondition(indices.count == self.ndim, "cannot return value because given indices were invalid")
            let flattenIndex = self.withStridesUnsafeMBPtr{
                stridesptr in
                indices.withUnsafeMutableBufferPointer{
                    _inner_product($0, stridesptr)
                }
            }
            
            precondition(flattenIndex < self.size, "indices \(indices) is out of bounds")
            if let newValue = newValue as? Double{
                self.withDataUnsafeMBPtrT(datatype: Double.self){
                    $0[flattenIndex] = newValue
                }
            }
            else if let newValue = newValue as? UInt8{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt16{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt32{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt64{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int8{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int16{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int32{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int64{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Float{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else{
                fatalError("Unsupported type was input")
            }
        }
        
    }
    //Use opaque?
    private func get_mfarray(mfslices: inout [MfSlice], newaxes: [Int]? = nil) -> MfArray{
        precondition(mfslices.count <= self.ndim, "cannot return value because given indices were too many")
        var mfarray = self
        if let newaxes = newaxes{
            //note that newaxes has already sorted
            for axis in newaxes.reversed(){
                mfarray = Matft.mfarray.expand_dims(mfarray, axis: axis)
            }
        }
        
        if mfslices.count < mfarray.ndim{
            for _ in 0..<mfarray.ndim - mfslices.count{
                mfslices.append(MfSlice())
            }
        }
        
        var offset = 0
        let newstructure = withDummyShapeStridesMBPtr(mfarray.ndim){
            newshapeptr, newstridesptr in
            mfarray.withShapeStridesUnsafeMBPtr{
                orig_shapeptr, orig_stridesptr in
                //copy strides
                newstridesptr.baseAddress!.assign(from: orig_stridesptr.baseAddress!, count: mfarray.ndim)
                    for (axis, mfslice) in mfslices.enumerated(){
                        let start = mfslice.start >= 0 ? mfslice.start * orig_stridesptr[axis] : orig_shapeptr[axis] + mfslice.start
                        var to = mfslice.to ?? orig_shapeptr[axis]
                        to = to >= 0 ? to : orig_shapeptr[axis] + to
                        
                        offset += start * orig_stridesptr[axis]
                        
                        let tmpdim = ceil(Float(to - start)/Float(abs(mfslice.by)))
                        newshapeptr[axis] = max(min(orig_shapeptr[axis], Int(tmpdim)), 0)
                        
                        newstridesptr[axis] *= mfslice.by
                    }
                }
            }
        
        
        //newarray.mfdata._storedSize = get_storedSize(newarray.shapeptr, newarray.stridesptr)
        //print(newarray.shape, newarray.mfdata._size, newarray.mfdata._storedSize)
        return MfArray(base: mfarray, mfstructure: newstructure, offset: offset)
    }
    
}

fileprivate func _inner_product(_ left: UnsafeMutableBufferPointer<Int>, _ right: UnsafeMutableBufferPointer<Int>) -> Int{
    
    assert(left.count == right.count, "cannot calculate inner product due to unsame dim")
    
    return zip(left, right).map(*).reduce(0, +)
}
