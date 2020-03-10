//
//  mfstructure.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/10.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public struct MfStructure{
    public var _shape: UnsafeMutablePointer<Int>
    public var _strides: UnsafeMutablePointer<Int>
    public var _ndim: Int
    public var _size: Int
    
    public init(shapeptr: UnsafeMutablePointer<Int>, mforder: MfOrder, ndim: Int){
        self._shape = shapeptr
        let shapeMBPtr = UnsafeMutableBufferPointer(start: shapeptr, count: ndim)
        let stridesptr = shape2strides(shapeMBPtr, mforder: mforder)
        self._strides = stridesptr.baseAddress!
        self._ndim = ndim
        self._size = shape2size(shapeMBPtr)
    }
    public init(shapeptr: UnsafeMutablePointer<Int>, stridesptr: UnsafeMutablePointer<Int>, ndim: Int){
        self._shape = shapeptr
        self._strides = stridesptr
        self._ndim = ndim
        let shapeMBPtr = UnsafeMutableBufferPointer(start: shapeptr, count: ndim)
        self._size = shape2size(shapeMBPtr)
    }
    internal func free(){
        
    }
}

extension MfStructure{
    public func withDummyShapeStridesMBPtr(_ ndim: Int, _ body: (UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>) throws -> (UnsafeMutableBufferPointer<Int>, UnsafeMutableBufferPointer<Int>)) rethrows -> MfStructure{
        
        let dummyShapePtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
        let dummyStridesPtr = UnsafeMutableBufferPointer(start: create_unsafeMPtrT(type: Int.self, count: ndim), count: ndim)
        
        let (shapeptr, stridesptr) = try body(dummyShapePtr, dummyStridesPtr)
        
        return MfStructure(shapeptr: shapeptr.baseAddress!, stridesptr: stridesptr.baseAddress!, ndim: ndim)
    }
}
