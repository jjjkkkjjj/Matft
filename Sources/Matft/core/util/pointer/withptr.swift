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
        return try body(self.mfdata.data + self.mfdata.byteOffset)
    }
    public func withUnsafeMutableStartPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawPointer{
            [unowned self](ptr) -> R in
            let dataptr = ptr.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(dataptr)
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


extension MfComplexArray{
    public func withUnsafeMutableStartRawPointer<R>(_ body: (UnsafeMutableRawPointer, UnsafeMutableRawPointer) throws -> R) rethrows -> R{
        return try body(self.mfdata.data_real + self.mfdata.byteOffset, self.mfdata.data_imag + self.mfdata.byteOffset)
    }
    public func withUnsafeMutableStartPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>, UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawPointer{
            [unowned self](ptrr, ptri) -> R in
            let datarptr = ptrr.bindMemory(to: T.self, capacity: self.storedSize)
            let dataiptr = ptri.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(datarptr, dataiptr)
        }
        
        return ret
    }
    
    public func withUnsafeMutablevDSPPointer<T: vDSP_ComplexTypable, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutableStartPointer(datatype: T.T.self){ (ptrrT, ptriT) -> R in
            var ptr = T(realp: ptrrT, imagp: ptriT)
            return try body(&ptr)
        }
        
        return ret
    }
    internal func withUnsafeMutableblasPointer<T: blas_ComplexTypable, R>(datatype: T.Type, vDSP_func: vDSP_convertcz_func<T.vDSPType, T>, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutablevDSPPointer(datatype: T.vDSPType.self){ [unowned self](ptr) -> R in
            var arr = Array(repeating: T(real: T.T.zero, imag: T.T.zero), count: self.storedSize)
            wrap_vDSP_convertcz(arr.count, ptr, 1, &arr, 1, vDSP_func)
            return try body(&arr)
        }
        
        return ret
    }
}

extension MfData{
    public func withUnsafeMutableStartRawPointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R{
        return try body(self.data + self.byteOffset)
    }
    
    public func withUnsafeMutableStartPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawPointer{
            [unowned self](ptr) -> R in
            let dataptr = ptr.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(dataptr)
        }
        
        return ret
    }
}

extension MfComplexData{
    public func withUnsafeMutableStartRawPointer<R>(_ body: (UnsafeMutableRawPointer, UnsafeMutableRawPointer) throws -> R) rethrows -> R{
        return try body(self.data_real + self.byteOffset, self.data_imag + self.byteOffset)
    }
    public func withUnsafeMutableStartPointer<T, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>, UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withUnsafeMutableStartRawPointer{
            [unowned self](ptrr, ptri) -> R in
            let datarptr = ptrr.bindMemory(to: T.self, capacity: self.storedSize)
            let dataiptr = ptri.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(datarptr, dataiptr)
        }
        
        return ret
    }
    
    public func withUnsafeMutablevDSPPointer<T: vDSP_ComplexTypable, R>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutableStartPointer(datatype: T.T.self){ (ptrrT, ptriT) -> R in
            var ptr = T(realp: ptrrT, imagp: ptriT)
            return try body(&ptr)
        }
        
        return ret
    }
    internal func withUnsafeMutableblasPointer<T: blas_ComplexTypable, R>(datatype: T.Type, vDSP_func: vDSP_convertcz_func<T.vDSPType, T>, _ body: (UnsafeMutablePointer<T>) throws -> R) rethrows -> R{
        
        let ret = try self.withUnsafeMutablevDSPPointer(datatype: T.vDSPType.self){ [unowned self](ptr) -> R in
            var arr = Array(repeating: T(real: T.T.zero, imag: T.T.zero), count: self.storedSize)
            wrap_vDSP_convertcz(arr.count, ptr, 1, &arr, 1, vDSP_func)
            return try body(&arr)
        }
        
        return ret
    }
}
