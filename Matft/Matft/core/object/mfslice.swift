//
//  mfindex.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/01.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public struct MfSlice {
    public let to: Int? // nil means all value
    public let start: Int
    public let by: Int
    
    public init(start: Int = 0, to: Int? = nil, by: Int = 1){
        self.to = to
        self.start = start
        self.by = by
    }
}
