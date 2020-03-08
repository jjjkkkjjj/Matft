//
//  cblas.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/03/07.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

//convert order
internal typealias cblas_convorder_func<T> = (Int32, UnsafePointer<T>, Int32, UnsafeMutablePointer<T>, Int32) -> Void
/*
internal func convorder_by_cblas<T: Numeric>(_ mfarray: MfArray, dstStridesPtr: UnsafeMutablePointer<Int>, cblas_func: cblas_convorder_func<T>) -> MfArray{
    
}
*/
