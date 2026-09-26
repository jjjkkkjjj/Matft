import XCTest

@testable import Matft

/// Operations whose algorithms were replaced must keep values, shapes and types
final class AlgorithmicTests: XCTestCase {

    /// Values of `f` over row major indices of `shape`
    private func expected(_ shape: [Int], _ f: ([Int]) -> Double) -> [Double]{
        var ret: [Double] = []
        var idx = [Int](repeating: 0, count: shape.count)
        for _ in 0..<shape.reduce(1, *){
            ret.append(f(idx))
            var k = shape.count - 1
            while k >= 0{ idx[k] += 1; if idx[k] < shape[k]{ break }; idx[k] = 0; k -= 1 }
        }
        return ret
    }

    private func sources() -> [(String, MfArray)]{
        // values: (i*7 + 3) % 11 - 5 in row major order of the logical shape [2, 3, 4]
        let values = (0..<24).map{ Float(($0 * 7 + 3) % 11 - 5) }
        let a = MfArray(values, shape: [2, 3, 4])
        return layoutVariants(a).map{ ($0.name, $0.array) } + [
            ("double", a.astype(.Double)),
            ("int", a.astype(.Int)),
        ]
    }
    private func value(_ idx: [Int]) -> Double{
        Double(((idx[0]*12 + idx[1]*4 + idx[2]) * 7 + 3) % 11 - 5)
    }

    func testCumsum(){
        for (name, x) in sources(){
            for axis in 0..<3{
                let ret = Matft.stats.cumsum(x, axis: axis)
                XCTAssertEqual(ret.shape, [2, 3, 4], "\(name) \(axis)")
                XCTAssertEqual(ret.mftype, x.mftype, "\(name) \(axis)")
                XCTAssertEqual(rowValues(ret), expected([2, 3, 4]){ idx in
                    (0...idx[axis]).map{ k -> Double in var i = idx; i[axis] = k; return value(i) }.reduce(0, +)
                }, "\(name) \(axis)")
            }
            // flatten
            let flat = Matft.stats.cumsum(x)
            XCTAssertEqual(flat.shape, [24], name)
            var acc = 0.0
            XCTAssertEqual(rowValues(flat), expected([2, 3, 4]){ acc += value($0); return acc }, name)
        }
        // Bool is summed as Int like numpy
        let b = Matft.stats.cumsum(MfArray([true, false, true]))
        XCTAssertEqual(b.mftype, .Int)
        XCTAssertEqual(b, MfArray([1, 1, 2]))
        // large 1d (partial sums stay below 2^24, where Int stored as Float is exact)
        let v = Matft.arange(start: 0, to: 5000, by: 1)
        let cv = Matft.stats.cumsum(v)
        XCTAssertEqual(cv.mftype, .Int)
        XCTAssertEqual(cv.data.last as! Int, 12497500)
        XCTAssertEqual(Array(cv.data.prefix(4)) as! [Int], [0, 1, 3, 6])
    }

    // the generic accumulation keeps the shape for any axis
    func testUfuncAccumulate(){
        let x = Matft.arange(start: 1, to: 25, by: 1, shape: [2, 3, 4], mftype: .Float)
        for axis in 0..<3{
            let ret = Matft.ufuncAccumulate(mfarray: x, ufunc: Matft.mul, axis: axis)
            XCTAssertEqual(ret.shape, [2, 3, 4], "\(axis)")
            XCTAssertEqual(rowValues(ret), expected([2, 3, 4]){ idx in
                (0...idx[axis]).map{ k -> Double in var i = idx; i[axis] = k; return Double(i[0]*12 + i[1]*4 + i[2] + 1) }.reduce(1, *)
            }, "\(axis)")
        }
    }
    
    func testArgmaxArgmin(){
        for (name, x) in sources(){
            for axis in 0..<3{
                var shape = [2, 3, 4]
                shape.remove(at: axis)
                // the first index of the max / min along the axis
                func arg(_ idx: [Int], _ better: (Double, Double) -> Bool) -> Double{
                    var full = idx
                    full.insert(0, at: axis)
                    var best = value(full), bestK = 0
                    for k in 1..<[2, 3, 4][axis]{
                        full[axis] = k
                        if better(value(full), best){ best = value(full); bestK = k }
                    }
                    return Double(bestK)
                }
                XCTAssertEqual(rowValues(x.argmax(axis: axis)), expected(shape){ arg($0, >) }, "\(name) \(axis)")
                XCTAssertEqual(rowValues(x.argmin(axis: axis)), expected(shape){ arg($0, <) }, "\(name) \(axis)")
            }
            // the max 5 appears first at the flat index 1
            XCTAssertEqual(rowValues(x.argmax()), [1], name)
        }
    }

