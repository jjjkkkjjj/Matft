//
//  operator_vector_postfix.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/05.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

//transpose
postfix operator ~
public postfix func ~<T: MfNumeric>(vector: inout Vector<T>) -> Vector<T>{
    vector.columned = !vector.columned
    return vector
}
