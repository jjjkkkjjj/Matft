//
//  mfindex.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/01.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public struct MfSlice: MfSlicable {
    public let to: Int? // nil means all value
    public let start: Int?
    public let by: Int
    
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
    case all
    case reverse
}
