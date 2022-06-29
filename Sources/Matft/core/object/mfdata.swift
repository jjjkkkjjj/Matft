//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

public class MfData{
    private var _base: MfData? // must be referenced because refdata could be freed automatically?
    internal var data: UnsafeMutableRawPointer
    
    internal var mftype: MfType
    internal var storedType: StoredType{
        return MfType.storedType(self.mftype)
    }
    /// The size of the stored data
    internal let storedSize: Int
    /// The size of the stored data (byte)
    internal var storedByteSize: Int{
        switch self.storedType {
        case .Float:
            return self.storedSize * MemoryLayout<Float>.size
        case .Double:
            return self.storedSize * MemoryLayout<Double>.size
        }
    }
    
    /// Whether to be VIEW or not
    internal var _isView: Bool{
        return self._base != nil
    }
    
    /// The offset value
    internal let offset: Int
    /// The offset value (byte)
    internal var byteOffset: Int{
        get{
            switch self.storedType {
            case .Float:
                return self.offset * MemoryLayout<Float>.size
            case .Double:
                return self.offset * MemoryLayout<Double>.size
            }
        }
    }
    
    /// Initialization from flatten array. Allocate memories with stored type's size, which will store a given flatten array
    /// - Parameters:
    ///     - flattenArray: An input flatten array
    ///     - mftype: Type
    public init(flattenArray: inout [Any], mftype: MfType){
        switch MfType.storedType(mftype){
        case .Float:
            // dynamic allocation
            self.data = flattenArray2UnsafeMRPtrF(&flattenArray, toBool: mftype == .Bool)
        case .Double:
            // dynamic allocation
            self.data = flattenArray2UnsafeMRPtrD(&flattenArray, toBool: mftype == .Bool)
        }
        self.storedSize = flattenArray.count
        self.mftype = mftype
        self.offset = 0
    }
    
    public init(dataptr: UnsafeMutableRawPointer, storedSize: Int, mftype: MfType){
        self.data = dataptr
        self.storedSize = storedSize
        self.mftype = mftype
        self.offset = 0
    }
    
    
    /// Create a MfData with VIEW based on base mfdata
    /// - Parameters:
    ///   - base: The base mfdata
    ///   - offset: The offset value from base's data
    public init(refdata: MfData, offset: Int){
        self._base = refdata
        self.data = refdata.data
        self.storedSize = refdata.storedSize
        self.mftype = refdata.mftype
        self.offset = offset
    }
    
    deinit {
        if !self._isView{
            func _deallocate<T: MfStorable>(_ type: T.Type){
                let dataptr = self.data.bindMemory(to: T.self, capacity: self.storedSize)
                dataptr.deinitialize(count: self.storedSize)
                dataptr.deallocate()
            }
            switch self.storedType {
            case .Float:
                _deallocate(Float.self)
            case .Double:
                _deallocate(Double.self)
            }
            //self._data.deallocate()
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
internal func flatten_array(ptr: UnsafeBufferPointer<Any>, mforder: inout MfOrder) -> (flatten: [Any], shape: [Int]){
    var shape: [Int] = [ptr.count]
    var queue = ptr.compactMap{ $0 }
    
    switch mforder {
    case .Row:
        return (_get_flatten_row_major(queue: &queue, shape: &shape), shape)
    case .Column:
        return (_get_flatten_column_major(queue: &queue, shape: &shape), shape)
    /*case .None:
        fatalError("Select row or column as MfOrder.")*/
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
