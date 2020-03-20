//
//  bioperator.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray{
    //infix
    /**
       Element-wise addition of  two mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func add(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _binary_operation(l_mfarray, r_mfarray, .add)
    }
    /**
       Element-wise subtraction right mfarray from left mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func sub(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _binary_operation(l_mfarray, r_mfarray, .sub)
    }
    /**
       Element-wise multiplication of two mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func mul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _binary_operation(l_mfarray, r_mfarray, .mul)
    }
    /**
       Element-wise division left mfarray by right mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func div(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _binary_operation(l_mfarray, r_mfarray, .div)
    }
    /**
       Matrix multiplication
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func matmul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _matmul_operation(l_mfarray, r_mfarray)
    }
    
    //prefix
    /**
       Element-wise negativity
       - parameters:
           - mfarray: mfarray
    */
    public static func neg(_ mfarray: MfArray) -> MfArray{
        return _prefix_operation(mfarray, .neg)
    }
}

fileprivate enum BiOp{
    case add
    case sub
    case mul
    case div
    case indot
    case outdot
}

fileprivate func _binary_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, _ biop: BiOp) -> MfArray{
    //precondition(l_mfarray.mftype == r_mfarray.mftype, "Two mfarray must be same mftype. but two mfarray having unsame mftype will be able to be calclulated in the future")
    
    
    var bigger_mfarray = l_mfarray
    var smaller_mfarray = r_mfarray
    if l_mfarray.storedSize < r_mfarray.storedSize{
        bigger_mfarray = r_mfarray
        smaller_mfarray = l_mfarray
    }
    
    if bigger_mfarray.mftype != smaller_mfarray.mftype{
        smaller_mfarray = smaller_mfarray.astype(bigger_mfarray.mftype)
    }
    
    if bigger_mfarray.shape != smaller_mfarray.shape{ // broadcast to bigger_mfarray
        do{
            smaller_mfarray = try smaller_mfarray.broadcast_to(shape: bigger_mfarray.shape)
        }catch {//conversion error
            fatalError("cannot calculate binary operation due to broadcasting error")
        }
    }
    //print(bigger_mfarray)
    //return mfarray must be either row or column major
    if smaller_mfarray.mfflags.column_contiguous{
        bigger_mfarray = Matft.mfarray.conv_order(bigger_mfarray, mforder: .Column)
    }
    else{
        bigger_mfarray = Matft.mfarray.conv_order(bigger_mfarray, mforder: .Row)
    }
    
    let calctype = bigger_mfarray.mftype
    switch biop {
    case .add:
        switch MfType.storedType(calctype){
        case .Float:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vadd)
        case .Double:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vaddD)
        }
    case .sub:
        switch MfType.storedType(calctype){
        case .Float:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vsub)
        case .Double:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vsubD)
        }
    case .mul:
        switch MfType.storedType(calctype){
        case .Float:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vmul)
        case .Double:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vmulD)
        }
    case .div:
        switch MfType.storedType(calctype){
        case .Float:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vdiv)
        case .Double:
            return biop_by_vDSP(bigger_mfarray, smaller_mfarray, vDSP_func: vDSP_vdivD)
        }
    default:
        fatalError()
        /*
    case .sub:
        
    case .mul:
        
    case .div:
        
    case .indot:
        
    case .outdot:*/
    }
}

fileprivate enum PreOp{
    case neg
}

fileprivate func _prefix_operation(_ mfarray: MfArray, _ preop: PreOp) -> MfArray{
    switch preop {
    case .neg:
        switch mfarray.storedType{
        case .Float:
            return preop_by_vDSP(mfarray, vDSP_vneg)
        case .Double:
            return preop_by_vDSP(mfarray, vDSP_vnegD)
        }
    }
}

/*
 >>> a = np.arange(100).reshape(10,2,5)
 >>> b = np.arange(135).reshape(5,3,9)
 >>> np.matmul(a,b)
 Traceback (most recent call last):
   File "<stdin>", line 1, in <module>
 ValueError: matmul: Input operand 1 has a mismatch in its core dimension 0, with gufunc signature (n?,k),(k,m?)->(n?,m?) (size 3 is different from 5)
 
 >>> a = np.arange(100).reshape(10,2,5)
 >>> b = np.arange(135).reshape(3,5,9)
 >>> np.matmul(a,b)
 Traceback (most recent call last):
   File "<stdin>", line 1, in <module>
 ValueError: operands could not be broadcast together with remapped shapes [original->remapped]: (10,2,5)->(10,newaxis,newaxis) (3,5,9)->(3,newaxis,newaxis) and requested shape (2,9)
 
 For N dimensions it is a sum product over the last axis of a and the second-to-last of b:
 
 >>> a = np.arange(2 * 2 * 4).reshape((2, 2, 4))
 >>> b = np.arange(2 * 2 * 4).reshape((2, 4, 2))
 >>> np.matmul(a,b).shape
 (2, 2, 2)
 >>> np.matmul(a, b)[0, 1, 1]
 98
 >>> sum(a[0, 1, :] * b[0 , :, 1])
 98
 
 
 //nice reference: https://stackoverflow.com/questions/34142485/difference-between-numpy-dot-and-python-3-5-matrix-multiplication
>>>From the above two definitions, you can see the requirements to use those two operations. Assume a.shape=(s1,s2,s3,s4) and b.shape=(t1,t2,t3,t4)

To use dot(a,b) you need
    t3=s4;

To use matmul(a,b) you need
    t3=s4
    t2=s2, or one of t2 and s2 is 1 // <- for broadcast
    t1=s1, or one of t1 and s1 is 1 // <- for broadcast

 */

