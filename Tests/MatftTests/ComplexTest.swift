//
//  ComplexTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/01.
//

import XCTest
//@testable import Matft
import Matft
import Accelerate

final class ComplexTests: XCTestCase {
    
    
    func testComplex() {
        do{
            
            let a = MfArray([[DSPComplex(real: 1.0, imag: 2.0), DSPComplex(real: 3.0, imag: 4.0)],
                             [DSPComplex(real: 5.0, imag: 6.0), DSPComplex(real: 7.0, imag: 8.0)]])
            let b = MfArray([[DSPComplex(real: 1.0, imag: 2.0), DSPComplex(real: 3.0, imag: 4.0)],
                             [DSPComplex(real: 4.0, imag: 3.0), DSPComplex(real: 2.0, imag: 1.0)]])
            print(a)
        }
    }
}
