//
//  File.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

/// The type comformed to this protocol can use MfArray
public protocol MfStoredTypeUsable: MfTypeUsable{
    static func from<T: MfTypeUsable>(_ value: T) -> Self
    
    //======= vDSP ========//
    static var vDSP_vcmprs_func: vDSP_vcmprs_func<Self>{ get }
    static var vDSP_preop_func: vDSP_convert_func<Self, Self>{ get }
    static var vDSP_vminmg_func: vDSP_vminmg_func<Self>{ get }
    static var vDSP_viclip_func: vDSP_viclip_func<Self>{ get }
    
    //======= cblas ========//
    static var cblas_copy_func: cblas_copy_func<Self>{ get }
}
