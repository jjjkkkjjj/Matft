//
//  withptr.swift
//  
//
//  Created by Junnosuke Kado on 2022/06/30.
//

import Foundation

extension MfArray{
    
    internal func withMNStackedMajorPtr<T: MfStorable>(type: T.Type, mforder: MfOrder, _ body: (UnsafeMutablePointer<T>, Int, Int, Int) throws -> Void) rethrows -> Void{
        let shape = self.shape
        let M = shape[self.ndim - 2]
        let N = shape[self.ndim - 1]
        let matricesNum = self.size / (M * N)
        
        // get stacked row major and copy
        let rowMfarray = mforder == .Row ? to_row_major(self) : to_row_major(self.swapaxes(axis1: -1, axis2: -2))
        
        var offset = 0
        try rowMfarray.withDataUnsafeMBPtrT(datatype: T.self){
            for _ in 0..<matricesNum{
                try body($0.baseAddress! + offset, M, N, offset)
                
                offset += M * N
            }
        }
    }
}
