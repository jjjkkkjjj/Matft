//
//  ComplexTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/07/04.
//

import XCTest
//@testable import Matft
import Matft

import Accelerate

final class ComplexTests: XCTestCase {
    
    func test_complex() {
        do {
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            
            XCTAssertEqual(a.real, real)
            XCTAssertEqual(a.imag!, imag)
        }
    }
    
    func testArithmetic() {
        do {
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            
            var ret = a + a
            XCTAssertEqual(ret.real, real+real)
            XCTAssertEqual(ret.imag, imag+imag)
            XCTAssertEqual(ret, MfArray(real: real+real, imag: imag+imag))
            
            ret = a - a
            XCTAssertEqual(ret.real, real-real)
            XCTAssertEqual(ret.imag, imag-imag)
            XCTAssertEqual(ret, MfArray(real: real-real, imag: imag-imag))
            
            ret = a * a
            XCTAssertEqual(ret.real, MfArray([[[0, 0, 0, 0],
                                               [0, 0, 0, 0]],

                                              [[0, 0, 0, 0],
                                               [0, 0, 0, 0]]]))
            XCTAssertEqual(ret.imag, MfArray([[[   0,   -2,   -8,  -18],
                                               [ -32,  -50,  -72,  -98]],

                                              [[-128, -162, -200, -242],
                                               [-288, -338, -392, -450]]]))
            
            
        }
    }
    
    func testAngle() {
        do {
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            
            XCTAssertEqual(Matft.complex.angle(a), MfArray([[[ 0.0        , -0.78539816, -0.78539816, -0.78539816],
                                                             [-0.78539816, -0.78539816, -0.78539816, -0.78539816]],

                                                            [[-0.78539816, -0.78539816, -0.78539816, -0.78539816],
                                                             [-0.78539816, -0.78539816, -0.78539816, -0.78539816]]] as [[[Float]]]))
        }
    }
    
    func testConjugate() {
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            
            XCTAssertEqual(Matft.complex.conjugate(real), real)
        }
        
        do {
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let conj = Matft.complex.conjugate(a)
            
            XCTAssertEqual(conj.real, real)
            XCTAssertEqual(conj.imag!, -imag)
        }
    }
}
