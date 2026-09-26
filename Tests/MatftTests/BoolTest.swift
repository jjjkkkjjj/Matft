import XCTest
//@testable import Matft
import Matft

final class BoolTests: XCTestCase {
    
    func testAllEqual() {
        do{
            let a = MfArray([true, false])
            XCTAssertTrue(a == MfArray([true, false]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertFalse(a == b)
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertTrue(a == c)
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertTrue(a == b)
            XCTAssertFalse(a[0~<,0~<,~<<-1] == Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]))
            
        }
    }
    
    //element-wise
    func testEqual(){
        do{
            let a = MfArray([true, false])
            XCTAssertEqual(a === MfArray([true, false]), MfArray([true, true]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray([true, false, true, true]))
            XCTAssertEqual(-3 === b, MfArray([false, false, true, false]))
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a === c, MfArray([true, true, true, true]))
            XCTAssertEqual(a === 1, MfArray([false, true, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertEqual(a === b, MfArray([[[true,true],
                                              [true,true]],
            
                                             [[true,true],
                                              [true,true]]]))
            
            XCTAssertEqual(a[0~<,0~<,~<<-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray([[[false,false],
                                              [false,false]],
            
                                             [[false,false],
                                              [false,false]]]))
        }
    }
    
    
    func testLogicalNot(){
        do{
            let a = MfArray([true, false])
            XCTAssertEqual(!a, MfArray([false, true]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray([true, false, true, true]))
            XCTAssertEqual(!(a === b), MfArray([false, true, false, false]))
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(!(a === c), MfArray([false, false, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertEqual(!(a === b), MfArray([[[false,false],
                                              [false,false]],
            
                                             [[false,false],
                                              [false,false]]]))
            
            XCTAssertEqual(!(a[0~<,0~<,~<<-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2])),
                                    MfArray([[[true,true],
                                              [true,true]],
                                    
                                             [[true,true],
                                              [true,true]]]))
        }
    }
    
    func testNotEqual(){
        do{
            let a = MfArray([true, false])
            XCTAssertEqual(a !== a, MfArray([false, false]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray([true, false, true, true]))
            XCTAssertEqual(a !== b, MfArray([false, true, false, false]))
            XCTAssertEqual(2 !== b, MfArray([false, true, true, true]))
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a !== c, MfArray([false, false, false, false]))
            XCTAssertEqual(a !== 1, MfArray([true, false, true, true]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertEqual(a !== b, MfArray([[[false,false],
                                              [false,false]],
            
                                             [[false,false],
                                              [false,false]]]))
            
            XCTAssertEqual(a[0~<,0~<,~<<-1] !== Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray([[[true,true],
                                              [true,true]],
                                    
                                             [[true,true],
                                              [true,true]]]))
        }
    }
    
    // Expected values are taken from numpy (#18)
    func testCompareEdgeCases(){
        let T = true, F = false
        do{
            // [nan, -inf, -1, -0, 0, 5e-324, 1e-50, 1, 1e38, inf]
            let x = MfArray([Double.nan, -Double.infinity, -1.0, -0.0, 0.0, 5e-324, 1e-50, 1.0, 1e38, Double.infinity], mftype: .Double)
            
            XCTAssertEqual(x > 0, MfArray([F, F, F, F, F, T, T, T, T, T]))
            XCTAssertEqual(x >= 0, MfArray([F, F, F, T, T, T, T, T, T, T]))
            XCTAssertEqual(x < 0, MfArray([F, T, T, F, F, F, F, F, F, F]))
            XCTAssertEqual(x <= 0, MfArray([F, T, T, T, T, F, F, F, F, F]))
            XCTAssertEqual(x === 0, MfArray([F, F, F, T, T, F, F, F, F, F]))
            XCTAssertEqual(x !== 0, MfArray([T, T, T, F, F, T, T, T, T, T]))
            XCTAssertEqual(0 < x, MfArray([F, F, F, F, F, T, T, T, T, T]))
            XCTAssertEqual(0 >= x, MfArray([F, T, T, T, T, F, F, F, F, F]))
            XCTAssertEqual(x === Double.infinity, MfArray([F, F, F, F, F, F, F, F, F, T]))
            XCTAssertEqual(x === -Double.infinity, MfArray([F, T, F, F, F, F, F, F, F, F]))
            XCTAssertEqual(x > 1e38, MfArray([F, F, F, F, F, F, F, F, F, T]))
            XCTAssertEqual(x.astype(.Bool), MfArray([T, T, T, F, F, T, T, T, T, T]))
            XCTAssertEqual(Matft.logical_not(x), MfArray([F, F, F, T, T, F, F, F, F, F]))
        }
        
        do{
            // [nan, -inf, -1, -0, 0, min subnormal, 1, 1e38, inf]
            let x = MfArray([Float.nan, -Float.infinity, -1, -0.0, 0, Float.leastNonzeroMagnitude, 1, 1e38, Float.infinity] as [Float])
            
            XCTAssertEqual(x > 0, MfArray([F, F, F, F, F, T, T, T, T]))
            XCTAssertEqual(x <= 0, MfArray([F, T, T, T, T, F, F, F, F]))
            XCTAssertEqual(x === 0, MfArray([F, F, F, T, T, F, F, F, F]))
            XCTAssertEqual(x !== 0, MfArray([T, T, T, F, F, T, T, T, T]))
            XCTAssertEqual(x.astype(.Bool), MfArray([T, T, T, F, F, T, T, T, T]))
        }
        
        do{
            let y = MfArray([Double.nan, 1.0, -2.0, 1e-50], mftype: .Double)
            let z = MfArray([Double.nan, 1.0, 1e-50, 0.0], mftype: .Double)
            
            XCTAssertEqual(y > z, MfArray([F, F, F, T]))
            XCTAssertEqual(y <= z, MfArray([F, T, T, F]))
            XCTAssertEqual(y === z, MfArray([F, T, F, F]))
            XCTAssertEqual(y !== z, MfArray([T, F, T, T]))
        }
    }
    
    // == / != with a non-zero scalar: only the exact value matches (the neighbors of 5 do not)
    func testEqualNonZeroScalar(){
        let T = true, F = false
        do{
            let x = MfArray([Float.nan, -Float.infinity, Float(5).nextDown, 5, Float(5).nextUp, -5, Float.infinity] as [Float])
            XCTAssertEqual(x === 5, MfArray([F, F, F, T, F, F, F]))
            XCTAssertEqual(x !== 5, MfArray([T, T, T, F, T, T, T]))
            XCTAssertEqual(5 === x, MfArray([F, F, F, T, F, F, F]))
            XCTAssertEqual(x === -5, MfArray([F, F, F, F, F, T, F]))
        }
        do{
            let x = MfArray([Double.nan, -Double.infinity, Double(5).nextDown, 5, Double(5).nextUp, -5, Double.infinity] as [Double])
            XCTAssertEqual(x === 5, MfArray([F, F, F, T, F, F, F]))
            XCTAssertEqual(x !== 5, MfArray([T, T, T, F, T, T, T]))
            XCTAssertEqual(x === -5, MfArray([F, F, F, F, F, T, F]))
        }
        do{
            // Int: values are stored as Float
            let x = Matft.arange(start: -3, to: 4, by: 1)
            XCTAssertEqual(x === 2, MfArray([F, F, F, F, F, T, F]))
            XCTAssertEqual(x !== 2, MfArray([T, T, T, T, T, F, T]))
        }
    }
    
    // array vs array comparisons over layouts must keep values, shape and the operands
    func testCompareArraysLayouts(){
        for mftype in [MfType.Float, .Double, .Int]{
            let a = Matft.arange(start: -12, to: 12, by: 1, shape: [2, 3, 4], mftype: mftype)
            let b = Matft.math.abs(a) - 6 // equal where a == -3
            let ac = a.to_contiguous(mforder: .Row), bc = b.to_contiguous(mforder: .Row)
            let cases: [(String, MfArray, MfArray)] = [("same", a, b), ("transposed", a.T, b.T), ("mixed", a, b.T.to_contiguous(mforder: .Row).T),
                                 ("view", a[1~<2], b[0~<1]), ("broadcast", a, b[0, 0])]
            for (name, l, r) in cases{
                let lc = l.to_contiguous(mforder: .Row), rc = r.to_contiguous(mforder: .Row)
                let lvals = lc.data.map{ "\($0)" }, rvals = rc.data.map{ "\($0)" }
                let expected: [(MfArray, MfArray) -> MfArray] = [{ $0 > $1 }, { $0 >= $1 }, { $0 < $1 }, { $0 <= $1 }, { $0 === $1 }, { $0 !== $1 }]
                let ops: [(Float, Float) -> Bool] = [{ $0 > $1 }, { $0 >= $1 }, { $0 < $1 }, { $0 <= $1 }, { $0 == $1 }, { $0 != $1 }]
                let rb = rc.broadcast_to(shape: lc.shape).to_contiguous(mforder: .Row)
                let lf = lc.astype(.Float).data.map{ $0 as! Float }, rf = rb.astype(.Float).data.map{ $0 as! Float }
                for (i, (f, op)) in zip(expected, ops).enumerated(){
                    let ret = f(l, r)
                    XCTAssertEqual(ret.mftype, .Bool, "\(mftype) \(name) \(i)")
                    XCTAssertEqual(ret.shape, lc.shape, "\(mftype) \(name) \(i)")
                    XCTAssertEqual(ret.to_contiguous(mforder: .Row).data.map{ $0 as! Bool }, zip(lf, rf).map{ op($0, $1) }, "\(mftype) \(name) \(i)")
                }
                // operands are not modified
                XCTAssertEqual(l.to_contiguous(mforder: .Row).data.map{ "\($0)" }, lvals, "\(mftype) \(name)")
                XCTAssertEqual(r.to_contiguous(mforder: .Row).data.map{ "\($0)" }, rvals, "\(mftype) \(name)")
            }
            XCTAssertEqual(a, ac)
            XCTAssertEqual(b, bc)
        }
    }
    
    func testLogicalNotTypes(){
        let T = true, F = false
        XCTAssertEqual(Matft.logical_not(MfArray([-1, 0, 2])), MfArray([F, T, F]))
        XCTAssertEqual(Matft.logical_not(MfArray([T, F, T])), MfArray([F, T, F]))
        XCTAssertEqual(Matft.logical_not(MfArray([Float.nan, 0, -0.0, 0.5] as [Float])), MfArray([F, T, T, F]))
        let x = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])
        XCTAssertEqual(Matft.logical_not(x.T), MfArray([[T, F], [F, F], [F, F]]))
        XCTAssertEqual(Matft.logical_not(x).mftype, .Bool)
    }
    
    func testLess(){
        do{
            let a = MfArray([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])
            
            XCTAssertEqual(a < b, MfArray([[ true,  true,  true,  true, false],
                                           [ true,  true, false, false, false]]))
        }
        
        do{
            let a = MfArray([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray([[0.31286134, 0.69967412]])
            
            XCTAssertEqual(a < b, MfArray([[false,  true],
                                           [false,  true],
                                           [ true,  true]]))
        }
        
        do{
            let a = MfArray([[[0.51448786, 0.25203844],
                              [0.85263964, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])
            
            XCTAssertEqual(a < b, MfArray([[[false, false],
                                            [false, false]],

                                           [[false, false],
                                            [ true,  true]]]))
            
            XCTAssertEqual(a.transpose(axes: [2,0,1]) < b, MfArray([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }
    }
    
    func testGreater(){
        do{
            let a = MfArray([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])
            
            XCTAssertEqual(b > a, MfArray([[ true,  true,  true,  true, false],
                                           [ true,  true, false, false, false]]))
        }
        
        do{
            let a = MfArray([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray([[0.31286134, 0.69967412]])
            
            XCTAssertEqual(b > a, MfArray([[false,  true],
                                           [false,  true],
                                           [ true,  true]]))
        }
        
        do{
            let a = MfArray([[[0.51448786, 0.25203844],
                              [0.85263964, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])
            
            XCTAssertEqual(b > a, MfArray([[[false, false],
                                            [false, false]],

                                           [[false, false],
                                            [ true,  true]]]))
            
            XCTAssertEqual(b > a.transpose(axes: [2,0,1]), MfArray([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }
        
        do{
            let img = MfArray([[1, 2, 3],
                               [4, 5, 6],
                               [7, 8, 9]], mftype: .UInt8)
            img[img > 3] = MfArray([10], mftype: .UInt8)
            XCTAssertEqual(img, MfArray([[ 1,  2,  3],
                                         [10, 10, 10],
                                         [10, 10, 10]], mftype: .UInt8))
            //print(img)
        }
    }
    
    func testLessEqual(){
        do{
            let a = MfArray([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])
            
            XCTAssertEqual(a <= b, MfArray([[ true,  true,  true,  true, false],
                                           [ true,  true, true, false, false]]))
        }
        
        do{
            let a = MfArray([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray([[0.60871936, 0.69967412]])
            
            XCTAssertEqual(a <= b, MfArray([[false,  true],
                                           [ true,  true],
                                           [ true,  true]]))
        }
        
        do{
            let a = MfArray([[[0.51448786, 0.25203844],
                              [0.70294935, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])
            
            XCTAssertEqual(a <= b, MfArray([[[false, false],
                                            [ true, false]],

                                           [[false, false],
                                            [ true,  true]]]))
            
            XCTAssertEqual(a.transpose(axes: [2,0,1]) <= b, MfArray([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }
    }
    
    func testGreaterEqual(){
        do{
            let a = MfArray([[24, 15,  8, 65, 82],
                             [56, 17, 61, 44, 68]])
            let b = MfArray([[41, 30, 71, 93,  1],
                             [78, 31, 61, 24, 44]])
            
            XCTAssertEqual(b >= a, MfArray([[ true,  true,  true,  true, false],
                                           [ true,  true, true, false, false]]))
        }
        
        do{
            let a = MfArray([[0.74823355, 0.5969193 ],
                             [0.60871936, 0.45788907],
                             [0.14370076, 0.50432377]], mforder: .Column)
            let b = MfArray([[0.60871936, 0.69967412]])
            
            XCTAssertEqual(b >= a, MfArray([[false,  true],
                                           [ true,  true],
                                           [ true,  true]]))
        }
        
        do{
            let a = MfArray([[[0.51448786, 0.25203844],
                              [0.70294935, 0.90533189]],

                             [[0.9674209 , 0.84241149],
                              [0.29424463, 0.56187957]]])
            let b = MfArray([[[0.35092796, 0.0700771 ],
                              [0.70294935, 0.34088329]],

                             [[0.57415529, 0.08435943],
                              [0.96066889, 0.83724368]]])
            
            XCTAssertEqual(b >= a, MfArray([[[false, false],
                                            [ true, false]],

                                           [[false, false],
                                            [ true,  true]]]))
            
            XCTAssertEqual(b >= a.transpose(axes: [2,0,1]), MfArray([[[false, false],
                                                                     [false,  true]],

                                                                    [[ true, false],
                                                                     [ true,  true]]]))
        }
    }
}
