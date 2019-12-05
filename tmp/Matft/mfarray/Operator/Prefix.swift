//
//  operator_mfarray_prefix.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/08.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

prefix operator -
public prefix func -<T: MfNumeric>(mfarray: inout MfArray<T>) -> MfArray<T>{
    mfarray *= -1
    return mfarray
}
