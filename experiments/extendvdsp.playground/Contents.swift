import UIKit
import Accelerate
import _Builtin_intrinsics.intel

extension vDSP{
    @_transparent static func sum<U> (_ vector: U) -> UInt8 where U:AccelerateBuffer, U.Element == UInt8 {
        vector.withUnsafeBufferPointer{
            (buffer) -> UInt8 in
            // 32 means 8bit*32 = 256bit
            let (iterations, remaining) = (buffer.count / 32, buffer.count % 32)
            let ret = buffer.baseAddress!.withMemoryRebound(to: __m256i.self, capacity: iterations){
                (ptr) -> UInt8 in
                // set zero to 256bit interger type
                var accumulator = _mm256_setzero_si256()
                
                for i in stride(from: 0, to: iterations, by: 1){
                    // ptr is the pointer of 256bit interger
                    // so ptr + i means load memories from 256*i bit to 256*(i+1)
                    // element: __m256i type
                    let element = _mm256_loadu_si256(ptr + i)
                    // considre __m256i as 8bit interget
                    accumulator = _mm256_add_epi8(accumulator, element)
                }
                
                // for now, accumulator is considered as;
                // accumulator = |8bit|8bit|...|8bit|
                //                = 8bit * 32
                let values = unsafeBitCast(accumulator, to: SIMD32<UInt8>.self)
                var ret: UInt8 = 0
                // sum of all 8bit in accumulator
                for i in 0..<16{
                    ret += values[i] &+ values[2*i]
                }
                
                // calculate remaining of above iterations
                for i in stride(from: 0, to: remaining, by: 1){
                    ret += buffer[iterations*8 + i]
                }
                
                return ret
            }
            return ret
        }
    }
}

var arru8: [UInt8] = [0, 2, 3, 1, 5, 9, 2, 0]
let ret = vDSP.sum(arru8)
print(ret)