    func testArgsort(){
        // no ties: argsort is unique
        let values = (0..<24).map{ Float(($0 * 7) % 24) - 12 }
        let a = MfArray(values, shape: [2, 3, 4])
        for (name, x) in [("contiguous", a), ("column", a.to_contiguous(mforder: .Column)), ("double", a.astype(.Double))]{
            for axis in 0..<3{
                let ret = x.argsort(axis: axis)
                XCTAssertEqual(ret.shape, [2, 3, 4], "\(name) \(axis)")
                XCTAssertEqual(rowValues(ret), expected([2, 3, 4]){ idx in
                    let line = (0..<[2, 3, 4][axis]).map{ k -> Double in var i = idx; i[axis] = k; return Double(values[i[0]*12 + i[1]*4 + i[2]]) }
                    return Double(line.indices.sorted{ line[$0] < line[$1] }[idx[axis]])
                }, "\(name) \(axis)")
                let desc = x.argsort(axis: axis, order: .Descending)
                XCTAssertEqual(rowValues(desc), expected([2, 3, 4]){ idx in
                    let line = (0..<[2, 3, 4][axis]).map{ k -> Double in var i = idx; i[axis] = k; return Double(values[i[0]*12 + i[1]*4 + i[2]]) }
                    return Double(line.indices.sorted{ line[$0] > line[$1] }[idx[axis]])
                }, "\(name) \(axis) desc")
            }
        }
    }

    // sort / argsort do not modify the input
    func testSortKeepsInput(){
        let x = MfArray([[3, 1, 2], [9, 7, 8]] as [[Float]])
        XCTAssertEqual(x.sort(axis: 1), MfArray([[1, 2, 3], [7, 8, 9]] as [[Float]]))
        XCTAssertEqual(x.argsort(axis: 1), MfArray([[1, 2, 0], [1, 2, 0]]))
        XCTAssertEqual(x.sort(axis: 0), x)
        XCTAssertEqual(x, MfArray([[3, 1, 2], [9, 7, 8]] as [[Float]]))
    }
    
    func testNestedArrayInit(){
        let rows: [[Float]] = (0..<30).map{ i in (0..<7).map{ Float(i * 7 + $0) } }
        let a = MfArray(rows)
        XCTAssertEqual(a.shape, [30, 7])
        XCTAssertEqual(a.mftype, .Float)
        XCTAssertEqual(rowValues(a), (0..<210).map{ Double($0) })

        let c = MfArray(rows, mforder: .Column)
        XCTAssertEqual(c.shape, [30, 7])
        XCTAssertEqual(rowValues(c), (0..<210).map{ Double($0) })
        XCTAssertTrue(c.mfstructure.column_contiguous)

        let cube: [[[Int]]] = (0..<3).map{ i in (0..<4).map{ j in (0..<5).map{ i * 20 + j * 5 + $0 } } }
        let b = MfArray(cube)
        XCTAssertEqual(b.shape, [3, 4, 5])
        XCTAssertEqual(b.mftype, .Int)
        XCTAssertEqual(rowValues(b), (0..<60).map{ Double($0) })
        XCTAssertEqual(rowValues(MfArray(cube, mforder: .Column)), (0..<60).map{ Double($0) })

        let d = MfArray([[1.5, 2.5], [3.5, 4.5]] as [[Double]])
        XCTAssertEqual(d.mftype, .Double)
        XCTAssertEqual(rowValues(d), [1.5, 2.5, 3.5, 4.5])
        XCTAssertEqual(MfArray([[true, false], [false, true]]).mftype, .Bool)
        XCTAssertEqual(MfArray([1, 2, 3]).shape, [3])
    }

    func testNums(){
        let f = Matft.nums(Float(1.5), shape: [3, 4])
        XCTAssertEqual(f.mftype, .Float)
        XCTAssertEqual(f.shape, [3, 4])
        XCTAssertEqual(rowValues(f), [Double](repeating: 1.5, count: 12))
        XCTAssertEqual(rowValues(Matft.nums(Double(-2.25), shape: [5])), [Double](repeating: -2.25, count: 5))
        XCTAssertEqual(Matft.nums(Double(-2.25), shape: [5]).mftype, .Double)
        XCTAssertEqual(Matft.nums(7, shape: [2, 2]).mftype, .Int)
        XCTAssertEqual(rowValues(Matft.nums(7, shape: [2, 2], mftype: .Float)), [7, 7, 7, 7])
        XCTAssertEqual(rowValues(Matft.nums(0, shape: [0])), [])
        XCTAssertTrue(Matft.nums(Float(1), shape: [2, 3], mforder: .Column).mfstructure.column_contiguous)
    }
}
