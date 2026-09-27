//
//  mfarray.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
#if canImport(CoreML)
import CoreML
#endif

/// A multi-dimensional array, the counterpart of Numpy's `ndarray`.
///
/// An `MfArray` consists of an `MfData` (the memory buffer) and an `MfStructure` (shape and strides).
/// Slicing and some manipulation functions (e.g. `transpose`) return a *view* that shares the buffer
/// with the original array; the original array is kept in `base`.
///
/// ```swift
/// let a = MfArray([[[ -8,  -7,  -6,  -5],
///                   [ -4,  -3,  -2,  -1]],
///                  [[ 0,  1,  2,  3],
///                   [ 4,  5,  6,  7]]])   // mftype is inferred as .Int, shape is [2, 2, 4]
/// let f = MfArray([1, 2, 3], mftype: .Float)
/// let b = a[0~<, 1]                        // a[:, 1] in Numpy (a view)
/// let c = a + 1                            // element-wise arithmetic with broadcasting
/// ```
open class MfArray: MfArrayProtocol{
    /// The data storage type of `MfArray`.
    public typealias MFDATA = MfData
    /// The underlying data storage. For a view, it references the base array's buffer.
    public internal(set) var mfdata: MfData // Only setter is private
    /// The shape and strides of this array.
    public internal(set) var mfstructure: MfStructure

    /// The array this view was created from, or `nil` if this array owns its memory.
    /// Equivalent to `numpy.ndarray.base`.
    public internal(set) var base: MfArray?


    /// Creates an array from a (nested) Swift array. Equivalent to `numpy.array`.
    ///
    /// The data is always copied into a new buffer.
    ///
    /// ```swift
    /// let a = MfArray([[1, 2], [3, 4], [5, 6]])            // mftype .Int, shape [3, 2]
    /// let b = MfArray([1, 2, 3, 4], mftype: .Double, shape: [2, 2])
    /// ```
    /// - Parameters:
    ///    - array: A (nested) Swift array of scalars. All inner arrays at the same depth must have the same length.
    ///    - mftype: The element type. If `nil`, it is inferred from the elements (e.g. `Int` values give `.Int`).
    ///      `.Object` and `.None` are not supported.
    ///    - shape: The shape of the result. If `nil`, the shape of the nested array is used.
    ///      The size must equal the number of elements.
    ///    - mforder: The order in which the nested array is flattened and stored. Defaults to `.Row`.
    /// - Precondition: The product of `shape` must equal the number of elements.
    public init (_ array: [Any], mftype: MfType? = nil, shape: [Int]? = nil, mforder: MfOrder = .Row) {
        
        var (flattenArray, shape_from_array) = array.withUnsafeBufferPointer{
            flatten_array(ptr: $0, mforder: mforder)
        }
    
        if mftype == .Object || mftype == .None{
            //print(flatten)
            preconditionFailure("Matft does not support Object and None. Shape was \(shape_from_array)")
        }
        // an empty nested array has no values to infer the type from, but its Swift element type is kept (e.g. [[], []] as [[Float]])
        let mftype_from_array = (flattenArray.isEmpty ? _mftype_of_empty_nested(array) : nil) ?? get_mftype(&flattenArray)
        let mftype = mftype ?? mftype_from_array
        
        // set mfdata and mfstructure
        var shape = shape ?? shape_from_array
        precondition(shape2size(&shape) == flattenArray.count, "Invalid shape, size must be \(flattenArray.count), but got \(shape2size(&shape))")
        
        self.mfdata = MfData(flattenArray: &flattenArray, mftype: mftype)
        self.mfstructure = MfStructure(shape: shape, mforder: mforder)

    }

    /// Creates an array from a flat Swift array of scalars. Same as `init(_:mftype:shape:mforder:)` with `[Any]`,
    /// except that the default `mftype` comes from the element type, so that an empty array keeps it too
    /// (e.g. `MfArray([] as [Int], shape: [3, 0])` is `.Int` like `np.array([], dtype=int)`).
    public convenience init<T: MfTypable>(_ array: [T], mftype: MfType? = nil, shape: [Int]? = nil, mforder: MfOrder = .Row) {
        self.init(array as [Any], mftype: mftype ?? MfType.mftype(value: T.zero), shape: shape, mforder: mforder)
    }
    
