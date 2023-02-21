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


/// Run FFT by pocket FFT. Call c language codes.
/// - Parameters:
///   - mfarray: The source mfarray
///   - number: The number to be processed
///   - axis: The axis
///   - isForward: Whether to be forward or backward
///   - norm: The nomalization mode
/// - Returns: The FFT mfarray
public func fft_by_pocketFFT(_ mfarray: MfArray, number: Int?, axis: Int, isReal: Bool, isForward: Bool, norm: FFTNorm) -> MfArray {
    precondition(number ?? 1 > 0, "Must pass number greater than 0")
    let axis = get_positive_axis(axis, ndim: mfarray.ndim)
    let axisdim = mfarray.shape[axis]
    let number = number ?? axisdim
    
    var src_mfarray: MfArray
    if number < axisdim {
        // extract
        src_mfarray = mfarray.moveaxis(src: axis, dst: 0)[0~<number].moveaxis(src: 0, dst: axis)
    }
    else if number == axisdim{
        src_mfarray = mfarray
    }
    else{
        // zero padding
        var srcShape = mfarray.shape
        srcShape[axis] = number
        src_mfarray = Matft.nums(Double.zero, shape: srcShape)
        /*TODO: Use slice version
        let slices = srcShape.map{MfSlice(start: 0, to: $0, by: 1)}
        src_mfarray[slices] = mfarray*/
        src_mfarray.moveaxis(src: 0, dst: axis)[~<axisdim] = mfarray.moveaxis(src: 0, dst: axis)
        src_mfarray = src_mfarray.moveaxis(src: axis, dst: 0)
        
    }
    // convert double to use pocketFFT
    src_mfarray = src_mfarray.storedType == .Float ? src_mfarray.astype(.Double) : src_mfarray
    
    if isReal {
        if isForward{
            let norm_val = _get_forward_norm(number: number, norm: norm)
            return execute_real_forward(src_mfarray, axis: axis, norm: 1/norm_val)
        }
        else{
            let norm_val = _get_backward_norm(number: number, norm: norm)
            return execute_real_backward(src_mfarray, axis: axis, norm: 1/norm_val)
        }
    }
    else{
        fatalError("")
        //return execute_complex(src_mfarray, pocketFFT_func: isForward ? cfft_forward : cfft_backward)
    }
}


/// Execute real forward FFT by pocketFFT
/// - Parameters:
///   - mfarray: The source mfarray
///   - axis: The axis
///   - norm: The normalization value
/// - Returns: FFT mfarray
internal func execute_real_forward(_ mfarray: MfArray, axis: Int, norm: Double) -> MfArray{
    assert(mfarray.storedType == .Double, "must be stored as Double!")

    let axis = get_positive_axis(axis, ndim: mfarray.ndim)
    let mfarray = check_contiguous(mfarray.swapaxes(axis1: axis, axis2: -1), .Row)
    
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
    mfarray.withUnsafeMutableStartPointer(datatype: Double.self){
        _srcptr in
        var srcptr = _srcptr
        dstarr.withUnsafeMutableBufferPointer{
            _dstptr in
            var dstptr = _dstptr.baseAddress!
            
            let plan = make_rfft_plan(src_offset)
            
            if (plan == nil) {
                fatalError("Coudn't be ready for FFT")
            }
            
            for _ in 0..<loopnum{
                dstptr.advanced(by: dst_offset - 1).pointee = 0.0
                memcpy(dstptr+1, srcptr, src_offset*MemoryLayout<Double>.size)
                if (rfft_forward(plan, dstptr+1, norm) != 0){
                    fatalError("Failed to process FFT")
                }
                dstptr.pointee = (dstptr + 1).pointee
                (dstptr + 1).pointee = 0.0
                
                srcptr += src_offset
                dstptr += dst_offset
            }
            
            destroy_rfft_plan(plan)
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
            
            wrap_cblas_copy(retSize, srcptr.baseAddress! + 1, 2, dstptr!, 1, cblas_dcopy)
        }
    }
    
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure).swapaxes(axis1: -1, axis2: axis)
}


/// Execute real backward FFT by pocketFFT
/// - Parameters:
///   - mfarray: The source mfarray
///   - axis: The axis
///   - norm: The normalization value
/// - Returns: FFT mfarray
internal func execute_real_backward(_ mfarray: MfArray, axis: Int, norm: Double) -> MfArray{
    assert(mfarray.storedType == .Double, "must be stored as Double!")

    let axis = get_positive_axis(axis, ndim: mfarray.ndim)

    let mfarray = check_contiguous(mfarray.swapaxes(axis1: axis, axis2: -1), .Row)
    
    // src
    var retShape = mfarray.shape
    let src_offset = retShape[retShape.count-1]*2
    let src_size = mfarray.size
    
    // dst
    let retSize = shape2size(&retShape)
    let dst_offset = retShape[retShape.count-1] // for complex
    
    var restShape = Array(retShape.prefix(retShape.count-1))
    let loopnum = shape2size(&restShape)
    
    var srcarr = Array(repeating: Double.zero, count: src_size*2) // for complex
    
    mfarray.withUnsafeMutableStartPointer(datatype: Double.self){
        mfarrptr in
        srcarr.withUnsafeMutableBufferPointer{
            srcptr in
            wrap_cblas_copy(src_size, mfarrptr, 1, srcptr.baseAddress!, 2, cblas_dcopy)
        }
    }
    mfarray.withUnsafeMutableStartImagPointer(datatype: Double.self){
        mfarrptr in
        srcarr.withUnsafeMutableBufferPointer{
            srcptr in
            
            wrap_cblas_copy(src_size, mfarrptr!, 1, srcptr.baseAddress! + 1, 2, cblas_dcopy)
        }
    }
    
    let newdata = MfData(size: retSize, mftype: .Double)
    newdata.withUnsafeMutableStartPointer(datatype: Double.self){
        _dstptr in
        var dstptr = _dstptr
        srcarr.withUnsafeMutableBufferPointer{
            _srcptr in
            var srcptr = _srcptr.baseAddress!
            
            let plan = make_rfft_plan(dst_offset)
            
            if (plan == nil) {
                fatalError("Coudn't be ready for FFT")
            }
            
            for _ in 0..<loopnum{
                memcpy(dstptr+1, srcptr+2, (dst_offset-1)*MemoryLayout<Double>.size)
                dstptr.pointee = srcptr.pointee

                if (rfft_backward(plan, dstptr, norm) != 0){
                    fatalError("Failed to process FFT")
                }
                srcptr += src_offset
                dstptr += dst_offset
            }
            
            destroy_rfft_plan(plan)
        }
    }
    
    let newstructure = MfStructure(shape: retShape, mforder: .Row)
    
    return MfArray(mfdata: newdata, mfstructure: newstructure).swapaxes(axis1: -1, axis2: axis)
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
    case .backward:
        return Double(1)
    case .ortho:
        return sqrt(Double(number))
    case .forward:
        return Double(number)
    }
}

/// Get normalize value for backward process
/// - Parameters:
///   - number: The number of process
///   - norm: The normalize mode
/// - Returns: The value to be normalized
fileprivate func _get_backward_norm(number: Int, norm: FFTNorm) -> Double{
    switch norm{
    case .backward:
        return Double(number)
    case .ortho:
        return sqrt(Double(number))
    case .forward:
        return Double(1)
    }
}
