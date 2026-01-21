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
        return _prefix_operation(mfarray, .neg)
    }
    
    /**
       Element-wise Not mfarray. Returned mfarray will be bool
       - parameters:
           - mfarray: mfarray
    */
    public static func logical_not(_ mfarray: MfArray) -> MfArray{
        var ret = to_Bool(mfarray)// copy and convert to bool
        #if canImport(Accelerate)
        ret = Matft.math.abs(ret - 1) // force cast to Float
        #else
        // Pure Swift fallback for abs(ret - 1)
        let size = ret.storedSize
        let newdata = MfData(size: size, mftype: .Bool)
        newdata.withUnsafeMutableStartPointer(datatype: Float.self) { dstptr in
            ret.withUnsafeMutableStartPointer(datatype: Float.self) { srcptr in
                for i in 0..<size {
                    dstptr[i] = Swift.abs(srcptr[i] - 1)
                }
            }
        }
        ret = MfArray(mfdata: newdata, mfstructure: MfStructure(shape: ret.shape, strides: ret.strides))
        #endif
        ret.mfdata.mftype = .Bool
        return ret
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
    let mfarray = check_contiguous(mfarray)
    let size = mfarray.storedSize
    let newdata = MfData(size: size, mftype: mfarray.mftype, complex: mfarray.isComplex)

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
