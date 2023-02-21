//
//  pocketFFT+wrapper.swift
//  
//
//  Created by AM19A0 on 2023/02/10.
//
import pocketFFT
import Accelerate

internal typealias rfft_func = (rfft_plan, UnsafeMutablePointer<Double>, Double) -> Int32

internal typealias cfft_func = (cfft_plan, UnsafeMutablePointer<Double>, Double) -> Int32

public func pocketFFT_execute(_ mfarray: MfArray, number: Int?, axis: Int, isForward: Bool, norm: FFTNorm) -> MfArray {
    precondition(number ?? 1 > 0, "Must pass number greater than 0")
    var src_mfarray: MfArray
    if let number = number {
        // extract
        src_mfarray = mfarray.moveaxis(src: axis, dst: 0)[0~<number].moveaxis(src: 0, dst: axis)
    }
    else{
        src_mfarray = mfarray
    }
    // convert double to use pocketFFT
    src_mfarray = src_mfarray.storedType == .Float ? src_mfarray.astype(.Double) : src_mfarray
    
    if src_mfarray.isReal {
        let norm = _get_forward_norm(number: src_mfarray.shape[src_mfarray.ndim-1], norm: norm)
        return execute_real_forward(src_mfarray, axis: axis, norm: norm)
    }
    else{
        fatalError("")
        //return execute_complex(src_mfarray, pocketFFT_func: isForward ? cfft_forward : cfft_backward)
    }
}


internal func execute_real_forward(_ mfarray: MfArray, axis: Int, norm: Double) -> MfArray{
    assert(mfarray.storedType == .Double, "must be stored as Double!")

    let axis = get_positive_axis(axis, ndim: mfarray.ndim)
    let mfarray = check_contiguous(mfarray.moveaxis(src: axis, dst: -1), .Row)
    
    // src
    var retShape = mfarray.shape
    let src_offset = retShape[retShape.count-1]
    
    // dst
    retShape[retShape.count-1] = retShape[retShape.count-1]/2+1
    let retSize = shape2size(&retShape)
    let dst_offset = retShape[retShape.count-1]*2 // for complex
    
    var restShape = Array(retShape.prefix(retShape.count-1))
    let loopnum = shape2size(&restShape)
    
    var dstarr = Array(repeating: Double.zero, count: retSize*2)
    mfarray.withUnsafeMutableStartRawPointer{
        _srcptr in
        var srcptr = _srcptr
        dstarr.withUnsafeMutableBufferPointer{
            _dstptr in
            var dstptr = _dstptr.baseAddress!
            
            let plan = make_rfft_plan(src_offset)
            
            /*if (Int(bitPattern: plan) != 1) {
                fatalError("Coudn't be ready for FFT")
            }*/
            
            for _ in 0..<loopnum{
                memcpy(dstptr+1, srcptr, src_offset*MemoryLayout<Double>.size)
                if (rfft_forward(plan, dstptr+1, norm) != 0){
                    fatalError("Failed to process FFT")
                }ここらへんから
                dstptr.pointee = (dstptr + 1).pointee
                (dstptr + 1).pointee = 0.0
                
                srcptr += src_offset
                dstptr += dst_offset
            }
        }
    }
    
    let newdata = MfData(size: retSize, mftype: .Double, complex: true)
    newdata.withUnsafeMutableStartPointer(datatype: Double.self){
        dstptr in
        dstarr.withUnsafeMutableBufferPointer{
            srcptr in
            wrap_cblas_copy(retSize, srcptr.baseAddress!, 2, dstptr, 1, cblas_dcopy)
        }
    }
    newdata.withUnsafeMutableStartImagPointer(datatype: Double.self){
        dstptr in
        dstarr.withUnsafeMutableBufferPointer{
            srcptr in
            wrap_cblas_copy(retSize, srcptr.baseAddress!, 2, dstptr!, 1, cblas_dcopy)
        }
    }
    
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}

internal func execute_complex(_ mfarray: MfArray, pocketFFT_func: cfft_func) -> MfArray{
    assert(mfarray.storedType == .Double, "must be stored as Double!")
    let mfarray = mfarray.to_complex()
    return mfarray
}


/// Get normalize value for forward process
/// - Parameters:
///   - number: The number of process
///   - norm: The normalize mode
/// - Returns: The value to be normalized
fileprivate func _get_forward_norm(number: Int, norm: FFTNorm) -> Double{
    switch norm{
    case .forward:
        return Double(1)
    case .ortho:
        return sqrt(Double(number))
    case .backward:
        return Double(number)
    }
}
