//
//  ptr2array.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
import Accelerate

//convert rawpointer to flattenarray via float or Double array
//All kinds of int and uint has been handled as float
internal func unsafeMRBPtr2array_viaForD(_ ptr: UnsafeMutableRawBufferPointer, mftype: MfType, size: Int) -> [Any]{
    let ptrF = ptr.bindMemory(to: Float.self)
    
    switch mftype {
        case .UInt8:
            var ptrui8 = create_unsafeMBPtrT(type: UInt8.self, count: size)
            ptrui8.withUnsafeMutableBufferPointer{
                retptr in
                ptrF.withUnsafeBufferPointer{
                    unsafePtrT2UnsafeMPtrU($0.baseAddress!, retptr.baseAddress!, vDSP_vfixru8, size)
                }
            }
            let ret = Array(ptrui8) as [Any]
            
            //free
            ptrui8.deallocate()

            return ret
        case .UInt16:
            var ptrui16 = create_unsafeMBPtrT(type: UInt16.self, count: size)
            ptrui16.withUnsafeMutableBufferPointer{
                retptr in
                ptrF.withUnsafeBufferPointer{
                    unsafePtrT2UnsafeMPtrU($0.baseAddress!, retptr.baseAddress!, vDSP_vfixru16, size)
                }
            }
            let ret = Array(ptrui16) as [Any]
            
            //free
            ptrui16.deallocate()

            return ret
        case .UInt32, .UInt64, .UInt:
            var ptrui32 = create_unsafeMBPtrT(type: UInt32.self, count: size)
            ptrui32.withUnsafeMutableBufferPointer{
                retptr in
                ptrF.withUnsafeBufferPointer{
                    unsafePtrT2UnsafeMPtrU($0.baseAddress!, retptr.baseAddress!, vDSP_vfixru32, size)
                }
            }
            let ret = Array(ptrui32) as [Any]
            
            //free
            ptrui32.deallocate()

            return ret
        case .Int8:
            var ptri8 = create_unsafeMBPtrT(type: Int8.self, count: size)
            ptri8.withUnsafeMutableBufferPointer{
                retptr in
                ptrF.withUnsafeBufferPointer{
                    unsafePtrT2UnsafeMPtrU($0.baseAddress!, retptr.baseAddress!, vDSP_vfixr8, size)
                }
            }
            let ret = Array(ptri8) as [Any]
            
            //free
            ptri8.deallocate()

            return ret
        case .Int16:
            var ptri16 = create_unsafeMBPtrT(type: Int16.self, count: size)
            ptri16.withUnsafeMutableBufferPointer{
                retptr in
                ptrF.withUnsafeBufferPointer{
                    unsafePtrT2UnsafeMPtrU($0.baseAddress!, retptr.baseAddress!, vDSP_vfixr16, size)
                }
            }
            let ret = Array(ptri16) as [Any]
            
            //free
            ptri16.deallocate()

            return ret
        case .Int32, .Int64, .Int:
            var ptri32 = create_unsafeMBPtrT(type: Int32.self, count: size)
            ptri32.withUnsafeMutableBufferPointer{
                retptr in
                ptrF.withUnsafeBufferPointer{
                    unsafePtrT2UnsafeMPtrU($0.baseAddress!, retptr.baseAddress!, vDSP_vfixr32, size)
                }
            }
            let ret = Array(ptri32) as [Any]
            
            //free
            ptri32.deallocate()

            return ret
        case .Float:
            let ret = Array(ptrF) as [Any]
            
            return ret
        case .Double:
            let ptrD = ptr.bindMemory(to: Double.self)
            let ret = Array(ptrD) as [Any]

            return ret
        default:
            fatalError("Unsupported type \(mftype).")
    }
    
}

