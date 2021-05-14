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
    - __B: Pointer to single-precision real input scalar: upper destination
    - __C: Pointer to single-precision real input scalar: lower destination
    - __D: Single-precision real output vector
    -  __ID: Stride for D
    - __N: The number of elements to process
 
 */
func evDSP_sign(_ __A: UnsafePointer<Float>, _ __IA: vDSP_Stride, _ __B: UnsafePointer<Float>, _ __C: UnsafePointer<Float>, _ __D: UnsafeMutablePointer<Float>, _ __ID: vDSP_Stride, _ __N: vDSP_Length){
    var __A = UnsafeMutablePointer(mutating: __A)
    var __D = UnsafeMutablePointer(mutating: __D)
   let strideA = Int(__IA)
   let strideD = Int(__ID)
   
    let (iterations, remaining) = (Int(__N) / 64, Int(__N) % 64)
    let zeros = SIMD64<Float>(repeating: 0)
    for _ in 0..<iterations{
        var a = SIMD64<Float>(__A.pointee, (__A + __IA).pointee, (__A + 2*__IA).pointee, (__A + 3*__IA).pointee, (__A + 4*__IA).pointee, (__A + 5*__IA).pointee, (__A + 6*__IA).pointee, (__A + 7*__IA).pointee, (__A + 8*__IA).pointee, (__A + 9*__IA).pointee, (__A + 10*__IA).pointee, (__A + 11*__IA).pointee, (__A + 12*__IA).pointee, (__A + 13*__IA).pointee, (__A + 14*__IA).pointee, (__A + 15*__IA).pointee, (__A + 16*__IA).pointee, (__A + 17*__IA).pointee, (__A + 18*__IA).pointee, (__A + 19*__IA).pointee, (__A + 20*__IA).pointee, (__A + 21*__IA).pointee, (__A + 22*__IA).pointee, (__A + 23*__IA).pointee, (__A + 24*__IA).pointee, (__A + 25*__IA).pointee, (__A + 26*__IA).pointee, (__A + 27*__IA).pointee, (__A + 28*__IA).pointee, (__A + 29*__IA).pointee, (__A + 30*__IA).pointee, (__A + 31*__IA).pointee, (__A + 32*__IA).pointee, (__A + 33*__IA).pointee, (__A + 34*__IA).pointee, (__A + 35*__IA).pointee, (__A + 36*__IA).pointee, (__A + 37*__IA).pointee, (__A + 38*__IA).pointee, (__A + 39*__IA).pointee, (__A + 40*__IA).pointee, (__A + 41*__IA).pointee, (__A + 42*__IA).pointee, (__A + 43*__IA).pointee, (__A + 44*__IA).pointee, (__A + 45*__IA).pointee, (__A + 46*__IA).pointee, (__A + 47*__IA).pointee, (__A + 48*__IA).pointee, (__A + 49*__IA).pointee, (__A + 50*__IA).pointee, (__A + 51*__IA).pointee, (__A + 52*__IA).pointee, (__A + 53*__IA).pointee, (__A + 54*__IA).pointee, (__A + 55*__IA).pointee, (__A + 56*__IA).pointee, (__A + 57*__IA).pointee, (__A + 58*__IA).pointee, (__A + 59*__IA).pointee, (__A + 60*__IA).pointee, (__A + 61*__IA).pointee, (__A + 62*__IA).pointee, (__A + 63*__IA).pointee)
        
        a.replace(with: __B.pointee, where: a .> zeros)
        a.replace(with: __C.pointee, where: a .< zeros)
       
       //
       withUnsafePointer(to: &a){
           ptr in
           ptr.withMemoryRebound(to: Float.self, capacity: 64){
               cblas_scopy(Int32(64), $0, Int32(1), __D, Int32(__ID))
           }
       }
       // proceeds offset
       __A += 64*strideA
       __D += 64*strideD

    }
    // remaining
   for _ in 0..<remaining{
       var tmp: Float
       if __A.pointee > 0{
           tmp = __B.pointee
       }
       else if __A.pointee < 0{
           tmp = __C.pointee
       }
       else{
           tmp = .zero
       }
       __D.assign(from: &tmp, count: 1)
       __A += strideA
       __D += strideD
   }
    
}

