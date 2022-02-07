//
//  subscript.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

public protocol MfSlicable {
    
}

public protocol MfSubscriptable{
    
}

extension MfSlice: MfSubscriptable{}
extension Int: MfSubscriptable{}
