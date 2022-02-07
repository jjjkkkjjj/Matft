//
//  typeconversion.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation
import Accelerate

/// Type conversion protocol
fileprivate protocol TypeConversionProtocol{
    
    associatedtype PreType
    associatedtype PostType
    
    /// Type conversion function
    /// - Parameters:
    ///   - src: The source pointer
    ///   - dst: The destination pointer
    ///   - size: The array size
    func convert(src: UnsafePointer<PreType>, dst: UnsafeMutablePointer<PostType>, size: Int) -> Void
}

internal struct ArrayConversionToStoredType<OriginalType, StoredType> {
    typealias PreType = OriginalType
    typealias PostType = StoredType
}

internal struct ArrayConversionToOriginalType<StoredType, OriginalType> {
    typealias PreType = StoredType
    typealias PostType = OriginalType
}


/// Check if the device is on 32 bit or not
/// - Returns: Bool, if the device is on 32 bit or not
fileprivate func is32bit() -> Bool{
    return MemoryLayout<Int>.size == MemoryLayout<Int32>.size
}


extension ArrayConversionToOriginalType: TypeConversionProtocol where PostType: MfTypeUsable, PreType == PostType.StoredType{
    init(src: UnsafePointer<StoredType>, dst: UnsafeMutablePointer<OriginalType>, size: Int) {
        self.convert(src: src, dst: dst, size: size)
    }
    
