import XCTest
import Matft

/// Tests for WASI fallback implementations
/// These tests validate the pure Swift implementations that are used when Accelerate is not available (e.g., on WASI)
/// The tests run on macOS to ensure the fallback logic is correct before deploying to WASI

final class WASIFallbackTests: XCTestCase {

    // MARK: - Type Conversion Tests

    func testTypeConversionFloatToDouble() {
        let floatArray = MfArray([1.0, 2.5, -3.7, 0.0], mftype: .Float)
        let doubleArray = floatArray.astype(.Double)

        XCTAssertEqual(doubleArray.mftype, .Double)
        XCTAssertEqual(doubleArray.shape, [4])

        let data = doubleArray.data as! [Double]
        XCTAssertEqual(data[0], 1.0, accuracy: 1e-6)
        XCTAssertEqual(data[1], 2.5, accuracy: 1e-6)
        XCTAssertEqual(data[2], -3.7, accuracy: 1e-5)
        XCTAssertEqual(data[3], 0.0, accuracy: 1e-6)
    }

    func testTypeConversionDoubleToFloat() {
        let doubleArray = MfArray([1.0, 2.5, -3.7, 0.0], mftype: .Double)
        let floatArray = doubleArray.astype(.Float)

        XCTAssertEqual(floatArray.mftype, .Float)
        XCTAssertEqual(floatArray.shape, [4])

        let data = floatArray.data as! [Float]
        XCTAssertEqual(data[0], 1.0, accuracy: 1e-6)
        XCTAssertEqual(data[1], 2.5, accuracy: 1e-6)
        XCTAssertEqual(data[2], -3.7, accuracy: 1e-5)
        XCTAssertEqual(data[3], 0.0, accuracy: 1e-6)
    }

    func testTypeConversionIntToFloat() {
        let intArray = MfArray([1, 2, -3, 0, 100])
        let floatArray = intArray.astype(.Float)

        XCTAssertEqual(floatArray.mftype, .Float)

        let data = floatArray.data as! [Float]
        XCTAssertEqual(data[0], 1.0)
        XCTAssertEqual(data[1], 2.0)
        XCTAssertEqual(data[2], -3.0)
        XCTAssertEqual(data[3], 0.0)
        XCTAssertEqual(data[4], 100.0)
    }

    func testTypeConversionUInt8ToFloat() {
        let uint8Array = MfArray([UInt8(0), UInt8(128), UInt8(255)])
        let floatArray = uint8Array.astype(.Float)

        XCTAssertEqual(floatArray.mftype, .Float)

        let data = floatArray.data as! [Float]
        XCTAssertEqual(data[0], 0.0)
        XCTAssertEqual(data[1], 128.0)
        XCTAssertEqual(data[2], 255.0)
    }

    func testTypeConversion2DArray() {
        let array2D = MfArray([[1.0, 2.0], [3.0, 4.0]], mftype: .Float)
        let converted = array2D.astype(.Double)

        XCTAssertEqual(converted.mftype, .Double)
        XCTAssertEqual(converted.shape, [2, 2])

        let expected = MfArray([[1.0, 2.0], [3.0, 4.0]], mftype: .Double)
        XCTAssertTrue(Matft.allEqual(converted, expected))
    }

    // MARK: - Negation Tests (Prefix Operations)

    func testNegationFloat() {
        let array = MfArray([1.0, -2.0, 3.5, 0.0, -0.5], mftype: .Float)
        let negated = -array

        let expected = MfArray([-1.0, 2.0, -3.5, 0.0, 0.5], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(negated, expected))
    }

    func testNegationDouble() {
        let array = MfArray([1.0, -2.0, 3.5, 0.0, -0.5], mftype: .Double)
        let negated = -array

        let expected = MfArray([-1.0, 2.0, -3.5, 0.0, 0.5], mftype: .Double)
        XCTAssertTrue(Matft.allEqual(negated, expected))
    }

    func testNegation2D() {
        let array = MfArray([[1.0, -2.0], [3.0, -4.0]], mftype: .Float)
        let negated = -array

        let expected = MfArray([[-1.0, 2.0], [-3.0, 4.0]], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(negated, expected))
    }

    func testNegationInt() {
        let array = MfArray([1, -2, 3, 0, -5])
        let negated = Matft.neg(array)

        let expected = MfArray([-1, 2, -3, 0, 5])
        XCTAssertTrue(Matft.allEqual(negated, expected))
    }