    /// Creates a complex array from real and imaginary parts. Either `real` or `imag` must be given.
    ///
    /// If only one part is given, the other part is filled with zeros.
    /// If both are given, they are broadcast to the same shape and converted to a common type if needed.
    /// - Parameters:
    ///    - real: The real part, which must be a real array, or `nil` for zeros.
    ///    - imag: The imaginary part, which must be a real array, or `nil` for zeros.
    ///    - mftype: The element type when both parts are given. If `nil`, the higher-priority type of the two parts is used.
    ///      Ignored when only one part is given.
    ///    - mforder: Currently unused.
    /// - Precondition: `real` and `imag` must be real arrays and at least one of them must be non-nil.
    public init(real: MfArray?, imag: MfArray?, mftype: MfType? = nil,  mforder: MfOrder = .Row){
        let realmfdata: MFDATA
        let imagmfdata: MFDATA
        let shape: [Int]
        let strides: [Int]
        if let real = real, let imag = imag{// complex
            precondition(real.isReal, "Argument: real must be real")
            precondition(imag.isReal, "Argument: imag must be real")
            
            let (real, imag) = _check_same_structure(real, imag, mftype: mftype)
            realmfdata = real.mfdata
            imagmfdata = imag.mfdata
            shape = real.shape
            strides = real.strides
        }
        else if let real = real {
            precondition(real.isReal, "Argument: real must be real")
            
            realmfdata = real.mfdata
            imagmfdata = MFDATA(size: real.storedSize, mftype: real.mftype)
            shape = real.shape
            strides = real.strides
        }
        else if let imag = imag {
            precondition(imag.isReal, "Argument: imag must be real")
            
            imagmfdata = imag.mfdata
            realmfdata = MFDATA(size: imag.storedSize, mftype: imag.mftype)
            shape = imag.shape
            strides = imag.strides
        }
        else{
            preconditionFailure("Either real or imag must be given.")
        }
        
        self.mfdata = MFDATA(ref_realdata: realmfdata, ref_imagdata: imagmfdata, offset: realmfdata.offset)
        self.mfstructure = MfStructure(shape: shape, strides: strides)
    }
    
    /// Creates an array directly from its data storage and structure. The data is not copied.
    /// - Parameters:
    ///    - mfdata: The data storage.
    ///    - mfstructure: The shape and strides. They must be consistent with `mfdata`.
    public init (mfdata: MfData, mfstructure: MfStructure){
        self.mfdata = mfdata
        self.mfstructure = mfstructure
    }
    
    /// Creates a view of another array that shares its memory.
    /// - Parameters:
    ///    - base: The array whose memory is shared. It is stored in `base`.
    ///    - mfstructure: The shape and strides of the view.
    ///    - offset: The element offset of the view's first element within the base's buffer.
    public init (base: MfArray, mfstructure: MfStructure, offset: Int){
        self.base = base
        self.mfdata = MfData(refdata: base.mfdata, offset: offset)
        self.mfstructure = mfstructure//mfstructure will be copied because mfstructure is struct
    }
    
    #if canImport(CoreML)
    /// Creates an array from a Core ML `MLMultiArray`, either sharing or copying its memory.
    ///
    /// The shape and strides of the `MLMultiArray` are kept. When sharing, the `MLMultiArray` is retained
    /// by the returned array's data, but `base` stays `nil`.
    /// - Parameters:
    ///    - base: The source `MLMultiArray`. Its data type must be `.float` or `.double`.
    ///    - share: Whether to share the memory (`true`, default) or copy it (`false`).
    /// - Precondition: `base.dataType` must be `.float` or `.double` (in both share and copy modes).
    @available(macOS 12.0, *)
    @available(iOS 14.0, *)
    public init (base: inout MLMultiArray, share: Bool = true){
        precondition([MLMultiArrayDataType.float, MLMultiArrayDataType.double].contains(base.dataType), "Must be float or double in share mode")
        // note that base is not assigned here!
        let mftype = MfType.mftype(value: base.dataType)
        let mfdata = MfData(source: share ? base : nil, data_real_ptr: base.dataPointer, storedSize: base.count, mftype: mftype, offset: 0)

        self.mfdata = mfdata
        self.mfstructure = MfStructure(shape: base.shape.map{ Int(truncating: $0) }, strides: base.strides.map{ Int(truncating: $0) })
    }
    #endif

    deinit {
        self.base = nil
        //self.mfdata.free()
        //self.mfstructure.free()
    }
}


extension MfArray{
    //mfdata getter
    //return base's data
    /// The raw stored elements, converted to the Swift type of `mftype`.
    ///
    /// This returns the whole underlying buffer in storage order (for a view, the base array's buffer),
    /// not the elements of this array in logical order. Use `toArray()` to get the logical elements.
    public var data: [Any]{
        if let base = self.base{
            return base.data
        }
        else{
            return self.withUnsafeMutableStartRawPointer{
                [unowned self] in
                data2flattenArray($0, mftype: self.mftype, size: self.storedSize)
            }
        }
    }
    /// The raw stored real parts. Alias for `data`.
    public var data_real: [Any]{
        return self.data
    }
    /// The raw stored imaginary parts converted to the Swift type of `mftype`, or `nil` for a real array.
    ///
    /// Like `data`, this is the whole underlying buffer in storage order.
    public var data_imag: [Any]?{
        if self.mfdata._isReal{
            return nil
        }
        
        if let base = self.base{
            return base.data_imag
        }
        else{
            return self.withUnsafeMutableStartRawImagPointer{
                [unowned self] in
                data2flattenArray($0!, mftype: self.mftype, size: self.storedSize)
            }
        }
    }
    
