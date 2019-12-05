//
//  Operation.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/19.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray{
    //basic vector calculation
    public static func add<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
        return self._mfarray_simple_operation(operator_: MfOperation.add, left: left, right: right)
    }
    public static func sub<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
        return self._mfarray_simple_operation(operator_: MfOperation.sub, left: left, right: right)
    }
    public static func mul<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
        return self._mfarray_simple_operation(operator_: MfOperation.mul, left: left, right: right)
    }
    public static func div<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
        return self._mfarray_simple_operation(operator_: MfOperation.div, left: left, right: right)
    }
    //standard vector calculation
    //broadcast
    //add
    public static func add<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
        let newRight = Matft.mfarray.nums(num: T.num(right), type: T.self, shape: left.shape, order: left.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.add, left: left, right: newRight)
    }
    public static func add<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
        let newLeft = Matft.mfarray.nums(num: T.num(left), type: T.self, shape: right.shape, order: right.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.add, left: newLeft, right: right)
    }
    //substract
    public static func sub<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
        let newRight = Matft.mfarray.nums(num: T.num(right), type: T.self, shape: left.shape, order: left.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.sub, left: left, right: newRight)
    }
    public static func sub<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
        let newLeft = Matft.mfarray.nums(num: T.num(left), type: T.self, shape: right.shape, order: right.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.sub, left: newLeft, right: right)
    }
    //multiply
    //Note that this operation is Hadamard Product
    public static func mul<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
        let newRight = Matft.mfarray.nums(num: T.num(right), type: T.self, shape: left.shape, order: left.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.mul, left: left, right: newRight)
    }
    public static func mul<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
        let newLeft = Matft.mfarray.nums(num: T.num(left), type: T.self, shape: right.shape, order: right.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.mul, left: newLeft, right: right)
    }
    //divide
    public static func div<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
        let newRight = Matft.mfarray.nums(num: T.num(right), type: T.self, shape: left.shape, order: left.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.div, left: left, right: newRight)
    }
    public static func div<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
        let newLeft = Matft.mfarray.nums(num: T.num(left), type: T.self, shape: right.shape, order: right.order.rawValue)
        return self._mfarray_simple_operation(operator_: MfOperation.div, left: newLeft, right: right)
    }
    
    //function for addition, substruction, multiplication and division
    private static func _mfarray_simple_operation<T: MfNumeric>(operator_: MfOperation, left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
        var left_ = left
        var right_ = right
        if left.shape != right.shape{//check broadcastable
            (left_, right_) = _check_broadcastable_and_get_broadcastedMfArray(left, right)
            //fatalError("mfarray cannot support broadcast operation, i will implement this function in the future")
        }
        
        let new = Matft.mfarray.nums(num: 0, type: T.self, shape: left.shape)

        switch operator_ {
        case MfOperation.add:
            //vDSP_vaddD(left.data, vDSP_Stride(1), right.data, vDSP_Stride(1), new.data, vDSP_Stride(1), vDSP_Length(left.size))
            return vDSP_infix(left_, right_, vDSP_vaddD)
            
            /*
             for index in 0..<left.size{
             (newDataPointer.baseAddress! + index).pointee = (leftData + index).pointee + (rightData + index).pointee
             }*/
            /*
             //==========benchmark test============//
             //==========  test code  ============//
             let a = Matft.mfarray.nums(num: 1, type: Int.self, shape: [10000, 10000])
             let b = a + a
             //===================================//
             
             var start = Date()
             for index in 0..<left.size{
                (newDataPointer.baseAddress! + index).pointee = (leftData + index).pointee + (rightData + index).pointee
             }
             var elapsed = Date().timeIntervalSince(start)
             print(elapsed)
             //->8.035097002983093
             
             start = Date()
             let new = Matft.mfarray.nums(num: 0, type: Double.self, shape: left.shape)
             let l = left.astype(Double.self)
             let r = right.astype(Double.self)
             
             let lptr = l.data
             let rptr = r.data
             
             vDSP_vsaddD(lptr, 1, rptr, new.data, 1, vDSP_Length(left.size))
             elapsed = Date().timeIntervalSince(start)
             print(elapsed)
             //->75.21474194526672
             
             let arr = Matft.mfarray.nums(num: 1, type: Int.self, shape: [10000,10000])
             var start = Date()
             let a = arr + arr
             var elapsed = Date().timeIntervalSince(start)
             print(elapsed)
             //->0.6240320205688477
             
             numpy
             //->0.42232394218444824
             */
        case MfOperation.sub:
            vDSP_vsubD(left.data, vDSP_Stride(1), right.data, vDSP_Stride(1), new.data, vDSP_Stride(1), vDSP_Length(left.size))
            //return vDSP_infix(left_, right_, vDSP_vsubD)
        case MfOperation.mul:
            vDSP_vmulD(left.data, vDSP_Stride(1), right.data, vDSP_Stride(1), new.data, vDSP_Stride(1), vDSP_Length(left.size))
            //return vDSP_infix(left_, right_, vDSP_vmulD)
        case MfOperation.div:
            vDSP_vdivD(left.data, vDSP_Stride(1), right.data, vDSP_Stride(1), new.data, vDSP_Stride(1), vDSP_Length(left.size))
            //return vDSP_infix(left_, right_, vDSP_vdivD)
        default:
            precondition(false, "argument \'operator_\' was invalid")
        }
        
        return new
    }

    
    
    
    //matrix multiplication
    public static func dot<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
        return self._mfarray_multiplication(left: left, right: right)
    }
    public static func dot<T: MfNumeric>(left: MfArray<T>, right: T) -> MfArray<T>{
        return Matft.mfarray.mul(left: left, right: right)
    }
    public static func dot<T: MfNumeric>(left: T, right: MfArray<T>) -> MfArray<T>{
        return Matft.mfarray.mul(left: left, right: right)
    }
    private static func _mfarray_multiplication<T: MfNumeric>(left: MfArray<T>, right: MfArray<T>) -> MfArray<T>{
        precondition((left.ndim == right.ndim) && (left.ndim == 2), "cannot calculate mfarray which have more than 3-d")
        
        //thread implementation in the future
        //NPY_BEGIN_ALLOW_THREADS
        
        //bras parameter
        let Order = CblasRowMajor
        var Trans1 = CblasNoTrans
        var Trans2 = CblasNoTrans
        let M = left.shape[0]
        let N = right.shape[1]
        let K = right.shape[0]
        var lda = left.shape[1] > 1 ? left.shape[1] : 1
        var ldb = right.shape[1] > 1 ? right.shape[1] : 1
        
        let calculatedMfArray = Matft.mfarray.nums(num: 0, type: left.type, shape: [M, N])
        
        let leftPointer = left.data
        let rightPointer = right.data
        let dataPointer = calculatedMfArray.data
        
        let ldc = calculatedMfArray.shape[1] > 1 ? calculatedMfArray.shape[1] : 1
        
        /*
         * Avoid temporary copies for arrays in Fortran order
         */
        if (left.info.flags.F_CONTIGUOUS) {
            Trans1 = CblasTrans;
            lda = left.shape[0] > 1 ? left.shape[0] : 1
        }
        if (right.info.flags.F_CONTIGUOUS) {
            Trans2 = CblasTrans;
            ldb = right.shape[0] > 1 ? right.shape[0] : 1
        }
        
        precondition(K == left.shape[1], "cannot mutiply due to incorrect shape \(left.shape) and \(right.shape)")
        
        print(left)
        print(right)
        cblas_dgemm(Order, Trans1, Trans2, Int32(M), Int32(N), Int32(K), 1.0, leftPointer, Int32(lda), rightPointer, Int32(ldb), 0.0, dataPointer, Int32(ldc))
        
        return calculatedMfArray
        /*
         //cblas debug
         var arr = [1.0,2.0,3.0, 2.0,1.0,3.0]
         var arrT = [1.0,2.0, 2.0,1.0, 3.0,3.0]
         var ans = [0.0,0.0, 0.0,0.0]
         
         let Order = CblasRowMajor
         let Trans1 = CblasNoTrans
         let Trans2 = CblasNoTrans
         let M = 2
         let N = 2
         let K = 3
         let lda = 3
         let ldb = 2
         let ldc = 2
         cblas_dgemm(Order, Trans1, Trans2, Int32(M), Int32(N), Int32(K), 1.0, &arr, Int32(lda), &arrT, Int32(ldb), 0.0, &ans, Int32(ldc))
         
         print(ans) // -> [14.0, 13.0, 13.0, 14.0]
         */
        /*
         let arr = MfArray(mfarray: [[1,2,3],[2,1,3]], type: Int.self)
         let arrT = MfArray(mfarray: [[1,2],[2,1],[3,3]], type: Int.self)
         
         print(arr ~* arr.T)
         //-> mfarray =
         [[    14,        13],
         [    13,        14]], type=Int, shape=[2, 2]
         */
        
        //end thread
        //NPY_END_ALLOW_THREADS;
        
        
        
        /*
         precondition(left.ndim > 1, "left must be more than 2d")
         precondition(right.ndim > 1, "left must be more than 2d")
         
         let M_ = left.shape[left.ndim - 2]
         let N_ = right.shape[right.ndim - 1]
         
         let M = Int32(M_)
         let N = Int32(N_)
         let K = Int32(left.shape[left.ndim - 1])
         precondition(left.shape[left.ndim - 2] == K, "cannot calculate multiplication: \(left.shape), \(right.shape)")
         
         let LDA = Int32(left.shape[left.ndim - 2])
         let LDB = Int32(right.shape[right.ndim - 2])
         
         let calculatedMatrixSize = left.shape[left.ndim - 2] * left.shape[left.ndim - 1]
         let matricesNum = left.size / calculatedMatrixSize
         let calculatedMfArray = Matft.mfarray.nums(num: 0, type: Double.self, shape: left.shape.dropLast(2) + [M_, N_])
         
         var leftPointer = left.astype(Double.self).data.baseAddress!
         var rightPointer = right.astype(Double.self).data.baseAddress!
         var dataPointer = calculatedMfArray.data.baseAddress!
         
         for _ in 0..<matricesNum{
         cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, M, N, K, 1, leftPointer, LDA, rightPointer, LDB, 0, dataPointer, N)
         
         dataPointer += calculatedMatrixSize
         leftPointer +=
         rightPointer +=
         }
         
         return calculatedMfArray.astype(T.self)*/
    }
    
    

}