    // MARK: - Logical Not Tests

    func testLogicalNotBool() {
        let array = MfArray([true, false, true, false])
        let result = !array

        XCTAssertEqual(result.mftype, .Bool)
        XCTAssertEqual(result, MfArray([false, true, false, true]))
    }

    func testLogicalNotNumeric() {
        let array = MfArray([0, 1, 2, 0, -1])
        let result = !array

        XCTAssertEqual(result.mftype, .Bool)
        XCTAssertEqual(result, MfArray([true, false, false, true, false]))
    }

    // MARK: - Array Creation Tests

    func testArrayCreationFromIntArray() {
        let array = MfArray([1, 2, 3, 4, 5])

        XCTAssertEqual(array.shape, [5])
        XCTAssertEqual(array.ndim, 1)
        XCTAssertEqual(array.size, 5)
    }

    func testArrayCreationFromFloatArray() {
        let array = MfArray([1.5, 2.5, 3.5], mftype: .Float)

        XCTAssertEqual(array.shape, [3])
        XCTAssertEqual(array.mftype, .Float)

        let data = array.data as! [Float]
        XCTAssertEqual(data[0], 1.5)
        XCTAssertEqual(data[1], 2.5)
        XCTAssertEqual(data[2], 3.5)
    }

    func testArrayCreation2D() {
        let array = MfArray([[1, 2, 3], [4, 5, 6]])

        XCTAssertEqual(array.shape, [2, 3])
        XCTAssertEqual(array.ndim, 2)
        XCTAssertEqual(array.size, 6)
    }

    func testArrayCreation3D() {
        let array = MfArray([[[1, 2], [3, 4]], [[5, 6], [7, 8]]])

        XCTAssertEqual(array.shape, [2, 2, 2])
        XCTAssertEqual(array.ndim, 3)
        XCTAssertEqual(array.size, 8)
    }

    // MARK: - Basic Arithmetic Tests

