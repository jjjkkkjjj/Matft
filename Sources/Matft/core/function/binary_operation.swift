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
    public static func add(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(rettype){
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
    public static func add<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func add<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func sub(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(rettype){
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
    public static func sub<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func sub<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func mul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(rettype){
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
    public static func mul<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func mul<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func div(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let (l_mfarray, r_mfarray, rettype) = biop_broadcast_to(l_mfarray, r_mfarray)
        switch MfType.storedType(rettype){
        case .Float:
            let ret = biop_vv_by_vDSP(l_mfarray, r_mfarray, vDSP_func: vDSP_vdiv)
            ret.mfdata._mftype = .Float
            return ret
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
    public static func div<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let r_mfype = MfType.mftype(value: r_scalar)
        let retmftype = MfType.priority(l_mfarray.mftype, r_mfype)
        
        var l_mfarray = l_mfarray
        if retmftype != l_mfarray.mftype{
            l_mfarray = l_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func div<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let l_mfype = MfType.mftype(value: l_scalar)
        let retmftype = MfType.priority(l_mfype, r_mfarray.mftype)
        
        var r_mfarray = r_mfarray
        if retmftype != r_mfarray.mftype{
            r_mfarray = r_mfarray.astype(retmftype)
        }
        
        switch MfType.storedType(retmftype) {
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
    public static func matmul(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _matmul_operation(l_mfarray, r_mfarray)
    }
    
    /**
       Inner product
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func inner(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _inner_operation(l_mfarray, r_mfarray)
    }
    /**
       Cross product
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func cross(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return _cross_operation(l_mfarray, r_mfarray)
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
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return _equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1]))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return _equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray)
    }
    
    /**
        Check NOT equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_mfarray: right mfarray
    */
    public static func not_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        return Matft.logical_not(_equal_operation(l_mfarray, r_mfarray))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func not_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        return Matft.logical_not(_equal_operation(l_mfarray, Matft.nums(r_scalar, shape: [1])))
    }
    /**
        Check equality in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func not_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        return Matft.logical_not(_equal_operation(Matft.nums(l_scalar, shape: [1]), r_mfarray))
    }
    
    /**
        Check left mfarray's elements are less than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func less(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left mfarray's elements are less than right scalar in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func less<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let diff = r_scalar - l_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left scalar is less than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func less<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_scalar
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left mfarray's elements are less equal than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func less_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_mfarray
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left mfarray's elements are less equal than right scalar in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func less_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let diff = r_scalar - l_mfarray
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left scalar is less equal than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func less_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = r_mfarray - l_scalar
        return to_Bool(diff.sign() + Float(1))
    }
    
    /**
        Check left mfarray's elements are greater than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func greater(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_mfarray - r_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left scalar is greater than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func greater<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        /* too slow, average is 0.03s...
        switch l_mfarray.storedType {
        case .Float:
            return to_Bool_ms_op(l_mfarray: l_mfarray, r_scalar: Float.from(r_scalar), op: >)
        case .Double:
            return to_Bool_ms_op(l_mfarray: l_mfarray, r_scalar: Double.from(r_scalar), op: >)
        }
        */
        let diff = l_mfarray - r_scalar
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left scalar is greater than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func greater<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_scalar - r_mfarray
        return to_Bool(diff.clip(min: 0, max: nil))
    }
    /**
        Check left mfarray's elements are greater equal than right ones in element-wise. Returned mfarray's type will be bool.
        - parameters:
            - l_mfarray: left mfarray
            - r_mfarray: right mfarray
     */
    public static func greater_equal(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_mfarray - r_mfarray
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left scalar is greater equal than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_mfarray: left mfarray
           - r_scalar: right scalar conformed to MfTypable
    */
    public static func greater_equal<T: MfTypable>(_ l_mfarray: MfArray, _ r_scalar: T) -> MfArray{
        let diff = l_mfarray - r_scalar
        return to_Bool(diff.sign() + Float(1))
    }
    /**
        Check left scalar is greater equal than right mfarray's elements in element-wise. Returned mfarray's type will be bool.
       - parameters:
           - l_scalar: left scalar conformed to MfTypable
           - r_mfarray: right mfarray
    */
    public static func greater_equal<T: MfTypable>(_ l_scalar: T, _ r_mfarray: MfArray) -> MfArray{
        let diff = l_scalar - r_mfarray
        return to_Bool(diff.sign() + Float(1))
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
    
    
    //run
    switch MfType.storedType(lmfarray.mftype) {
    case .Float:
        return matmul_by_cblas(&lmfarray, &rmfarray, cblas_func: cblas_sgemm)
        
    case .Double:
        return matmul_by_cblas(&lmfarray, &rmfarray, cblas_func: cblas_dgemm)
    }
    
}

//Note that this function is slighly different from biobiop_broadcast_to for precondition and checked axis
//TODO: gather this function and biobiop_broadcast_to
fileprivate func _matmul_broadcast_to(_ lmfarray: inout MfArray, _ rmfarray: inout MfArray){
    var lshape = lmfarray.shape
    var lstrides = lmfarray.strides
    var rshape = rmfarray.shape
    var rstrides = rmfarray.strides
    
    precondition(lshape[lmfarray.ndim - 1] == rshape[rmfarray.ndim - 2], "Last 2 dimensions of the input mfarray must be lmfarray:(...,l,m) and rmfarray:(...,m,n)")
    
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


fileprivate func _cross_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
    var (l_mfarray, r_mfarray, rettype) = biop_broadcast_to(l_mfarray, r_mfarray)
    
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
        let ret = Matft.nums(0, shape: [l_mfarray.shape[0], lastdim], mftype: rettype)
        
        ret[0~<,0] = l_mfarray[0~<,1] * r_mfarray[0~<,2] - l_mfarray[0~<,2]*r_mfarray[0~<,1]
        ret[0~<,1] = l_mfarray[0~<,2] * r_mfarray[0~<,0] - l_mfarray[0~<,0]*r_mfarray[0~<,2]
        ret[0~<,2] = l_mfarray[0~<,0] * r_mfarray[0~<,1] - l_mfarray[0~<,1]*r_mfarray[0~<,0]
        
        return ret.reshape(orig_shape_for3d)
    }
    else{
        preconditionFailure("Last dimension must be 2 or 3")
    }
}

//uncompleted
fileprivate func _inner_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray) -> MfArray{
    let lastdim = l_mfarray.shape[l_mfarray.ndim - 1]
    precondition(lastdim == r_mfarray.shape[r_mfarray.ndim - 1], "Last dimension must be same")
    let retShape = Array(l_mfarray.shape.prefix(l_mfarray.ndim - 1) + r_mfarray.shape.prefix(r_mfarray.ndim - 1))
    let rettype = l_mfarray.mftype
    
    //convert shape to calculate
    let l_mfarray = l_mfarray.reshape([-1, lastdim])
    let l_calcsize = l_mfarray.shape[0]
    let r_mfarray = r_mfarray.reshape([-1, lastdim])
    let r_calcsize = r_mfarray.shape[0]
    
    let ret = Matft.nums(0, shape: [l_calcsize*r_calcsize], mftype: rettype)
    for lind in 0..<l_calcsize{
        for rind in 0..<r_calcsize{
            ret[lind*r_calcsize + rind] = (l_mfarray[lind] * r_mfarray[rind]).sum()
        }
    }
    
    return ret.reshape(retShape.count != 0 ? retShape : [1])
}



fileprivate func _equal_operation(_ l_mfarray: MfArray, _ r_mfarray: MfArray, thresholdF: Float = 1e-5, thresholdD: Double = 1e-10) -> MfArray{
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
    return !to_Bool(diff, thresholdF: thresholdF, thresholdD: thresholdD)
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
