import XCTest

@testable import Matft

/// Result buffers are allocated without zero-filling where the kernel writes every element.
/// In debug builds `MfData._poisonUninitialized` fills those buffers with NaN, so an element the kernel forgets to write
/// shows up as a difference against the unpoisoned result.
final class UninitializedAllocTests: XCTestCase {

    /// Row-major values of an mfarray (real part, then imaginary part if complex) as Double
    private func values(_ x: MfArray) -> [Double]{
        func real(_ x: MfArray) -> [Double]{
            x.astype(.Double, mforder: .Row).data.map{ $0 as! Double }
        }
        if x.isComplex{
            return real(x.real) + real(x.imag!)
        }
        return real(x)
    }

    private func assertSameWithPoison(_ name: String, file: StaticString = #filePath, line: UInt = #line, _ op: () throws -> MfArray) rethrows{
        let expected = try op()
        #if DEBUG
        MfData._poisonUninitialized = true
        defer { MfData._poisonUninitialized = false }
        #endif
        let actual = try op()
        XCTAssertEqual(actual.shape, expected.shape, name, file: file, line: line)
        XCTAssertEqual(actual.mftype, expected.mftype, name, file: file, line: line)
        let e = values(expected), a = values(actual)
        XCTAssertEqual(a.count, e.count, name, file: file, line: line)
        let same = zip(a, e).allSatisfy{ $0 == $1 || ($0.isNaN && $1.isNaN) }
        XCTAssertTrue(same, "\(name): \(a) != \(e)", file: file, line: line)
    }

    #if DEBUG
    func testPoisonHookFillsNaN(){
        MfData._poisonUninitialized = true
        defer { MfData._poisonUninitialized = false }
        let d = MfData(uninitializedSize: 4, mftype: .Float, complex: true)
        let x = MfArray(mfdata: d, mfstructure: MfStructure(shape: [4], mforder: .Row))
        XCTAssertTrue(values(x).allSatisfy{ $0.isNaN })
        // zeroed allocation is not affected by the hook
        XCTAssertEqual(values(Matft.nums(0, shape: [4])), [0, 0, 0, 0])
        XCTAssertEqual(values(MfArray([1, 2] as [Float]).to_complex(false)), [1, 2, 0, 0])
    }
    #endif

    private var layouts: [(String, MfArray)]{
        let a = Matft.arange(start: -12, to: 12, by: 1, shape: [2, 3, 4], mftype: .Float)
        return [
            ("contiguous", a),
            ("column", a.to_contiguous(mforder: .Column)),
            ("transposed", a.T),
            ("permuted", a.transpose(axes: [1, 0, 2])),
            ("view", a[1~<2]),
            ("strided", a[Matft.all, Matft.all, 0~<4~<2]),
            ("reversed", a[Matft.reverse]),
            ("double", a.astype(.Double)),
            ("int", a.astype(.Int)),
        ]
    }

    func testElementwiseOps(){
        for (name, x) in layouts{
            assertSameWithPoison("neg \(name)"){ -x }
            assertSameWithPoison("sign \(name)"){ x.sign() }
            assertSameWithPoison("abs \(name)"){ Matft.math.abs(x) }
            assertSameWithPoison("sin \(name)"){ Matft.math.sin(x) }
            assertSameWithPoison("sqrt \(name)"){ Matft.math.sqrt(x) }
            assertSameWithPoison("clip \(name)"){ x.clip(min: -3, max: 3) }
            assertSameWithPoison("add scalar \(name)"){ x + 1 }
            assertSameWithPoison("sub scalar \(name)"){ 1 - x }
            assertSameWithPoison("add \(name)"){ x + x }
            assertSameWithPoison("mul broadcast \(name)"){ x * x[Matft.all, Matft.all, 0~<1] }
            assertSameWithPoison("greater \(name)"){ x > 0 }
            assertSameWithPoison("equal \(name)"){ x === 1 }
            assertSameWithPoison("equal array \(name)"){ x === x }
            assertSameWithPoison("logical_not \(name)"){ Matft.logical_not(x) }
            assertSameWithPoison("logical_not bool \(name)"){ Matft.logical_not(x.astype(.Bool)) }
            assertSameWithPoison("power \(name)"){ Matft.math.power(bases: x, exponents: 2) }
            assertSameWithPoison("arctan2 \(name)"){ Matft.math.arctan2(x1: x, x2: x + 1) }
            assertSameWithPoison("maximum \(name)"){ Matft.stats.maximum(x, -x) }
        }
    }

