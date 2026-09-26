//
//  File 2.swift
//  
//
//  Created by AM19A0 on 2020/05/20.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

extension Matft{
    /**
       Element-wise negativity
       - parameters:
           - mfarray: mfarray
    */
    public static func neg(_ mfarray: MfArray) -> MfArray{
        return wrap_integer_overflow(_prefix_operation(mfarray, .neg))
    }
    
    /**
       Element-wise Not mfarray. Returned mfarray will be bool
       - parameters:
           - mfarray: mfarray
    */
    public static func logical_not(_ mfarray: MfArray) -> MfArray{
        #if canImport(Accelerate)
        if mfarray.mftype == .Bool && mfarray.isReal{
            // Bool is stored as 1/0 in Float, so not x = 1 - x in one pass
            return biopvs_by_vDSP(mfarray, Float(1)){
                srcptr, srcStride, one, dstptr, dstStride, n in
                var minus_one = Float(-1)
                vDSP_vsmsa(srcptr, srcStride, &minus_one, one, dstptr, dstStride, n)
            }
        }
        #endif
        // not x == (x == 0)
        return to_IBool(mfarray)
    }
}

fileprivate enum PreOp{
    case neg
}

#if canImport(Accelerate)
fileprivate func _prefix_operation(_ mfarray: MfArray, _ preop: PreOp) -> MfArray{
    switch preop {
    case .neg:
        if mfarray.isReal{
            switch mfarray.storedType{
            case .Float:
                return preop_by_vDSP(mfarray, vDSP_vneg)
            case .Double:
                return preop_by_vDSP(mfarray, vDSP_vnegD)
            }
        }
        else{
            switch mfarray.storedType{
            case .Float:
                return zpreop_by_vDSP(mfarray, vDSP_zvneg)
            case .Double:
                return zpreop_by_vDSP(mfarray, vDSP_zvnegD)
            }
        }
    }
}
#else
fileprivate func _prefix_operation(_ mfarray: MfArray, _ preop: PreOp) -> MfArray{
    let mfarray = check_dense(mfarray)
    let size = mfarray.storedSize
    let newdata = MfData(uninitializedSize: size, mftype: mfarray.mftype, complex: mfarray.isComplex)

    switch preop {
    case .neg:
        switch mfarray.storedType {
        case .Float:
            newdata.withUnsafeMutableStartPointer(datatype: Float.self) { dstptr in
                mfarray.withUnsafeMutableStartPointer(datatype: Float.self) { srcptr in
                    for i in 0..<size {
                        dstptr[i] = -srcptr[i]
                    }
                }
            }
            if mfarray.isComplex {
                newdata.withUnsafeMutableStartImagPointer(datatype: Float.self) { dstptr in
                    mfarray.withUnsafeMutableStartImagPointer(datatype: Float.self) { srcptr in
                        if let dstptr = dstptr, let srcptr = srcptr {
                            for i in 0..<size {
                                dstptr[i] = -srcptr[i]
                            }
                        }
                    }
                }
            }
        case .Double:
            newdata.withUnsafeMutableStartPointer(datatype: Double.self) { dstptr in
                mfarray.withUnsafeMutableStartPointer(datatype: Double.self) { srcptr in
                    for i in 0..<size {
                        dstptr[i] = -srcptr[i]
                    }
                }
            }
            if mfarray.isComplex {
                newdata.withUnsafeMutableStartImagPointer(datatype: Double.self) { dstptr in
                    mfarray.withUnsafeMutableStartImagPointer(datatype: Double.self) { srcptr in
                        if let dstptr = dstptr, let srcptr = srcptr {
                            for i in 0..<size {
                                dstptr[i] = -srcptr[i]
                            }
                        }
                    }
                }
            }
        }
    }

    let newstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    return MfArray(mfdata: newdata, mfstructure: newstructure)
}
#endif
