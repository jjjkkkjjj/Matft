import XCTest

@testable import Matft

final class OptParamsTests: XCTestCase {
    
    /// Collect all parameters and check they visit every element exactly once
    private func params(_ shape: [Int], _ b: [Int], _ s: [Int]) -> [(b_offset: Int, b_stride: Int, s_offset: Int, s_stride: Int, blocksize: Int)]{
        return Array(OptOffsetParamsSequence(shape: shape, bigger_strides: b, smaller_strides: s))
    }
    
    func testPreferUnitStride(){
        // a (row major) vs a.transpose(axes: [0,3,4,2,1,5])
        // The largest common block is 100 elements with strides (1000, 10), but strided vDSP access is slow.
        // The unit stride block (10 elements) must be chosen.
        let shape = [10,10,10,10,10,10]
        let ps = params(shape, [100000, 10000, 1000, 100, 10, 1], [100000, 100, 10, 1000, 10000, 1])
        XCTAssertEqual(ps.first!.b_stride, 1)
        XCTAssertEqual(ps.first!.s_stride, 1)
        XCTAssertEqual(ps.first!.blocksize, 10)
        XCTAssertEqual(ps.count, 100000)
    }
    
    func testVisitAllElements(){
        let shape = [3,4,5]
        let ps = params(shape, [20, 5, 1], [1, 3, 12])
        var bvisited = Set<Int>(), svisited = Set<Int>()
        for p in ps{
            for i in 0..<p.blocksize{
                bvisited.insert(p.b_offset + i*p.b_stride)
                svisited.insert(p.s_offset + i*p.s_stride)
            }
        }
        XCTAssertEqual(bvisited, Set(0..<60))
        XCTAssertEqual(svisited, Set(0..<60))
    }
    
    func testContiguousIsSingleBlock(){
        let ps = params([10,10], [10, 1], [10, 1])
        XCTAssertEqual(ps.count, 1)
        XCTAssertEqual(ps.first!.blocksize, 100)
    }
}
