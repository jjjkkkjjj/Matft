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
        
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            
            var ret = a + 3
            XCTAssertEqual(ret.real, real+3)
            XCTAssertEqual(ret.imag, imag)
            XCTAssertEqual(ret, MfArray(real: real+3, imag: imag))
            
            ret = a - 3
            XCTAssertEqual(ret.real, real-3)
            XCTAssertEqual(ret.imag, imag)
            XCTAssertEqual(ret, MfArray(real: real-3, imag: imag))
            
            ret = a * -2
            XCTAssertEqual(ret.real, real * -2)
            XCTAssertEqual(ret.imag, imag * -2)
            XCTAssertEqual(ret, MfArray(real: real * -2, imag: imag * -2))
            
            ret = a / 3
            XCTAssertEqual(ret.real, real / 3)
            XCTAssertEqual(ret.imag, imag / 3)
            XCTAssertEqual(ret, MfArray(real: real / 3, imag: imag / 3))
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
    
    func testAstype(){
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = a.astype(.Double)
            
            XCTAssertEqual(ret.real, real.astype(.Double))
            XCTAssertEqual(ret.imag!, imag.astype(.Double))
        }
    }
    
    func testNegative(){
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = -a
            
            XCTAssertEqual(ret.real, -real)
            XCTAssertEqual(ret.imag!, -imag)
        }
    }
    
    func testAbsolute(){
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.complex.abs(a)
            
            XCTAssertEqual(ret, MfArray([[[ 0.0        ,  1.41421356,  2.82842712,  4.24264069],
                                          [ 5.65685425,  7.07106781,  8.48528137,  9.89949494]],

                                         [[11.3137085 , 12.72792206, 14.14213562, 15.55634919],
                                          [16.97056275, 18.38477631, 19.79898987, 21.21320344]]] as [[[Float]]]))
        }
    }
    
    func testMath(){
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.math.sin(a)
            
            XCTAssertEqual(ret.real.round(decimals: 1), MfArray([[[ 0.00000000e+00,  1.29845758e+00,  3.42095486e+00,
                                                       1.42074854e+00],
                                                     [-2.06669388e+01, -7.11617211e+01, -5.63624750e+01,
                                                       3.60236944e+02]],

                                                    [[ 1.47461785e+03,  1.66971536e+03, -5.99143121e+03,
                                                      -2.99367777e+04],
                                                     [-4.36649067e+04,  9.29437620e+04,  5.95654325e+05,
                                                       1.06290112e+06]]] as [[[Float]]]).round(decimals: 1))
            XCTAssertEqual(ret.imag!.round(decimals: 1), MfArray([[[ 0.00000000e+00, -6.34963915e-01,  1.50930649e+00,
                                                  9.91762101e+00],
                                                [ 1.78378803e+01, -2.10486449e+01, -1.93678980e+02,
                                                 -4.13376761e+02]],

                                               [[ 2.16864720e+02,  3.69148243e+03,  9.24089015e+03,
                                                 -1.32492434e+02],
                                                [-6.86706375e+04, -2.00733304e+05, -8.22203822e+04,
                                                  1.24171649e+06]]] as [[[Float]]]).round(decimals: 1))
        }
        
        do{
            let real = Matft.arange(start: 1, to: 17, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 1, to: -15, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.math.log(a)
            XCTAssertEqual(ret.real, MfArray([[[0.34657359, 0.69314718, 1.15129255, 1.49786614],
                                                                               [1.76318026, 1.97562186, 2.15203255, 2.30258509]],

                                                                              [[2.43376723, 2.54993321, 2.65413385, 2.74858411],
                                                                               [2.83494046, 2.91447281, 2.98817545, 3.05684109]]] as [[[Float]]]))
            XCTAssertEqual(ret.imag!, MfArray([[[ 0.78539816,  0.0        , -0.32175055, -0.46364761],
                                                [-0.5404195 , -0.5880026 , -0.62024949, -0.64350111]],

                                               [[-0.66104317, -0.67474094, -0.68572951, -0.69473828],
                                                [-0.70225693, -0.70862627, -0.7140907 , -0.71883   ]]] as [[[Float]]]))
        }
    }
}