    func testCopyAndConversionOps(){
        for (name, x) in layouts{
            assertSameWithPoison("deepcopy \(name)"){ Matft.deepcopy(x) }
            assertSameWithPoison("to_contiguous row \(name)"){ x.to_contiguous(mforder: .Row) }
            assertSameWithPoison("to_contiguous column \(name)"){ x.to_contiguous(mforder: .Column) }
            assertSameWithPoison("astype double \(name)"){ x.astype(.Double) }
            assertSameWithPoison("astype float \(name)"){ x.astype(.Float) }
            assertSameWithPoison("astype bool \(name)"){ x.astype(.Bool) }
            assertSameWithPoison("flatten \(name)"){ x.flatten() }
            assertSameWithPoison("reshape \(name)"){ x.reshape([-1]) }
            assertSameWithPoison("roll \(name)"){ Matft.roll(x, shift: 1) }
            assertSameWithPoison("roll axis \(name)"){ Matft.roll(x, shift: 1, axis: 1) }
            assertSameWithPoison("sort \(name)"){ x.sort(axis: 1) }
            assertSameWithPoison("argsort \(name)"){ x.argsort(axis: 1) }
            assertSameWithPoison("unique \(name)"){ Matft.orderedUnique(x) }
            assertSameWithPoison("vstack \(name)"){ Matft.vstack([x, x]) }
            assertSameWithPoison("hstack \(name)"){ Matft.hstack([x, x]) }
            assertSameWithPoison("concatenate \(name)"){ Matft.concatenate([x, x], axis: 2) }
            assertSameWithPoison("bool get \(name)"){ x[x > 0] }
            assertSameWithPoison("fancy get \(name)"){ x[MfArray([0, 0])] }
        }
    }

    func testReduceOps(){
        for (name, x) in layouts{
            assertSameWithPoison("sum \(name)"){ x.sum() }
            assertSameWithPoison("sum axis \(name)"){ x.sum(axis: 1) }
            assertSameWithPoison("mean axis \(name)"){ x.mean(axis: 0) }
            assertSameWithPoison("max axis \(name)"){ x.max(axis: 2) }
            assertSameWithPoison("argmax axis \(name)"){ x.argmax(axis: 2) }
            assertSameWithPoison("argmin \(name)"){ x.argmin() }
            assertSameWithPoison("cumsum \(name)"){ Matft.stats.cumsum(x, axis: 1) }
        }
    }

    func testCreationOps(){
        assertSameWithPoison("nums"){ Matft.nums(3, shape: [2, 3]) }
        assertSameWithPoison("zeros"){ Matft.nums(0, shape: [2, 3]) }
        assertSameWithPoison("eye"){ Matft.eye(dim: 3) }
        assertSameWithPoison("diag"){ Matft.diag(v: MfArray([1, 2, 3])) }
        assertSameWithPoison("diag k"){ Matft.diag(v: [1, 2], k: 1) }
        assertSameWithPoison("arange"){ Matft.arange(start: 0, to: 10, by: 1) }
        assertSameWithPoison("mfarray"){ MfArray([[1, 2], [3, 4]]) }
        assertSameWithPoison("mfarray double"){ MfArray([[1.5, 2], [3, 4]] as [[Double]]) }
    }

    func testLinAlgOps() throws{
        let m = MfArray([[[2, 1], [1, 3]], [[4, 1], [2, 5]], [[1, 2], [3, 4]]] as [[[Float]]])
        #if os(WASI)
        // single-precision LAPACK and SVD are not available on WASI
        let cases = [("double", m.astype(.Double)), ("transposed double", m.astype(.Double).transpose(axes: [0, 2, 1]))]
        #else
        let cases = [("stacked", m), ("transposed", m.transpose(axes: [0, 2, 1])), ("double", m.astype(.Double))]
        #endif
        for (name, x) in cases{
            try assertSameWithPoison("inv \(name)"){ try Matft.linalg.inv(x) }
            try assertSameWithPoison("det \(name)"){ try Matft.linalg.det(x) }
            try assertSameWithPoison("eigen valRe \(name)"){ try Matft.linalg.eigen(x).valRe }
            try assertSameWithPoison("eigen valIm \(name)"){ try Matft.linalg.eigen(x).valIm }
            try assertSameWithPoison("eigen rvecRe \(name)"){ try Matft.linalg.eigen(x).rvecRe }
            #if !os(WASI)
            try assertSameWithPoison("svd s \(name)"){ try Matft.linalg.svd(x).s }
            try assertSameWithPoison("svd v \(name)"){ try Matft.linalg.svd(x).v }
            #endif
            try assertSameWithPoison("matmul \(name)"){ x *& x }
        }
    }