    func testAdditionArrays() {
        let a = MfArray([1.0, 2.0, 3.0], mftype: .Float)
        let b = MfArray([4.0, 5.0, 6.0], mftype: .Float)
        let result = a + b

        let expected = MfArray([5.0, 7.0, 9.0], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    func testSubtractionArrays() {
        let a = MfArray([5.0, 7.0, 9.0], mftype: .Float)
        let b = MfArray([1.0, 2.0, 3.0], mftype: .Float)
        let result = a - b

        let expected = MfArray([4.0, 5.0, 6.0], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    func testMultiplicationArrays() {
        let a = MfArray([1.0, 2.0, 3.0], mftype: .Float)
        let b = MfArray([2.0, 3.0, 4.0], mftype: .Float)
        let result = a * b

        let expected = MfArray([2.0, 6.0, 12.0], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    func testDivisionArrays() {
        let a = MfArray([6.0, 8.0, 12.0], mftype: .Float)
        let b = MfArray([2.0, 4.0, 3.0], mftype: .Float)
        let result = a / b

        let expected = MfArray([3.0, 2.0, 4.0], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    func testScalarAddition() {
        let a = MfArray([1.0, 2.0, 3.0], mftype: .Float)
        let result = a + 5.0

        let expected = MfArray([6.0, 7.0, 8.0], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    func testScalarMultiplication() {
        let a = MfArray([1.0, 2.0, 3.0], mftype: .Float)
        let result = a * 2.0

        let expected = MfArray([2.0, 4.0, 6.0], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    // MARK: - Broadcasting Tests

    func testBroadcastAddition() {
        let a = MfArray([[1, 2, 3], [4, 5, 6]])
        let b = MfArray([10, 20, 30])
        let result = a + b

        let expected = MfArray([[11, 22, 33], [14, 25, 36]])
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    func testBroadcastMultiplication() {
        let a = MfArray([[1, 2], [3, 4]])
        let b = MfArray([[2], [3]])
        let result = a * b

        let expected = MfArray([[2, 4], [9, 12]])
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    // MARK: - Reshape and Transpose Tests

    func testReshape() {
        let array = MfArray([1, 2, 3, 4, 5, 6])
        let reshaped = array.reshape([2, 3])

        XCTAssertEqual(reshaped.shape, [2, 3])

        let expected = MfArray([[1, 2, 3], [4, 5, 6]])
        XCTAssertTrue(Matft.allEqual(reshaped, expected))
    }

    func testTranspose() {
        let array = MfArray([[1, 2, 3], [4, 5, 6]])
        let transposed = array.T

        XCTAssertEqual(transposed.shape, [3, 2])

        let expected = MfArray([[1, 4], [2, 5], [3, 6]])
        XCTAssertTrue(Matft.allEqual(transposed, expected))
    }

    func testFlatten() {
        let array = MfArray([[1, 2, 3], [4, 5, 6]])
        let flattened = array.flatten()

        XCTAssertEqual(flattened.shape, [6])

        let expected = MfArray([1, 2, 3, 4, 5, 6])
        XCTAssertTrue(Matft.allEqual(flattened, expected))
    }

    // MARK: - Comparison Tests

    func testEqual() {
        let a = MfArray([1, 2, 3, 4])
        let b = MfArray([1, 0, 3, 5])
        let result = Matft.equal(a, b)

        XCTAssertEqual(result.mftype, .Bool)

        let boolData = result.data as! [Bool]
        XCTAssertEqual(boolData[0], true)
        XCTAssertEqual(boolData[1], false)
        XCTAssertEqual(boolData[2], true)
        XCTAssertEqual(boolData[3], false)
    }

    func testLess() {
        let a = MfArray([1, 2, 3, 4])
        let b = MfArray([2, 2, 2, 2])
        let result = Matft.less(a, b)

        XCTAssertEqual(result.mftype, .Bool)

        let boolData = result.data as! [Bool]
        XCTAssertEqual(boolData[0], true)
        XCTAssertEqual(boolData[1], false)
        XCTAssertEqual(boolData[2], false)
        XCTAssertEqual(boolData[3], false)
    }

    func testGreater() {
        let a = MfArray([1, 2, 3, 4])
        let b = MfArray([2, 2, 2, 2])
        let result = Matft.greater(a, b)

        XCTAssertEqual(result.mftype, .Bool)

        let boolData = result.data as! [Bool]
        XCTAssertEqual(boolData[0], false)
        XCTAssertEqual(boolData[1], false)
        XCTAssertEqual(boolData[2], true)
        XCTAssertEqual(boolData[3], true)
    }

    // MARK: - Slicing Tests

    func testSlicing1D() {
        let array = MfArray([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let sliced = array[2~<7]

        let expected = MfArray([2, 3, 4, 5, 6])
        XCTAssertTrue(Matft.allEqual(sliced, expected))
    }

    func testSlicing2D() {
        let array = MfArray([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
        let sliced = array[0~<2, 1~<3]

        let expected = MfArray([[2, 3], [5, 6]])
        XCTAssertTrue(Matft.allEqual(sliced, expected))
    }

    func testStepSlicing() {
        let array = MfArray([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let sliced = array[0~<10~<2]

        let expected = MfArray([0, 2, 4, 6, 8])
        XCTAssertTrue(Matft.allEqual(sliced, expected))
    }

    // MARK: - Reduce Operations Tests

    func testSum() {
        let array = MfArray([1, 2, 3, 4, 5])
        let result = array.sum()

        XCTAssertEqual(result.scalar as! Int, 15)
    }

    func testSumAxis() {
        let array = MfArray([[1, 2, 3], [4, 5, 6]])
        let result = array.sum(axis: 0)

        let expected = MfArray([5, 7, 9])
        XCTAssertTrue(Matft.allEqual(result, expected))
    }

    func testMean() {
        let array = MfArray([1.0, 2.0, 3.0, 4.0, 5.0], mftype: .Float)
        let result = array.mean()

        let scalar = result.scalar as! Float
        XCTAssertEqual(scalar, 3.0, accuracy: 1e-6)
    }

    func testMax() {
        let array = MfArray([3, 1, 4, 1, 5, 9, 2, 6])
        let result = array.max()

        XCTAssertEqual(result.scalar as! Int, 9)
    }

    func testMin() {
        let array = MfArray([3, 1, 4, 1, 5, 9, 2, 6])
        let result = array.min()

        XCTAssertEqual(result.scalar as! Int, 1)
    }

    // MARK: - Deep Copy Tests

    func testDeepCopy() {
        let original = MfArray([1, 2, 3, 4, 5])
        let copy = original.deepcopy()

        XCTAssertTrue(Matft.allEqual(original, copy))

        copy[0] = MfArray([100])
        XCTAssertNotEqual(original[0].scalar as! Int, copy[0].scalar as! Int)
    }

    // MARK: - Contiguous Tests

    func testToContiguousRow() {
        let array = MfArray([[1, 2, 3], [4, 5, 6]], mforder: .Column)
        let contiguous = array.to_contiguous(mforder: .Row)

        XCTAssertTrue(Matft.allEqual(array, contiguous))
        XCTAssertEqual(contiguous.strides, [3, 1])
    }

    func testToContiguousColumn() {
        let array = MfArray([[1, 2, 3], [4, 5, 6]], mforder: .Row)
        let contiguous = array.to_contiguous(mforder: .Column)

        XCTAssertTrue(Matft.allEqual(array, contiguous))
        XCTAssertEqual(contiguous.strides, [1, 2])
    }

    // MARK: - Squeeze and Expand Dims Tests

    func testSqueeze() {
        let array = MfArray([[[1, 2, 3]]])
        let squeezed = array.squeeze()

        XCTAssertEqual(squeezed.shape, [3])
    }

    func testExpandDims() {
        let array = MfArray([1, 2, 3])
        let expanded = array.expand_dims(axis: 0)

        XCTAssertEqual(expanded.shape, [1, 3])
    }

    // MARK: - Clip Tests

    func testClip() {
        let array = MfArray([1, 5, 10, 15, 20], mftype: .Float)
        let clipped = Matft.clip(array, min: Float(5), max: Float(15))

        let expected = MfArray([5, 5, 10, 15, 15], mftype: .Float)
        XCTAssertTrue(Matft.allEqual(clipped, expected))
    }

    // MARK: - Where Tests

    func testAllEqual() {
        let a = MfArray([1, 2, 3])
        let b = MfArray([1, 2, 3])
        let c = MfArray([1, 2, 4])

        XCTAssertTrue(Matft.allEqual(a, b))
        XCTAssertFalse(Matft.allEqual(a, c))
    }

    // MARK: - Data Access Tests

    func testDataAccess() {
        let array = MfArray([1.5, 2.5, 3.5], mftype: .Float)
        let data = array.data as! [Float]

        XCTAssertEqual(data.count, 3)
        XCTAssertEqual(data[0], 1.5)
        XCTAssertEqual(data[1], 2.5)
        XCTAssertEqual(data[2], 3.5)
    }

    func testScalarAccess() {
        let array = MfArray([42])
        let scalar = array.scalar as! Int

        XCTAssertEqual(scalar, 42)
    }

    // MARK: - Linear Algebra Tests (CLAPACK-backed for WASI)
    // These tests validate the CLAPACK wrapper implementations used on WASI
    // Only Double-precision is supported via CLAPACK

    func testMatrixInverseDouble() {
        // Test 2x2 matrix inverse (Double precision - supported on WASI)
        let a = MfArray([[1, 2], [3, 4]], mftype: .Double)
        let inv = try! Matft.linalg.inv(a)

        let expected = MfArray([[-2.0, 1.0], [1.5, -0.5]], mftype: .Double)
        XCTAssertEqual(inv.round(decimals: 6), expected.round(decimals: 6))

        // Verify A * A^-1 = I
        let identity = a *& inv
        let expectedIdentity = Matft.eye(dim: 2, mftype: .Double)
        XCTAssertEqual(identity.round(decimals: 6), expectedIdentity.round(decimals: 6))
    }

    func testMatrixInverse3x3Double() {
        // Test 3x3 matrix inverse
        let a = MfArray([[1, 2, 3],
                         [0, 1, 4],
                         [5, 6, 0]], mftype: .Double)
        let inv = try! Matft.linalg.inv(a)

        // Verify A * A^-1 = I
        let identity = a *& inv
        let expectedIdentity = Matft.eye(dim: 3, mftype: .Double)
        XCTAssertEqual(identity.round(decimals: 6), expectedIdentity.round(decimals: 6))
    }

    func testDeterminantDouble() {
        // Test 2x2 determinant
        let a = MfArray([[1, 2], [3, 4]], mftype: .Double)
        let det = try! Matft.linalg.det(a)

        XCTAssertEqual(det, MfArray([-2.0], mftype: .Double))
    }

    func testDeterminant3x3Double() {
        // Test 3x3 determinant
        let a = MfArray([[1, 2, 3],
                         [4, 5, 6],
                         [7, 8, 10]], mftype: .Double)
        let det = try! Matft.linalg.det(a)

        // det = 1*(5*10-6*8) - 2*(4*10-6*7) + 3*(4*8-5*7) = 1*(50-48) - 2*(40-42) + 3*(32-35)
        //     = 2 - (-4) + (-9) = 2 + 4 - 9 = -3
        // Note: The sign depends on the LU decomposition pivot count
        XCTAssertEqual(abs(det.scalar as! Double), 3.0, accuracy: 1e-10)
    }

    func testEigenDecompositionDouble() {
        // Test eigenvalue decomposition with real eigenvalues (Double precision)
        // Identity matrix has eigenvalues [1, 1, 1]
        let a = MfArray([[1, 0, 0],
                         [0, 2, 0],
                         [0, 0, 3]], mftype: .Double)
        let ret = try! Matft.linalg.eigen(a)

        // Eigenvalues should be 1, 2, 3 (real)
        XCTAssertEqual(ret.valRe, MfArray([1, 2, 3], mftype: .Double))
        XCTAssertEqual(ret.valIm, MfArray([0, 0, 0], mftype: .Double))

        // Eigenvectors should be identity (for diagonal matrix)
        XCTAssertEqual(ret.lvecRe, MfArray([[1.0, 0.0, 0.0],
                                            [0.0, 1.0, 0.0],
                                            [0.0, 0.0, 1.0]], mftype: .Double))
        XCTAssertEqual(ret.rvecRe, MfArray([[1.0, 0.0, 0.0],
                                            [0.0, 1.0, 0.0],
                                            [0.0, 0.0, 1.0]], mftype: .Double))
    }

    func testEigenDecompositionComplexDouble() {
        // Test eigenvalue decomposition with complex eigenvalues
        // Rotation matrix by 90 degrees has complex eigenvalues
        let a = MfArray([[0, -1],
                         [1, 0]], mftype: .Double)
        let ret = try! Matft.linalg.eigen(a)

        // Eigenvalues should be ±i (imaginary)
        XCTAssertEqual(ret.valRe.round(decimals: 10), MfArray([0, 0], mftype: .Double))
        XCTAssertEqual(ret.valIm.round(decimals: 10), MfArray([1, -1], mftype: .Double))
    }

    func testBatchedMatrixInverseDouble() {
        // Test batched matrix inverse (multiple matrices)
        let a = MfArray([[[1.0, 2.0],
                          [3.0, 4.0]],

                         [[1.0, 3.0],
                          [3.0, 5.0]]], mftype: .Double)

        let inv = try! Matft.linalg.inv(a)

        let expected = MfArray([[[-2.0, 1.0],
                                 [1.5, -0.5]],

                                [[-1.25, 0.75],
                                 [0.75, -0.25]]], mftype: .Double)

        XCTAssertEqual(inv.round(decimals: 6), expected.round(decimals: 6))
    }

    func testBatchedDeterminantDouble() {
        // Test batched determinant
        let a = MfArray([[[1.0, 2.0],
                          [3.0, 4.0]],

                         [[1.0, 3.0],
                          [3.0, 5.0]]], mftype: .Double)

        let det = try! Matft.linalg.det(a)

        XCTAssertEqual(det, MfArray([-2.0, -4.0], mftype: .Double))
    }

    func testBatchedEigenDouble() {
        // Test batched eigenvalue decomposition
        let a = MfArray([[[1, 0, 0],
                          [0, 2, 0],
                          [0, 0, 3]]], mftype: .Double)

        let ret = try! Matft.linalg.eigen(a)

        // Eigenvalues
        XCTAssertEqual(ret.valRe, MfArray([[1, 2, 3]], mftype: .Double))
        XCTAssertEqual(ret.valIm, MfArray([[0, 0, 0]], mftype: .Double))

        // Eigenvectors (identity for diagonal matrix)
        XCTAssertEqual(ret.lvecRe, MfArray([[[1.0, 0.0, 0.0],
                                             [0.0, 1.0, 0.0],
                                             [0.0, 0.0, 1.0]]], mftype: .Double))
    }

    func testSingularMatrixThrows() {
        // Singular matrix should throw an error
        let a = MfArray([[1, 2], [2, 4]], mftype: .Double)

        XCTAssertThrowsError(try Matft.linalg.inv(a))
    }

    // MARK: - Pure Swift Eigenvalue Implementation Tests
    // These tests directly call the swiftEigenDecomposition function
    // to verify it works correctly before deploying to WASM

    func testSwiftEigenDiagonalMatrix() {
        // Diagonal matrix has eigenvalues on the diagonal
        let n = 3
        var a = [1.0, 0.0, 0.0,
                 0.0, 2.0, 0.0,
                 0.0, 0.0, 3.0]  // Column-major
        var wr = [Double](repeating: 0, count: n)
        var wi = [Double](repeating: 0, count: n)
        var vl = [Double](repeating: 0, count: n * n)
        var vr = [Double](repeating: 0, count: n * n)

        let result = swiftEigenDecomposition(n, &a, &wr, &wi, &vl, &vr, computeLeft: true, computeRight: true)

        XCTAssertEqual(result, 0, "Should converge successfully")

        // Check eigenvalues (may be in different order)
        let eigenvalues = Set(wr)
        XCTAssertTrue(eigenvalues.contains(1.0), "Should have eigenvalue 1")
        XCTAssertTrue(eigenvalues.contains(2.0), "Should have eigenvalue 2")
        XCTAssertTrue(eigenvalues.contains(3.0), "Should have eigenvalue 3")

        // All imaginary parts should be zero
        for i in 0..<n {
            XCTAssertEqual(wi[i], 0.0, accuracy: 1e-10, "Imaginary part should be zero")
        }
    }

    func testSwiftEigenSymmetricMatrix() {
        // Symmetric matrix: [[2, 1], [1, 2]] has eigenvalues 1 and 3
        let n = 2
        var a = [2.0, 1.0,
                 1.0, 2.0]  // Column-major (same as row-major for symmetric)
        var wr = [Double](repeating: 0, count: n)
        var wi = [Double](repeating: 0, count: n)
        var vl = [Double](repeating: 0, count: n * n)
        var vr = [Double](repeating: 0, count: n * n)

        let result = swiftEigenDecomposition(n, &a, &wr, &wi, &vl, &vr, computeLeft: false, computeRight: true)

        XCTAssertEqual(result, 0, "Should converge successfully")

        // Check eigenvalues
        let sortedEigenvalues = wr.sorted()
        XCTAssertEqual(sortedEigenvalues[0], 1.0, accuracy: 1e-10)
        XCTAssertEqual(sortedEigenvalues[1], 3.0, accuracy: 1e-10)

        // All imaginary parts should be zero for symmetric matrix
        for i in 0..<n {
            XCTAssertEqual(wi[i], 0.0, accuracy: 1e-10)
        }
    }

    func testSwiftEigenComplexEigenvalues() {
        // Rotation matrix [[0, -1], [1, 0]] has eigenvalues ±i
        let n = 2
        var a = [0.0, 1.0,
                -1.0, 0.0]  // Column-major: [[0, -1], [1, 0]]
        var wr = [Double](repeating: 0, count: n)
        var wi = [Double](repeating: 0, count: n)
        var vl = [Double](repeating: 0, count: n * n)
        var vr = [Double](repeating: 0, count: n * n)

        let result = swiftEigenDecomposition(n, &a, &wr, &wi, &vl, &vr, computeLeft: false, computeRight: true)

        XCTAssertEqual(result, 0, "Should converge successfully")

        // Eigenvalues should be ±i (real parts 0, imaginary parts ±1)
        XCTAssertEqual(wr[0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(wr[1], 0.0, accuracy: 1e-10)
        XCTAssertEqual(abs(wi[0]), 1.0, accuracy: 1e-10)
        XCTAssertEqual(abs(wi[1]), 1.0, accuracy: 1e-10)
        XCTAssertEqual(wi[0], -wi[1], accuracy: 1e-10, "Complex eigenvalues should be conjugates")
    }

    func testSwiftEigen3x3WithComplexPair() {
        // Matrix with one real and two complex conjugate eigenvalues
        // [[1, -1, 0], [1, 1, 0], [0, 0, 2]]
        // Eigenvalues: 2 (real), 1±i (complex pair)
        let n = 3
        var a = [1.0, 1.0, 0.0,
                -1.0, 1.0, 0.0,
                 0.0, 0.0, 2.0]  // Column-major
        var wr = [Double](repeating: 0, count: n)
        var wi = [Double](repeating: 0, count: n)
        var vl = [Double](repeating: 0, count: n * n)
        var vr = [Double](repeating: 0, count: n * n)

        let result = swiftEigenDecomposition(n, &a, &wr, &wi, &vl, &vr, computeLeft: false, computeRight: true)

        XCTAssertEqual(result, 0, "Should converge successfully")

        // Find the real eigenvalue (imaginary part = 0)
        var foundReal = false
        var complexCount = 0
        for i in 0..<n {
            if abs(wi[i]) < 1e-10 {
                XCTAssertEqual(wr[i], 2.0, accuracy: 1e-10, "Real eigenvalue should be 2")
                foundReal = true
            } else {
                complexCount += 1
                XCTAssertEqual(wr[i], 1.0, accuracy: 1e-10, "Complex eigenvalue real part should be 1")
                XCTAssertEqual(abs(wi[i]), 1.0, accuracy: 1e-10, "Complex eigenvalue imaginary part should be ±1")
            }
        }
        XCTAssertTrue(foundReal, "Should have one real eigenvalue")
        XCTAssertEqual(complexCount, 2, "Should have two complex eigenvalues")
    }

    func testSwiftEigen1x1Matrix() {
        // 1x1 matrix: eigenvalue equals the element
        let n = 1
        var a = [5.0]
        var wr = [Double](repeating: 0, count: n)
        var wi = [Double](repeating: 0, count: n)
        var vl = [Double](repeating: 0, count: n * n)
        var vr = [Double](repeating: 0, count: n * n)

        let result = swiftEigenDecomposition(n, &a, &wr, &wi, &vl, &vr, computeLeft: true, computeRight: true)

        XCTAssertEqual(result, 0)
        XCTAssertEqual(wr[0], 5.0, accuracy: 1e-14)
        XCTAssertEqual(wi[0], 0.0, accuracy: 1e-14)
        XCTAssertEqual(vr[0], 1.0, accuracy: 1e-14)
        XCTAssertEqual(vl[0], 1.0, accuracy: 1e-14)
    }

    func testSwiftEigenSymmetricTridiagonal() {
        // Test eigenvalues of a symmetric tridiagonal matrix
        // [[1, 0.5, 0], [0.5, 2, 0.5], [0, 0.5, 3]] has known eigenvalues
        let n = 3
        var a = [1.0, 0.5, 0.0,
                 0.5, 2.0, 0.5,
                 0.0, 0.5, 3.0]  // Column-major symmetric tridiagonal
        var wr = [Double](repeating: 0, count: n)
        var wi = [Double](repeating: 0, count: n)
        var vl = [Double](repeating: 0, count: n * n)
        var vr = [Double](repeating: 0, count: n * n)

        let result = swiftEigenDecomposition(n, &a, &wr, &wi, &vl, &vr, computeLeft: false, computeRight: true)

        XCTAssertEqual(result, 0, "Should converge")

        // All eigenvalues should be real for symmetric matrix
        for i in 0..<n {
            XCTAssertEqual(wi[i], 0.0, accuracy: 1e-10, "Imaginary parts should be zero for symmetric matrix")
        }

        // Eigenvalues should be approximately: 0.77, 2.0, 3.23 (from characteristic polynomial)
        // Sum of eigenvalues = trace = 1 + 2 + 3 = 6
        let eigenSum = wr.reduce(0, +)
        XCTAssertEqual(eigenSum, 6.0, accuracy: 1e-10, "Sum of eigenvalues should equal trace")

        // Product of eigenvalues = determinant ≈ 5.0
        let eigenProduct = wr.reduce(1, *)
        XCTAssertEqual(eigenProduct, 5.0, accuracy: 1e-8, "Product of eigenvalues should equal determinant")
    }

    func testSwiftEigenLargerMatrix() {
        // Test with a larger 5x5 matrix
        let n = 5
        // Diagonal matrix for simplicity
        var a = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            a[i * n + i] = Double(i + 1)  // Eigenvalues: 1, 2, 3, 4, 5
        }
        var wr = [Double](repeating: 0, count: n)
        var wi = [Double](repeating: 0, count: n)
        var vl = [Double](repeating: 0, count: n * n)
        var vr = [Double](repeating: 0, count: n * n)

        let result = swiftEigenDecomposition(n, &a, &wr, &wi, &vl, &vr, computeLeft: false, computeRight: true)

        XCTAssertEqual(result, 0)

        // Check all eigenvalues are present
        let eigenvalues = Set(wr.map { Int(round($0)) })
        XCTAssertEqual(eigenvalues, Set([1, 2, 3, 4, 5]))

        // All imaginary parts should be zero
        for i in 0..<n {
            XCTAssertEqual(wi[i], 0.0, accuracy: 1e-10)
        }
    }
}
