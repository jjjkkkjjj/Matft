// Test execution disabled for WASM until we support complex operations
#if canImport(Accelerate)
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
    
    func testsin(){
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1, mftype: .Double).reshape([2,2,4])
            let imag = Matft.arange(start: 0, to: -16, by: -1, mftype: .Double).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.math.sin(a)
            
            XCTAssertEqual(ret.real.round(decimals: 1), MfArray([[[ 0.00000000e+00,  1.29845758e+00,  3.42095486e+00,
                                                       1.42074854e+00],
                                                     [-2.06669388e+01, -7.11617211e+01, -5.63624750e+01,
                                                       3.60236944e+02]],

                                                    [[ 1.47461785e+03,  1.66971536e+03, -5.99143121e+03,
                                                      -2.99367777e+04],
                                                     [-4.36649067e+04,  9.29437620e+04,  5.95654325e+05,
                                                       1.06290112e+06]]] as [[[Double]]]).round(decimals: 1))
            XCTAssertEqual(ret.imag!.round(decimals: 1), MfArray([[[ 0.00000000e+00, -6.34963915e-01,  1.50930649e+00,
                                                  9.91762101e+00],
                                                [ 1.78378803e+01, -2.10486449e+01, -1.93678980e+02,
                                                 -4.13376761e+02]],

                                               [[ 2.16864720e+02,  3.69148243e+03,  9.24089015e+03,
                                                 -1.32492434e+02],
                                                [-6.86706375e+04, -2.00733304e+05, -8.22203822e+04,
                                                  1.24171649e+06]]] as [[[Double]]]).round(decimals: 1))
        }
    }
    func testlog(){
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
    func testexp(){
        do{
            let real = Matft.arange(start: 1, to: 17, by: 1, mftype: .Double).reshape([2,2,4])
            let imag = Matft.arange(start: 1, to: -15, by: -1, mftype: .Double).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.math.exp(a)
            XCTAssertEqual(ret.real.round(decimals: 1), MfArray([[[ 1.46869394e+00,  7.38905610e+00,  1.08522619e+01,
                                                 -2.27208474e+01],
                                                [-1.46927914e+02, -2.63698657e+02,  3.11073358e+02,
                                                  2.86222728e+03]],

                                               [[ 6.10893324e+03, -3.20485152e+03, -5.45531424e+04,
                                                 -1.36562912e+05],
                                                [ 1.95798806e+03,  1.01482239e+06,  2.96645929e+06,
                                                  1.21506203e+06]]] as [[[Double]]]).round(decimals: 1))
            XCTAssertEqual(ret.imag!.round(decimals: 1), MfArray([[[ 2.28735529e+00,  0.00000000e+00, -1.69013965e+01,
                                                  -4.96459573e+01],
                                                 [-2.09440662e+01,  3.05315918e+02,  1.05158816e+03,
                                                   8.32925861e+02]],

                                                [[-5.32361755e+03, -2.17920656e+04, -2.46752406e+04,
                                                   8.85420424e+04],
                                                 [ 4.42409059e+05,  6.45284890e+05, -1.37353334e+06,
                                                  -8.80264645e+06]]] as [[[Double]]]).round(decimals: 1))
        }
    }
    
    func testpower(){
        do{
            let real = Matft.arange(start: 1, to: 17, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 1, to: -15, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.math.power(bases: a, exponents: 2)
            XCTAssertEqual(ret.real.nearest(), MfArray([[[ 0.0,  4.0,  8.0, 12.0],
                                               [16.0, 20.0, 24.0, 28.0]],

                                              [[32.0, 36.0, 40.0, 44.0],
                                               [48.0, 52.0, 56.0, 60.0]]] as [[[Float]]]).nearest())
            XCTAssertEqual(ret.imag!.nearest(), MfArray([[[   2.0,    0.0,   -6.0,  -16.0],
                                                [ -30.0,  -48.0,  -70.0,  -96.0]],

                                               [[-126.0, -160.0, -198.0, -240.0],
                                                [-286.0, -336.0, -390.0, -448.0]]] as [[[Float]]]).nearest())
        }
        
        do{
            let real = Matft.arange(start: 1, to: 5, by: 1).reshape([4])
            let imag = Matft.arange(start: 1, to: -3, by: -1).reshape([4])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.math.power(bases: a, exponents: a)
            XCTAssertEqual(ret.real.round(decimals: 4), MfArray([  0.27395725,   4.0        , -11.89819176,  21.75871639] as [Float]).round(decimals: 4))
            XCTAssertEqual(ret.imag!.round(decimals: 4), MfArray([  0.58370076,   0.0        , -19.5929216 , 156.74592048] as [Float]).round(decimals: 4))
        }
        
        do{
            let real = Matft.arange(start: 1, to: 9, by: 1).reshape([2,2,2])
            let imag = Matft.arange(start: -1, to: -9, by: -1).reshape([2,2,2])
            let a = MfArray(real: real, imag: imag)
            let ret = Matft.math.power(bases: 2, exponents: a)
            XCTAssertEqual(ret.real.round(decimals: 1), MfArray([[[  1.5384778 ,   0.7338279 ],
                                                                  [ -3.89595534, -14.92299323]],

                                                                 [[-30.33356629, -33.64306392],
                                                                  [ 17.81605106, 189.39145385]]] as [[[Float]]]).round(decimals: 1))
            XCTAssertEqual(ret.imag!.round(decimals: 1), MfArray([[[ -1.27792255,  -3.93211096],
                                                                   [ -6.98724065,  -5.77098545]],

                                                                  [[ 10.19189658,  54.44395513],
                                                                   [126.75404658, 172.24075363]]] as [[[Float]]]).round(decimals: 1))
        }
    }
    
    func testSubscript(){
        do{
            let real = Matft.arange(start: 1, to: 17, by: 1).reshape([2,2,4])
            let imag = Matft.arange(start: 1, to: -15, by: -1).reshape([2,2,4])
            let a = MfArray(real: real, imag: imag)
            
            var b = a[0, Matft.all]
            XCTAssertEqual(b.real, real[0, Matft.all])
            XCTAssertEqual(b.imag!, imag[0, Matft.all])
            
            b = a[0, Matft.all].T
            XCTAssertEqual(b.real, real[0, Matft.all].T)
            XCTAssertEqual(b.imag!, imag[0, Matft.all].T)
            
            b = a[0, Matft.reverse]
            XCTAssertEqual(b.real, real[0, Matft.reverse])
            XCTAssertEqual(b.imag!, imag[0, Matft.reverse])
            
            b = a[0, Matft.reverse].T
            XCTAssertEqual(b.real, real[0, Matft.reverse].T)
            XCTAssertEqual(b.imag!, imag[0, Matft.reverse].T)
            
            b = a[0, Matft.all, 1~<2]
            XCTAssertEqual(b.real, real[0, Matft.all, 1~<2])
            XCTAssertEqual(b.imag!, imag[0, Matft.all, 1~<2])
            
            b = a[real > 5]
            XCTAssertEqual(b.real, real[real > 5])
            XCTAssertEqual(b.imag!, imag[real > 5])
            
            let indices = MfArray([1, -1])
            b = a[indices]
            XCTAssertEqual(b.real, real[indices])
            XCTAssertEqual(b.imag!, imag[indices])
            
            b = a[indices, indices]
            XCTAssertEqual(b.real, real[indices, indices])
            XCTAssertEqual(b.imag!, imag[indices, indices])

            // getter -> setter round trip
            let c = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
            c[real > 5] = a[real > 5]
            XCTAssertEqual(c.real[real > 5], real[real > 5])
            XCTAssertEqual(c.imag![real > 5], imag[real > 5])

            c[indices] = a[indices]
            XCTAssertEqual(c.real[indices], real[indices])
            XCTAssertEqual(c.imag![indices], imag[indices])

            c[indices, indices] = a[indices, indices]
            XCTAssertEqual(c.real[indices, indices], real[indices, indices])
            XCTAssertEqual(c.imag![indices, indices], imag[indices, indices])
        }
    }

    func testBasicIndexingSet(){
        do{
            let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,4,2])
            let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,4,2])
            let a = MfArray(real: real, imag: imag)

            // complex <- complex
            a[Matft.all, 2, Matft.all] = MfArray(real: MfArray([3]), imag: MfArray([-1]))
            // complex <- real
            a[0, 1, Matft.all] = MfArray([7])
            // complex <- complex scalar
            a[1, 0, 0] = MfArray(real: MfArray([100]), imag: MfArray([200]))
            // complex <- real scalar
            a[1, 0, 1] = 5

            _assertComplexEqual(a,
                                real: MfArray([[[  0,   1],
                                                [  7,   7],
                                                [  3,   3],
                                                [  6,   7]],
                                               [[100,   5],
                                                [ 10,  11],
                                                [  3,   3],
                                                [ 14,  15]]]),
                                imag: MfArray([[[  0,  -1],
                                                [  0,   0],
                                                [ -1,  -1],
                                                [ -6,  -7]],
                                               [[200,   0],
                                                [-10, -11],
                                                [ -1,  -1],
                                                [-14, -15]]]))
        }
    }

    func testBooleanIndexingSet(){
        // complex <- complex
        do{
            let real = Matft.arange(start: 0, to: 8, by: 1).reshape([2,4])
            let imag = Matft.arange(start: 0, to: -8, by: -1).reshape([2,4])
            let a = MfArray(real: real, imag: imag)

            a[real > 3] = MfArray(real: MfArray([100]), imag: MfArray([-100]))
            _assertComplexEqual(a,
                                real: MfArray([[  0,   1,   2,   3],
                                               [100, 100, 100, 100]]),
                                imag: MfArray([[   0,   -1,   -2,   -3],
                                               [-100, -100, -100, -100]]))
        }

        // complex <- complex with lower dimensional indices
        do{
            let real = Matft.arange(start: 0, to: 12, by: 1).reshape([3,2,2])
            let imag = Matft.arange(start: 0, to: -12, by: -1).reshape([3,2,2])
            let a = MfArray(real: real, imag: imag)

            a[MfArray([true, false, true])] = MfArray(real: Matft.arange(start: 100, to: 108, by: 1).reshape([2,2,2]),
                                                      imag: Matft.arange(start: -100, to: -108, by: -1).reshape([2,2,2]))
            _assertComplexEqual(a,
                                real: MfArray([[[100, 101],
                                                [102, 103]],
                                               [[  4,   5],
                                                [  6,   7]],
                                               [[104, 105],
                                                [106, 107]]]),
                                imag: MfArray([[[-100, -101],
                                                [-102, -103]],
                                               [[  -4,   -5],
                                                [  -6,   -7]],
                                               [[-104, -105],
                                                [-106, -107]]]))
        }

        // real <- complex
        do{
            let a = Matft.arange(start: 0, to: 6, by: 1).reshape([2,3])

            a[MfArray([[false, true, false],
                       [true, false, true]])] = MfArray(real: MfArray([7]), imag: MfArray([1]))
            _assertComplexEqual(a,
                                real: MfArray([[0, 7, 2],
                                               [7, 4, 7]]),
                                imag: MfArray([[0, 1, 0],
                                               [1, 0, 1]]))
        }

        // complex <- real
        do{
            let real = Matft.arange(start: 0, to: 6, by: 1).reshape([2,3])
            let imag = Matft.arange(start: 10, to: 16, by: 1).reshape([2,3])
            let a = MfArray(real: real, imag: imag)

            a[MfArray([[true, false, false],
                       [false, false, true]])] = MfArray([-1])
            _assertComplexEqual(a,
                                real: MfArray([[-1, 1, 2],
                                               [ 3, 4, -1]]),
                                imag: MfArray([[ 0, 11, 12],
                                               [13, 14,  0]]))
        }
    }

    func testFancyIndexingSet(){
        // 1d complex <- complex
        do{
            let real = Matft.arange(start: 0, to: 6, by: 1)
            let imag = Matft.arange(start: 0, to: -6, by: -1)
            let a = MfArray(real: real, imag: imag)

            a[MfArray([3, -1, 0])] = MfArray(real: MfArray([10, 20, 30]), imag: MfArray([-10, -20, -30]))
            _assertComplexEqual(a,
                                real: MfArray([ 30,  1,  2,  10,  4,  20]),
                                imag: MfArray([-30, -1, -2, -10, -4, -20]))
        }

        // nd complex <- complex with broadcasting
        do{
            let real = Matft.arange(start: 0, to: 12, by: 1).reshape([3,2,2])
            let imag = Matft.arange(start: 0, to: -12, by: -1).reshape([3,2,2])
            let a = MfArray(real: real, imag: imag)

            a[MfArray([2, 0])] = MfArray(real: Matft.arange(start: 100, to: 104, by: 1).reshape([2,2]),
                                         imag: Matft.arange(start: -100, to: -104, by: -1).reshape([2,2]))
            _assertComplexEqual(a,
                                real: MfArray([[[100, 101],
                                                [102, 103]],
                                               [[  4,   5],
                                                [  6,   7]],
                                               [[100, 101],
                                                [102, 103]]]),
                                imag: MfArray([[[-100, -101],
                                                [-102, -103]],
                                               [[  -4,   -5],
                                                [  -6,   -7]],
                                               [[-100, -101],
                                                [-102, -103]]]))
        }

        // transposed view
        do{
            let real = Matft.arange(start: 0, to: 6, by: 1).reshape([2,3])
            let imag = Matft.arange(start: 10, to: 16, by: 1).reshape([2,3])
            let a = MfArray(real: real, imag: imag)

            a.T[MfArray([1])] = MfArray(real: MfArray([-1]), imag: MfArray([-2]))
            _assertComplexEqual(a,
                                real: MfArray([[ 0, -1,  2],
                                               [ 3, -1,  5]]),
                                imag: MfArray([[10, -2, 12],
                                               [13, -2, 15]]))
        }

        // real <- complex
        do{
            let a = Matft.arange(start: 0, to: 4, by: 1)

            a[MfArray([1])] = MfArray(real: MfArray([5]), imag: MfArray([6]))
            _assertComplexEqual(a,
                                real: MfArray([0, 5, 2, 3]),
                                imag: MfArray([0, 6, 0, 0]))
        }

        // complex <- real
        do{
            let real = Matft.arange(start: 0, to: 4, by: 1).reshape([2,2])
            let imag = Matft.arange(start: 4, to: 8, by: 1).reshape([2,2])
            let a = MfArray(real: real, imag: imag)

            a[MfArray([0])] = MfArray([9])
            _assertComplexEqual(a,
                                real: MfArray([[9, 9],
                                               [2, 3]]),
                                imag: MfArray([[0, 0],
                                               [6, 7]]))
        }
    }

    func testFancyIndexingSetAll(){
        // complex <- complex
        do{
            let real = Matft.arange(start: 0, to: 27, by: 1).reshape([3,3,3])
            let imag = Matft.arange(start: 0, to: -27, by: -1).reshape([3,3,3])
            let a = MfArray(real: real, imag: imag)

            a[MfArray([-2, 1, 0]), MfArray([0, 1, 0])] = MfArray(real: MfArray([999]), imag: MfArray([-999]))
            _assertComplexEqual(a,
                                real: MfArray([[[999, 999, 999],
                                                [  3,   4,   5],
                                                [  6,   7,   8]],
                                               [[999, 999, 999],
                                                [999, 999, 999],
                                                [ 15,  16,  17]],
                                               [[ 18,  19,  20],
                                                [ 21,  22,  23],
                                                [ 24,  25,  26]]]),
                                imag: MfArray([[[-999, -999, -999],
                                                [  -3,   -4,   -5],
                                                [  -6,   -7,   -8]],
                                               [[-999, -999, -999],
                                                [-999, -999, -999],
                                                [ -15,  -16,  -17]],
                                               [[ -18,  -19,  -20],
                                                [ -21,  -22,  -23],
                                                [ -24,  -25,  -26]]]))
        }

        // all axes are indexed, and transposed view
        do{
            let real = MfArray([[1, 2], [3, 4], [5, 6]])
            let imag = MfArray([[10, 20], [30, 40], [50, 60]])
            let a = MfArray(real: real, imag: imag)

            a[MfArray([0, 1, 2]), MfArray([0, -1, 0])] = MfArray(real: MfArray([999, 888, 777]), imag: MfArray([-9, -8, -7]))
            _assertComplexEqual(a,
                                real: MfArray([[999,   2],
                                               [  3, 888],
                                               [777,   6]]),
                                imag: MfArray([[-9, 20],
                                               [30, -8],
                                               [-7, 60]]))

            a.T[MfArray([0, 1, -1]), MfArray([0, 1, 0])] = MfArray(real: MfArray([-999, -888, -777]), imag: MfArray([1, 2, 3]))
            _assertComplexEqual(a,
                                real: MfArray([[-999, -777],
                                               [   3, -888],
                                               [ 777,    6]]),
                                imag: MfArray([[ 1,  3],
                                               [30,  2],
                                               [-7, 60]]))
        }

        // real <- complex
        do{
            let a = Matft.arange(start: 0, to: 4, by: 1).reshape([2,2])

            a[MfArray([0, 1]), MfArray([1, 0])] = MfArray(real: MfArray([7]), imag: MfArray([8]))
            _assertComplexEqual(a,
                                real: MfArray([[0, 7],
                                               [7, 3]]),
                                imag: MfArray([[0, 8],
                                               [8, 0]]))
        }

        // complex <- real
        do{
            let real = Matft.arange(start: 0, to: 4, by: 1).reshape([2,2])
            let imag = Matft.arange(start: 4, to: 8, by: 1).reshape([2,2])
            let a = MfArray(real: real, imag: imag)

            a[MfArray([1]), MfArray([1])] = MfArray([-1])
            _assertComplexEqual(a,
                                real: MfArray([[0,  1],
                                               [2, -1]]),
                                imag: MfArray([[4,  5],
                                               [6,  0]]))
        }
    }

    private func _assertComplexEqual(_ mfarray: MfArray, real: MfArray, imag: MfArray, file: StaticString = #filePath, line: UInt = #line){
        XCTAssertTrue(mfarray.isComplex, "must be complex", file: file, line: line)
        XCTAssertEqual(mfarray.real, real, file: file, line: line)
        guard let mfimag = mfarray.imag else { return }
        XCTAssertEqual(mfimag, imag, file: file, line: line)
    }
}
#endif
