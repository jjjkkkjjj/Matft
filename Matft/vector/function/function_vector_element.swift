//
//  function_vector_element.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/06.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension Matft.vector{
    public static func sum<T: MfNumeric>(vector: Vector<T>) -> T{
        return vector ~* 1
    }
}
