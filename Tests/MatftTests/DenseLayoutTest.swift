import XCTest

@testable import Matft

final class DenseLayoutTests: XCTestCase {
    
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
}
