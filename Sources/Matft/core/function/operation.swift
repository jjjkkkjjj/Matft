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
    
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _equal_operation(l_mfarray, r_mfarray)
    }
    /**
        Check equality in element-wise, and then when all of elements are true, return true, otherwise false
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func allEqual(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> Bool{
        return _equalAll_operation(l_mfarray, r_mfarray)
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
    
    
    var l_mfarray = l_mfarray
    var r_mfarray = r_mfarray
    /*
    if l_mfarray.storedSize < r_mfarray.storedSize{
        l_mfarray = r_mfarray
        r_mfarray = l_mfarray
    }*/
    
    let rettype = MfType.priority(l_mfarray.mftype, r_mfarray.mftype)
    if l_mfarray.mftype != rettype{
        l_mfarray = l_mfarray.astype(rettype)
    }
    else if r_mfarray.mftype != rettype{
        r_mfarray = r_mfarray.astype(rettype)
    }
    
    do{
        if l_mfarray.size > r_mfarray.size{
            r_mfarray = try r_mfarray.broadcast_to(shape: l_mfarray.shape)
        }
        else if r_mfarray.size > l_mfarray.size{
            l_mfarray = try l_mfarray.broadcast_to(shape: r_mfarray.shape)
        }
        // below condition has same size implicitly
        // below condition cannot be deprecated into above condition because l.size > r.size & l.ndim < r.ndim is possible
        else if l_mfarray.ndim > r_mfarray.ndim{
            r_mfarray = try r_mfarray.broadcast_to(shape: l_mfarray.shape)
        }
        else if r_mfarray.ndim > l_mfarray.ndim{
            l_mfarray = try l_mfarray.broadcast_to(shape: r_mfarray.shape)
        }
    }catch {//conversion error
        fatalError("cannot calculate binary operation due to broadcasting error")
    }
    //print(l_mfarray)
    //print(r_mfarray)
    
    switch biop {
    case .add:
        switch MfType.storedType(rettype){
        case .Float:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vadd)
        case .Double:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vaddD)
        }
    case .sub:
        switch MfType.storedType(rettype){
        case .Float:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsub)
        case .Double:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsubD)
        }
    case .mul:
        switch MfType.storedType(rettype){
        case .Float:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmul)
        case .Double:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmulD)
        }
    case .div:
        switch MfType.storedType(rettype){
        case .Float:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdiv).astype(.Float)
        case .Double:
            return biop_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdivD)
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
    /*
    print(lmfarray.shape, lmfarray.strides)
    print(lmfarray.data)
    print(rmfarray.shape, rmfarray.strides)
    print(rmfarray.data)
    print(lmfarray)
    print(rmfarray)*/
    
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
                        matmul_by_cblas(retorder, lshape[retndim - 2], lshape[retndim - 1], lptr, rshape[retndim - 2], rshape[retndim - 1], rptr, dstptrF, cblas_sgemm)
                        
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
                        matmul_by_cblas(retorder, lshape[retndim - 2], lshape[retndim - 1], lptr, rshape[retndim - 2], rshape[retndim - 1], rptr, dstptrD, cblas_dgemm)
                        
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
    let retndim: Int
    
    if lmfarray.ndim < rmfarray.ndim{ // l has smaller dim
        retndim = rmfarray.ndim
        lshape = Array<Int>(repeating: 1, count: rmfarray.ndim - lmfarray.ndim) + lshape // the 1 concatenated elements means broadcastable
        lstrides = Array<Int>(repeating: 0, count: rmfarray.ndim - lmfarray.ndim) + lstrides// the 0 concatenated elements means broadcastable
    }
    else if lmfarray.ndim > rmfarray.ndim{// r has smaller dim
        retndim = lmfarray.ndim
        rshape = Array<Int>(repeating: 1, count: lmfarray.ndim - rmfarray.ndim) + rshape // the 1 concatenated elements means broadcastable
        rstrides = Array<Int>(repeating: 0, count: lmfarray.ndim - rmfarray.ndim) + rstrides// the 0 concatenated elements means broadcastable
    }
    else{
        retndim = lmfarray.ndim
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
        //print(Array<Int>(UnsafeBufferPointer<Int>(start: l_mfstructure._shape, count: l_mfstructure._ndim)))
        //print(Array<Int>(UnsafeBufferPointer<Int>(start: r_mfstructure._shape, count: r_mfstructure._ndim)))
        let l_mfdata = withDummyDataMRPtr(lmfarray.mftype, storedSize: lmfarray.storedSize){
            dstptr in
            lmfarray.withDataUnsafeMRPtr{
                [unowned lmfarray] (srcptr) in
                dstptr.copyMemory(from: srcptr, byteCount: lmfarray.storedByteSize)
            }
        }
        let r_mfdata = withDummyDataMRPtr(rmfarray.mftype, storedSize: rmfarray.storedSize){
            dstptr in
            rmfarray.withDataUnsafeMRPtr{
                [unowned rmfarray] (srcptr) in
                dstptr.copyMemory(from: srcptr, byteCount: rmfarray.storedByteSize)
            }
        }
        
        lmfarray = MfArray(base: lmfarray, mfstructure: l_mfstructure, offset: lmfarray.offsetIndex)
        rmfarray = MfArray(base: rmfarray, mfstructure: r_mfstructure, offset: rmfarray.offsetIndex)
    }
    catch{
        //conversion error
        fatalError("cannot calculate matrix multiplication due to broadcasting error. hint: For all dim < ndim-2, left.shape[dim] or right.shape[dim] is one, or left.shape[dim] == right.shape[dim]")
    }
}


