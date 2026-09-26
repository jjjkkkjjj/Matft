import XCTest

import Matft

/// Operations must give numpy's values for any memory layout of the input (see `layoutVariants`).
/// Base: a = np.array([[1, -2, 3], [4, 5, -6]], dtype=np.float32)
final class LayoutVariantTests: XCTestCase {

    private let base = MfArray([[1, -2, 3], [4, 5, -6]] as [[Float]])

    private func check(_ op: String, rtol: Double = 1e-6, _ f: (MfArray) -> MfArray, _ expected: [Double], shape: [Int]? = nil, file: StaticString = #filePath, line: UInt = #line){
        for dtype in [MfType.Float, .Double]{
            for (name, x) in layoutVariants(base.astype(dtype)){
                let ret = f(x)
                if let shape = shape{
                    XCTAssertEqual(ret.shape, shape, "\(op) \(dtype) \(name)", file: file, line: line)
                }
                XCTAssertEqual(ret.size, expected.count, "\(op) \(dtype) \(name)", file: file, line: line)
                guard ret.size == expected.count else { continue }
                let a = rowValues(ret)
                for i in 0..<a.count where !(Swift.abs(a[i] - expected[i]) <= 1e-7 + rtol * Swift.abs(expected[i])){
                    XCTFail("\(op) \(dtype) \(name): \(a) != \(expected)", file: file, line: line)
                    break
                }
            }
        }
    }

    func testArithmetic(){
        check("a + 1", { $0 + 1 }, [2, -1, 4, 5, 6, -5])
        check("1 - a", { 1 - $0 }, [0, 3, -2, -3, -4, 7])
        check("-a", { -$0 }, [-1, 2, -3, -4, -5, 6])
        check("a * 2", { $0 * 2 }, [2, -4, 6, 8, 10, -12])
        check("a / 2", { $0 / 2 }, [0.5, -1, 1.5, 2, 2.5, -3])
        check("12 / a", { 12 / $0 }, [12, -6, 4, 3, 2.4, -2])
        // a + a[::-1]
        check("a + reversed", { $0 + $0[Matft.reverse] }, [5, 3, -3, 5, 3, -3])
        check("a.T", { $0.T }, [1, 4, -2, 5, 3, -6], shape: [3, 2])
    }

    func testMath(){
        check("clip", { $0.clip(min: -1, max: 3) }, [1, -1, 3, 3, 3, -1])
        check("sin", { Matft.math.sin($0) }, [0.841471, -0.9092974, 0.14112, -0.7568025, -0.9589243, 0.2794155])
        check("exp", { Matft.math.exp($0 / 4) }, [1.2840254, 0.6065307, 2.1170001, 2.7182817, 3.4903429, 0.2231302])
        check("abs", { Matft.math.abs($0) }, [1, 2, 3, 4, 5, 6])
        check("sign", { Matft.math.sign($0) }, [1, -1, 1, 1, 1, -1])
        check("sqrt", { Matft.math.sqrt(Matft.math.abs($0)) }, [1, 1.4142135, 1.7320508, 2, 2.236068, 2.4494898])
        check("floor", { Matft.math.floor($0 / 4) }, [0, -1, 0, 1, 1, -2])
        check("power", { Matft.math.power(bases: $0, exponents: 2) }, [1, 4, 9, 16, 25, 36])
        check("a > 1", { ($0 > 1).astype(.Float) }, [0, 0, 1, 1, 1, 0])
    }

    func testReduce(){
        check("sum", { Matft.stats.sum($0) }, [5])
        check("sum 0", { Matft.stats.sum($0, axis: 0) }, [5, 3, -3])
        check("sum 1", { Matft.stats.sum($0, axis: 1) }, [2, 3])
        check("max 0", { Matft.stats.max($0, axis: 0) }, [4, 5, 3])
        check("min 1", { Matft.stats.min($0, axis: 1) }, [-2, -6])
        check("argmax 1", { Matft.stats.argmax($0, axis: 1) }, [2, 1])
        check("argmin 0", { Matft.stats.argmin($0, axis: 0) }, [0, 0, 1])
        check("mean 1", { Matft.stats.mean($0, axis: 1) }, [0.6666667, 1])
        check("std 0", { Matft.stats.std($0, axis: 0) }, [1.5, 3.5, 4.5])
        check("cumsum 1", { Matft.stats.cumsum($0, axis: 1) }, [1, -1, 2, 4, 9, 3])
        check("sort 1", { $0.sort(axis: 1) }, [-2, 1, 3, -6, 4, 5])
        check("argsort 1", { $0.argsort(axis: 1) }, [1, 0, 2, 2, 0, 1])
    }

    #if canImport(Accelerate)
    func testComplex(){
        // z = a + 1j * a[::-1]
        for (name, x) in layoutVariants(base){
            let z = MfArray(real: x, imag: x[Matft.reverse])
            // numpy: z * 2, z / 2, np.abs(z)
            let mul = z * 2
            XCTAssertEqual(rowValues(mul.real), [2, -4, 6, 8, 10, -12], name)
            XCTAssertEqual(rowValues(mul.imag!), [8, 10, -12, 2, -4, 6], name)
            let div = z / 2
            XCTAssertEqual(rowValues(div.real), [0.5, -1, 1.5, 2, 2.5, -3], name)
            XCTAssertEqual(rowValues(div.imag!), [2, 2.5, -3, 0.5, -1, 1.5], name)
            XCTAssertClose(Matft.complex.abs(z), MfArray([[4.1231055, 5.3851647, 6.7082043], [4.1231055, 5.3851647, 6.7082043]] as [[Float]]), rtol: 1e-6)
        }
    }

    func testComplexViews(){
        // complex scalar ops on views with an offset or a smaller size than the stored data
        let zbase = MfArray(real: MfArray([[1, 2], [3, 4], [5, 6]] as [[Float]]), imag: MfArray([[-1, -2], [-3, -4], [-5, -6]] as [[Float]]))
        for (name, v) in [("offset", zbase[1~<2]), ("prefix", zbase[0~<1])]{
            let first: Float = name == "offset" ? 3 : 1
            let mul = v * 2
            XCTAssertEqual(mul.shape, [1, 2], name)
            XCTAssertEqual(mul.storedSize, 2, name)
            XCTAssertEqual(rowValues(mul.real), [Double(first) * 2, Double(first + 1) * 2], name)
            XCTAssertEqual(rowValues(mul.imag!), [-Double(first) * 2, -Double(first + 1) * 2], name)
            let div = 2 / v
            XCTAssertEqual(div.shape, [1, 2], name)
            // numpy: 2 / (x - 1j*x) = (1 + 1j) / x
            XCTAssertClose(div.real, MfArray([[1 / first, 1 / (first + 1)]] as [[Float]]), rtol: 1e-6)
            XCTAssertClose(div.imag!, MfArray([[1 / first, 1 / (first + 1)]] as [[Float]]), rtol: 1e-6)
        }
    }
    #endif
}
