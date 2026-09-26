import XCTest

@testable import Matft

final class DenseLayoutTests: XCTestCase {
    func testMfDataRefOffset(){
        // real and imag views with an offset (a[1:3] of a (3, 2) array)
        let real = Matft.arange(start: 0, to: 6, by: 1, shape: [3, 2], mftype: .Float)
        let imag = real * 10
        let rv = real[1~<3], iv = imag[1~<3]
        let data = MfData(ref_realdata: rv.mfdata, ref_imagdata: iv.mfdata, offset: rv.mfdata.offset)
        // the offset is kept and the data are copied from the beginning, not from the offset
        XCTAssertEqual(data.offset, rv.mfdata.offset)
        XCTAssertEqual(data.storedSize, 6)
        let z = MfArray(mfdata: data, mfstructure: MfStructure(shape: rv.shape, strides: rv.strides))
        XCTAssertEqual(z.real, MfArray([[2, 3], [4, 5]], mftype: .Float))
        XCTAssertEqual(z.imag!, MfArray([[20, 30], [40, 50]], mftype: .Float))
    }

    
    func testCheckDense(){
        let a = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4])
        // row / column contiguous
        XCTAssertTrue(check_dense(a) === a)
        let t = a.T
        XCTAssertTrue(check_dense(t) === t)
        // permuted but dense: no copy
        let p = a.transpose(axes: [1, 0, 2])
        XCTAssertTrue(check_dense(p) === p)
        // slice view (offset, gap): copied into row contiguous
        let v = a[1~<2]
        XCTAssertFalse(check_dense(v) === v)
        XCTAssertTrue(check_dense(v).mfstructure.row_contiguous)
        let s = a[Matft.all, Matft.all, 0~<4~<2]
        XCTAssertFalse(check_dense(s) === s)
        // broadcast (stride 0)
        let bc = MfArray([1, 2, 3]).broadcast_to(shape: [2, 3])
        XCTAssertFalse(check_dense(bc) === bc)
    }
    
    // element-wise ops on a dense permuted array must keep values and layout (numpy computes them without copy too)
    func testElementwiseOnPermuted(){
        let a = Matft.arange(start: -12, to: 12, by: 1, shape: [2, 3, 4])
        let p = a.transpose(axes: [2, 0, 1])
        let pc = p.to_contiguous(mforder: .Row)
        
        XCTAssertEqual(p.sign(), pc.sign())
        XCTAssertEqual(Matft.math.sin(p), Matft.math.sin(pc))
        XCTAssertEqual(p > 0, pc > 0)
        XCTAssertEqual(p + 1, pc + 1)
        XCTAssertEqual(1 - p, 1 - pc)
        XCTAssertEqual(-p, -pc)
        XCTAssertEqual(p.clip(min: -3, max: 3), pc.clip(min: -3, max: 3))
        
        // row contiguous slice view: must not process the base's whole stored data
        let v = a[1~<2]
        XCTAssertEqual(v.sign(), MfArray([[[0, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]]]))
        XCTAssertEqual(v.sign().storedSize, 12)
        XCTAssertEqual((v > 0).storedSize, 12)
        
        // the result keeps the input's strides instead of copying it
        XCTAssertEqual(p.sign().strides, p.strides)
        XCTAssertEqual(Matft.math.sin(p).strides, p.strides)
        XCTAssertEqual((p > 0).strides, p.strides)
        XCTAssertEqual((p + 1).strides, p.strides)
    }
    
    /// Expected row-major values of `src.transpose(axes: axes)` computed index by index
    private func transposedValues(_ values: [Float], shape: [Int], axes: [Int]) -> [Float]{
        let newshape = axes.map{ shape[$0] }
        var strides = [Int](repeating: 1, count: shape.count)
        for i in stride(from: shape.count - 2, through: 0, by: -1){ strides[i] = strides[i + 1] * shape[i + 1] }
        var ret: [Float] = []
        var idx = [Int](repeating: 0, count: shape.count)
        for _ in 0..<values.count{
            ret.append(values[zip(idx, axes).map{ $0 * strides[$1] }.reduce(0, +)])
            var k = shape.count - 1
            while k >= 0{ idx[k] += 1; if idx[k] < newshape[k]{ break }; idx[k] = 0; k -= 1 }
        }
        return ret
    }
    
    func testToContiguousPermutations(){
        let shape = [2, 3, 4, 5]
        let a = Matft.arange(start: 0, to: 120, by: 1, shape: shape, mftype: .Float)
        let values = (0..<120).map{ Float($0) }
        func permutations(_ xs: [Int]) -> [[Int]]{
            xs.count <= 1 ? [xs] : xs.flatMap{ x in permutations(xs.filter{ $0 != x }).map{ [x] + $0 } }
        }
        for axes in permutations([0, 1, 2, 3]){
            let p = a.transpose(axes: axes)
            XCTAssertEqual(p.to_contiguous(mforder: .Row).data as! [Float], transposedValues(values, shape: shape, axes: axes), "axes: \(axes)")
            XCTAssertEqual(p.astype(.Double).to_contiguous(mforder: .Row).data as! [Double], transposedValues(values, shape: shape, axes: axes).map{ Double($0) }, "axes: \(axes)")
        }
        
        // non-dense / negative strides fall back to the block copy
        let s = a[Matft.all, 0~<3~<2]
        XCTAssertEqual(s.to_contiguous(mforder: .Row), MfArray((0..<120).filter{ ($0 / 20) % 3 != 1 }.map{ Float($0) }, shape: [2, 2, 4, 5]))
        let f = a[Matft.reverse]
        XCTAssertEqual(f.to_contiguous(mforder: .Row).data as! [Float], Array(values[60..<120]) + Array(values[0..<60]))
    }
    
    func testBinaryOperationPermutations(){
        let shape = [2, 3, 4, 5]
        let a = Matft.arange(start: 0, to: 120, by: 1, shape: shape, mftype: .Float)
        for axes in [[0, 1, 2, 3], [3, 2, 1, 0], [0, 2, 1, 3], [1, 0, 3, 2], [0, 3, 2, 1]]{
            let inverse = axes.indices.map{ axes.firstIndex(of: $0)! }
            let p = (-a).transpose(axes: axes).to_contiguous(mforder: .Row).transpose(axes: inverse)
            // p equals -a element-wise, in a permuted layout
            XCTAssertEqual(a + p, Matft.nums(Float(0), shape: shape), "axes: \(axes)")
            XCTAssertEqual(p + a, Matft.nums(Float(0), shape: shape), "axes: \(axes)")
            XCTAssertEqual(a - p, a * 2, "axes: \(axes)")
            XCTAssertEqual(a > p, a > 0, "axes: \(axes)")
        }
        // broadcast operand (stride 0)
        let row = Matft.arange(start: 0, to: 5, by: 1, shape: [5], mftype: .Float)
        XCTAssertEqual(a.transpose(axes: [1, 0, 2, 3]) - row, (a - row).transpose(axes: [1, 0, 2, 3]))
    }

    // row contiguous slice views share the base's stored data: kernels must process `size` elements from the offset
    func testSliceViewKernels(){
        let a = Matft.arange(start: -12, to: 12, by: 1, shape: [2, 3, 4])
        let v = a[1~<2]
        
        let r = Matft.roll(v, shift: 1)
        XCTAssertEqual(r, MfArray([[[11, 0, 1, 2], [3, 4, 5, 6], [7, 8, 9, 10]]]))
        XCTAssertEqual(r.storedSize, 12)
        let r1 = Matft.roll(v, shift: 1, axis: 2)
        XCTAssertEqual(r1, MfArray([[[3, 0, 1, 2], [7, 4, 5, 6], [11, 8, 9, 10]]]))
        XCTAssertEqual(r1.storedSize, 12)
        
        // axis other than 0 on a plain array
        let b = Matft.arange(start: 0, to: 12, by: 1, shape: [2, 3, 2])
        XCTAssertEqual(Matft.roll(b, shift: 1, axis: 1), MfArray([[[4, 5], [0, 1], [2, 3]], [[10, 11], [6, 7], [8, 9]]]))
        XCTAssertEqual(Matft.roll(b, shift: -1, axis: 2), MfArray([[[1, 0], [3, 2], [5, 4]], [[7, 6], [9, 8], [11, 10]]]))
    }
    
    // mask indexing on a non row contiguous array
    func testBoolGetNonContiguous(){
        let a = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])
        let t = a.T // [[0, 3], [1, 4], [2, 5]]
        XCTAssertEqual(t[t > 1], MfArray([3, 4, 2, 5]))
        XCTAssertEqual(t[t < 4], MfArray([0, 3, 1, 2]))
    }
    
    #if canImport(Accelerate)
    func testComplexSliceViewKernels(){
        let real = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4], mftype: .Float)
        let imag = Matft.arange(start: 0, to: -24, by: -1, shape: [2, 3, 4], mftype: .Float)
        let z = MfArray(real: real, imag: imag)
        let zv = z[1~<2]
        let zc = MfArray(real: real[1~<2].to_contiguous(mforder: .Row), imag: imag[1~<2].to_contiguous(mforder: .Row))
        
        XCTAssertEqual(-zv, -zc)
        XCTAssertEqual((-zv).storedSize, 12)
        XCTAssertEqual(zv + 1, zc + 1)
        XCTAssertEqual((zv + 1).storedSize, 12)
        XCTAssertEqual(1 - zv, 1 - zc)
        XCTAssertEqual((1 - zv).storedSize, 12)
        XCTAssertEqual(Matft.complex.conjugate(zv), Matft.complex.conjugate(zc))
        XCTAssertEqual(Matft.complex.conjugate(zv).storedSize, 12)
        XCTAssertEqual(Matft.complex.abs(zv), Matft.complex.abs(zc))
        XCTAssertEqual(Matft.complex.abs(zv).storedSize, 12)
        XCTAssertEqual(Matft.complex.angle(zv).storedSize, 12)
    }
    
    func testComplexDeepcopy(){
        let z = MfArray(real: MfArray([0, 1, 2] as [Float]), imag: MfArray([10, 11, 12] as [Float]))
        XCTAssertEqual(Matft.deepcopy(z).imag!, MfArray([10, 11, 12] as [Float]))
        XCTAssertEqual(z.to_contiguous(mforder: .Column).imag!, MfArray([10, 11, 12] as [Float]))
        let zd = MfArray(real: MfArray([0, 1, 2] as [Double]), imag: MfArray([10, 11, 12] as [Double]))
        XCTAssertEqual(Matft.deepcopy(zd).imag!, MfArray([10, 11, 12] as [Double]))
    }
    
    // a real operand of a complex operation must not be converted in place
    func testRealOperandUnchanged(){
        let x = MfArray([1, 2, 3] as [Float])
        let z = MfArray(real: MfArray([0, 1, 2] as [Float]), imag: MfArray([10, 11, 12] as [Float]))
        let s = x + z
        XCTAssertEqual(s, MfArray(real: MfArray([1, 3, 5] as [Float]), imag: MfArray([10, 11, 12] as [Float])))
        XCTAssertTrue(x.isReal)
        let s2 = z * x
        XCTAssertEqual(s2, MfArray(real: MfArray([0, 2, 6] as [Float]), imag: MfArray([10, 22, 36] as [Float])))
        XCTAssertTrue(x.isReal)
    }
    #endif
}
