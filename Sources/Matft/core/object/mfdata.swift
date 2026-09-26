//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

internal enum MfDataSource{
    case mfdata
    case mlshapedarray
}

/// The raw storage of an `MfArray`.
///
/// `MfData` owns (or references) the contiguous memory buffer holding the elements.
/// Every `MfType` is stored as either `Float` or `Double` (see `MfType.storedType(_:)`);
/// complex arrays keep a second buffer for the imaginary part.
/// Several `MfArray` views can share the same `MfData`.
///
/// - Note: You rarely need to use `MfData` directly; create arrays with `MfArray` initializers instead.
public class MfData: MfDataProtocol{
    internal var _base: MfDataBasable? // must be referenced because refdata could be freed automatically?
    internal var _fromOtherDataSource: Bool = false
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

    
    /// Creates real data by allocating a new buffer of the stored type and copying a flattened array into it.
    /// - Parameters:
    ///     - flattenArray: A flattened array of scalars. Each element is converted to the stored type of `mftype`.
    ///     - mftype: The logical type of the data. When `.Bool`, non-zero values are stored as 1.
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
    
    /// Creates complex data by allocating new real and imaginary buffers and copying the flattened arrays into them.
    /// - Parameters:
    ///     - flatten_realArray: A flattened array of the real parts.
    ///     - flatten_imagArray: A flattened array of the imaginary parts. Must have the same count as `flatten_realArray`.
    ///     - mftype: The logical type of the data.
    /// - Precondition: `flatten_realArray.count == flatten_imagArray.count`.
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
            self.data_imag = allocate_doubledata_from_flattenArray(&flatten_imagArray, toBool: mftype == .Bool)
        }
        self.storedSize = flatten_realArray.count
        self.mftype = mftype
        self.offset = 0
    }
    
    /// Creates data from raw pointers, either sharing or copying the memory.
    /// - Parameters:
    ///    - source: The object that owns the memory. If `nil`, the pointed memory is COPIED into a newly allocated buffer;
    ///      otherwise the pointers are SHARED and `source` is retained to keep the memory alive.
    ///    - data_real_ptr: A pointer to the real part, laid out as the stored type of `mftype` (`Float` or `Double`).
    ///    - data_imag_ptr: A pointer to the imaginary part, or `nil` for real data.
    ///    - storedSize: The number of stored elements.
    ///    - mftype: The logical type of the data.
    ///    - offset: The element offset of the first element within the buffer.
    /// - Important: The given pointers will NOT be freed in SHARE mode. So don't forget to free them manually.
    public init(source: MfDataBasable?, data_real_ptr: UnsafeMutableRawPointer, data_imag_ptr: UnsafeMutableRawPointer? = nil, storedSize: Int, mftype: MfType, offset: Int){
        self._base = source
        self._fromOtherDataSource = source != nil
        self.storedSize = storedSize
        self.mftype = mftype
        self.offset = offset
        
        if self._fromOtherDataSource{
            self.data_real = data_real_ptr
            self.data_imag = data_imag_ptr
        }
        else{
            switch MfType.storedType(mftype) {
            case .Float:
                self.data_real = allocate_unsafeMRPtr(type: Float.self, count: storedSize, zeroed: false)
                memcpy(self.data_real, data_real_ptr, self.storedByteSize)
                
                if let data_imag_ptr = data_imag_ptr{
                    self.data_imag = allocate_unsafeMRPtr(type: Float.self, count: storedSize, zeroed: false)
                    memcpy(self.data_imag!, data_imag_ptr, self.storedByteSize)
                }
                else{
                    self.data_imag = nil
                }
            case .Double:
                self.data_real = allocate_unsafeMRPtr(type: Double.self, count: storedSize, zeroed: false)
                memcpy(self.data_real, data_real_ptr, self.storedByteSize)

                if let data_imag_ptr = data_imag_ptr{
                    self.data_imag = allocate_unsafeMRPtr(type: Double.self, count: storedSize, zeroed: false)
                    memcpy(self.data_imag!, data_imag_ptr, self.storedByteSize)
                }
                else{
                    self.data_imag = nil
                }
            }
            
        }
        
    }

    #if DEBUG
    /// Fill buffers allocated by `init(uninitializedSize:)` with NaN to detect elements that a kernel never writes. For tests only
    internal static var _poisonUninitialized = false
    #endif
    
    /// Creates zero-filled data.
    /// - Parameters:
    ///    - size: The number of stored elements.
    ///    - mftype: The logical type of the data.
    ///    - complex: Whether to also allocate a (zero-filled) imaginary buffer. Defaults to `false`.
    public convenience init(size: Int, mftype: MfType, complex: Bool = false){
        self.init(size: size, mftype: mftype, complex: complex, zeroed: true)
    }
    
    /// Create a MfData without initializing its elements. The caller must write every element
    /// - Parameters:
    ///    - uninitializedSize: A size
    ///    - mftype: Type
    internal convenience init(uninitializedSize size: Int, mftype: MfType, complex: Bool = false){
        self.init(size: size, mftype: mftype, complex: complex, zeroed: false)
    }
    
    private init(size: Int, mftype: MfType, complex: Bool, zeroed: Bool){
        // dynamic allocation
        switch MfType.storedType(mftype){
        case .Float:
            self.data_real = allocate_unsafeMRPtr(type: Float.self, count: size, zeroed: zeroed)
            if complex{
                self.data_imag = allocate_unsafeMRPtr(type: Float.self, count: size, zeroed: zeroed)
            }
            
        case .Double:
            self.data_real = allocate_unsafeMRPtr(type: Double.self, count: size, zeroed: zeroed)
            if complex{
                self.data_imag = allocate_unsafeMRPtr(type: Double.self, count: size, zeroed: zeroed)
            }
        }
        
        self.storedSize = size
        self.mftype = mftype
        self.offset = 0
    }
    
    /// Creates a view that shares the buffers of another `MfData`.
    /// - Parameters:
    ///   - refdata: The base data whose memory is shared.
    ///   - offset: The element offset from the start of the base's buffer.
    public init(refdata: MfData, offset: Int){
        self._base = refdata
        self.data_real = refdata.data_real
        self.data_imag = refdata.data_imag
        self.storedSize = refdata.storedSize
        self.mftype = refdata.mftype
        self.offset = offset
    }
    
    /// Creates complex data by COPYING the real parts from one `MfData` and the imaginary parts from another.
    ///
    /// Despite the `ref_` labels, the result does not share memory: new buffers are allocated and
    /// the whole stored data (`storedSize` elements from the beginning) of each source is copied.
    /// - Parameters:
    ///   - ref_realdata: The data providing the real parts (its real buffer is used).
    ///   - ref_imagdata: The data providing the imaginary parts (its real buffer is used).
    ///   - offset: The offset of the result, usually `ref_realdata.offset`.
    /// - Precondition: Both sources must have the same stored size, offset and `mftype` (checked only in debug builds).
    public init(ref_realdata: MfData, ref_imagdata: MfData, offset: Int) {
        assert(ref_realdata.storedSize == ref_imagdata.storedSize, "Must have same size!")
        assert(ref_realdata.offset == ref_imagdata.offset, "Must have same offset!")
        assert(ref_realdata.mftype == ref_imagdata.mftype, "Must have same mftype!")
        
        let size = ref_realdata.storedSize
        let bytesize = ref_realdata.storedByteSize
        let datarptr, dataiptr: UnsafeMutableRawPointer
        switch ref_realdata.storedType{
        case .Float:
            datarptr = allocate_unsafeMRPtr(type: Float.self, count: size, zeroed: false)
            dataiptr = allocate_unsafeMRPtr(type: Float.self, count: size, zeroed: false)
            
        case .Double:
            datarptr = allocate_unsafeMRPtr(type: Double.self, count: size, zeroed: false)
            dataiptr = allocate_unsafeMRPtr(type: Double.self, count: size, zeroed: false)
        }
        
        // copy the whole stored data and keep the offset. Copying `storedSize` elements from the offset would run past the end
        memcpy(datarptr, ref_realdata.data_real, bytesize)
        memcpy(dataiptr, ref_imagdata.data_real, bytesize)
        
        self.data_real = datarptr
        self.data_imag = dataiptr
        self.storedSize = size
        self.mftype = ref_realdata.mftype
        self.offset = offset
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

/// Get a flatten array with row major order from a given structured array. This function is using breadth-first search which is a recursive function
/// - Parameters:
///   - queue: An input structured array
///   - shape: An input-output shape. Input must be [queue.count], and final output is proper shape
/// - Returns: flatten array with row major order
fileprivate func _get_flatten_row_major(queue: inout [Any], shape: inout [Int]) -> [Any]{
    precondition(shape.count == 1, "shape must have only one element")
    var cnt = 0 // count up the number that value is extracted from queue for while statement, reset 0 when iteration number reaches size
    var size = queue.count
    var axis = 0//the axis in searching
    // the front of the queue. Advancing it instead of removeFirst keeps this O(n)
    var head = 0
    
    while head < queue.count {
        //get first element
        let elements = queue[head]
        
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
        head += 1
        
        if cnt == size{//reset count and forward next axis
            cnt = 0
            size *= shape[axis]
        }
    }
    
    return Array(queue[head...])
}

/// Get a flatten array with column major order from a given structured array. This function is a recursive function
/// - Parameters:
///   - queue: An input structured array
///   - shape: An input-output shape. Input must be [queue.count], and final output is proper shape
/// - Returns: flatten array with column major order
fileprivate func _get_flatten_column_major(queue: inout [Any], shape: inout [Int]) -> [Any]{
    //precondition(shape.count == 1, "shape must have only one element")
    var cnt = 0 // count up the number that value is extracted from queue for while statement, reset 0 when iteration number reaches size
    //var axis = 0//the axis in searching
    let dim = queue.count // given
    
    var objectFlag = false
    
    var newqueue: [Any] = []
    // the front of the queue. Advancing it instead of removeFirst keeps this O(n)
    var head = 0
    while head < queue.count{
        //get first element
        let elements = queue[head]
        
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
            return Array(queue[head...])
        }
        
        head += 1
    }
    
    if !objectFlag{
        //recurrsive
        return _get_flatten_column_major(queue: &newqueue, shape: &shape)
    }
    else{
        return newqueue
    }
}
