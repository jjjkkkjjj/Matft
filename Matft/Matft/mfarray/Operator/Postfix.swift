//
//  operator_postfix_mfarray.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/08.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

//transpose
postfix operator ~
public postfix func ~<T: MfNumeric>(mfarray: inout MfArray<T>) -> MfArray<T>{
    return mfarray.T
}
