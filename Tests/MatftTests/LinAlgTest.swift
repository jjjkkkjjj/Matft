import XCTest

@testable import Matft

final class LinAlgTests: XCTestCase {

    // MARK: - Tests requiring gesv_ (not available on WASM)
    #if !os(WASI)
    func testSolve() {
        do{
            let coef = MfArray([[3,2],[1,2]])
            let b = MfArray([7,1])

            XCTAssertEqual(try Matft.linalg.solve(coef, b: b), MfArray([ 3.0, -1.0], mftype: .Float))
        }

        do{
            let coef = MfArray([[3,1],[1,2]], mftype: .Double)
            let b = MfArray([9,8])

            XCTAssertEqual(try Matft.linalg.solve(coef, b: b), MfArray([ 2.0, 3.0], mftype: .Double))
        }

        do{
            let coef = MfArray([[1,2],[2,4]])
            let b = MfArray([-1,-2])

            XCTAssertThrowsError(try Matft.linalg.solve(coef, b: b))
        }

        do{
            let coef = MfArray([[1,2],[2,4]])
            let b = MfArray([-1,-3])

            XCTAssertThrowsError(try Matft.linalg.solve(coef, b: b))
        }
    }
    #endif


    func testInv(){
        // Float test - requires sgetrf_/sgetri_ (not available on WASM)
        #if !os(WASI)
        do{
            let a = MfArray([[1, 2], [3, 4]])
            XCTAssertEqual(try Matft.linalg.inv(a), MfArray([[-2.0 ,  1.0 ],
                                                                     [ 1.5, -0.5]], mftype: .Float))
        }
        #endif
        // Double test - uses dgetrf_/dgetri_ (available on WASM via CLAPACK)
        do{
            let a = MfArray([[[1.0, 2.0],
                              [3.0, 4.0]],

                             [[1.0, 3.0],
                              [3.0, 5.0]]], mftype: .Double)
            XCTAssertEqual(try Matft.linalg.inv(a), MfArray([[[-2.0  ,  1.0  ],
                                                [ 1.5 , -0.5 ]],
                                                                     [[-1.25,  0.75],
                                                                      [ 0.75, -0.25]]], mftype: .Double))
        }
    }

    func testDet(){
        // Float test - requires sgetrf_ (not available on WASM)
        #if !os(WASI)
        do{
            let a = MfArray([[1, 2], [3, 4]])
            XCTAssertEqual(try Matft.linalg.det(a), MfArray([-2.0], mftype: .Float))
        }
        #endif

        // Double test - uses dgetrf_ (available on WASM via CLAPACK)
        do{
            let a = MfArray([[[1.0, 2.0],
                              [3.0, 4.0]],

                             [[1.0, 3.0],
                              [3.0, 5.0]]], mftype: .Double)
            XCTAssertEqual(try Matft.linalg.det(a), MfArray([-2.0, -4.0], mftype: .Double))
        }
    }

