//
//  data.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

public class MfData<T: MfTypeUsable>{
    public typealias MfArrayType = T
    internal typealias MfArrayStoredType = T.StoredType
    
    private var _base: MfData?
    internal var _isView: Bool{
        return self._base != nil
    }
    
    /// The stored data's pointer
    internal var storedPtr: UnsafeMutableBufferPointer<MfArrayStoredType>
    internal var storedData: [MfArrayStoredType]{
        return Array<MfArrayStoredType>(self.storedPtr)
    }
    /// The size of the stored data
    internal var storedSize: Int {
        return self.storedPtr.count
    }
    
    /// The offset value
    internal let offset: Int
    
    
    /// Initialization from flatten array. Allocate memories with stored type's size, which will store a given flatten array
    /// - Parameter flattenArray: An input flatten array
    public init(flattenArray: inout [MfArrayType]){
        // dynamic allocation
        typealias ptr = UnsafeMutableBufferPointer<MfArrayStoredType>
        let storedPtr = ptr.allocate(capacity: flattenArray.count)
        
        
        // type conversion
        _ = flattenArray.withUnsafeBufferPointer{
            ArrayConversionToStoredType(src: $0.baseAddress!, dst: storedPtr.baseAddress!, size: flattenArray.count)
        }
        
        self.storedPtr = storedPtr
        self.offset = 0
    }
    
    
    /// Initialization from stored flatten array.
    /// - Parameters:
    ///   - orig_type: The original type
    ///   - storedFlattenArray: An input stored flatten array
    public init(_ orig_type: MfArrayType.Type, storedFlattenArray: inout [MfArrayType.StoredType]){
        // dynamic allocation
        typealias ptr = UnsafeMutableBufferPointer<MfArrayStoredType>
        let storedPtr = ptr.allocate(capacity: storedFlattenArray.count)
        
        _ = storedFlattenArray.withUnsafeBufferPointer{
            memcpy(storedPtr.baseAddress!, $0.baseAddress!, storedFlattenArray.count*MemoryLayout<MfArrayStoredType>.size)
        }
        
        self.storedPtr = storedPtr
        self.offset = 0
    }
    
    
    /// Create a MfData with VIEW based on base mfdata
    /// - Parameters:
    ///   - base: The base mfdata
    ///   - offset: The offset value from base's data
    public init(base: MfData, offset: Int){
        self._base = base
        // Note that this storedPtr will not be freed in this MfData!
        self.storedPtr = base.storedPtr
        self.offset = offset
    }
    
    
    /// Create a zero padded MfData
    /// - Parameter size: A size
    public init(size: Int){
        // dynamic allocation
        typealias ptr = UnsafeMutableBufferPointer<MfArrayStoredType>
        let storedPtr = ptr.allocate(capacity: size)
        storedPtr.initialize(repeating: MfArrayStoredType.zero)
        
        self.storedPtr = storedPtr
        self.offset = 0
    }
    
    deinit {
        if !self._isView{
            // deallocate
            self.storedPtr.deallocate()
        }
        
        self._base = nil
    }
}


/// Convert a given array with Any type into a flatten array with specific type
/// - Parameters:
///   - array: Input Any typed array
///   - mforder: MfOrder
/// - Returns:
///   - flatten: Flatten array
///   - shape: Input array's shape
internal func flatten_array<T: MfTypeUsable>(array: [Any], mforder: MfOrder) -> (flatten: [T], shape: [Int]){
    var shape: [Int] = [array.count]
    var queue = array
    var _flatten: [Any]
    
    switch mforder {
    case .Row:
        _flatten = _get_flatten_row_major(queue: &queue, shape: &shape)
    case .Column:
        _flatten = _get_flatten_column_major(queue: &queue, shape: &shape)
    }

    if let flatten = _flatten as? [T]{
        return (flatten, shape)
    }
    else{
        fatalError("couldn't cast \(T.self).")
    }
}

/// Get a flatten array with row majar order from a given structured array. This function is using breadth-first search which is a recurrsive function
/// - Parameters:
///   - queue: An input strucrured array
///   - shape: An input-output shape. Input must be [queue.count], and final output is proper shape
/// - Returns: flatten array with row major order
fileprivate func _get_flatten_row_major(queue: inout [Any], shape: inout [Int]) -> [Any]{
    precondition(shape.count == 1, "shape must have only one element")
    var cnt = 0 // count up the number that value is extracted from queue for while statement, reset 0 when iteration number reaches size
    var size = queue.count
    var axis = 0//the axis in searching
    
    while queue.count > 0 {
        //get first element
        let elements = queue[0]
        
        if let elements = elements as? [Any]{
            queue += elements
            
            if cnt == 0{ //append next dim
                shape.append(elements.count)
                axis += 1
            }
            else{// check if same dim is or not
                if shape[axis] != elements.count{
                    shape = shape.dropLast()
                }
            }
            cnt += 1
        }
        else{ // value was detected. this means queue in this case becomes flatten array
            break
        }
        //remove first element from array
        let _ = queue.removeFirst()
        
        if cnt == size{//reset count and forward next axis
            cnt = 0
            size *= shape[axis]
        }
    }
    
    return queue
}

/// Get a flatten array with column majar order from a given structured array. This function is a recurrsive function
/// - Parameters:
///   - queue: An input strucrured array
///   - shape: An input-output shape. Input must be [queue.count], and final output is proper shape
/// - Returns: flatten array with column major order
fileprivate func _get_flatten_column_major(queue: inout [Any], shape: inout [Int]) -> [Any]{
    //precondition(shape.count == 1, "shape must have only one element")
    var cnt = 0 // count up the number that value is extracted from queue for while statement, reset 0 when iteration number reaches size
    //var axis = 0//the axis in searching
    let dim = queue.count // given
    
    var objectFlag = false
    
    var newqueue: [Any] = []
    while queue.count > 0{
        //get first element
        let elements = queue[0]
        
        if var elements = elements as? [Any]{
            if cnt == 0{ //append next dim
                shape.append(elements.count)
                //axis += 1
            }
            else if cnt < dim{// check if same dim is or not
                if shape.last! != elements.count{
                    shape = shape.dropLast()
                    objectFlag = true
                    break
                }
            }
            cnt += 1
            
            newqueue.append(elements.removeFirst())
            if elements.count > 0{
                queue.append(elements)
            }
            
            
        }
        else{ // value was detected. this means queue in this case becomes flatten array
            return queue
        }
        
        let _ = queue.removeFirst()
    }
    
    if !objectFlag{
        //recurrsive
        return _get_flatten_column_major(queue: &newqueue, shape: &shape)
    }
    else{
        return newqueue
    }
}
