import Accelerate
import Foundation
import simd

/**
 Apply sign function for the given single-precision vector.
 
 ```
 for (n = 0; n < N; ++n)
    if (A[n*IA] > 0)
        *D[n*ID] = *B;
    else if (A[n*IA] < 0)
 *      *D[n*ID] = *C;
    else
 *      *D[n*ID] = 0;
 ```
 
 - Parameters:
    - __A: Single-precision real input vector
    - __IA: Stride for A
    - __B: Pointer to single-precision real input scalar: lower destination
    - __C: Pointer to single-precision real input scalar: upper destination
    - __D: Single-precision real output vector
    -  __ID: Stride for D
    - __N: The number of elements to process
 
 */
func evDSP_sign(_ __A: UnsafePointer<Float>, _ __IA: vDSP_Stride, _ __B: UnsafePointer<Float>, _ __C: UnsafePointer<Float>, _ __D: UnsafeMutablePointer<Float>, _ __ID: vDSP_Stride, _ __N: vDSP_Length){
   let strideA = Int(__IA)
   let strideD = Int(__ID)
   
    let (iterations, remaining) = (Int(__N) / 64, Int(__N) % 64)
    let zeros = SIMD64<Float>(repeating: 0)
    var aptr = __A
    var dptr = __D
    for _ in 0..<iterations{
        aptr.withMemoryRebound(to: SIMD64<Float>.self, capacity: 64){
            a in
            dptr.withMemoryRebound(to: SIMD64<Float>.self, capacity: 64){
                d in
                d.pointee.replace(with: __B.pointee, where: a.pointee .< zeros)
                d.pointee.replace(with: __C.pointee, where: a.pointee .> zeros)
            }
        }
        aptr += 64*strideA
        dptr += 64*strideD
     }
    // remaining
   for _ in 0..<remaining{
       var tmp: Float
       if aptr.pointee > 0{
           tmp = __C.pointee
       }
       else if __A.pointee < 0{
           tmp = __B.pointee
       }
       else{
           tmp = .zero
       }
       dptr.assign(from: &tmp, count: 1)
        aptr += strideA
       dptr += strideD
   }
    
}

func evDSP_signD(_ __A: UnsafePointer<Double>, _ __IA: vDSP_Stride, _ __B: UnsafePointer<Double>, _ __C: UnsafePointer<Double>, _ __D: UnsafeMutablePointer<Double>, _ __ID: vDSP_Stride, _ __N: vDSP_Length){
    var __A = UnsafeMutablePointer(mutating: __A)
    var __D = UnsafeMutablePointer(mutating: __D)
   let strideA = Int(__IA)
   let strideD = Int(__ID)
   
    let (iterations, remaining) = (Int(__N) / 64, Int(__N) % 64)
    let zeros = SIMD64<Double>(repeating: 0)
    var aptr = __A
    var dptr = __D
    for _ in 0..<iterations{
        aptr.withMemoryRebound(to: SIMD64<Double>.self, capacity: 64){
            a in
            dptr.withMemoryRebound(to: SIMD64<Double>.self, capacity: 64){
                d in
                d.pointee.replace(with: __B.pointee, where: a.pointee .< zeros)
                d.pointee.replace(with: __C.pointee, where: a.pointee .> zeros)
            }
        }
        aptr += 64*strideA
        dptr += 64*strideD
     }
    // remaining
   for _ in 0..<remaining{
       var tmp: Double
       if __A.pointee > 0{
           tmp = __C.pointee
       }
       else if __A.pointee < 0{
           tmp = __B.pointee
       }
       else{
           tmp = .zero
       }
       __D.assign(from: &tmp, count: 1)
       __A += strideA
       __D += strideD
   }
    
}


internal typealias evDSP_sign_func<T: MfStorable> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, UnsafePointer<T>, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func sign_by_evDSP<T: MfStorable>(_ mfarray: MfArray, lower: T, upper: T, _ evDSP_func: evDSP_sign_func<T>) -> MfArray{
    let mfarray = check_contiguous(mfarray)
    var lower = lower
    var upper = upper
    let size = mfarray.storedSize
    
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: size){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: size)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            srcptr in
            evDSP_func(srcptr.baseAddress!, vDSP_Stride(1), &lower, &upper, dstptrT, vDSP_Stride(1), vDSP_Length(size))
        }
    }
    
    let newmfstructure = MfStructure(shape: mfarray.shape, strides: mfarray.strides)
    
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
