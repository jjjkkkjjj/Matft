//
//  structure.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation


public class MfStructure{
    internal var shape: [Int]
    internal var strides: [Int]
    
    internal var row_contiguous: Bool
    internal var column_contiguous: Bool
    
    
    /// Initialization from shape array and order
    /// - Parameters:
    ///   - shape: A shape array
    ///   - mforder: Order
    public init(shape: [Int], mforder: MfOrder){
        self.shape = shape
        self.strides = shape2strides(&self.shape, mforder: mforder)
        
        (self.row_contiguous, self.column_contiguous) = _check_contiguous(shape: &self.shape, strides: &self.strides)
    }
    
    
    /// Initialization from shape and strides array
    /// - Parameters:
    ///   - shape: A shape array
    ///   - strides: A strides array
    public init(shape: [Int], strides: [Int]){
        assert(shape.count == strides.count, "must have same size!")
        self.shape = shape
        self.strides = strides
        
        (self.row_contiguous, self.column_contiguous) = _check_contiguous(shape: &self.shape, strides: &self.strides)
    }
    
    
    /// Update contiguous information
    internal func updateContiguous(){
        (self.row_contiguous, self.column_contiguous) = _check_contiguous(shape: &self.shape, strides: &self.strides)
    }
}



/// Calculate a dimension from a shape
/// - Parameter shape: A shape array
/// - Returns: A dimension
@_transparent
internal func shape2ndim(_ shape: inout [Int]) -> Int{
    return shape.count
}


/// Calculate a size from a shape
/// - Parameter shape: A shape array
/// - Returns: A size
@_transparent
internal func shape2size(_ shape: inout [Int]) -> Int{
    return shape.reduce(1, *)
}


/// Calculate strides with a given order from a shape
/// - Parameters:
///   - shape: A shape array
///   - mforder: Order
/// - Returns: A strides array
internal func shape2strides(_ shape: inout [Int], mforder: MfOrder) -> [Int]{
    var ret = Array<Int>(repeating: 0, count: shape.count)
    
    switch mforder {
    case .Row://, .None:
        var prevAxisNum = shape2size(&shape)
        for index in 0..<shape.count{
            ret[index] = prevAxisNum / shape[index]
            prevAxisNum = ret[index]
        }
    case .Column:
        ret[0] = 1
        for index in 1..<shape.count{
            ret[index] = ret[index - 1] * shape[index - 1]
        }
    }
    return ret
}


/// Check if the array is row or column contiguous or not from the array's shape and strides array
/// - Parameters:
///   - shape: A shape array
///   - strides: A strides array
/// - Returns:
///   - Whether row contiguous is or not
///   - Whether column contiguous is or not
fileprivate func _check_contiguous(shape: inout [Int], strides: inout [Int]) -> (row_contiguous: Bool, column_contiguous: Bool){
    assert(shape.count == strides.count, "must have same size!")
    var sd = 1
    
    //check row contiguous
    var is_c_contig = true
    for i in stride(from: shape.count - 1, through: 0, by: -1){
        let dim = shape[i]
        if dim == 0{
            return (true, true)
        }
        if dim != 1{
            if strides[i] != sd{
                is_c_contig = false
            }
            sd *= dim
        }
    }

    sd = 1
    //check column contiguous
    for i in 0..<shape.count{
        let dim = shape[i]
        if dim != 1{
            if strides[i] != sd{
                return (is_c_contig, false)
            }
            sd *= dim
        }
    }
    return (is_c_contig, true)
}
