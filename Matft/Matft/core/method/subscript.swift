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
    public subscript(indices: Any...) -> MfArray{
        get{
            var mfslices = indices.map{
                (index) -> MfSlice in
                if let index = index as? Int{
                    return MfSlice(to: index + 1)
                }
                else if let index = index as? MfSlice{
                    return index
                }
                else{
                    fatalError("\(index) is not subscriptable value")
                }
            }
            return self.get_mfarray(mfslices: &mfslices)
        }
    }

    public subscript(indices: [Int]) -> Any{
        
        get{
            var indices = indices
            precondition(indices.count == self.ndim, "cannot return value because given indices were invalid")
            let flattenIndex = indices.withUnsafeMutableBufferPointer{
                _inner_product($0, self.stridesptr)
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
            let flattenIndex = indices.withUnsafeMutableBufferPointer{
                _inner_product($0, self.stridesptr)
            }
            
            precondition(flattenIndex < self.size, "indices \(indices) is out of bounds")
            if let newValue = newValue as? Double, let dataptr = self.dataptrD{
                dataptr[flattenIndex] = newValue
            }
            else if let newValue = newValue as? UInt8, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt16, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt32, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt64, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int8, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int16, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int32, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int64, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Float, let dataptr = self.dataptrF{
                dataptr[flattenIndex] = Float(newValue)
            }
            else{
                fatalError("Unsupported type was input")
            }
        }
        
    }
    
    private func get_mfarray(mfslices: inout [MfSlice]) -> MfArray{
        precondition(mfslices.count <= self.ndim, "cannot return value because given indices were too many")
        
        if mfslices.count < self.ndim{
            for _ in 0..<self.ndim - mfslices.count{
                mfslices.append(MfSlice())
            }
        }
        
        let newarray = self.shallowcopy()
        var offset = 0
        for (axis, mfslice) in mfslices.enumerated(){
            offset += mfslice.start * self.stridesptr[axis]
            
            if let to = mfslice.to{//0<=to-1-start<dim
                newarray.shapeptr[axis] = max(min(self.shapeptr[axis], to - 1 - mfslice.start), 0)
            }//note that nil indicates all elements
            else{
                let tmpdim = ceil(Float(self.shapeptr[axis] - mfslice.start)/Float(mfslice.by))
                newarray.shapeptr[axis] = max(min(self.shapeptr[axis], Int(tmpdim)), 0)
            }
            newarray.stridesptr[axis] *= mfslice.by
        }
        newarray.mfdata._offset = offset
        newarray.mfdata._size = shape2size(newarray.shapeptr)
        //newarray.mfdata._storedSize = get_storedSize(newarray.shapeptr, newarray.stridesptr)
        //print(newarray.shape, newarray.mfdata._size, newarray.mfdata._storedSize)
        return newarray
    }
    
}

fileprivate func _inner_product(_ left: UnsafeMutableBufferPointer<Int>, _ right: UnsafeMutableBufferPointer<Int>) -> Int{
    
    assert(left.count == right.count, "cannot calculate inner product due to unsame dim")
    
    return zip(left, right).map(*).reduce(0, +)
}
