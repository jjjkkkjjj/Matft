//
//  bioperator.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft{
    //infix
    /**
       Element-wise addition of  two mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func add<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(T.self){
        case .Float:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vadd)
        case .Double:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vaddD)
        }
    }
    /**
       Element-wise addition of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func add<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{
        switch MfType.storedType(T.self) {
        case .Float:
            return biop_vs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsadd)
        case .Double:
            return biop_vs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsaddD)
        }
    }
    /**
       Element-wise addition of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func add<T: MfNumeric>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        switch MfType.storedType(T.self) {
        case .Float:
            return biop_vs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_vsadd)
        case .Double:
            return biop_vs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_vsaddD)
        }
    }
    /**
       Element-wise subtraction right mfarray from left mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func sub<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(T.self){
        case .Float:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsub)
        case .Double:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vsubD)
        }
    }
    /**
       Element-wise subtraction of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func sub<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{
        
        switch MfType.storedType(T.self) {
        case .Float:
            return biop_vs_by_vDSP(l_mfarray, -Float.from(r_scalar), vDSP_vsadd)
        case .Double:
            return biop_vs_by_vDSP(l_mfarray, -Double.from(r_scalar), vDSP_vsaddD)
        }
    }
    /**
       Element-wise subtraction of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func sub<T: MfNumeric>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        
        switch MfType.storedType(T.self) {
        case .Float:
            return biop_vs_by_vDSP(-r_mfarray, Float.from(l_scalar), vDSP_vsadd)
        case .Double:
            return biop_vs_by_vDSP(-r_mfarray, Double.from(l_scalar), vDSP_vsaddD)
        }
    }
    /**
       Element-wise multiplication of two mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func mul<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(T.self){
        case .Float:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmul)
        case .Double:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vmulD)
        }
    }
    /**
       Element-wise multiplication of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func mul<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{
        
        switch MfType.storedType(T.self) {
        case .Float:
            return biop_vs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsmul)
        case .Double:
            return biop_vs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsmulD)
        }
    }
    /**
       Element-wise multiplication of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func mul<T: MfNumeric>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        
        switch MfType.storedType(T.self) {
        case .Float:
            return biop_vs_by_vDSP(r_mfarray, Float.from(l_scalar), vDSP_vsmul)
        case .Double:
            return biop_vs_by_vDSP(r_mfarray, Double.from(l_scalar), vDSP_vsmulD)
        }
    }
    /**
       Element-wise division left mfarray by right mfarray
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func div<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        let (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(T.self){
        case .Float:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdiv)
        case .Double:
            return biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdivD)
        }
    }
    /**
       Element-wise division of  mfarray and scalar
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func div<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<T>{

        switch MfType.storedType(T.self) {
        case .Float:
            return biop_vs_by_vDSP(l_mfarray, Float.from(r_scalar), vDSP_vsdiv)
        case .Double:
            return biop_vs_by_vDSP(l_mfarray, Double.from(r_scalar), vDSP_vsdivD)
        }
    }
    /**
       Element-wise division of  mfarray and scalar
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func div<T: MfNumeric>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        
        switch MfType.storedType(T.self) {
        case .Float:
            return biop_sv_by_vDSP(Float.from(l_scalar), r_mfarray, vDSP_svdiv)
        case .Double:
            return biop_sv_by_vDSP(Double.from(l_scalar), r_mfarray, vDSP_svdivD)
        }
    }
    
    /**
       Matrix multiplication
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func matmul<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        return _matmul_operation(l_mfarray, r_mfarray)
    }
    
    /**
       Inner product
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    
    public static func inner<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        return _inner_operation(l_mfarray, r_mfarray)
    }
    /**
       Cross product
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func cross<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
        return _cross_operation(l_mfarray, r_mfarray)
    }
    
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func equal<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return _equal_operation(l_mfarray, r_mfarray)
    }
    public static func equal<T: MfBinary>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return _equal_operation(l_mfarray, r_mfarray)
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func equal<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        return _equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1]))
    }
    public static func equal<T: MfBinary>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        return _equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1]))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func equal<T: MfNumeric>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return _equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray)
    }
    public static func equal<T: MfBinary>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return _equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray)
    }
    
    /**
        Check NOT equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func not_equal<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return Matft.logical_not(_equal_operation(l_mfarray, r_mfarray))
    }
    public static func not_equal<T: MfBinary>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return Matft.logical_not(_equal_operation(l_mfarray, r_mfarray))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func not_equal<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        return Matft.logical_not(_equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1])))
    }
    public static func not_equal<T: MfBinary>(_ l_mfarray: MfArray<T>, _ r_scalar: T) -> MfArray<Bool>{
        return Matft.logical_not(_equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1])))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func not_equal<T: MfNumeric>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return Matft.logical_not(_equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray))
    }
    public static func not_equal<T: MfBinary>(_ l_scalar: T, _ r_mfarray: MfArray<T>) -> MfArray<Bool>{
        return Matft.logical_not(_equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray))
    }
    
    /**
        Check equality in element-wise, and then when all of elements are true, return true, otherwise false
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func allEqual<T: MfTypable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> Bool{
        return _equalAll_operation(l_mfarray, r_mfarray)
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
fileprivate func _matmul_operation<T: MfNumeric>(_ lmfarray: MfArray<T>, _ rmfarray: MfArray<T>) -> MfArray<T>{
    precondition(lmfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    precondition(rmfarray.ndim > 1, "cannot get an inverse matrix from 1-d mfarray")
    
    //preprocessing
    //type
    var lmfarray = lmfarray
    var rmfarray = rmfarray
    
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
    
    
    //run
    switch MfType.storedType(T.self) {
    case .Float:
        return matmul_by_cblas(&lmfarray, &rmfarray, cblas_func: cblas_sgemm)
        
    case .Double:
        return matmul_by_cblas(&lmfarray, &rmfarray, cblas_func: cblas_dgemm)
    }
    
}


fileprivate func _matmul_broadcast_to<T: MfNumeric>(_ lmfarray: inout MfArray<T>, _ rmfarray: inout MfArray<T>){
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

    let (l_mfstructure, r_mfstructure) = withDummy2ShapeStridesMBPtr(retndim){
        
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
                preconditionFailure("Broadcast error: cannot calculate matrix multiplication due to broadcasting error. hint: For all dim < ndim-2, left.shape[dim] or right.shape[dim] is one, or left.shape[dim] == right.shape[dim]")
            }
        }
    }
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: l_mfstructure._shape, count: l_mfstructure._ndim)))
    //print(Array<Int>(UnsafeBufferPointer<Int>(start: r_mfstructure._shape, count: r_mfstructure._ndim)))
    
    lmfarray = MfArray(base: lmfarray, mfstructure: l_mfstructure, offset: lmfarray.offsetIndex)
    rmfarray = MfArray(base: rmfarray, mfstructure: r_mfstructure, offset: rmfarray.offsetIndex)
}


fileprivate func _cross_operation<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
    var (l_mfarray, r_mfarray) = biop_broadcast_to(l_mfarray, r_mfarray)
    
    let orig_shape_for3d = l_mfarray.shape
    let lastdim = orig_shape_for3d[l_mfarray.ndim - 1]
    
    //convert shape to calculate
    l_mfarray = l_mfarray.reshape([-1, lastdim])
    r_mfarray = r_mfarray.reshape([-1, lastdim])

    if lastdim == 2{
        let ret = l_mfarray[0~<,0] * r_mfarray[0~<,1] - l_mfarray[0~<,1]*r_mfarray[0~<,0]
        return ret
    }
    else if lastdim == 3{
        let ret: MfArray<T> = Matft.nums(T.zero, shape: [l_mfarray.shape[0], lastdim])
        
        ret[0~<,0] = l_mfarray[0~<,1] * r_mfarray[0~<,2] - l_mfarray[0~<,2]*r_mfarray[0~<,1]
        ret[0~<,1] = l_mfarray[0~<,2] * r_mfarray[0~<,0] - l_mfarray[0~<,0]*r_mfarray[0~<,2]
        ret[0~<,2] = l_mfarray[0~<,0] * r_mfarray[0~<,1] - l_mfarray[0~<,1]*r_mfarray[0~<,0]
        
        return ret.reshape(orig_shape_for3d)
    }
    else{
        preconditionFailure("Last dimension must be 2 or 3")
    }
}


fileprivate func _inner_operation<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>) -> MfArray<T>{
    let lastdim = l_mfarray.shape[l_mfarray.ndim - 1]
    precondition(lastdim == r_mfarray.shape[r_mfarray.ndim - 1], "Last dimension must be same")
    let retShape = Array(l_mfarray.shape.prefix(l_mfarray.ndim - 1) + r_mfarray.shape.prefix(r_mfarray.ndim - 1))
    
    //convert shape to calculate
    let l_mfarray = l_mfarray.reshape([-1, lastdim])
    let l_calcsize = l_mfarray.shape[0]
    let r_mfarray = r_mfarray.reshape([-1, lastdim])
    let r_calcsize = r_mfarray.shape[0]
    
    let ret = Matft.nums(T.zero, shape: [l_calcsize*r_calcsize])
    for lind in 0..<l_calcsize{
        for rind in 0..<r_calcsize{
            ret[lind*r_calcsize + rind] = (l_mfarray[lind] * r_mfarray[rind]).sum()
        }
    }
    
    return ret.reshape(retShape.count != 0 ? retShape : [1])
}



fileprivate func _equal_operation<T: MfNumeric>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray<Bool>{
    let diff = l_mfarray - r_mfarray
    //print(diff)
    
    /*
    let diff = l_mfarray - r_mfarray
    print(diff)
    diff.withDataUnsafeMRPtr{
        dataptr in
        var bytes = UnsafeMutableRawBufferPointer(start: dataptr, count: diff.storedByteSize).map{ ~<$0 }
        bytes.withUnsafeMutableBufferPointer{
            dataptr.copyMemory(from: $0.baseAddress!, byteCount: diff.storedByteSize)
        }
    }
    print(diff)*/
    return to_NotBool(diff, thresholdF: thresholdF, thresholdD: thresholdD)
}
fileprivate func _equal_operation<T: MfBinary>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray<Bool>{
    let diff = l_mfarray.astype(Float.self) - r_mfarray.astype(Float.self)
    
    return to_NotBool(diff, thresholdF: thresholdF, thresholdD: thresholdD)
}