    func convert(src: UnsafePointer<StoredType>, dst: UnsafeMutablePointer<OriginalType>, size: Int) {
        
        if StoredType.self == OriginalType.self{
            memcpy(dst, src, size*MemoryLayout<PreType>.size)
        }
        else if let src = src as? UnsafePointer<Float>{
            
            // UInt
            if let dst = dst as? UnsafeMutablePointer<UInt8>{
                vDSP_vfixu8(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt16>{
                vDSP_vfixu16(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt32>{
                vDSP_vfixu32(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt>{
                
                if is32bit(){
                    dst.withMemoryRebound(to: UInt32.self, capacity: size){
                        vDSP_vfixu32(src, vDSP_Stride(1), $0, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                    // note that
                    dst.withMemoryRebound(to: UInt32.self, capacity: size*2){
                        vDSP_vfixu32(src, vDSP_Stride(1), $0, vDSP_Stride(2), vDSP_Length(size))
                    }
                }
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt64>{
                // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                // note that
                dst.withMemoryRebound(to: UInt32.self, capacity: size*2){
                    vDSP_vfixu32(src, vDSP_Stride(1), $0, vDSP_Stride(2), vDSP_Length(size))
                }
            }
            
            // Int
            else if let dst = dst as? UnsafeMutablePointer<Int8>{
                vDSP_vfix8(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<Int16>{
                vDSP_vfix16(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<Int32>{
                vDSP_vfix32(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<Int>{
                
                if is32bit(){
                    dst.withMemoryRebound(to: Int32.self, capacity: size){
                        vDSP_vfix32(src, vDSP_Stride(1), $0, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    // Invalid!
                    // negative value must be -1!
                    /*
                    dst.withMemoryRebound(to: Int32.self, capacity: size*2){
                        vDSP_vfix32(src, vDSP_Stride(1), $0, vDSP_Stride(2), vDSP_Length(size))
                    }*/

                    let srcarr = Array(UnsafeBufferPointer(start: src, count: size))
                    let i64 = srcarr.map{ Int64($0) }
                    _ = i64.withUnsafeBufferPointer{
                        memcpy(dst, $0.baseAddress, size*MemoryLayout<Int64>.size)
                    }
                }
            }
            else if let dst = dst as? UnsafeMutablePointer<Int64>{
                let srcarr = Array(UnsafeBufferPointer(start: src, count: size))
                let i64 = srcarr.map{ Int64($0) }
                _ = i64.withUnsafeBufferPointer{
                    memcpy(dst, $0.baseAddress, size*MemoryLayout<Int64>.size)
                }
            }
            else if let dst = dst as? UnsafeMutablePointer<Bool>{
                let srcarr = Array(UnsafeBufferPointer(start: src, count: size))
                let bool = srcarr.map{ $0 != 0 }
                _ = bool.withUnsafeBufferPointer{
                    memcpy(dst, $0.baseAddress, size*MemoryLayout<Bool>.size)
                }
            }
            
            else{
                fatalError("Unsupported Type: \(OriginalType.self)!")
            }
        }
        
        else if let src = src as? UnsafePointer<Double>{
            
            // UInt
            if let dst = dst as? UnsafeMutablePointer<UInt8>{
                vDSP_vfixu8D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt16>{
                vDSP_vfixu16D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt32>{
                vDSP_vfixu32D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt>{
                
                if is32bit(){
                    dst.withMemoryRebound(to: UInt32.self, capacity: size){
                        vDSP_vfixu32D(src, vDSP_Stride(1), $0, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                    // note that
                    dst.withMemoryRebound(to: UInt32.self, capacity: size*2){
                        vDSP_vfixu32D(src, vDSP_Stride(1), $0, vDSP_Stride(2), vDSP_Length(size))
                    }
                }
            }
            else if let dst = dst as? UnsafeMutablePointer<UInt64>{
                // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                // note that
                dst.withMemoryRebound(to: UInt32.self, capacity: size*2){
                    vDSP_vfixu32D(src, vDSP_Stride(1), $0, vDSP_Stride(2), vDSP_Length(size))
                }
            }
            
            // Int
            else if let dst = dst as? UnsafeMutablePointer<Int8>{
                vDSP_vfix8D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<Int16>{
                vDSP_vfix16D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<Int32>{
                vDSP_vfix32D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let dst = dst as? UnsafeMutablePointer<Int>{
                
                if is32bit(){
                    dst.withMemoryRebound(to: Int32.self, capacity: size){
                        vDSP_vfix32D(src, vDSP_Stride(1), $0, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    let srcarr = Array(UnsafeBufferPointer(start: src, count: size))
                    let i64 = srcarr.map{ Int64($0) }
                    _ = i64.withUnsafeBufferPointer{
                        memcpy(dst, $0.baseAddress, size*MemoryLayout<Int64>.size)
                    }
                }
            }
            else if let dst = dst as? UnsafeMutablePointer<Int64>{
                let srcarr = Array(UnsafeBufferPointer(start: src, count: size))
                let i64 = srcarr.map{ Int64($0) }
                _ = i64.withUnsafeBufferPointer{
                    memcpy(dst, $0.baseAddress, size*MemoryLayout<Int64>.size)
                }
            }
            else if let dst = dst as? UnsafeMutablePointer<Bool>{
                let srcarr = Array(UnsafeBufferPointer(start: src, count: size))
                let bool = srcarr.map{ $0 != 0 }
                _ = bool.withUnsafeBufferPointer{
                    memcpy(dst, $0.baseAddress, size*MemoryLayout<Bool>.size)
                }
            }
            else{
                fatalError("Unsupported Type: \(OriginalType.self)!")
            }
        }
        else{
            fatalError("Unsupported Type: \(OriginalType.self)!")
        }
    }
}

extension ArrayConversionToStoredType: TypeConversionProtocol where PreType: MfTypeUsable, PostType == PreType.StoredType{
    init(src: UnsafePointer<OriginalType>, dst: UnsafeMutablePointer<StoredType>, size: Int) {
        self.convert(src: src, dst: dst, size: size)
    }
    
    func convert(src: UnsafePointer<OriginalType>, dst: UnsafeMutablePointer<StoredType>, size: Int) {
        
        if StoredType.self == OriginalType.self{
            memcpy(dst, src, size*MemoryLayout<PreType>.size)
        }
        else if let dst = dst as? UnsafeMutablePointer<Float>{
            
            // UInt
            if let src = src as? UnsafePointer<UInt8>{
                vDSP_vfltu8(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<UInt16>{
                vDSP_vfltu16(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<UInt32>{
                vDSP_vfltu32(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<UInt>{
                
                if is32bit(){
                    src.withMemoryRebound(to: UInt32.self, capacity: size){
                        vDSP_vfltu32($0, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                    // note that
                    src.withMemoryRebound(to: UInt32.self, capacity: size*2){
                        vDSP_vfltu32($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                }
            }
            else if let src = src as? UnsafePointer<UInt64>{
                // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                // note that
                src.withMemoryRebound(to: UInt32.self, capacity: size*2){
                    vDSP_vfltu32($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                }
            }
            
            // Int
            else if let src = src as? UnsafePointer<Int8>{
                vDSP_vflt8(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<Int16>{
                vDSP_vflt16(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<Int32>{
                vDSP_vflt32(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<Int>{
                
                if is32bit(){
                    src.withMemoryRebound(to: Int32.self, capacity: size){
                        vDSP_vflt32($0, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                    // note that
                    src.withMemoryRebound(to: Int32.self, capacity: size*2){
                        vDSP_vflt32($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                }
            }
            else if let src = src as? UnsafePointer<Int64>{
                // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                // note that
                src.withMemoryRebound(to: Int32.self, capacity: size*2){
                    vDSP_vflt32($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                }
            }
            else if let src = src as? UnsafePointer<Bool>{
                // tricky method!!
                // deal with Bool as UInt8
                src.withMemoryRebound(to: UInt8.self, capacity: size){
                    vDSP_vfltu8($0, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
                }
            }
            else{
                fatalError("Unsupported Type: \(OriginalType.self)!")
            }
        }
        
        else if let dst = dst as? UnsafeMutablePointer<Double>{
            
            // UInt
            if let src = src as? UnsafePointer<UInt8>{
                vDSP_vfltu8D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<UInt16>{
                vDSP_vfltu16D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<UInt32>{
                vDSP_vfltu32D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<UInt>{
                
                if is32bit(){
                    src.withMemoryRebound(to: UInt32.self, capacity: size){
                        vDSP_vfltu32D($0, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                    // note that
                    src.withMemoryRebound(to: UInt32.self, capacity: size*2){
                        vDSP_vfltu32D($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                }
            }
            else if let src = src as? UnsafePointer<UInt64>{
                // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                // note that
                src.withMemoryRebound(to: UInt32.self, capacity: size*2){
                    vDSP_vfltu32D($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                }
            }
            
            // Int
            else if let src = src as? UnsafePointer<Int8>{
                vDSP_vflt8D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<Int16>{
                vDSP_vflt16D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<Int32>{
                vDSP_vflt32D(src, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
            }
            else if let src = src as? UnsafePointer<Int>{
                
                if is32bit(){
                    src.withMemoryRebound(to: Int32.self, capacity: size){
                        vDSP_vflt32D($0, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                    
                }else{
                    // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                    // note that
                    src.withMemoryRebound(to: Int32.self, capacity: size*2){
                        vDSP_vflt32D($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                    }
                }
            }
            else if let src = src as? UnsafePointer<Int64>{
                // tricky method!! : https://stackoverflow.com/questions/64276933/fast-uint-to-float-conversion-in-swift
                // note that
                src.withMemoryRebound(to: Int32.self, capacity: size*2){
                    vDSP_vflt32D($0, vDSP_Stride(2), dst, vDSP_Stride(1), vDSP_Length(size))
                }
            }
            else if let src = src as? UnsafePointer<Bool>{
                // tricky method!!
                // deal with Bool as UInt8
                src.withMemoryRebound(to: UInt8.self, capacity: size){
                    vDSP_vfltu8D($0, vDSP_Stride(1), dst, vDSP_Stride(1), vDSP_Length(size))
                }
            }
            else{
                fatalError("Unsupported Type: \(OriginalType.self)!")
            }
        }
        else{
            fatalError("Unsupported Type: \(OriginalType.self)!")
        }
    }
}

