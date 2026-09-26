import XCTest

import Matft

/// Same as `np.testing.assert_allclose`: |actual - expected| <= atol + rtol * |expected|, and NaN only matches NaN
/// - Parameters:
///   - checkType: Whether the mftypes must be the same too
func XCTAssertClose(_ actual: MfArray, _ expected: MfArray, rtol: Double = 1e-7, atol: Double = 1e-10, checkType: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(actual.shape, expected.shape, "shape mismatch", file: file, line: line)
    guard actual.shape == expected.shape else { return }
    if checkType {
        XCTAssertEqual(actual.mftype, expected.mftype, "type mismatch", file: file, line: line)
    }

    let a = rowValues(actual)
    let e = rowValues(expected)
    var worst = 0.0
    var worstIndex = -1
    for i in 0..<a.count {
        if a[i].isNaN || e[i].isNaN {
            XCTAssertEqual(a[i].isNaN, e[i].isNaN, "NaN mismatch at flatten index \(i)", file: file, line: line)
            continue
        }
        // inf must match exactly
        let excess = a[i] == e[i] ? 0 : abs(a[i] - e[i]) - (atol + rtol * abs(e[i]))
        if !(excess <= worst) {
            worst = excess
            worstIndex = i
        }
    }
    if worstIndex >= 0 {
        XCTFail("not close at flatten index \(worstIndex): actual=\(a[worstIndex]), expected=\(e[worstIndex])", file: file, line: line)
    }
}

/// Values in row major order as Double
func rowValues(_ x: MfArray) -> [Double] {
    x.astype(.Double).to_contiguous(mforder: .Row).data.map{ $0 as! Double }
}

/// The same logical values (shape, type and values) as `a` in different memory layouts:
/// row/column major, a transposed view, views with an offset or a smaller size than the stored data, a strided view and a reversed view
func layoutVariants(_ a: MfArray) -> [(name: String, array: MfArray)] {
    precondition(a.ndim >= 1 && a.shape[0] > 0)
    let n = a.shape[0]
    let values = rowValues(a)
    let rowSize = values.count / n
    let filler = [Double](repeating: 99, count: rowSize)
    func make(_ values: [Double], rows: Int) -> MfArray {
        var shape = a.shape
        shape[0] = rows
        return MfArray(values, shape: shape).astype(a.mftype)
    }
    // rows interleaved with fillers
    var interleaved: [Double] = []
    for i in 0..<n {
        interleaved += values[i*rowSize..<(i+1)*rowSize] + filler
    }
    var reversedRows: [Double] = []
    for i in (0..<n).reversed() {
        reversedRows += values[i*rowSize..<(i+1)*rowSize]
    }

    var ret: [(name: String, array: MfArray)] = [
        ("contiguous", a.to_contiguous(mforder: .Row)),
        ("column", a.to_contiguous(mforder: .Column)),
        ("offset view", make(filler + values + filler, rows: n + 2)[1~<(n + 1)]),
        ("prefix view", make(values + filler, rows: n + 1)[0~<n]),
        ("strided view", make(interleaved, rows: 2 * n)[0~<(2 * n)~<2]),
        ("reversed view", make(reversedRows, rows: n)[Matft.reverse]),
    ]
    if a.ndim >= 2 {
        ret.append(("transposed view", a.T.to_contiguous(mforder: .Row).T))
    }
    return ret
}