//very dirty code....
fileprivate func _matmul_operation(_ lmfarray: MfArray, _ rmfarray: MfArray) -> MfArray{
    precondition(lmfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(rmfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    
    //preprocessing
    //type
    var lmfarray = lmfarray
    var rmfarray = rmfarray
    if lmfarray.mftype != rmfarray.mftype{
        let returnedType = MfType.priority(lmfarray.mftype, rmfarray.mftype)
        if returnedType != lmfarray.mftype{
            lmfarray = lmfarray.astype(returnedType)
        }
        else{
            rmfarray = rmfarray.astype(returnedType)
        }
    }
    
    
    
    // order
    // must be row or column major
    //let retorder = _matmul_convorder(&lmfarray, &rmfarray)
    
    //broadcast
    _matmul_broadcast_to(&lmfarray, &rmfarray)
    
    let lshape = lmfarray.shape
    let rshape = rmfarray.shape
    var retshape = lmfarray.shape
    let retndim = retshape.count
    retshape[retndim - 1] = rshape[retndim - 1]
    
    // order
    // must be row column major
    let retorder = _matmul_convorder(&lmfarray, &rmfarray)
    
    let newmfstructure = withDummyShapeStridesMBPtr(retndim){
        shapeptr, stridesptr in
        //move
        retshape.withUnsafeMutableBufferPointer{
            shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
        }
        //move
        let newstrides = shape2strides(shapeptr, mforder: retorder)
        stridesptr.baseAddress!.moveAssign(from: newstrides.baseAddress!, count: retndim)
        //free
        newstrides.deallocate()
    }
    

    let matNum = lshape[retndim - 2] * rshape[retndim - 1]
    let l_matNum = lshape[retndim - 2] * lshape[retndim - 1]
    let r_matNum = rshape[retndim - 2] * rshape[retndim - 1]
    let iterNum = newmfstructure._size / matNum
    //run
    switch MfType.storedType(lmfarray.mftype) {
    case .Float:
        let newmfdata = withDummyDataMRPtr(lmfarray.mftype, storedSize: newmfstructure._size){
            dstptr in
            var dstptrF = dstptr.bindMemory(to: Float.self, capacity: newmfstructure._size)
            lmfarray.withDataUnsafeMBPtrT(datatype: Float.self){
                lptr in
                var lptr = lptr.baseAddress!
                rmfarray.withDataUnsafeMBPtrT(datatype: Float.self){
                    rptr in
                    var rptr = rptr.baseAddress!
                    
                    for _ in 0..<iterNum{
                        matmul_by_cblas(retorder, lshape[retndim - 2], lshape[retndim - 1], lptr, rshape[retndim - 2], rshape[retndim - 1], rptr, dstptrF, Float(1), Float(0), cblas_sgemm)
                        
                        lptr += l_matNum
                        rptr += r_matNum
                        dstptrF += matNum
                    }
                }
            }
        }
        
        return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
        
    case .Double:
        let newmfdata = withDummyDataMRPtr(lmfarray.mftype, storedSize: newmfstructure._size){
            dstptr in
            var dstptrD = dstptr.bindMemory(to: Double.self, capacity: newmfstructure._size)
            lmfarray.withDataUnsafeMBPtrT(datatype: Double.self){
                lptr in
                var lptr = lptr.baseAddress!
                
                rmfarray.withDataUnsafeMBPtrT(datatype: Double.self){
                    rptr in
                    var rptr = rptr.baseAddress!
                    
                    for _ in 0..<iterNum{
                        matmul_by_cblas(retorder, lshape[retndim - 2], lshape[retndim - 1], lptr, rshape[retndim - 2], rshape[retndim - 1], rptr, dstptrD, Double(1), Double(0), cblas_dgemm)
                        
                        lptr += l_matNum
                        rptr += r_matNum
                        dstptrD += matNum
                    }
                }
            }
        }
        
        return MfArray(mfdata: newmfdata, mfstructure: newmfstructure)
    }
    
}


fileprivate func _matmul_convorder(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray) -> MfOrder{
    // order
    /*
    // must be close to either row or column major
    var retorder = MfOrder.Row
    if !(lmfarray.mfflags.column_contiguous && rmfarray.mfflags.column_contiguous) || lmfarray.mfflags.row_contiguous && rmfarray.mfflags.row_contiguous{//convert either row or column major
        if lmfarray.mfflags.column_contiguous{
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Column)
            retorder = .Column
        }
        else if lmfarray.mfflags.row_contiguous{
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Row)
            retorder = .Row
        }
        else if rmfarray.mfflags.column_contiguous{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Column)
            retorder = .Column
        }
        else if rmfarray.mfflags.row_contiguous{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Row)
            retorder = .Row
        }
        else{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Row)
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Row)
            retorder = .Row
        }
    }
    else{
        retorder = lmfarray.mfflags.row_contiguous ? .Row : .Column
    }*/
    let retorder = MfOrder.Row
    if !(lmfarray.mfflags.row_contiguous && rmfarray.mfflags.row_contiguous){//convert row major
        if !rmfarray.mfflags.row_contiguous{
            rmfarray = Matft.mfarray.conv_order(rmfarray, mforder: .Row)
        }
        if !lmfarray.mfflags.row_contiguous{
            lmfarray = Matft.mfarray.conv_order(lmfarray, mforder: .Row)
        }
    }
    return retorder
}

fileprivate func _matmul_broadcast_to(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray){
    var lshape = lmfarray.shape
    var lstrides = lmfarray.strides
    var rshape = rmfarray.shape
    var rstrides = rmfarray.strides
    
    precondition(lshape[lmfarray.ndim - 1] == rshape[rmfarray.ndim - 2], "Last 2 dimensions of the mfarray must be square")
    
    // broadcast
    var retndim = lmfarray.ndim
    
    if lmfarray.ndim > rmfarray.ndim{ // r has smaller dim
        lshape = Array<Int>(repeating: 1, count: lmfarray.ndim - rmfarray.ndim) + lshape // the 1 concatenated elements means broadcastable
        lstrides = Array<Int>(repeating: 0, count: lmfarray.ndim - rmfarray.ndim) + lstrides// the 0 concatenated elements means broadcastable
    }
    else if lmfarray.ndim < rmfarray.ndim{// r has smaller dim
        retndim = rmfarray.ndim
        rshape = Array<Int>(repeating: 1, count: lmfarray.ndim - rmfarray.ndim) + rshape // the 1 concatenated elements means broadcastable
        rstrides = Array<Int>(repeating: 0, count: lmfarray.ndim - rmfarray.ndim) + rstrides// the 0 concatenated elements means broadcastable
    }

    do{
        let (l_mfstructure, r_mfstructure) = try withDummy2ShapeStridesMBPtr(retndim){
            
            l_shapeptr, l_stridesptr, r_shapeptr, r_stridesptr in
            //move
            lshape.withUnsafeMutableBufferPointer{
                l_shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
            }
            lstrides.withUnsafeMutableBufferPointer{
                l_stridesptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
            }
            rshape.withUnsafeMutableBufferPointer{
                r_shapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
            }
            rstrides.withUnsafeMutableBufferPointer{
                r_stridesptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: retndim)
            }
            
            
            for axis in (0..<retndim-2).reversed(){
                if l_shapeptr[axis] == r_shapeptr[axis]{
                    continue
                }
                else if l_shapeptr[axis] == 1{
                    l_shapeptr[axis] = r_shapeptr[axis] // aligned to r
                    l_stridesptr[axis] = 0 // broad casted 0
                }
                else if r_shapeptr[axis] == 1{
                    r_shapeptr[axis] = l_shapeptr[axis] // aligned to l
                    r_stridesptr[axis] = 0 // broad casted 0
                }
                else{
                    throw MfError.conversionError("Broadcast error")
                }
            }
        }
        let l_mfdata = withDummyDataMRPtr(lmfarray.mftype, storedSize: lmfarray.storedSize){
            dstptr in
            lmfarray.withDataUnsafeMRPtr{
                srcptr in
                dstptr.copyMemory(from: srcptr, byteCount: lmfarray.storedByteSize)
            }
        }
        let r_mfdata = withDummyDataMRPtr(rmfarray.mftype, storedSize: rmfarray.storedSize){
            dstptr in
            rmfarray.withDataUnsafeMRPtr{
                srcptr in
                dstptr.copyMemory(from: srcptr, byteCount: rmfarray.storedByteSize)
            }
        }
        
        lmfarray = MfArray(mfdata: l_mfdata, mfstructure: l_mfstructure)
        rmfarray = MfArray(mfdata: r_mfdata, mfstructure: r_mfstructure)
    }
    catch{
        //conversion error
        fatalError("cannot calculate matrix multiplication due to broadcasting error. hint: For all dim < ndim-2, left.shape[dim] or right.shape[dim] is one, or left.shape[dim] == right.shape[dim]")
    }
}