    #if canImport(Accelerate)
    func testComplexOps(){
        let real = Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4], mftype: .Float)
        let z = MfArray(real: real, imag: -real)
        for (name, x) in [("contiguous", z), ("transposed", z.T), ("view", z[1~<2]), ("double", z.astype(.Double))]{
            assertSameWithPoison("neg \(name)"){ -x }
            assertSameWithPoison("add scalar \(name)"){ x + 1 }
            assertSameWithPoison("sub scalar \(name)"){ 1 - x }
            assertSameWithPoison("add \(name)"){ x + x }
            assertSameWithPoison("mul \(name)"){ x * x }
            assertSameWithPoison("conjugate \(name)"){ Matft.complex.conjugate(x) }
            assertSameWithPoison("abs \(name)"){ Matft.complex.abs(x) }
            assertSameWithPoison("angle \(name)"){ Matft.complex.angle(x) }
            assertSameWithPoison("deepcopy \(name)"){ Matft.deepcopy(x) }
            assertSameWithPoison("to_contiguous \(name)"){ x.to_contiguous(mforder: .Row) }
            assertSameWithPoison("real + complex \(name)"){ x.real + x }
            assertSameWithPoison("bool get \(name)"){ x[x.real > 3] }
        }
    }

    func testFFTOps(){
        let a = Matft.arange(start: 0, to: 16, by: 1, shape: [2, 8], mftype: .Float)
        assertSameWithPoison("rfft"){ Matft.fft.rfft(a) }
        assertSameWithPoison("rfft axis 0"){ Matft.fft.rfft(a.T, axis: 0) }
        assertSameWithPoison("rfft vDSP"){ Matft.fft.rfft(a, vDSP: true) }
        assertSameWithPoison("rfft vDSP axis 0"){ Matft.fft.rfft(a.T, axis: 0, vDSP: true) }
        assertSameWithPoison("rfft vDSP pad"){ Matft.fft.rfft(a, number: 16, vDSP: true) }
        assertSameWithPoison("irfft"){ Matft.fft.irfft(Matft.fft.rfft(a)) }
    }

    func testImageOps(){
        let rgba = Matft.arange(start: 0, to: 4*6*4, by: 1, shape: [4, 6, 4], mftype: .Float) / (4*6*4)
        let gray = rgba[Matft.all, Matft.all, 0]
        assertSameWithPoison("color"){ Matft.image.color(rgba) }
        assertSameWithPoison("resize rgba"){ Matft.image.resize(rgba, width: 9, height: 5) }
        assertSameWithPoison("resize gray"){ Matft.image.resize(gray, width: 3, height: 2) }
        let matrix = MfArray([[1, 0.2, 1], [0, 1, -1]] as [[Float]])
        assertSameWithPoison("warpAffine rgba"){ Matft.image.warpAffine(rgba, matrix: matrix, width: 7, height: 5) }
        assertSameWithPoison("warpAffine gray"){ Matft.image.warpAffine(gray, matrix: matrix, width: 7, height: 5) }
        assertSameWithPoison("cgimage roundtrip"){ Matft.image.cgimage2mfarray(Matft.image.mfarray2cgimage(rgba)) }
        for (name, x) in [("rgba", rgba), ("gray", gray)]{
            assertSameWithPoison("cvtColor \(name)"){ Matft.image.cvtColor(rgba, code: .RGBA2GRAY) }
            assertSameWithPoison("threshold \(name)"){ Matft.image.threshold(x, thresh: 0.5, maxval: 1, type: .Binary).dst }
            assertSameWithPoison("blur \(name)"){ Matft.image.blur(x, ksize: (3, 3)) }
            assertSameWithPoison("GaussianBlur \(name)"){ Matft.image.GaussianBlur(x, ksize: (3, 3), sigmaX: 1) }
            assertSameWithPoison("Sobel \(name)"){ Matft.image.Sobel(x, dx: 1, dy: 0) }
            assertSameWithPoison("Laplacian \(name)"){ Matft.image.Laplacian(x) }
            assertSameWithPoison("erode \(name)"){ Matft.image.erode(x) }
            assertSameWithPoison("dilate \(name)"){ Matft.image.dilate(x) }
            assertSameWithPoison("flip \(name)"){ Matft.image.flip(x, flipCode: 1) }
            assertSameWithPoison("rotate \(name)"){ Matft.image.rotate(x, rotateCode: .Rotate90Clockwise) }
            assertSameWithPoison("normalize \(name)"){ Matft.image.normalize(x) }
            assertSameWithPoison("resize linear \(name)"){ Matft.image.resize(x, width: 9, height: 5, interpolation: .Linear) }
        }
        assertSameWithPoison("Canny"){ Matft.image.Canny((gray * 255).astype(.UInt8), threshold1: 30, threshold2: 90) }
        assertSameWithPoison("calcHist"){ Matft.image.calcHist(gray, histSize: 8, range: (0, 1)) }
    }

    #endif

    // eigenvalues of stacked matrices must match those of each matrix
    func testEigenStacked() throws{
        // Double: single-precision eigen is not available on WASI
        let m = MfArray([[[2, 1], [1, 3]], [[4, 1], [2, 5]], [[1, 2], [3, 4]]] as [[[Double]]])
        let ret = try Matft.linalg.eigen(m)
        XCTAssertEqual(ret.valRe.shape, [3, 2])
        for i in 0..<3{
            let single = try Matft.linalg.eigen(m[i])
            XCTAssertEqual(ret.valRe[i], single.valRe, "matrix \(i)")
            XCTAssertEqual(ret.rvecRe[i], single.rvecRe, "matrix \(i)")
        }
    }
}
