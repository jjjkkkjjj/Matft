//
//  withPointer.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension MfArray{
    internal func withUnsafeMutableStartPointer<R>(_ body: (UnsafeMutablePointer<MfArrayStoredType>) throws -> R) rethrows -> R{
        return try body(self.mfdata.storedPtr.baseAddress! + self.mfdata.offset)
    }
}
