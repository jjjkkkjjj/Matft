//
//  ComplexTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/04.
//

import XCTest
//@testable import Matft
import Matft

final class ComplexTests: XCTestCase {
    
    func test_complex() {
        do {
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfComplexArray(real: real, imag: imag)
            print(a)
        }
    }
}
