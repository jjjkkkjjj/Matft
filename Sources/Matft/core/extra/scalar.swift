//
//  scalar.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import Foundation

extension MfArray{
    public var scalar: MfArrayType?{
        return self.size == 1 ? self.data[self.offsetIndex] : nil
    }
}
