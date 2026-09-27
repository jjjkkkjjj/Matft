//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

/// Element-wise comparison operator between an mfarray and a scalar
internal enum MfCompareOp{
    case greater, greaterEqual, less, lessEqual, equal, notEqual
    
    /// The operator to use when the operands are swapped, i.e. `s op a` == `a op.flipped s`
    var flipped: MfCompareOp{
        switch self {
        case .greater: return .less
        case .greaterEqual: return .lessEqual
        case .less: return .greater
        case .lessEqual: return .greaterEqual
        case .equal, .notEqual: return self
        }
    }
}

/// Compare mfarray's elements with a scalar. The scalar is converted into the mfarray's stored type.
/// - Parameters:
///   - mfarray: An input mfarray
///   - op: The comparison operator
///   - scalar: The right-hand scalar
/// - Returns: Bool mfarray
internal func compare_mfarray<U: MfTypable>(_ mfarray: MfArray, _ op: MfCompareOp, _ scalar: U) -> MfArray{
    switch mfarray.storedType {
    case .Float:
        guard mfarray.isReal else {
            return compare_complex_mfarray(mfarray, Matft.nums(Float.from(scalar), shape: mfarray.shape), op)
        }
        return compare_by_vDSP(mfarray, op, Float.from(scalar))
    case .Double:
        guard mfarray.isReal else {
            return compare_complex_mfarray(mfarray, Matft.nums(Double.from(scalar), shape: mfarray.shape), op)
        }
        return compare_by_vDSP(mfarray, op, Double.from(scalar))
    }
}

/// Compare complex elements like numpy: `==` and `!=` compare both parts, and the others are lexicographic,
/// i.e. the real parts decide unless they are equal (and then the imaginary parts decide). Like numpy, the real parts decide only when neither imaginary part is NaN.
/// A real operand has 0 imaginary part.
/// - Parameters:
///   - l_mfarray: The left operand
///   - r_mfarray: The right operand of the same shape as `l_mfarray`
///   - op: The comparison operator
/// - Returns: Bool mfarray in row major order
internal func compare_complex_mfarray(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ op: MfCompareOp) -> MfArray{
    assert(l_mfarray.shape == r_mfarray.shape, "call biop_broadcast_to first!")
    switch MfType.storedType(MfType.priority(l_mfarray.mftype, r_mfarray.mftype)){
    case .Float:
        return _compare_complex(l_mfarray, r_mfarray, op, Float.self)
    case .Double:
        return _compare_complex(l_mfarray, r_mfarray, op, Double.self)
    }
}

fileprivate func _compare_complex<T: MfStorable & BinaryFloatingPoint>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ op: MfCompareOp, _ type: T.Type) -> MfArray{
    let mftype: MfType = T.self == Float.self ? .Float : .Double
    let size = l_mfarray.size
    // the real and imaginary parts as row major arrays of T
    func parts(_ mfarray: MfArray) -> (re: [T], im: [T]){
        func values(_ part: MfArray?) -> [T]{
            guard let part = part else { return [T](repeating: T.zero, count: size) }
            let row = part.astype(mftype, mforder: .Row)
            return row.withUnsafeMutableStartPointer(datatype: T.self){ Array(UnsafeBufferPointer(start: $0, count: size)) }
        }
        return (values(mfarray.real), values(mfarray.imag))
    }
    let (lre, lim) = parts(l_mfarray)
    let (rre, rim) = parts(r_mfarray)
    
    func compare(_ i: Int) -> Bool{
        let (xr, xi, yr, yi) = (lre[i], lim[i], rre[i], rim[i])
        // numpy's CEQ, CNE, CLT, CLE, CGT and CGE
        let ordered = !xi.isNaN && !yi.isNaN
        switch op{
        case .equal: return xr == yr && xi == yi
        case .notEqual: return xr != yr || xi != yi
        case .less: return (xr < yr && ordered) || (xr == yr && xi < yi)
        case .lessEqual: return (xr < yr && ordered) || (xr == yr && xi <= yi)
        case .greater: return (xr > yr && ordered) || (xr == yr && xi > yi)
        case .greaterEqual: return (xr > yr && ordered) || (xr == yr && xi >= yi)
        }
    }
    
    let newdata = MfData(uninitializedSize: size, mftype: .Bool)
    newdata.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptr in
        for i in 0..<size{
            dstptr[i] = compare(i) ? 1 : 0
        }
    }
    return MfArray(mfdata: newdata, mfstructure: MfStructure(shape: l_mfarray.shape, mforder: .Row))
}