    func testEigen(){
        // Float test - requires sgeev_ (not available on WASM)
        #if !os(WASI)
        do{
            let a = MfArray([[1, -1], [1, 1]])
            let ret = try! Matft.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray([1, 1], mftype: .Float))
            XCTAssertEqual(ret.valIm, MfArray([1, -1], mftype: .Float))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray([[-0.70710677, -0.70710677],
                                                [0.0, 0.0]], mftype: .Float))
            XCTAssertEqual(ret.lvecIm, MfArray([[0.0, 0.0],
                                                [0.70710677, -0.70710677]], mftype: .Float))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray([[0.70710677, 0.70710677],
                                                [0.0, 0.0]], mftype: .Float))
            XCTAssertEqual(ret.rvecIm, MfArray([[0.0, 0.0],
                                                [-0.70710677, 0.70710677]], mftype: .Float))

        }
        #endif
        // Double tests - use dgeev_ (available on WASM via pure Swift fallback)
        do{
            let a = MfArray([[[1,0,0],
                              [0,2,0],
                              [0,0,3]]], mftype: .Double)
            let ret = try! Matft.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray([[1, 2, 3]], mftype: .Double))
            XCTAssertEqual(ret.valIm, MfArray([[0, 0, 0]], mftype: .Double))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray([[[1.0, 0.0, 0.0],
                                                [0.0, 1.0, 0.0],
                                                [0.0, 0.0, 1.0]]], mftype: .Double))
            XCTAssertEqual(ret.lvecIm, MfArray([[[0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0]]], mftype: .Double))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray([[[1.0, 0.0, 0.0],
                                                [0.0, 1.0, 0.0],
                                                [0.0, 0.0, 1.0]]], mftype: .Double))
            XCTAssertEqual(ret.rvecIm, MfArray([[[0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0],
                                                 [0.0, 0.0, 0.0]]], mftype: .Double))

        }
        do{
            let a = MfArray([[0, -1],
                             [1, 0]], mftype: .Double)
            let ret = try! Matft.linalg.eigen(a)
            // value
            XCTAssertEqual(ret.valRe, MfArray([0, 0], mftype: .Double))
            XCTAssertEqual(ret.valIm, MfArray([1, -1], mftype: .Double))
            // vector-left
            XCTAssertEqual(ret.lvecRe, MfArray([[-0.707106781186547, -0.707106781186547],
                                                [0.0, 0.0]], mftype: .Double))
            XCTAssertEqual(ret.lvecIm, MfArray([[0.0, 0.0],
                                                [0.707106781186547, -0.707106781186547]], mftype: .Double))
            // vector-right
            XCTAssertEqual(ret.rvecRe, MfArray([[0.707106781186547, 0.707106781186547],
                                                [0.0, 0.0]], mftype: .Double))
            XCTAssertEqual(ret.rvecIm, MfArray([[0.0, 0.0],
                                                [-0.707106781186547, 0.707106781186547]], mftype: .Double))

        }
    }

    // MARK: - Tests requiring SVD (not available on WASM)
    #if !os(WASI)
    func testSVD(){
        do{
            let a = MfArray([[2, 4, 1, 3],
                             [1, 5, 3, 2],
                             [5, 7, 0, 7]])
            let ret = try! Matft.linalg.svd(a)

            // v and rt is not unique?
            XCTAssertEqual(ret.v *& ret.v.T, Matft.eye(dim: 3, mftype: .Float))
            //astype is for avoiding minute error
            XCTAssertEqual(ret.s.astype(.Float), MfArray([1.33853840e+01, 3.58210781e+00, 5.07054122e-16], mftype: .Float))
            XCTAssertEqual(ret.rt *& ret.rt.T , Matft.eye(dim: 4, mftype: .Float))

            let ret_nofull = try! Matft.linalg.svd(a, full_matrices: false)
            XCTAssertEqual((ret_nofull.v *& Matft.diag(v: ret_nofull.s) *& ret_nofull.rt).nearest(), a)
        }

        do{
            let a = MfArray([[1, 2],
                             [3, 4]])
            let ret = try! Matft.linalg.svd(a)
            // v and rt is not unique?
            // these are same as numpy results
            XCTAssertEqual(ret.v, MfArray([[-0.40455358, -0.9145143 ],
                                           [-0.9145143 ,  0.40455358]], mftype: .Float))
            XCTAssertEqual(ret.s, MfArray([ 5.4649857 ,  0.36596619], mftype: .Float))
            XCTAssertEqual(ret.rt, MfArray([[-0.57604844, -0.81741556],
                                            [ 0.81741556, -0.57604844]], mftype: .Float))
            XCTAssertEqual(ret.v *& ret.v.T, Matft.eye(dim: 2, mftype: .Float))
            XCTAssertEqual(ret.rt *& ret.rt.T , Matft.eye(dim: 2, mftype: .Float))

            XCTAssertEqual((ret.v *& Matft.diag(v: ret.s) *& ret.rt).nearest(), a)
        }

    }

    func testPInv(){
        do{
            let a = MfArray([[2, -1, 0],
                             [4,3,-2]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 5), MfArray([[ 0.31666667,  0.08333333],
                                                            [-0.36666667,  0.16666667],
                                                            [ 0.08333333, -0.08333333]], mftype: .Float).round(decimals: 5))
        }

        do{
            let a = MfArray([[ 0.10122714, -1.7555435 ,  0.72242671],
                             [ 0.70605646, -3.03520525, -0.8974524 ],
                             [ 0.89382228,  0.53009567,  1.59680764],
                             [-0.61128203, -0.75155814,  0.00382533]], mftype: .Float)
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 3), MfArray([[-0.34872843,  0.42493471,  0.39808427, -0.62075487],
                                                            [-0.24171501, -0.14397516,  0.0288316 , -0.16416708],
                                                            [ 0.40742503, -0.2408292 ,  0.30600237,  0.23674046]], mftype: .Float).round(decimals: 3))
        }

        do{
            let a = MfArray([[-33,  43,  25],
                             [-65, -36, -33],
                             [-26,  44, -65],
                             [-35,  -7,  40]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 7), MfArray([[-0.00586522, -0.00820323, -0.00198698, -0.00633075],
                                                            [ 0.00937469, -0.00758197,  0.00732988, -0.00020324],
                                                            [ 0.00565919, -0.00350739, -0.00734483,  0.00663407]], mftype: .Float).round(decimals: 7))
        }

        do{
            let a = MfArray([[7, 2],
                             [3, 4],
                             [5, 3]], mftype: .Double)
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret.round(decimals: 7), MfArray([[ 0.16666667, -0.10606061,  0.03030303],
                                                            [-0.16666667,  0.28787879,  0.06060606]], mftype: .Double).round(decimals: 7))
        }

        do{
            let a = MfArray([[ -6,   4,  -1,   8,   2],
                             [ -1,   6, -10,  -1,   6],
                             [  3,  -4,   5,  -7,   5]])
            let ret = try! Matft.linalg.pinv(a)
            XCTAssertEqual(ret, MfArray([[-0.06456498,  0.00644501, -0.01798566],
                                         [ 0.01267183,  0.02793085, -0.01456178],
                                         [ 0.0539209 , -0.0576122 ,  0.05869991],
                                         [ 0.05795672, -0.02618938, -0.0251714 ],
                                         [ 0.07609496,  0.03942475,  0.10520211]], mftype: .Float))
        }
    }

    func testPolar(){
        do{
            let a = MfArray([[1, -1],
                             [2, 4]])
            let retR = try! Matft.linalg.polar_right(a)
            XCTAssertEqual(retR.u, MfArray([[ 0.85749293, -0.51449576],
                                           [ 0.51449576,  0.85749293]], mftype: .Float))
            XCTAssertEqual(retR.p, MfArray([[ 1.88648444,  1.2004901 ],
                                           [ 1.2004901 ,  3.94446746]], mftype: .Float))

            let retL = try! Matft.linalg.polar_left(a)
            XCTAssertEqual(retL.l, MfArray([[ 0.85749293, -0.51449576],
                                            [ 0.51449576,  0.85749293]], mftype: .Float))
            XCTAssertEqual(retL.p, MfArray([[ 1.37198868, -0.34299717],
                                            [-0.34299717,  4.45896321]], mftype: .Float))

        }
        do{
            let a = MfArray([[0.5, 1, 2],
                             [1.5, 3, 4],
                             [2, 3.5, 1]])
            let retR = try! Matft.linalg.polar_right(a)
            XCTAssertEqual(retR.u.astype(.Float), MfArray([[ 0.72794019, -0.42246022,  0.54002819],
                                                          [-0.28527167,  0.52959999,  0.79883911],
                                                          [ 0.62347667,  0.73556183, -0.26500119]], mftype: .Float))
            XCTAssertEqual(retR.p.astype(.Float), MfArray([[1.18301594, 2.05429354, 0.93827039],
                                                           [2.05429354, 3.74080617, 2.00904136],
                                                           [0.93827039, 2.00904136, 4.01041163]], mftype: .Float))
            let retL = try! Matft.linalg.polar_left(a)
            XCTAssertEqual(retL.l.astype(.Float), MfArray([[ 0.72794019, -0.42246022,  0.54002819],
                                                           [-0.28527167,  0.52959999,  0.79883911],
                                                           [ 0.62347667,  0.73556183, -0.26500119]], mftype: .Float))
            XCTAssertEqual(retL.p.astype(.Float), MfArray([[1.02156625, 1.98464238, 0.51729779],
                                                           [1.98464238, 4.35624892, 2.08189576],
                                                           [0.51729779, 2.08189576, 3.55641857]], mftype: .Float))

        }
    }
    #endif

    // MARK: - Norm tests (pure Swift, work on WASM)
    func testNorm_vec(){
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1, shape: [2,2,2,2])

            XCTAssertEqual(Matft.linalg.normlp_vec(a, ord: 2, axis: 3).round(decimals: 4),
                           MfArray([[[ 1.0        ,  3.60555128],
                                     [ 6.40312424,  9.21954446]],

                                    [[12.04159458, 14.86606875],
                                     [17.69180601, 20.51828453]]], mftype: .Float).round(decimals: 4))
            XCTAssertEqual(Matft.linalg.normlp_vec(a, ord: 2, axis: 0).round(decimals: 4),
                           MfArray([[[ 8.0        ,  9.05538514],
                                     [10.19803903, 11.40175425]],

                                    [[12.64911064, 13.92838828],
                                     [15.23154621, 16.55294536]]], mftype: .Float).round(decimals: 4))

            XCTAssertEqual(Matft.linalg.normlp_vec(a, ord: 0, axis: 0).round(decimals: 4),
            MfArray([[[1.0, 2.0],
                      [2.0, 2.0]],

                     [[2.0, 2.0],
                      [2.0, 2.0]]], mftype: .Float).round(decimals: 4))

            XCTAssertEqual(Matft.linalg.normlp_vec(a, ord: Float.infinity, axis: -1).round(decimals: 4),
            MfArray([[[ 1.0,  3.0],
                      [ 5.0,  7.0]],

                     [[ 9.0, 11.0],
                      [13.0, 15.0]]], mftype: .Float).round(decimals: 4))
        }

    }

    func testNormlp_mat(){
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1, shape: [2,2,2,2])
            // ord=2 requires SVD - only test on non-WASM platforms
            #if !os(WASI)
            XCTAssertEqual(Matft.linalg.normlp_mat(a, ord: 2, axes: (3, 1)).round(decimals: 4),
                           MfArray([[ 6.45100985,  9.89123156],
                                    [21.40011829, 25.3372271 ]], mftype: .Float).round(decimals: 4))
            XCTAssertEqual(Matft.linalg.normlp_mat(a, ord: 2, axes: (0, -1)).round(decimals: 4),
                           MfArray([[12.06483816, 15.28810568],
                                    [18.81008019, 22.49163147]], mftype: .Float).round(decimals: 4))
            #endif

            // ord=-1 and ord=inf use pure Swift operations - work on WASM
            XCTAssertEqual(Matft.linalg.normlp_mat(a, ord: -1, axes: (2, 3)).round(decimals: 4),
            MfArray([[ 2.0, 10.0],
                     [18.0, 26.0]], mftype: .Float).round(decimals: 4))

            XCTAssertEqual(Matft.linalg.normlp_mat(a, ord: Float.infinity, axes: (-1, 0)).round(decimals: 4),
            MfArray([[10.0, 14.0],
                     [18.0, 22.0]], mftype: .Float).round(decimals: 4))
        }

    }

    func testNormFro_mat(){

        do{
            let a = Matft.arange(start: 0, to: 16, by: 1, shape: [2,2,2,2])

            XCTAssertEqual(Matft.linalg.normfro_mat(a, axes: (2, 0), keepDims: false).round(decimals: 4),
                           MfArray([[12.9614814 , 14.56021978],
                                    [19.79898987, 21.63330765]], mftype: .Float).round(decimals: 4))
            XCTAssertEqual(Matft.linalg.normfro_mat(a, axes: (-2, 1), keepDims: false).round(decimals: 4),
                           MfArray([[ 7.48331477,  9.16515139],
                                    [22.44994432, 24.41311123]], mftype: .Float).round(decimals: 4))

        }
    }

    // Nuclear norm requires SVD - not available on WASM
    #if !os(WASI)
    func testNormNuc_mat(){
        do{
            let a = Matft.arange(start: 0, to: 16, by: 1, shape: [2,2,2,2])

            XCTAssertEqual(Matft.linalg.normnuc_mat(a, axes: (2, 0), keepDims: false).round(decimals: 4),
                           MfArray([[14.14213562, 15.62049935],
                                    [20.59126028, 22.36067977]], mftype: .Float).round(decimals: 4))
            XCTAssertEqual(Matft.linalg.normnuc_mat(a, axes: (-2, 1), keepDims: false).round(decimals: 4),
                           MfArray([[ 8.48528137, 10.0        ],
                                    [22.8035085 , 24.73863375]], mftype: .Float).round(decimals: 4))

        }
    }
    #endif
}
