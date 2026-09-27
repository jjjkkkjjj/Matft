import XCTest

import Matft

/// Regression tests for the creation / conversion bugs found by the 2026-09-27 bug hunt. Expected values are numpy 2.0.2 outputs (quoted in the comments)
final class BugHuntCreationConversionTests: XCTestCase {

    // MARK: - mixed Int / Double literals

    /// `[0.5, 1, 2]` is passed to the `[Any]` init as Double and Int elements. np.array([0.5, 1, 2]) -> float64
    func testMixedIntDoubleLiteral() {
        XCTAssertClose(MfArray([0.5, 1, 2]), MfArray([0.5, 1.0, 2.0] as [Double]), checkType: true)
        XCTAssertClose(MfArray([1, 2.5]), MfArray([1.0, 2.5] as [Double]), checkType: true)
        XCTAssertClose(MfArray([0.5, 1, 2], mftype: .Double), MfArray([0.5, 1.0, 2.0] as [Double]), checkType: true)
        // np.array([0.5, 1, 2]).astype(int) -> [0, 1, 2]
        XCTAssertClose(MfArray([0.5, 1, 2], mftype: .Int), MfArray([0, 1, 2]), checkType: true)
        // the rows infer [Double] and [Int]. np.array([[1.0, 0], [3, 1]]) -> float64
        XCTAssertClose(MfArray([[1.0, 0], [3, 1]]), MfArray([[1.0, 0.0], [3.0, 1.0]] as [[Double]]), checkType: true)
        // np.array([True, 2]) -> int64 [1, 2]
        XCTAssertClose(MfArray([true, 2] as [Any]), MfArray([1, 2]), checkType: true)
        // np.array([np.int8(-1), np.uint8(200)]) -> int16 [-1, 200]
        XCTAssertClose(MfArray([Int8(-1), UInt8(200)] as [Any]), MfArray([-1, 200], mftype: .Int16), checkType: true)
    }

    // MARK: - integers beyond Int32 / UInt32

    /// np.array([3_000_000_000]) -> int64; these values are exact in Float
    func testLargeIntegers() {
        XCTAssertClose(MfArray([Int64(-3_000_000_000)]), MfArray([-3e9] as [Double], mftype: .Int64), checkType: true)
        XCTAssertClose(MfArray([UInt64(5_000_000_000)]), MfArray([5e9] as [Double], mftype: .UInt64), checkType: true)
        #if !arch(wasm32) // Int / UInt are 32-bit on wasm32, so these literals don't fit
        XCTAssertClose(MfArray([3_000_000_000]), MfArray([3e9] as [Double], mftype: .Int), checkType: true)
        XCTAssertClose(MfArray([-3_000_000_000], mftype: .Double), MfArray([-3e9] as [Double]), checkType: true)
        XCTAssertClose(MfArray([UInt(5_000_000_000)], mftype: .Double), MfArray([5e9] as [Double]), checkType: true)
        // np.arange(0, 6_000_000_000, 3_000_000_000) -> [0, 3000000000]
        XCTAssertClose(Matft.arange(start: 0, to: 6_000_000_000, by: 3_000_000_000), MfArray([0, 3e9] as [Double], mftype: .Int), checkType: true)
        let r = Matft.random.randint(low: 0, high: 1 << 40, shape: [3])
        XCTAssertEqual(r.shape, [3])
        XCTAssertEqual(r.mftype, .Int)
        #endif
    }

    // MARK: - init with an integer mftype

    /// np.array([1.5, -2.7]).astype(int) -> [1, -2]; the stored values must be truncated too
    func testInitIntegerMfTypeTruncates() {
        let a = MfArray([1.5, -2.7], mftype: .Int)
        XCTAssertClose(a, MfArray([1, -2]), checkType: true)
        XCTAssertClose(a * 2, MfArray([2, -4]), checkType: true)
        XCTAssertEqual(a > 1, MfArray([false, false]))
        XCTAssertEqual(a[0].scalar(Int.self), 1)
        XCTAssertEqual(a.data as! [Int], [1, -2])
    }

