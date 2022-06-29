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
    private var __refdata: MfData? // must be referenced because refdata could be freed automatically?
    public internal(set) var _data: UnsafeMutableRawPointer
    
    public internal(set) var _mftype: MfType
    internal var _storedType: StoredType{
        return MfType.storedType(self._mftype)
    }
    public let _storedSize: Int
    public var _storedByteSize: Int{
        switch self._storedType {
        case .Float:
            return self._storedSize * MemoryLayout<Float>.size
        case .Double:
            return self._storedSize * MemoryLayout<Double>.size
        }
    }

    public var _isView: Bool{
        return self.__refdata != nil
    }
    
    public let _offset: Int
    public var _byteOffset: Int{
        get{
            switch self._storedType {
            case .Float:
                return self._offset * MemoryLayout<Float>.size
            case .Double:
                return self._offset * MemoryLayout<Double>.size
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
            self._data = flattenArray2UnsafeMRPtrF(&flattenArray, toBool: mftype == .Bool)
        case .Double:
            // dynamic allocation
            self._data = flattenArray2UnsafeMRPtrD(&flattenArray, toBool: mftype == .Bool)
        }
        self._storedSize = flattenArray.count
        self._mftype = mftype
        self._offset = 0
    }
    
    public init(dataptr: UnsafeMutableRawPointer, storedSize: Int, mftype: MfType){
        self._data = dataptr
        self._storedSize = storedSize
        self._mftype = mftype
        self._offset = 0
    }
    public init(mfdata: MfData){
        self._data = mfdata._data
        self._storedSize = mfdata._storedSize
        self._mftype = mfdata._mftype
        self._offset = 0
    }
    
    
    // create view
    public init(refdata: MfData, offset: Int){
        self.__refdata = refdata
        self._data = refdata._data
        self._storedSize = refdata._storedSize
        self._mftype = refdata._mftype
        self._offset = offset
    }
    
    deinit {
        if !self._isView{
            func _deallocate<T: MfStorable>(_ type: T.Type){
                let dataptr = self._data.bindMemory(to: T.self, capacity: self._storedSize)
                dataptr.deinitialize(count: self._storedSize)
                dataptr.deallocate()
            }
            switch self._storedType {
            case .Float:
                _deallocate(Float.self)
            case .Double:
                _deallocate(Double.self)
            }
            //self._data.deallocate()
        }
        self.__refdata = nil
    }
}

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

//row major order
//breadth-first search
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

//column major order
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
