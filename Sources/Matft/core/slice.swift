//
//  slice.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

public struct MfSlice: MfSlicable {
    public let to: Int? // nil means all value
    public let start: Int?
    public let by: Int
    
    
    /// Initilize slice object
    /// Note that to's value is NOT included
    /// - Parameters:
    ///   - start: A start index
    ///   - to: A end index. NOT included
    ///   - by: A stride value
    public init(start: Int? = nil, to: Int? = nil, by: Int = 1){
        precondition(by != 0, "by must not be 0")
        self.to = to
        self.start = start
        self.by = by
    }
    
}

extension Int: MfSlicable{
}

public enum SubscriptOps: MfSlicable{
    case newaxis
}
