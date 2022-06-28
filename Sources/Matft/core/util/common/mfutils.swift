//
//  array.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

extension MfStructure{
    public func updateContiguous(){
        self._flags.updateContiguous(shapeptr: self._shape, stridesptr: self._strides, ndim: self._ndim)
    }
    
}

internal func shape2ndim(_ shape: inout [Int]) -> Int{
    return shape.count
}
internal func shape2ndim(_ shapeptr: UnsafeMutableBufferPointer<Int>) -> Int{
    return shapeptr.count
}

internal func shape2size(_ shapeptr: UnsafeMutableBufferPointer<Int>) -> Int{
    return shapeptr.reduce(1, *)
    //return shapeptr.filter{ $0 != 0 }.reduce(1, *)
}
internal func shape2size(_ shape: inout [Int]) -> Int{
    return shape.withUnsafeMutableBufferPointer{
        shape2size($0)
    }
}

/**
    - Important: this function allocate new memory, so don't forget deallocate!
 */
internal func shape2strides(_ shapeptr: UnsafeMutableBufferPointer<Int>, mforder: MfOrder) -> UnsafeMutableBufferPointer<Int>{
    let stridesptr = create_unsafeMPtrT(type: Int.self, count: shapeptr.count)
    let ret = UnsafeMutableBufferPointer(start: stridesptr, count: shapeptr.count)
    
    switch mforder {
    case .Row://, .None:
        var prevAxisNum = shape2size(shapeptr)
        for index in 0..<shapeptr.count{
            ret[index] = prevAxisNum / shapeptr[index]
            prevAxisNum = ret[index]
        }
    case .Column:
        ret[0] = 1
        for index in 1..<shapeptr.count{
            ret[index] = ret[index - 1] * shapeptr[index - 1]
        }
    }
    
    return ret
}

internal func get_storedSize(_ shapeptr: UnsafeMutableBufferPointer<Int>, _ stridesptr: UnsafeMutableBufferPointer<Int>) -> Int{
    
    var ret = 1
    let _ = zip(shapeptr, stridesptr).map{
        (dim, st) in
        ret *= st != 0 && dim != 0 ? dim : 1
    }
    return ret
}

/**
        return boolean represents whether to contain reverse
 */
internal func isReverse(_ stridesptr: UnsafeMutableBufferPointer<Int>) -> Bool{
    return stridesptr.contains{ $0 < 0 }
}

internal func copy_mfstructure(_ mfstructure: MfStructure) -> MfStructure{
    return withDummyShapeStridesMBPtr(mfstructure._ndim){
        shapeptr, stridesptr in
        shapeptr.baseAddress!.assign(from: mfstructure._shape, count: mfstructure._ndim)
        stridesptr.baseAddress!.assign(from: mfstructure._strides, count: mfstructure._ndim)
    }
}

/**
    Create mfstructure from shape only
 */
internal func create_mfstructure(_ shape: inout [Int], mforder: MfOrder) -> MfStructure{
    let ndim = shape.count
    let newmfstructure = withDummyShapeStridesMBPtr(ndim){
        shapeptr, stridesptr in
        shape.withUnsafeMutableBufferPointer{
            shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: ndim)
        }
        
        let newstrides = shape2strides(shapeptr, mforder: mforder)
        stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: ndim)
        
        newstrides.deallocate()
    }
    
    return newmfstructure
}

/**
    Create mfstructure from shape and strides
 */
internal func create_mfstructure(_ shape: inout [Int], _ strides: inout [Int]) -> MfStructure{
    let ndim = shape.count
    let newmfstructure = withDummyShapeStridesMPtr(ndim){
        shapeptr, stridesptr in
        shape.withUnsafeMutableBufferPointer{
            shapeptr.moveAssign(from: $0.baseAddress!, count: ndim)
        }
        strides.withUnsafeMutableBufferPointer{
            stridesptr.moveAssign(from: $0.baseAddress!, count: ndim)
        }
    }
    
    return newmfstructure
}

/*
internal func copy_mfdata(_ mfdata: MfData){
    let newmfdata = withDummyDataMRPtr(mfdata.mftype, storedSize: mfdata._storedSize){
        dstptr in
        dstptr.copyMemory(from: mfdata._data + mfdata._byteOffset, byteCount: mfarray.byteSize)
    }
}

internal func create_mfdata(){
    
}
*/