func evDSP_signD(_ __A: UnsafePointer<Double>, _ __IA: vDSP_Stride, _ __B: UnsafePointer<Double>, _ __C: UnsafePointer<Double>, _ __D: UnsafeMutablePointer<Double>, _ __ID: vDSP_Stride, _ __N: vDSP_Length){
    var __A = UnsafeMutablePointer(mutating: __A)
    var __D = UnsafeMutablePointer(mutating: __D)
   let strideA = Int(__IA)
   let strideD = Int(__ID)
   
    let (iterations, remaining) = (Int(__N) / 64, Int(__N) % 64)
    let zeros = SIMD64<Double>(repeating: 0)
    for _ in 0..<iterations{
        var a = SIMD64<Double>(__A.pointee, (__A + __IA).pointee, (__A + 2*__IA).pointee, (__A + 3*__IA).pointee, (__A + 4*__IA).pointee, (__A + 5*__IA).pointee, (__A + 6*__IA).pointee, (__A + 7*__IA).pointee, (__A + 8*__IA).pointee, (__A + 9*__IA).pointee, (__A + 10*__IA).pointee, (__A + 11*__IA).pointee, (__A + 12*__IA).pointee, (__A + 13*__IA).pointee, (__A + 14*__IA).pointee, (__A + 15*__IA).pointee, (__A + 16*__IA).pointee, (__A + 17*__IA).pointee, (__A + 18*__IA).pointee, (__A + 19*__IA).pointee, (__A + 20*__IA).pointee, (__A + 21*__IA).pointee, (__A + 22*__IA).pointee, (__A + 23*__IA).pointee, (__A + 24*__IA).pointee, (__A + 25*__IA).pointee, (__A + 26*__IA).pointee, (__A + 27*__IA).pointee, (__A + 28*__IA).pointee, (__A + 29*__IA).pointee, (__A + 30*__IA).pointee, (__A + 31*__IA).pointee, (__A + 32*__IA).pointee, (__A + 33*__IA).pointee, (__A + 34*__IA).pointee, (__A + 35*__IA).pointee, (__A + 36*__IA).pointee, (__A + 37*__IA).pointee, (__A + 38*__IA).pointee, (__A + 39*__IA).pointee, (__A + 40*__IA).pointee, (__A + 41*__IA).pointee, (__A + 42*__IA).pointee, (__A + 43*__IA).pointee, (__A + 44*__IA).pointee, (__A + 45*__IA).pointee, (__A + 46*__IA).pointee, (__A + 47*__IA).pointee, (__A + 48*__IA).pointee, (__A + 49*__IA).pointee, (__A + 50*__IA).pointee, (__A + 51*__IA).pointee, (__A + 52*__IA).pointee, (__A + 53*__IA).pointee, (__A + 54*__IA).pointee, (__A + 55*__IA).pointee, (__A + 56*__IA).pointee, (__A + 57*__IA).pointee, (__A + 58*__IA).pointee, (__A + 59*__IA).pointee, (__A + 60*__IA).pointee, (__A + 61*__IA).pointee, (__A + 62*__IA).pointee, (__A + 63*__IA).pointee)
        
        a.replace(with: __B.pointee, where: a .> zeros)
        a.replace(with: __C.pointee, where: a .< zeros)
       
       //
       withUnsafePointer(to: &a){
           ptr in
           ptr.withMemoryRebound(to: Double.self, capacity: 64){
               cblas_dcopy(Int32(64), $0, Int32(1), __D, Int32(__ID))
           }
       }
       // proceeds offset
       __A += 64*strideA
       __D += 64*strideD

    }
    // remaining
   for _ in 0..<remaining{
       var tmp: Double
       if __A.pointee > 0{
           tmp = __B.pointee
       }
       else if __A.pointee < 0{
           tmp = __C.pointee
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
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}
