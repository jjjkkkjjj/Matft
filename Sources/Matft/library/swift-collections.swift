//
//  swift-collections.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import Foundation
import Collections

internal func orderedUnique_by_swcoll<T: MfTypeUsable>(_ flatten_array: inout [T.StoredType], rest_shape: inout [Int], stride: Int, axis: Int?) -> MfArray<T>{
    
    var unique_array: [T.StoredType]
    if stride == 1{// flatten array
        unique_array = Array(OrderedSet(flatten_array))
    }
    else{
        assert(axis != nil)
        
        var axis_array: [[T.StoredType]] = []
        for i in 0..<(flatten_array.count/stride){
            axis_array += [Array(flatten_array[i*stride..<(i+1)*stride])]
        }

        unique_array = OrderedSet(axis_array).flatMap{ $0 }
    }
    
    let new_size = unique_array.count
    let newdata: MfData<T> = MfData(T.self, storedFlattenArray: &unique_array)
    
    rest_shape.insert(new_size / stride, at: 0)
    let newstructure = MfStructure(shape: rest_shape, mforder: .Row)
    
    let ret = MfArray(mfdata: newdata, mfstructure: newstructure)
    
    
    if let axis = axis{
        return ret.moveaxis(src: axis, dst: 0)
    }
    else{
        return ret
    }

}
