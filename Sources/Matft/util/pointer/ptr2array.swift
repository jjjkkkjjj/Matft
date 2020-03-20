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
internal func unsafeMRBPtr2array_viaForD(_ ptr: UnsafeMutableRawPointer, mftype: MfType, size: Int) -> [Any]{
    
    switch MfType.storedType(mftype) {
    case .Float://in case that storedtype is Float
        let ptrF = ptr.bindMemory(to: Float.self, capacity: size)
    
        switch mftype {
        case .UInt8:
            let ptrui8 = create_unsafeMPtrT(type: UInt8.self, count: size)
            unsafePtrT2UnsafeMPtrU(ptrF, ptrui8, vDSP_vfixru8, size)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrui8, count: size)) as [Any]
            
            //free
            ptrui8.deinitialize(count: size)
            ptrui8.deallocate()

            return ret
        case .UInt16:
            let ptrui16 = create_unsafeMPtrT(type: UInt16.self, count: size)
            unsafePtrT2UnsafeMPtrU(ptrF, ptrui16, vDSP_vfixru16, size)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrui16, count: size)) as [Any]
            
            //free
            ptrui16.deinitialize(count: size)
            ptrui16.deallocate()

            return ret
        case .UInt32, .UInt64, .UInt:
            let ptrui32 = create_unsafeMPtrT(type: UInt32.self, count: size)
            unsafePtrT2UnsafeMPtrU(ptrF, ptrui32, vDSP_vfixru32, size)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrui32, count: size)) as [Any]
            
            //free
            ptrui32.deinitialize(count: size)
            ptrui32.deallocate()

            return ret
        case .Int8:
            let ptri8 = create_unsafeMPtrT(type: Int8.self, count: size)
            unsafePtrT2UnsafeMPtrU(ptrF, ptri8, vDSP_vfixr8, size)
            let ret = Array(UnsafeMutableBufferPointer(start: ptri8, count: size)) as [Any]
            
            //free
            ptri8.deinitialize(count: size)
            ptri8.deallocate()

            return ret
        case .Int16:
            let ptri16 = create_unsafeMPtrT(type: Int16.self, count: size)
            unsafePtrT2UnsafeMPtrU(ptrF, ptri16, vDSP_vfixr16, size)
            let ret = Array(UnsafeMutableBufferPointer(start: ptri16, count: size)) as [Any]
            
            //free
            ptri16.deinitialize(count: size)
            ptri16.deallocate()

            return ret
        case .Int32, .Int64, .Int:
            let ptri32 = create_unsafeMPtrT(type: Int32.self, count: size)
            unsafePtrT2UnsafeMPtrU(ptrF, ptri32, vDSP_vfixr32, size)
            let ret = Array(UnsafeMutableBufferPointer(start: ptri32, count: size)) as [Any]
            
            //free
            ptri32.deinitialize(count: size)
            ptri32.deallocate()

            return ret
        case .Float:
            let ret = Array(UnsafeMutableBufferPointer(start: ptrF, count: size)) as [Any]
            
            return ret
        default:
            fatalError("Unsupported type \(mftype).")
        }
        
    case .Double://in case that storedtype is Double
        let ptrD = ptr.bindMemory(to: Double.self, capacity: size)
        switch mftype {
            case .Double:
                let ret = Array(UnsafeMutableBufferPointer(start: ptrD, count: size)) as [Any]

                return ret
            default:
                fatalError("Unsupported type \(mftype).")
        }
    }
    
}

