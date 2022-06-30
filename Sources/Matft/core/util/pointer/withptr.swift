//
//  withptr.swift
//  
//
//  Created by Junnosuke Kado on 2022/06/30.
//

import Foundation

extension MfArray{
    
    public func withDataUnsafeMRPtr<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R{
        return try body(self.mfdata.data + self.mfdata.byteOffset)
    }
    public func withDataUnsafeMBPtrT<T, R>(datatype: T.Type, _ body: (UnsafeMutableBufferPointer<T>) throws -> R) rethrows -> R{
        let ret = try self.withDataUnsafeMRPtr{
            [unowned self](ptr) -> R in
            let dataptr = ptr.bindMemory(to: T.self, capacity: self.storedSize)
            return try body(UnsafeMutableBufferPointer(start: dataptr, count: self.storedSize))
        }
        
        return ret
    }
    public func withContiguousDataUnsafeMPtrT<T>(datatype: T.Type, _ body: (UnsafeMutablePointer<T>) throws -> Void) rethrows -> Void{
        var shape = self.shape
        var strides = self.strides
        try self.withDataUnsafeMBPtrT(datatype: T.self){
            ptr in
            for ind in FlattenIndSequence(shape: &shape, strides: &strides){
                try body(ptr.baseAddress! + ind.flattenIndex)
            }
        }
    }
    
    internal func withMNStackedMajorPtr<T: MfStorable>(type: T.Type, mforder: MfOrder, _ body: (UnsafeMutablePointer<T>, Int, Int, Int) throws -> Void) rethrows -> Void{
        let shape = self.shape
        let M = shape[self.ndim - 2]
        let N = shape[self.ndim - 1]
        let matricesNum = self.size / (M * N)
        
        // get stacked row major and copy
        let rowMfarray = mforder == .Row ? self.to_contiguous(mforder: .Row) : self.swapaxes(axis1: -1, axis2: -2).to_contiguous(mforder: .Row)
        
        var offset = 0
        try rowMfarray.withDataUnsafeMBPtrT(datatype: T.self){
            for _ in 0..<matricesNum{
                try body($0.baseAddress! + offset, M, N, offset)
                
                offset += M * N
            }
        }
    }
}
