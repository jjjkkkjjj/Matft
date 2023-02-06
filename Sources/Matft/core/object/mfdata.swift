//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

internal enum MfDataSource{
    case mfdata
    case mlshapedarray
}

public class MfData: MfDataProtocol{
    internal var _base: MfDataBasable? // must be referenced because refdata could be freed automatically?
    private var _fromOtherDataSource: Bool = false
    internal var data_real: UnsafeMutableRawPointer
    internal var data_imag: UnsafeMutableRawPointer?
    
    internal var mftype: MfType

    /// The size of the stored data
    internal var storedSize: Int
    
    /// Whether to be VIEW or not
    internal var _isView: Bool{
        return (self._base != nil || self._fromOtherDataSource)
    }
    
    /// Whether to be real or not
    internal var _isReal: Bool{
        return self.data_imag == nil
    }
    
    /// The offset value
    internal var offset: Int

    
    /// Initialization from flatten array. Allocate memories with stored type's size, which will store a given flatten array
    /// - Parameters:
    ///     - flattenArray: An input flatten array
    ///     - mftype: Type
    public init(flattenArray: inout [Any], mftype: MfType){
        switch MfType.storedType(mftype){
        case .Float:
            // dynamic allocation
            self.data_real = allocate_floatdata_from_flattenArray(&flattenArray, toBool: mftype == .Bool)
        case .Double:
            // dynamic allocation
            self.data_real = allocate_doubledata_from_flattenArray(&flattenArray, toBool: mftype == .Bool)
        }
        self.storedSize = flattenArray.count
        self.mftype = mftype
        self.offset = 0
    }
    
    /// Initialization from flatten array. Allocate memories with stored type's size, which will store a given flatten array
    /// - Parameters:
    ///     - flatten_realArray: An input flatten real array
    ///     - flatten_imagArray: An input flatten imag array
    ///     - mftype: Type
    public init(flatten_realArray: inout [Any], flatten_imagArray: inout [Any], mftype: MfType){
        precondition(flatten_realArray.count == flatten_imagArray.count, "Unsame flatten array between real: \(flatten_realArray.count) and imag: \(flatten_imagArray.count)")
        switch MfType.storedType(mftype){
        case .Float:
            // dynamic allocation
            self.data_real = allocate_floatdata_from_flattenArray(&flatten_realArray, toBool: mftype == .Bool)
            self.data_imag = allocate_floatdata_from_flattenArray(&flatten_imagArray, toBool: mftype == .Bool)
        case .Double:
            // dynamic allocation
            self.data_real = allocate_doubledata_from_flattenArray(&flatten_realArray, toBool: mftype == .Bool)
            self.data_imag = allocate_floatdata_from_flattenArray(&flatten_imagArray, toBool: mftype == .Bool)
        }
        self.storedSize = flatten_realArray.count
        self.mftype = mftype
        self.offset = 0
    }
    
    /// Pass a pointer directly.
    /// - Parameters:
    ///    - data_real_ptr: A real data pointer
    ///    - data_imag_ptr: A imag data pointer
    ///    - storedSize: A size
    ///    - mftype: Type
    /// - Important: The given dataptr will NOT be freed. So don't forget to free manually.
    internal init(source: MfDataBasable, data_real_ptr: UnsafeMutableRawPointer, data_imag_ptr: UnsafeMutableRawPointer? = nil, storedSize: Int, mftype: MfType, offset: Int){
        self._base = source
        self._fromOtherDataSource = true
        self.data_real = data_real_ptr
        self.data_imag = data_imag_ptr
        self.storedSize = storedSize
        self.mftype = mftype
        self.offset = offset
    }
    

    /// Create a zero padded MfData
    /// - Parameters:
    ///    - size: A size
    ///    - mftype: Type
    public init(size: Int, mftype: MfType, complex: Bool = false){
        // dynamic allocation
        switch MfType.storedType(mftype){
        case .Float:
            let ptrF = allocate_unsafeMPtrT(type: Float.self, count: size)
            self.data_real = UnsafeMutableRawPointer(ptrF)
            
            if complex{
                let ptriF = allocate_unsafeMPtrT(type: Float.self, count: size)
                self.data_imag = UnsafeMutableRawPointer(ptriF)
            }
            
        case .Double:
            let ptrD = allocate_unsafeMPtrT(type: Double.self, count: size)
            self.data_real = UnsafeMutableRawPointer(ptrD)
            
            if complex{
                let ptriD = allocate_unsafeMPtrT(type: Double.self, count: size)
                self.data_imag = UnsafeMutableRawPointer(ptriD)
            }
        }
        
        self.storedSize = size
        self.mftype = mftype
        self.offset = 0
    }
    
    /// Create a MfData with VIEW based on base mfdata
    /// - Parameters:
    ///   - refdata: The base mfdata
    ///   - offset: The offset value from base's data
    public init(refdata: MfData, offset: Int){
        self._base = refdata
        self.data_real = refdata.data_real
        self.data_imag = refdata.data_imag
        self.storedSize = refdata.storedSize
        self.mftype = refdata.mftype
        self.offset = offset
    }
    
    /// Create a MfData with VIEW based on base mfdata
    /// - Parameters:
    ///   - ref_realdata: The base real mfdata
    ///   - ref_imagdata: The base imag mfdata
    ///   - offset: The offset value from base's data
    public init(ref_realdata: MfData, ref_imagdata: MfData, offset: Int) {
        assert(ref_realdata.storedSize == ref_imagdata.storedSize, "Must have same size!")
        assert(ref_realdata.offset == ref_imagdata.offset, "Must have same offset!")
        assert(ref_realdata.mftype == ref_imagdata.mftype, "Must have same mftype!")
        
        let size = ref_realdata.storedSize
        let bytesize = ref_realdata.storedByteSize
        let datarptr, dataiptr: UnsafeMutableRawPointer
        switch ref_realdata.storedType{
        case .Float:
            datarptr = allocate_unsafeMRPtr(type: Float.self, count: size)
            dataiptr = allocate_unsafeMRPtr(type: Float.self, count: size)
            
        case .Double:
            datarptr = allocate_unsafeMRPtr(type: Double.self, count: size)
            dataiptr = allocate_unsafeMRPtr(type: Double.self, count: size)
        }
        
        memcpy(datarptr, ref_realdata.data_real + ref_realdata.byteOffset, bytesize)
        memcpy(dataiptr, ref_imagdata.data_real + ref_imagdata.byteOffset, bytesize)
        
        self.data_real = datarptr
        self.data_imag = dataiptr
        self.storedSize = size
        self.mftype = ref_realdata.mftype
        self.offset = 0
    }
    
    deinit {
        if !self._isView{
            func _deallocate<T: MfStorable>(_ type: T.Type){
                let dataptr = self.data_real.bindMemory(to: T.self, capacity: self.storedSize)
                dataptr.deinitialize(count: self.storedSize)
                dataptr.deallocate()
                
                if let data_img = self.data_imag{
                    let dataiptr = data_img.bindMemory(to: T.self, capacity: self.storedSize)
                    dataiptr.deinitialize(count: self.storedSize)
                    dataiptr.deallocate()
                }
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
internal func flatten_array(ptr: UnsafeBufferPointer<Any>, mforder: MfOrder) -> (flatten: [Any], shape: [Int]){
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
