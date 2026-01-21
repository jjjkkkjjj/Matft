//
//  ptr2array.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

//convert rawpointer to flattenarray via float or Double array
//All kinds of int and uint has been handled as float
internal func data2flattenArray(_ ptr: UnsafeMutableRawPointer, mftype: MfType, size: Int) -> [Any]{
    
    switch MfType.storedType(mftype) {
    case .Float://in case that storedtype is Float
        let ptrF = ptr.bindMemory(to: Float.self, capacity: size)
    
        switch mftype {
        case .Bool:
            let ret = UnsafeMutableBufferPointer(start: ptrF, count: size).map{ $0 != Float.zero } as [Any]
            
            return ret
        case .UInt8:
            let ptrui8 = allocate_unsafeMPtrT(type: UInt8.self, count: size)
            wrap_vDSP_convert(size, ptrF, 1, ptrui8, 1, vDSP_vfixru8)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrui8, count: size)) as [Any]
            
            //free
            ptrui8.deinitialize(count: size)
            ptrui8.deallocate()

            return ret
        case .UInt16:
            let ptrui16 = allocate_unsafeMPtrT(type: UInt16.self, count: size)
            wrap_vDSP_convert(size, ptrF, 1, ptrui16, 1, vDSP_vfixru16)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrui16, count: size)) as [Any]
            
            //free
            ptrui16.deinitialize(count: size)
            ptrui16.deallocate()

            return ret
        case .UInt32, .UInt64, .UInt:
            let ptrui32 = allocate_unsafeMPtrT(type: UInt32.self, count: size)
            wrap_vDSP_convert(size, ptrF, 1, ptrui32, 1, vDSP_vfixru32)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrui32, count: size))
            
            //free
            ptrui32.deinitialize(count: size)
            ptrui32.deallocate()
            
            if mftype == .UInt64{
                return ret.map{ UInt64($0) } as [Any]
            }
            else if mftype == .UInt{
                return ret.map{ UInt($0) } as [Any]
            }
            return ret as [Any]
        case .Int8:
            let ptri8 = allocate_unsafeMPtrT(type: Int8.self, count: size)
            wrap_vDSP_convert(size, ptrF, 1, ptri8, 1, vDSP_vfixr8)
            let ret = Array(UnsafeMutableBufferPointer(start: ptri8, count: size)) as [Any]
            
            //free
            ptri8.deinitialize(count: size)
            ptri8.deallocate()

            return ret
        case .Int16:
            let ptri16 = allocate_unsafeMPtrT(type: Int16.self, count: size)
            wrap_vDSP_convert(size, ptrF, 1, ptri16, 1, vDSP_vfixr16)
            let ret = Array(UnsafeMutableBufferPointer(start: ptri16, count: size)) as [Any]
            
            //free
            ptri16.deinitialize(count: size)
            ptri16.deallocate()

            return ret
        case .Int32, .Int64, .Int:
            let ptri32 = allocate_unsafeMPtrT(type: Int32.self, count: size)
            wrap_vDSP_convert(size, ptrF, 1, ptri32, 1, vDSP_vfixr32)
            let ret = Array(UnsafeMutableBufferPointer(start: ptri32, count: size))
            
            //free
            ptri32.deinitialize(count: size)
            ptri32.deallocate()
            
            if mftype == .Int64{
                return ret.map{ Int64($0) } as [Any]
            }
            else if mftype == .Int{
                return ret.map{ Int($0) } as [Any]
            }
            return ret as [Any]
        case .Float:
            let ret = Array(UnsafeMutableBufferPointer(start: ptrF, count: size)) as [Any]
            
            return ret
        case .ComplexFloat:
            let ptrCF = ptr.bindMemory(to: DSPComplex.self, capacity: size*2)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrCF, count: size)) as [Any]
            
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
        case .ComplexDouble:
            let ptrCD = ptr.bindMemory(to: DSPDoubleComplex.self, capacity: size*2)
            let ret = Array(UnsafeMutableBufferPointer(start: ptrCD, count: size*2)) as [Any]
            
            return ret
            default:
                fatalError("Unsupported type \(mftype).")
        }
    }
    
}

