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
    public subscript(indices: Int...) -> Any{

        get {
            return self[indices]
        }
        set(newValue){
            self[indices] = newValue
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
                return self.dataptr.bindMemory(to: Double.self)[flattenIndex]
            }
            else{
                return self.dataptr.bindMemory(to: Float.self)[flattenIndex]
            }
        }
        set(newValue){
            var indices = indices
            precondition(indices.count == self.ndim, "cannot return value because given indices were invalid")
            let flattenIndex = indices.withUnsafeMutableBufferPointer{
                _inner_product($0, self.stridesptr)
            }
            
            precondition(flattenIndex < self.size, "indices \(indices) is out of bounds")
            if let newValue = newValue as? Double, self.mftype == .Double{
                self.dataptr.bindMemory(to: Double.self)[flattenIndex] = newValue
            }
            else if let newValue = newValue as? UInt8{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt16{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt32{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt64{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? UInt{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int8{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int16{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int32{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int64{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Int{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else if let newValue = newValue as? Float{
                self.dataptr.bindMemory(to: Float.self)[flattenIndex] = Float(newValue)
            }
            else{
                fatalError("Unsupported type was input")
            }
        }
        
    }
}

fileprivate func _inner_product(_ left: UnsafeMutableBufferPointer<Int>, _ right: UnsafeMutableBufferPointer<Int>) -> Int{
    
    precondition(left.count == right.count, "cannot calculate inner product due to unsame dim")
    var ret = 0
    for (l, r) in zip(left, right){
        ret += l * r
    }
    
    return ret
}
