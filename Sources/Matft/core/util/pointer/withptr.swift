//
//  withptr.swift
//  
//
//  Created by Junnosuke Kado on 2022/06/30.
//

import Foundation
import Accelerate

extension MfArray{
    
    public func withUnsafeMutableStartRawPointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R{
        return try body(self.mfdata.data_real + self.mfdata.byteOffset)
    }
    public func withUnsafeMutableStartRawImagPointer<R>(_ body: (UnsafeMutableRawPointer?) throws -> R) rethrows -> R{
        guard let data_imag = self.mfdata.data_imag else { return try body(nil) }
        return try body(data_imag + self.mfdata.byteOffset)
    }
    public func withUnsafeMutableStartPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawPointer{
            [unowned self](ptr) -> R in
            let dataptr = ptr.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(dataptr)
        }
        
        return ret
    }
    public func withUnsafeMutableStartImagPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>?) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawImagPointer{
            [unowned self](ptr) -> R in
            let dataptr = ptr?.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(dataptr)
        }
        
        return ret
    }
    
    public func withUnsafeMutablevDSPComplexPointer<T: vDSP_ComplexTypable, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutableStartPointer(datatype: T.T.self){ ptrrT in
            return try self.withUnsafeMutableStartImagPointer(datatype: T.T.self){
                ptriT -> R in
                var ptr = T(realp: ptrrT, imagp: ptriT!)
                return try body(&ptr)
            }
        }
        
        return ret
    }
    internal func withUnsafeMutableBlasComplexPointer<T: blas_ComplexTypable, R>(datatype: T.Type, vDSP_func: vDSP_convert_func<T.vDSPType, T>, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutablevDSPComplexPointer(datatype: T.vDSPType.self){ [unowned self](ptr) -> R in
            var arr = Array(repeating: T(real: T.T.zero, imag: T.T.zero), count: self.storedSize)
            wrap_vDSP_convert(arr.count, ptr, 1, &arr, 1, vDSP_func)
            return try body(&arr)
        }
        
        return ret
    }
    
    public func withContiguousDataUnsafeMPtrT<T>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> Void) rethrows -> Void{
        var shape = self.shape
        var strides = self.strides
        try self.withUnsafeMutableStartPointer(datatype: T.self){
            ptr in
            for ind in FlattenIndSequence(shape: &shape, strides: &strides){
                try body(ptr + ind.flattenIndex)
            }
        }
    }
    
    internal func withMNStackedMajorPointer<T: MfStorable>(datatype: T.Type, mforder: MfOrder, _ body: (UnsafeMutablePointer<T>, Int, Int, Int) throws -> Void) rethrows -> Void{
        let shape = self.shape
        let M = shape[self.ndim - 2]
        let N = shape[self.ndim - 1]
        let matricesNum = self.size / (M * N)
        
        // get stacked row major and copy
        let rowMfarray = mforder == .Row ? self.to_contiguous(mforder: .Row) : self.swapaxes(axis1: -1, axis2: -2).to_contiguous(mforder: .Row)
        
        var offset = 0
        try rowMfarray.withUnsafeMutableStartPointer(datatype: T.self){
            for _ in 0..<matricesNum{
                try body($0 + offset, M, N, offset)
                
                offset += M * N
            }
        }
    }
}


extension MfData{
    public func withUnsafeMutableStartRawPointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R{
        return try body(self.data_real + self.byteOffset)
    }
    public func withUnsafeMutableStartRawImagPointer<R>(_ body: (UnsafeMutableRawPointer?) throws -> R) rethrows -> R{
        guard let data_imag = self.data_imag else { return try body(nil) }
        return try body(data_imag + self.byteOffset)
    }
    public func withUnsafeMutableStartPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawPointer{
            [unowned self](ptr) -> R in
            let dataptr = ptr.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(dataptr)
        }
        
        return ret
    }
    
    public func withUnsafeMutableStartImagPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>?) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawImagPointer{
            [unowned self](ptr) -> R in
            let dataptr = ptr?.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(dataptr)
        }
        
        return ret
    }
    
    public func withUnsafeMutablevDSPComplexPointer<T: vDSP_ComplexTypable, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutableStartPointer(datatype: T.T.self){ ptrrT in
            return try self.withUnsafeMutableStartImagPointer(datatype: T.T.self){
                ptriT -> R in
                var ptr = T(realp: ptrrT, imagp: ptriT!)
                return try body(&ptr)
            }
        }
        
        return ret
    }
    internal func withUnsafeBlasComplexPointer<T: blas_ComplexTypable, R>(datatype: T.Type, vDSP_func: vDSP_convert_func<T.vDSPType, T>, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutablevDSPComplexPointer(datatype: T.vDSPType.self){ [unowned self](ptr) -> R in
            var arr = Array(repeating: T(real: T.T.zero, imag: T.T.zero), count: self.storedSize)
            wrap_vDSP_convert(arr.count, ptr, 1, &arr, 1, vDSP_func)
            return try body(&arr)
        }
        
        return ret
    }
}


public func withAdvancedUnsafeMutablevDSPComplexPointer<T: vDSP_ComplexTypable, R>(pointer: UnsafePointer<T>, by: Int, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
    
    var ptr = T(realp: pointer.pointee.realp + by, imagp: pointer.pointee.imagp + by)
    return try body(&ptr)
}