    /// np.array([-1, 300]).astype(np.uint8) -> [255, 44]
    func testInitIntegerMfTypeWraps() {
        let u = MfArray([-1, 300], mftype: .UInt8)
        XCTAssertClose(u, MfArray([255, 44], mftype: .UInt8), checkType: true)
        XCTAssertEqual(u > 100, MfArray([true, false]))
        XCTAssertEqual(u.max().scalar(UInt8.self), 255)
        // np.array([-1.5, 300.7]).astype(np.int8) -> [-1, 44]
        XCTAssertClose(MfArray([-1.5, 300.7], mftype: .Int8), MfArray([-1, 44], mftype: .Int8), checkType: true)
        // np.array([[1.5, 2.5]]).astype(bool) -> True; stored as 1
        XCTAssertClose(MfArray([[1.5, 0.0]], mftype: .Bool), MfArray([[true, false]]), checkType: true)
    }

    #if !os(WASI)
    /// A file with "3.7,1\n-2.5,2" loaded as int gives the truncated values (numpy raises, Matft converts like astype)
    func testLoadtxtIntegerMfTypeTruncates() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bughunt_loadtxt_int_\(UUID().uuidString).csv")
        try "3.7,1\n-2.5,2\n".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let a = Matft.file.loadtxt(url: url, delimiter: ",", mftype: .Int)!
        XCTAssertClose(a, MfArray([[3, 1], [-2, 2]]), checkType: true)
        XCTAssertEqual(a.toArray() as! [[Int]], [[3, 1], [-2, 2]])
    }
    #endif

    // MARK: - nums with .Bool

    /// np.full(2, 2, dtype=bool).sum() -> 2
    func testNumsBoolStoresZeroOrOne() {
        XCTAssertClose(Matft.nums(2, shape: [2], mftype: .Bool), MfArray([true, true]), checkType: true)
        XCTAssertClose(Matft.nums(0.5, shape: [2], mftype: .Bool), MfArray([true, true]), checkType: true)
        XCTAssertClose(Matft.nums(0, shape: [2], mftype: .Bool), MfArray([false, false]), checkType: true)
        XCTAssertClose(Matft.stats.sum(Matft.nums(2, shape: [2], mftype: .Bool)), MfArray([2]))
    }

    // MARK: - astype Double -> integer

    /// np.array([2.9999999999, -0.9999999999, 255.9999999999]).astype(int) -> [2, 0, 255]
    func testAstypeDoubleToIntegerTruncatesInDouble() {
        let a = MfArray([2.9999999999, -0.9999999999, 255.9999999999] as [Double])
        XCTAssertClose(a.astype(.Int), MfArray([2, 0, 255]), checkType: true)
        // np.array([255.9999999999]).astype(np.uint8) -> [255]
        XCTAssertClose(MfArray([255.9999999999] as [Double]).astype(.UInt8), MfArray([255], mftype: .UInt8), checkType: true)
        // np.array([-3.9999999999]).astype(np.int8) -> [-3]
        XCTAssertClose(MfArray([-3.9999999999] as [Double]).astype(.Int8), MfArray([-3], mftype: .Int8), checkType: true)
        // a transposed view
        let t = MfArray([[2.9999999999, 0.5], [-1.9999999999, 7.9999999999]] as [[Double]]).T
        XCTAssertClose(t.astype(.Int), MfArray([[2, -1], [0, 7]]), checkType: true)
        // the input is not modified
        XCTAssertEqual(a.data as! [Double], [2.9999999999, -0.9999999999, 255.9999999999])
    }

    // MARK: - 0-d arrays

    /// np.array([[5.0]]).squeeze() is the 0-d array(5.)
    func testZeroDimensionalArray() {
        let a = MfArray([[5.0]]).squeeze()
        XCTAssertEqual(a.shape, [])
        XCTAssertEqual(a.size, 1)
        XCTAssertEqual(a.description, "mfarray = \n\t5.0, type=Double, shape=[]")
        XCTAssertEqual(a.toArray() as! [Double], [5.0])
        XCTAssertEqual(a.data as! [Double], [5.0])
        XCTAssertEqual(a.scalar(Double.self), 5.0)
        let i = a.astype(.Int)
        XCTAssertEqual(i.shape, [])
        XCTAssertEqual(i.mftype, .Int)
        XCTAssertEqual(i.data as! [Int], [5])
        XCTAssertEqual((a + 1).data as! [Double], [6.0])
        XCTAssertEqual(Matft.flip(a).data as! [Double], [5.0])
        XCTAssertEqual(a.deepcopy().shape, [])
    }

    func testZeroDimensionalIntArray() {
        let a = MfArray([[5]]).squeeze()
        XCTAssertEqual(a.shape, [])
        XCTAssertEqual(a.data as! [Int], [5])
        XCTAssertEqual(a.description, "mfarray = \n\t5, type=Int, shape=[]")
        XCTAssertEqual(a.toArray() as! [Int], [5])
        XCTAssertEqual((a + 1).data as! [Int], [6])
        XCTAssertEqual(Matft.flip(a).data as! [Int], [5])
        XCTAssertEqual(a.astype(.Double).data as! [Double], [5.0])
        XCTAssertEqual(a.scalar(Int.self), 5)
        // np: sqrt -> 2.236..., a == 5 -> True, a * [1, 2] -> [5, 10], reshape(1, 1) -> [[5]]
        XCTAssertClose(Matft.math.sqrt(a).reshape([1]), MfArray([Float(5).squareRoot()]))
        XCTAssertEqual((a === 5).data as! [Bool], [true])
        XCTAssertClose(a * MfArray([1, 2]), MfArray([5, 10]), checkType: true)
        XCTAssertClose(a.reshape([1, 1]), MfArray([[5]]), checkType: true)
        XCTAssertEqual(a.T.shape, [])
        XCTAssertEqual(a.expand_dims(axis: 0).toArray() as! [Int], [5])
    }

    #if !os(WASI)
    /// np.loadtxt of a file with a single value gives the 0-d array(5.)
    func testLoadtxtSingleValue() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bughunt_loadtxt_single_\(UUID().uuidString).csv")
        try "5\n".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let a = Matft.file.loadtxt(url: url, delimiter: ",", mftype: .Double)!
        XCTAssertEqual(a.shape, [])
        XCTAssertEqual(a.description, "mfarray = \n\t5.0, type=Double, shape=[]")
        XCTAssertEqual(a.toArray() as! [Double], [5.0])
    }

    // MARK: - savetxt with no columns

    /// np.savetxt of shape (3, 0) writes 3 empty lines; of an empty 1-D array writes nothing
    func testSavetxtNoColumns() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bughunt_savetxt_\(UUID().uuidString).csv")
        defer { try? FileManager.default.removeItem(at: url) }
        Matft.file.savetxt(url: url, mfarray: Matft.nums(0, shape: [3, 0]), delimiter: ",")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "\n\n\n")
        Matft.file.savetxt(url: url, mfarray: MfArray([] as [Double]), delimiter: ",")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "")
    }
    #endif

    // MARK: - randint with high == max + 1

    /// high is exclusive: np.random.randint(0, 256, dtype=np.uint8) is valid
    func testRandintHighIsTypeMaxPlusOne() {
        let cases: [(MfType, Int, Int)] = [(.UInt8, 0, 256), (.Int8, -128, 128), (.UInt16, 0, 65536), (.Int16, -32768, 32768)]
        for (mftype, low, high) in cases {
            let r = Matft.random.randint(low: low, high: high, shape: [200], mftype: mftype)
            XCTAssertEqual(r.mftype, mftype)
            let v = r.astype(.Double).data as! [Double]
            XCTAssertTrue(v.allSatisfy{ $0 >= Double(low) && $0 < Double(high) }, "\(mftype)")
        }
        // high == low + 1 gives low only
        let r = Matft.random.randint(low: 255, high: 256, shape: [5], mftype: .UInt8)
        XCTAssertEqual(r.data as! [UInt8], [255, 255, 255, 255, 255])
    }
}