fileprivate func _equalAll_operation<T: MfTypable>(_ l_mfarray: MfArray<T>, _ r_mfarray: MfArray<T>, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> Bool{
   //print(diff)
    if l_mfarray.shape != r_mfarray.shape{
       return false
    }
    let (l, r) = biop_broadcast_to(l_mfarray, r_mfarray)
    let (l_mfarray, r_mfarray) = conv_order_biop(l, r)
    // for contiguous array
    // below example, l_mfarray is row contiguous
    // print(l_mfarray.data, r_mfarray.data)
    //>> [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31] [10, 11]
    let l_data = Array(l_mfarray.data[l_mfarray.offsetIndex..<l_mfarray.offsetIndex+l_mfarray.size])
    let r_data = Array(r_mfarray.data[r_mfarray.offsetIndex..<r_mfarray.offsetIndex+r_mfarray.size])

    switch l_mfarray.storedType {
    case .Float:
        if let l_data = l_data as? [Float], let r_data = r_data as? [Float]{
            return zip(l_data, r_data).allSatisfy{ abs($0 - $1) <= thresholdF }
        }
        //print(l_data, r_data)
        return zip(l_data, r_data).allSatisfy{ $0 == $1 }
        
    case .Double:
        if let l_data = l_data as? [Double], let r_data = r_data as? [Double]{
            return zip(l_data, r_data).allSatisfy{ abs($0 - $1) <= thresholdD }
        }
        return zip(l_data, r_data).allSatisfy{ $0 == $1 }
    }
}