/// Recompute the elements of `ret` = op(l, r) where l or r is NaN or ±inf.
/// vDSP_vmax / vDSP_vmin drop NaN and `l - r` of the same infinities is NaN, whereas numpy propagates NaN and treats inf == inf.
/// The other elements are kept, so the whole array is visited only when an operand has a non-finite value.
/// - Parameters:
///   - l_mfarray: The left operand broadcast to the shape of `ret`
///   - r_mfarray: The right operand broadcast to the shape of `ret`
///   - ret: The result of the vDSP operation
///   - op: The correct result of an element
/// - Returns: `ret`, or a row contiguous copy of it with the non-finite elements recomputed
internal func fix_nonfinite_elements<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ ret: MfArray, datatype: T.Type, _ op: (T, T) -> T) -> MfArray{
    guard _has_nonfinite(l_mfarray, T.self) || _has_nonfinite(r_mfarray, T.self) else{
        return ret
    }
    let l = l_mfarray.to_contiguous(mforder: .Row)
    let r = r_mfarray.to_contiguous(mforder: .Row)
    let ret = ret.to_contiguous(mforder: .Row)
    let size = ret.size
    l.withUnsafeMutableStartPointer(datatype: T.self){
        lptr in
        r.withUnsafeMutableStartPointer(datatype: T.self){
            rptr in
            ret.withUnsafeMutableStartPointer(datatype: T.self){
                dstptr in
                for i in 0..<size where !lptr[i].isFinite || !rptr[i].isFinite{
                    dstptr[i] = op(lptr[i], rptr[i])
                }
            }
        }
    }
    return ret
}

/// Recompute the NaN elements of `ret` = op(l, r) by vDSP.
/// On x86_64, vDSP_vdiv / vDSP_svdiv of Float return NaN for x / ±0 and 1 / ±inf instead of ±inf and ±0.
/// - Parameters:
///   - l_mfarray: The left operand broadcast to the shape of `ret`
///   - r_mfarray: The right operand broadcast to the shape of `ret`
///   - ret: The result of the vDSP operation
///   - op: The correct result of an element
/// - Returns: `ret`, or a row contiguous copy of it with the NaN elements recomputed
internal func fix_nan_elements<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ ret: MfArray, datatype: T.Type, _ op: (T, T) -> T) -> MfArray{
    guard _has_nonfinite(ret, T.self) else{
        return ret
    }
    let l = l_mfarray.to_contiguous(mforder: .Row)
    let r = r_mfarray.to_contiguous(mforder: .Row)
    let ret = ret.to_contiguous(mforder: .Row)
    let size = ret.size
    l.withUnsafeMutableStartPointer(datatype: T.self){
        lptr in
        r.withUnsafeMutableStartPointer(datatype: T.self){
            rptr in
            ret.withUnsafeMutableStartPointer(datatype: T.self){
                dstptr in
                for i in 0..<size where dstptr[i].isNaN{
                    dstptr[i] = op(lptr[i], rptr[i])
                }
            }
        }
    }
    return ret
}

/// Whether the stored data (including the elements outside of a view) has NaN or ±inf. The sum of them is not finite
fileprivate func _has_nonfinite<T: MfStorable>(_ mfarray: MfArray, _ type: T.Type) -> Bool{
    let size = mfarray.mfdata.storedSize
    guard size > 0 else { return false }
    #if canImport(Accelerate)
    let n = vDSP_Length(size)
    #else
    let n = size // the fallbacks in vDSP.swift take Int
    #endif
    if T.self == Float.self{
        let ptr = mfarray.mfdata.data_real.bindMemory(to: Float.self, capacity: size)
        var sum = Float.zero
        vDSP_sve(ptr, 1, &sum, n)
        return !sum.isFinite
    }
    else{
        let ptr = mfarray.mfdata.data_real.bindMemory(to: Double.self, capacity: size)
        var sum = Double.zero
        vDSP_sveD(ptr, 1, &sum, n)
        return !sum.isFinite
    }
}

