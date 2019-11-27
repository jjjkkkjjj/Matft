//
//  operator_vector_prefix.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/05.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

prefix operator -
public prefix func -<T: MfNumeric>(vector: inout Vector<T>) -> Vector<T>{
    vector *= -1
    return vector
}