    /// The raw stored real parts as `Float` or `Double` values (the stored type), without converting to `mftype`.
    ///
    /// Like `data`, this is the whole underlying buffer in storage order.
    public var storedData: [Any]{
        if let base = self.base{
            return base.storedData
        }
        else{
            switch self.storedType {
            case .Float:
                return self.withUnsafeMutableStartPointer(datatype: Float.self){
                    Array(UnsafeMutableBufferPointer(start: $0, count: self.storedSize)) as [Any]
                }
            case .Double:
                return self.withUnsafeMutableStartPointer(datatype: Double.self){
                    Array(UnsafeMutableBufferPointer(start: $0, count: self.storedSize)) as [Any]
                }
            }
        }
    }
    
    /// The real part. Equivalent to `numpy.ndarray.real`.
    ///
    /// For a real array this returns `self`; for a complex array it returns a view that shares the real buffer.
    public var real: MfArray{
        if self.mfdata._isReal{
            return self
        }
        else{
            let mfdata = MfData(source: self.mfdata, data_real_ptr: self.mfdata.data_real, storedSize: self.mfdata.storedSize, mftype: self.mfdata.mftype, offset: self.mfdata.offset)
            return MfArray(mfdata: mfdata, mfstructure: self.mfstructure)
        }
    }
    /// The imaginary part as a view that shares the imaginary buffer, or `nil` for a real array.
    ///
    /// Unlike `numpy.ndarray.imag`, a real array returns `nil` instead of zeros.
    public var imag: MfArray?{
        if self.mfdata._isReal{
            return nil
        }
        else{
            let mfdata = MfData(source: self.mfdata, data_real_ptr: self.mfdata.data_imag!, storedSize: self.mfdata.storedSize, mftype: self.mfdata.mftype, offset: self.mfdata.offset)
            return MfArray(mfdata: mfdata, mfstructure: self.mfstructure)
        }
    }
    
    /// Whether the array has no imaginary part.
    public var isReal: Bool{
        return self.mfdata._isReal
    }
    /// Whether the array has an imaginary part.
    public var isComplex: Bool{
        return !self.mfdata._isReal
    }
    
    internal var mfdata_base: MfData{
        if self.isView{
            return self.base!.mfdata_base
        }
        else{
            return self.mfdata
        }
    }
}


fileprivate func _check_same_structure(_ real: MfArray, _ imag: MfArray, mftype: MfType?) -> (real: MfArray, imag: MfArray){
    
    var r: MfArray = real
    var i: MfArray = imag
    // check same shape
    if real.shape != imag.shape{
        let ret = biop_broadcast_to(real, imag)
        r = ret.l
        i = ret.r
    }
    
    let rettype = mftype ?? MfType.priority(r.mftype, i.mftype)
    if rettype != r.mftype{
        r = r.astype(rettype)
    }
    if rettype != i.mftype{
        i = i.astype(rettype)
    }
    
    // the stored data are copied from the offsets, so they must be dense (not views like `a[1~<2]` or `a[Matft.reverse]`) in the same layout
    (r, i) = check_same_dense_layout(r, i)
    
    assert((r.shape == i.shape) &&
         (r.strides == i.strides) &&
         (r.mftype == i.mftype) &&
         (r.storedSize == i.storedSize) &&
         (r.offsetIndex == 0 && i.offsetIndex == 0), "Not same structure")
    
    return (r, i)
}

/// The element type of an empty nested Swift array, e.g. `.Float` for `[[], []] as [[Float]]`.
/// `get_mftype` can't infer it from the (no) values, but each empty inner array keeps its Swift type
/// - Parameter array: The nested array
/// - Returns: The MfType of the innermost element type, or nil if it is unknown (e.g. `[] as [Any]`)
fileprivate func _mftype_of_empty_nested(_ array: [Any]) -> MfType?{
    var value: Any = array
    // down to the first empty inner array
    while let inner = value as? [Any], let first = inner.first{
        value = first
    }
    let elementTypes: [(Any.Type, MfType)] = [
        ([Bool].self, .Bool), ([UInt8].self, .UInt8), ([UInt16].self, .UInt16), ([UInt32].self, .UInt32), ([UInt64].self, .UInt64),
        ([UInt].self, .UInt), ([Int8].self, .Int8), ([Int16].self, .Int16), ([Int32].self, .Int32), ([Int64].self, .Int64),
        ([Int].self, .Int), ([Float].self, .Float), ([Double].self, .Double),
    ]
    let valueType = ObjectIdentifier(type(of: value))
    return elementTypes.first{ ObjectIdentifier($0.0) == valueType }?.1
}