internal func to_Bool(_ mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray{
    return compare_mfarray(mfarray, .notEqual, 0)
}

internal func to_IBool(_ mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray{
    return compare_mfarray(mfarray, .equal, 0)
}

/*
internal func to_Bool_mm_op<U: MfStorable>(l_mfarray: MfArray, r_mfarray: MfArray, op: (U, U) -> Bool) -> MfArray{
    assert(l_mfarray.shape == r_mfarray.shape, "call biop_broadcast_to first!")
    var retShape = l_mfarray.shape
    var i = 0
    let newdata = withDummyDataMRPtr(.Bool, storedSize: l_mfarray.size){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: Float.self, capacity: l_mfarray.size)
        withDataMBPtr_multi(datatype: U.self, l_mfarray, r_mfarray){
            lptr, rptr in
            var val = op(lptr.baseAddress!.pointee, rptr.baseAddress!.pointee) ? Float(1) : Float.zero
            (dstptrT + i).update(from: &val, count: 1)
            i += 1
        }
    }
    let newstructure = create_mfstructure(&retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
internal func to_Bool_ms_op<U: MfStorable>(l_mfarray: MfArray, r_scalar: U, op: (U, U) -> Bool) -> MfArray{
    let r_scalar = Float.from(r_scalar)
    let ret = l_mfarray.astype(.Float)
    ret.withDataUnsafeMBPtrT(datatype: Float.self){
        [unowned ret] (dataptr) in
        var newptr = dataptr.map{ $0 > r_scalar ? Float.zero : Float(1) }
        newptr.withUnsafeMutableBufferPointer{
            dataptr.baseAddress!.moveUpdate(from: $0.baseAddress!, count: ret.storedSize)
        }
    }
    ret.mfdata._mftype = .Bool
    return ret
}
internal func to_Bool_sm_op<U: MfStorable>(l_scalar: U, r_mfarray: MfArray, op: (U, U) -> Bool) -> MfArray{
    var retShape = r_mfarray.shape
    var i = 0
    let newdata = withDummyDataMRPtr(.Bool, storedSize: r_mfarray.size){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: Float.self, capacity: r_mfarray.size)
        r_mfarray.withContiguousDataUnsafeMPtrT(datatype: U.self){
            rptr in
            var val = op(l_scalar, rptr.pointee) ? Float(1) : Float.zero
            (dstptrT + i).update(from: &val, count: 1)
            i += 1
        }
    }
    let newstructure = create_mfstructure(&retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
*/
/**
   - Important: this function creates copy bool mfarray, not view!
 */
internal func bool_broadcast_to(_ mfarray: MfArray, shape: [Int]) -> MfArray{
    assert(mfarray.mftype == .Bool, "must be bool")
    var mfarray = mfarray
    
    let origSize = mfarray.size
    
    let new_ndim = shape.count
    var retShape = shape
    let retSize = shape2size(&retShape)
    
    
    let idim_start = new_ndim  - mfarray.ndim
    
    precondition(idim_start >= 0, "can't broadcast to fewer dimensions")
    
    // broadcast for common part's shape
    let commonShape = Array(shape[0..<mfarray.ndim])
    mfarray = mfarray.broadcast_to(shape: commonShape)
    
    // convert row contiguous
    let rowc_mfarray = check_contiguous(mfarray, .Row)

    if idim_start == 0{
        return rowc_mfarray
    }
    var newerShape = Array(shape[mfarray.ndim..<new_ndim])
    let offset = shape2size(&newerShape)
    
    let newdata = MfData(uninitializedSize: retSize, mftype: .Bool)

    newdata.withUnsafeMutableStartPointer(datatype: Float.self){
        dstptrF in
        var dstptrF = dstptrF
        rowc_mfarray.withUnsafeMutableStartPointer(datatype: Float.self){
            srcptr in
            for i in 0..<origSize{
                dstptrF.update(repeating: (srcptr + i).pointee, count: offset)
                dstptrF += offset
            }
        }
    }
    
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func boolean2float(_ mfarray: MfArray) -> MfArray{
    if mfarray.mftype == .Bool{
        mfarray.mfdata.mftype = .Float
    }
    return mfarray
}
