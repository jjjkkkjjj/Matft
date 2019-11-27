//
//  InfoCreation.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/13.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension MfArrayInfo{
    internal func newDataPointer(){
        typealias TPointer = UnsafeMutableBufferPointer<Double>
        let dataPointer = TPointer.allocate(capacity: self.size)
        
        memcpy(dataPointer.baseAddress!, self.bufdata.baseAddress!, MemoryLayout<Double>.size*self.size)
        self._bufdata.deallocate()
        
        self._bufdata = dataPointer
    }
    
    internal func deepcopy() -> MfArrayInfo<T> {
        typealias TPointer = UnsafeMutableBufferPointer<Double>
        let newdataPointer = TPointer.allocate(capacity: self.size)
        memcpy(newdataPointer.baseAddress!, self.bufdata.baseAddress!, MemoryLayout<Double>.size*self.size)
        
        return MfArrayInfo(dataPointer: newdataPointer, type: T.self, shape: self.shape, strides: self.strides, order: self.flags.order)
    }
}
