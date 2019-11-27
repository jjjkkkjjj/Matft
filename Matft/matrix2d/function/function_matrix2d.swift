//
//  function_matrix2d.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/06.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension Matft.matrix2d{
    public static func nums<T: MfNumeric>(num: T, type: T.Type, shape: [Int]) -> Matrix2d<T>{
        let data = Array<T>(repeating: num, count: shape[0] * shape[1])
        return Matrix2d(data: data, shape: shape)
    }
}