fileprivate func _equal_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray{
    let diff = l_mfarray - r_mfarray
    //print(diff)
    
    switch diff.storedType {
    case .Float:
        diff.withDataUnsafeMBPtrT(datatype: Float.self){
            [unowned diff] (dataptr) in
            var newptr = dataptr.map{ abs($0) <= thresholdF ? Float(1) : Float.zero }
            newptr.withUnsafeMutableBufferPointer{
                dataptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: diff.storedSize)
            }
        }
    case .Double:
        diff.withDataUnsafeMBPtrT(datatype: Double.self){
            [unowned diff] (dataptr) in
            var newptr = dataptr.map{ abs($0) <= thresholdD ? Double(1) : Double.zero }
            newptr.withUnsafeMutableBufferPointer{
                dataptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: diff.storedSize)
            }
        }
    }
    
    /*
    let diff = l_mfarray - r_mfarray
    print(diff)
    diff.withDataUnsafeMRPtr{
        dataptr in
        var bytes = UnsafeMutableRawBufferPointer(start: dataptr, count: diff.storedByteSize).map{ ~$0 }
        bytes.withUnsafeMutableBufferPointer{
            dataptr.copyMemory(from: $0.baseAddress!, byteCount: diff.storedByteSize)
        }
    }
    print(diff)*/
    return diff.astype(.Bool)
}

fileprivate func _equalAll_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> Bool{
   //print(diff)
   if l_mfarray.shape != r_mfarray.shape{
       return false
   }
    let diff = l_mfarray - r_mfarray
    
    // diff must be 0 if all of elements are same
    switch diff.storedType {
    case .Float:
        if let data = diff.data as? [UInt8]{
            return data.allSatisfy{ $0 == UInt8.zero }
        }
        else if let data = diff.data as? [UInt16]{
            return data.allSatisfy{ $0 == UInt8.zero }
        }
        else if let data = diff.data as? [UInt32]{
            return data.allSatisfy{ $0 == UInt32.zero }
        }
        else if let data = diff.data as? [UInt64]{
            return data.allSatisfy{ $0 == UInt64.zero }
        }
        else if let data = diff.data as? [UInt]{
            return data.allSatisfy{ $0 == UInt.zero }
        }
        else if let data = diff.data as? [Int8]{
            return data.allSatisfy{ $0 == Int8.zero }
        }
        else if let data = diff.data as? [Int16]{
            return data.allSatisfy{ $0 == Int16.zero }
        }
        else if let data = diff.data as? [Int32]{
            return data.allSatisfy{ $0 == Int32.zero }
        }
        else if let data = diff.data as? [Int64]{
            return data.allSatisfy{ $0 == Int64.zero }
        }
        else if let data = diff.data as? [Int]{
            return data.allSatisfy{ $0 == Int.zero }
        }
        else if let data = diff.data as? [Float]{
            return data.allSatisfy{ abs($0) <= thresholdF }
        }
        else{
            // bool
            guard let data = diff.astype(.Float).data as? [Float] else{
                return false
            }
            
            return data.allSatisfy{ $0 == Float.zero }
        }
    case .Double:
        if let data = diff.data as? [Double]{
            return data.allSatisfy{ abs($0) <= thresholdD }
        }
        else{
            return false
        }
    }
    
}
