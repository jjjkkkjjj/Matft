//
//  array.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/05.
//

import Foundation
import Accelerate

public class MfArray<T: MfTypeUsable>{
    public typealias MfArrayType = T
    
    public internal(set) var mfdata: MfData<MfArrayType>
    public internal(set) var mfstructure: MfStructure
    
    public internal(set) var base: MfArray?
    
    public init(_ array: [Any], shape: [Int]? = nil, mforder: MfOrder = .Row){
        
        // convert a given array into flatten array
        var (flatten, _shape): ([MfArrayType], [Int]) = flatten_array(array: array, mforder: mforder)
        
        var shape = shape ?? _shape
        precondition(shape2size(&shape) == flatten.count, "Invalid shape, size must be \(flatten.count), but got \(shape2size(&shape))")
        
        self.mfdata = MfData(flattenArray: &flatten)
        self.mfstructure = MfStructure(shape: shape, mforder: mforder)
    }
    
    deinit {
        self.base = nil
    }
}





