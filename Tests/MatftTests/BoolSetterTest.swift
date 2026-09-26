import XCTest

import Matft

/// `a[mask] = v` over layouts, value shapes and types. Expected values are computed in row major order like numpy
final class BoolSetterTests: XCTestCase {
    
    /// Assign `values` (cycled when it has one element) to the elements where `mask` is true, in row major order
    private func expected(_ x: [Double], _ mask: [Bool], _ values: [Double]) -> [Double]{
        var ret = x
        var k = 0
        for i in 0..<ret.count where mask[i]{
            ret[i] = values.count == 1 ? values[0] : values[k]
            k += 1
        }
        return ret
    }
    
    private func targets() -> [(String, () -> MfArray)]{
        let base = { Matft.arange(start: -12, to: 12, by: 1, shape: [2, 3, 4], mftype: .Float) }
        return [
            ("contiguous", { base() }),
            ("column", { base().to_contiguous(mforder: .Column) }),
            ("transposed", { base().T }),
            ("permuted", { base().transpose(axes: [1, 0, 2]) }),
            ("view", { base()[1~<2] }),
            ("strided", { base()[Matft.all, Matft.all, 0~<4~<2] }),
            ("reversed", { base()[Matft.reverse] }),
            ("double", { base().astype(.Double) }),
            ("int", { base().astype(.Int) }),
        ]
    }
    
    func testScalar(){
        for (name, make) in targets(){
            let x = make()
            let before = rowValues(x)
            let mask = x > 5
            let maskValues = mask.to_contiguous(mforder: .Row).data.map{ $0 as! Bool }
            x[mask] = MfArray([100])
            XCTAssertEqual(rowValues(x), expected(before, maskValues, [100]), name)
        }
    }
    
    func testArray(){
        for (name, make) in targets(){
            let x = make()
            let before = rowValues(x)
            let mask = x < -3
            let maskValues = mask.to_contiguous(mforder: .Row).data.map{ $0 as! Bool }
            let n = maskValues.filter{ $0 }.count
            let values = (0..<n).map{ Double($0) * 10 + 1 }
            x[mask] = MfArray(values.map{ Float($0) })
            XCTAssertEqual(rowValues(x), expected(before, maskValues, values), name)
        }
    }
    
    // the view's base is updated through the view
    func testViewUpdatesBase(){
        let a = Matft.arange(start: -12, to: 12, by: 1, shape: [2, 3, 4], mftype: .Float)
        let v = a[1~<2]
        v[v > 5] = MfArray([7])
        XCTAssertEqual(rowValues(a), (-12..<12).map{ $0 > 5 ? 7 : Double($0) })
        let t = a.T
        t[t < -10] = MfArray([-1])
        XCTAssertEqual(rowValues(a), (-12..<12).map{ $0 > 5 ? 7 : ($0 < -10 ? -1 : Double($0)) })
    }
    
    // a mask with fewer dimensions selects sub arrays
    func testLowerDimMask(){
        let a = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4], mftype: .Float)
        a[MfArray([false, true])] = MfArray([-1])
        XCTAssertEqual(rowValues(a), (0..<24).map{ $0 >= 12 ? -1 : Double($0) })
        let b = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4], mftype: .Float)
        b[MfArray([true, false])] = Matft.arange(start: 100, to: 112, by: 1, shape: [3, 4], mftype: .Float)
        XCTAssertEqual(rowValues(b), (0..<24).map{ $0 < 12 ? Double($0 + 100) : Double($0) })
        // broadcast the value along the rest dimensions
        let c = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4], mftype: .Float)
        c[MfArray([[true, false, true], [false, false, true]])] = MfArray([1, 2, 3, 4] as [Float])
        XCTAssertEqual(rowValues(c), (0..<24).map{ i -> Double in
            let row = i / 4
            return [0, 2, 5].contains(row) ? Double(i % 4 + 1) : Double(i)
        })
    }
    
    // non finite values are kept or assigned as they are
    func testNonFinite(){
        let x = MfArray([Float.infinity, -Float.infinity, Float.nan, 1, 2] as [Float])
        x[MfArray([false, false, false, true, false])] = MfArray([Float.infinity] as [Float])
        let v = x.data.map{ $0 as! Float }
        XCTAssertEqual(v[0], Float.infinity)
        XCTAssertEqual(v[1], -Float.infinity)
        XCTAssertTrue(v[2].isNaN)
        XCTAssertEqual(v[3], Float.infinity)
        XCTAssertEqual(v[4], 2)
        
        let y = MfArray([Float.infinity, 1] as [Float])
        y[MfArray([true, false])] = MfArray([Float.nan] as [Float])
        XCTAssertTrue((y.data[0] as! Float).isNaN)
        XCTAssertEqual(y.data[1] as! Float, 1)
    }
    
    // the assigned value is converted into the target's type
    func testTypes(){
        let i = MfArray([1, 2, 3])
        i[i > 1] = MfArray([7.0] as [Double])
        XCTAssertEqual(i, MfArray([1, 7, 7]))
        XCTAssertEqual(i.mftype, .Int)
        let d = MfArray([1, 2, 3] as [Double])
        d[d > 1] = MfArray([5, 6])
        XCTAssertEqual(d, MfArray([1, 5, 6] as [Double]))
        XCTAssertEqual(d.mftype, .Double)
        // the mask itself is not modified
        let m = MfArray([true, false, true])
        let f = MfArray([0, 0, 0] as [Float])
        f[m] = MfArray([9])
        XCTAssertEqual(m, MfArray([true, false, true]))
        XCTAssertEqual(f, MfArray([9, 0, 9] as [Float]))
    }
    
    #if canImport(Accelerate)
    func testComplex(){
        let z = MfArray(real: MfArray([1, 2, 3] as [Float]), imag: MfArray([4, 5, 6] as [Float]))
        z[z.real > 1] = MfArray(real: MfArray([0] as [Float]), imag: MfArray([-1] as [Float]))
        XCTAssertEqual(z.real, MfArray([1, 0, 0] as [Float]))
        XCTAssertEqual(z.imag!, MfArray([4, -1, -1] as [Float]))
        // a real value gives 0 imaginary part
        z[z.real > 0] = MfArray([9] as [Float])
        XCTAssertEqual(z.real, MfArray([9, 0, 0] as [Float]))
        XCTAssertEqual(z.imag!, MfArray([0, -1, -1] as [Float]))
    }
    #endif
}
