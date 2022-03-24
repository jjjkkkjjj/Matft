//
//  withPointer.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension MfArray{
    
    public func withUnsafeMutableStartPointer<R>(_ body: (UnsafeMutablePointer<MfArrayStoredType>) throws -> R) rethrows -> R{
        return try body(self.mfdata.storedPtr.baseAddress! + self.mfdata.offset)
    }
    
    internal func withMNStackedMajorPointer(mforder: MfOrder, _ body: (UnsafeMutablePointer<MfArrayStoredType>, Int, Int, Int) throws -> Void) rethrows -> Void{
        let shape = self.shape
        let M = shape[self.ndim - 2]
        let N = shape[self.ndim - 1]
        let matrices_num = self.size / (M * N)
        
        // get stacked row major and copy
        let rowMfarray = mforder == .Row ? self.to_contiguous(mforder: .Row) : self.swapaxes(axis1: -1, axis2: -2).to_contiguous(mforder: .Row) // Note Column Major is trecky!
        
        var offset = 0
        try rowMfarray.withUnsafeMutableStartPointer{
            for _ in 0..<matrices_num{
                try body($0 + offset, M, N, offset)
                
                offset += M * N
            }
        }
    }
    
}
