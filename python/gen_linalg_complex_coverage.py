"""Generate Tests/MatftTests/LinAlgComplexCoverageTest.swift from numpy (and scipy for polar).

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_linalg_complex_coverage.py

Every case is a Swift expression and the numpy expression computing its expected value.
Cases taking `x` run over `layoutVariants(input)` (row/column major, transposed, offset, prefix, strided and reversed views),
or over the complex layouts declared by `zinp` (the same views built from complex literals),
so the expected values must not depend on the memory layout.

Matft conventions (not bugs):
- A reduction over all the axes returns shape [1] (numpy returns a 0-d scalar).
- LAPACK functions return `.Float` for every non-Double input (numpy returns float64 for integers).
- `det` of an integer matrix is .Float (numpy: float64), and it throws for an exactly singular matrix (numpy returns 0).
- `normlp_vec(ord: 0)` keeps the input mftype; the other norms return `.Float` for integer input.
- `matmul` / `cross` use `MfType.priority` for mixed types, so Int with Float gives Float (numpy float64).
- `inner` returns the left operand's mftype.
- `eigen` returns the real and imaginary parts separately, and eigenvectors / singular vectors are checked by
  reconstruction (`A v = v λ`, `U diag(s) Vh = A`) or by absolute values, because their signs are not unique.
"""
import os
import warnings

import numpy as np
import scipy.linalg

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "LinAlgComplexCoverageTest.swift")
CLASS = "LinAlgComplexCoverageTests"
DOC = "Linear algebra and complex numbers over dtypes, memory layouts (`layoutVariants`) and edge cases. Expected values are numpy outputs"

nan = np.nan
inf = np.inf

# numpy dtype <-> MfType
NP_DTYPE = {"Bool": np.bool_, "UInt8": np.uint8, "UInt16": np.uint16, "UInt32": np.uint32, "Int8": np.int8,
            "Int16": np.int16, "Int32": np.int32, "Int": np.int64, "Float": np.float32, "Double": np.float64}
INT_TYPES = ("Int", "Int8", "Int16", "Int32", "UInt8", "UInt16", "UInt32")
# LAPACK-backed results in Float: numpy computes in float32 (or float64 and we cast), rounding differs a little
FLOAT_LAPACK_TOL = dict(rtol=1e-4, atol=1e-5)


def mftype_of(a):
    """MfType of numpy's result, used to assert that Matft returns the same dtype"""
    dt = np.asarray(a).dtype
    for name, t in NP_DTYPE.items():
        if dt == t:
            return name
    raise ValueError(f"no MfType for {dt}")


def lit(v):
    v = float(v)
    if np.isnan(v):
        return ".nan"
    if np.isinf(v):
        return ".infinity" if v > 0 else "-.infinity"
    return repr(v)


def swift_array(a, mftype):
    """Swift expression creating `a` as MfArray of mftype. 0-d arrays become shape [1] like Matft's reductions"""
    a = np.asarray(a)
    shape = list(a.shape) if a.ndim > 0 else [1]
    flat = a.ravel()
    if a.size == 0:
        cast = "Bool" if mftype == "Bool" else ("Int" if mftype in INT_TYPES else "Double")
        return f"MfArray([] as [{cast}], mftype: .{mftype}, shape: {shape})"
    if mftype == "Bool":
        values = ", ".join("true" if bool(v) else "false" for v in flat)
        return f"MfArray([{values}] as [Bool], shape: {shape})"
    if mftype in INT_TYPES:
        values = ", ".join(str(int(v)) for v in flat)
        return f"MfArray([{values}] as [Int], mftype: .{mftype}, shape: {shape})"
    values = ", ".join(lit(v) for v in flat)
    return f"MfArray([{values}] as [Double], mftype: .{mftype}, shape: {shape})"


def swift_complex(z, mftype):
    """Swift expression creating the complex array `z` with Float or Double parts"""
    z = np.asarray(z)
    return f"MfArray(real: {swift_array(z.real, mftype)}, imag: {swift_array(z.imag, mftype)})"


def swift_escape(s):
    return s.replace("\\", "\\\\").replace("\"", "\\\"")


# ---------- inputs (defined identically in Swift) ----------
INPUTS = {}  # name -> Swift expression
NP_INPUTS = {}  # name -> (numpy array, mftype)


def inp(name, a, mftype):
    """Declare a real input. The numpy array is cast to the dtype of mftype so the reference is computed in that type"""
    a = np.asarray(a).astype(NP_DTYPE[mftype])
    INPUTS[name] = swift_array(a, mftype)
    NP_INPUTS[name] = (a, mftype)
    return a


ZLAYOUTS = {}  # name -> Swift expression of the [(name, array)] list


def zinp(name, z, mftype):
    """Declare a complex input and its layouts: the same logical values as a column-major copy and
    as views with an offset, a smaller size, a stride, reversed rows and a transposed view (all built from literals)"""
    z = np.asarray(z)
    z = (z.real.astype(NP_DTYPE[mftype]) + 1j * z.imag.astype(NP_DTYPE[mftype]))
    n = z.shape[0]
    filler = np.full((1,) + z.shape[1:], 99 - 77j)
    interleaved = np.concatenate([np.concatenate([z[i:i + 1], filler]) for i in range(n)])
    INPUTS[name] = swift_complex(z, mftype)
    INPUTS[name + "_pad"] = swift_complex(np.concatenate([filler, z, filler]), mftype)
    INPUTS[name + "_pre"] = swift_complex(np.concatenate([z, filler]), mftype)
    INPUTS[name + "_str"] = swift_complex(interleaved, mftype)
    INPUTS[name + "_rev"] = swift_complex(z[::-1], mftype)
    views = [("contiguous", name), ("column", f"{name}.to_contiguous(mforder: .Column)"),
             ("offset view", f"{name}_pad[1~<{n + 1}]"), ("prefix view", f"{name}_pre[0~<{n}]"),
             ("strided view", f"{name}_str[0~<{2 * n}~<2]"), ("reversed view", f"{name}_rev[Matft.reverse]")]
    if z.ndim >= 2:
        INPUTS[name + "_t"] = swift_complex(z.T, mftype)
        views.append(("transposed view", f"{name}_t.T"))
    ZLAYOUTS[name] = "[" + ", ".join(f"(\"{v}\", {e})" for v, e in views) + "]"
    NP_INPUTS[name] = (z, mftype)
    return z


TESTS = []  # (name, [lines], wasi_skip)


def test(name, lines, wasi_skip=False):
    TESTS.append((name, lines, wasi_skip))


def _loop(layout, assertions):
    if layout is None:
        return assertions
    if layout in ZLAYOUTS:
        head = f"for (name, x) in {ZLAYOUTS[layout]} as [(String, MfArray)]{{"
    else:
        head = f"for (name, x) in layoutVariants({layout}){{"
    return [head] + ["    " + a for a in assertions] + ["}"]


def _label(swift, layout):
    return swift_escape(swift) + (" \\(name)" if layout else "")


def _tol(mftype, rtol, atol):
    rtol = rtol if rtol is not None else (1e-5 if mftype == "Float" else 1e-10)
    atol = atol if atol is not None else (1e-5 if mftype == "Float" else 1e-10)
    return rtol, atol


def close(swift, expected, mftype=None, rtol=None, atol=None, layout=None, check_type=True):
    """XCTAssertClose line. mftype defaults to numpy's result dtype, and the Matft dtype is asserted too (check_type).
    `layout`: the input whose layouts are iterated (the expression uses `x`)"""
    mftype = mftype or mftype_of(expected)
    rtol, atol = _tol(mftype, rtol, atol)
    ct = ", checkType: true" if check_type else ""
    return _loop(layout, [f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: {rtol}, atol: {atol}{ct}, \"{_label(swift, layout)}\")"])


def equal(swift, expected, mftype=None, layout=None):
    """Exact comparison for Int / Bool results: values, shape and mftype"""
    mftype = mftype or mftype_of(expected)
    return _loop(layout, [f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: 0, atol: 0, checkType: true, \"{_label(swift, layout)}\")"])


def zclose(swift, expected, mftype, rtol=None, atol=None, layout=None):
    """The result is complex and its real and imaginary parts (both of mftype) match numpy"""
    expected = np.asarray(expected)
    rtol, atol = _tol(mftype, rtol, atol)
    label = _label(swift, layout)
    return _loop(layout, [
        "do {",
        f"    let ret = {swift}",
        f"    XCTAssertTrue(ret.isComplex, \"not complex: {label}\")",
        f"    XCTAssertClose(ret.real, {swift_array(expected.real, mftype)}, rtol: {rtol}, atol: {atol}, checkType: true, \"real: {label}\")",
        f"    XCTAssertClose(ret.imag ?? MfArray([Double.nan]), {swift_array(expected.imag, mftype)}, rtol: {rtol}, atol: {atol}, checkType: true, \"imag: {label}\")",
        "}",
    ])


def shape(swift, expected_shape, layout=None):
    return _loop(layout, [f"XCTAssertEqual(({swift}).shape, {list(expected_shape)}, \"{_label(swift, layout)}\")"])


def raw(*lines):
    return list(lines)


def f32(a):
    return np.asarray(a).astype(np.float32)


# ============================================================
# Linear algebra inputs
# ============================================================
# square, well conditioned, with negatives and non-symmetric
M3 = [[4, -2, 1], [3, 6, -4], [2, 1, 8]]
A3 = inp("A3", M3, "Double")
A3F = inp("A3F", M3, "Float")
A3I = inp("A3I", M3, "Int")
# stack of two 3x3
S23 = inp("S23", [M3, [[2, 1, 0], [1, 3, 1], [0, 1, 4]]], "Double")
# non-square 3x4 and 4x3 with ties and negatives
M34 = [[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]]
A34 = inp("A34", M34, "Double")
A34F = inp("A34F", M34, "Float")
A34I = inp("A34I", M34, "Int")
A43 = inp("A43", np.array(M34).T, "Double")
B42 = inp("B42", [[1, -2], [0, 3], [2, 2], [-1, 4]], "Double")
B42I = inp("B42I", [[1, -2], [0, 3], [2, 2], [-1, 4]], "Int")
B42F = inp("B42F", [[1, -2], [0, 3], [2, 2], [-1, 4]], "Float")
T234 = inp("T234", np.arange(24).reshape(2, 3, 4) % 7 - 3, "Double")
# symmetric (real eigenvalues) and a rotation block (complex eigenvalues)
SYM = inp("SYM", [[2, -1, 0], [-1, 2, -1], [0, -1, 2]], "Double")
SYMF = inp("SYMF", [[2, -1, 0], [-1, 2, -1], [0, -1, 2]], "Float")
ROT = inp("ROT", [[0, -2, 0], [1, 0, 0], [0, 0, 3]], "Double")
# singular and rank-deficient
# exactly singular in any LU (a zero column): numpy det -> 0.0, inv/solve raise
SING = inp("SING", [[1, 0, 2], [3, 0, 4], [5, 0, 6]], "Double")
SINGF = inp("SINGF", [[1, 0, 2], [3, 0, 4], [5, 0, 6]], "Float")
RANK1 = inp("RANK1", [[1, 2, 3, 4], [2, 4, 6, 8], [-1, -2, -3, -4]], "Double")
ONE = inp("ONE", [[-4]], "Double")
bvec = inp("bvec", [1, -2, 3], "Double")
bvecF = inp("bvecF", [1, -2, 3], "Float")
bmat = inp("bmat", [[1, 0], [-2, 1], [3, 5]], "Double")
V4 = inp("V4", [3, -4, 0, 12], "Double")
V4I = inp("V4I", [3, -4, 0, 12], "Int")
P3 = inp("P3", [[1, 0, -2], [3, 4, 5], [-1, 2, 0], [0, 0, 1]], "Double")
Q3 = inp("Q3", [[2, -1, 1], [0, 1, 0], [4, 5, 6], [1, 1, 1]], "Double")
P3I = inp("P3I", [[1, 0, -2], [3, 4, 5], [-1, 2, 0], [0, 0, 1]], "Int")
Q3I = inp("Q3I", [[2, -1, 1], [0, 1, 0], [4, 5, 6], [1, 1, 1]], "Int")
P2 = inp("P2", [[1, 2], [-3, 4], [5, 0]], "Double")
Q2 = inp("Q2", [[0, 1], [2, -1], [3, 3]], "Double")

W = True  # LAPACK is unavailable on WASI

# ---------- solve ----------
lines = []
for src, b, bname in [("A3", bvec, "bvec"), ("A3", bmat, "bmat")]:
    lines += close(f"try Matft.linalg.solve(x, b: {bname})", np.linalg.solve(A3, b), layout=src)
# Matft convention: Float for non-Double input (numpy float64 for Int)
lines += close("try Matft.linalg.solve(x, b: bvecF)", f32(np.linalg.solve(A3, bvec)), mftype="Float", layout="A3F", **FLOAT_LAPACK_TOL)
lines += close("try Matft.linalg.solve(A3I, b: bvecF)", f32(np.linalg.solve(A3, bvec)), mftype="Float", **FLOAT_LAPACK_TOL)
# mixed Float coef + Double b -> Double
lines += close("try Matft.linalg.solve(A3F, b: bvec)", np.linalg.solve(A3, bvec))
lines += close("try Matft.linalg.solve(ONE, b: MfArray([2] as [Double]))", np.linalg.solve(ONE, [2.0]))
lines += raw("XCTAssertThrowsError(try Matft.linalg.solve(SING, b: bvec), \"singular\")",
             "XCTAssertThrowsError(try Matft.linalg.solve(SINGF, b: bvecF), \"singular Float\")")
test("solve", lines, wasi_skip=W)

# ---------- inv ----------
lines = []
lines += close("try Matft.linalg.inv(x)", np.linalg.inv(A3), layout="A3")
lines += close("try Matft.linalg.inv(x)", f32(np.linalg.inv(A3)), mftype="Float", layout="A3F", **FLOAT_LAPACK_TOL)
lines += close("try Matft.linalg.inv(A3I)", f32(np.linalg.inv(A3)), mftype="Float", **FLOAT_LAPACK_TOL)
lines += close("try Matft.linalg.inv(x)", np.linalg.inv(S23), layout="S23")
lines += close("try Matft.linalg.inv(ONE)", np.linalg.inv(ONE))
lines += raw("XCTAssertThrowsError(try Matft.linalg.inv(SING), \"singular\")",
             "XCTAssertThrowsError(try Matft.linalg.inv(SINGF), \"singular Float\")")
# inv(a) @ a == I, and the input is unchanged
lines += close("try Matft.linalg.inv(A3) *& A3", np.eye(3))
lines += close("A3", A3)
test("inv", lines, wasi_skip=W)

# ---------- det ----------
lines = []
lines += close("try Matft.linalg.det(x)", np.linalg.det(A3), layout="A3")
lines += close("try Matft.linalg.det(x)", f32(np.linalg.det(A3)), mftype="Float", layout="A3F", **FLOAT_LAPACK_TOL)
# Matft convention: det of an integer matrix is .Float (numpy: float64)
lines += close("try Matft.linalg.det(A3I)", f32(np.linalg.det(A3)), mftype="Float", **FLOAT_LAPACK_TOL)
lines += close("try Matft.linalg.det(x)", np.linalg.det(S23), layout="S23")
lines += close("try Matft.linalg.det(ONE)", np.linalg.det(ONE))
lines += close("try Matft.linalg.det(x)", np.linalg.det(SYM), layout="SYM")
# Matft convention: exactly singular throws (numpy returns 0)
lines += raw("XCTAssertThrowsError(try Matft.linalg.det(SING), \"singular\")")
test("det", lines, wasi_skip=W)

# ---------- eigen ----------
lines = []
for src in ["SYM", "ROT", "A3", "S23"]:
    a, _ = NP_INPUTS[src]
    w = np.linalg.eigvals(a)
    lines += close(f"try Matft.linalg.eigen(x).valRe", w.real, mftype="Double", layout=src)
    lines += close(f"try Matft.linalg.eigen(x).valIm", w.imag, mftype="Double", layout=src)
    # reconstruction (vectors have no unique sign/phase): A (Vr + iVi) = (Vr + iVi) diag(λ) and
    # u^H A = λ u^H for the left vectors, i.e. A^T (Lr + iLi) = (Lr + iLi) diag(conj λ)
    ax = "-2" if a.ndim == 2 else "1"
    lines += _loop(src, [
        "do {",
        f"    let e = try Matft.linalg.eigen(x)",
        f"    let re = e.valRe.expand_dims(axis: {ax}), im = e.valIm.expand_dims(axis: {ax})",
        f"    let at = x.swapaxes(axis1: -1, axis2: -2)",
        f"    XCTAssertClose(x *& e.rvecRe, e.rvecRe * re - e.rvecIm * im, rtol: 1e-9, atol: 1e-9, \"A vr real {src} \\(name)\")",
        f"    XCTAssertClose(x *& e.rvecIm, e.rvecRe * im + e.rvecIm * re, rtol: 1e-9, atol: 1e-9, \"A vr imag {src} \\(name)\")",
        f"    XCTAssertClose(at *& e.lvecRe, e.lvecRe * re + e.lvecIm * im, rtol: 1e-9, atol: 1e-9, \"A^T vl real {src} \\(name)\")",
        f"    XCTAssertClose(at *& e.lvecIm, e.lvecIm * re - e.lvecRe * im, rtol: 1e-9, atol: 1e-9, \"A^T vl imag {src} \\(name)\")",
        "}",
    ])
w = np.linalg.eigvals(SYM)
# the order of the eigenvalues is not specified (Accelerate sgeev orders them differently from dgeev), so sort them
lines += close("(try Matft.linalg.eigen(SYMF).valRe).sort()", f32(np.sort(w.real)), mftype="Float", **FLOAT_LAPACK_TOL)
# symmetric with distinct eigenvalues: |vector| is unique
lines += close("Matft.math.abs(try Matft.linalg.eigen(SYM).rvecRe)", np.abs(np.linalg.eig(SYM).eigenvectors))
lines += close("try Matft.linalg.eigen(ONE).valRe", np.linalg.eigvals(ONE).real)
test("eigen", lines, wasi_skip=W)

# ---------- svd ----------
lines = []
for src in ["A34", "A43", "A3", "RANK1", "T234"]:
    a, _ = NP_INPUTS[src]
    for full in [True, False]:
        u, s, vh = np.linalg.svd(a, full_matrices=full)
        call = f"try Matft.linalg.svd(x, full_matrices: {str(full).lower()})"
        lines += close(f"{call}.s", s, layout=src)
        lines += shape(f"{call}.v", u.shape, layout=src)
        lines += shape(f"{call}.rt", vh.shape, layout=src)
    u, s, vh = np.linalg.svd(a, full_matrices=False)
    if src != "RANK1":  # singular vectors of the zero singular values are not unique
        lines += close(f"Matft.math.abs(try Matft.linalg.svd(x, full_matrices: false).v)", np.abs(u), layout=src)
        lines += close(f"Matft.math.abs(try Matft.linalg.svd(x, full_matrices: false).rt)", np.abs(vh), layout=src)
    # reconstruction U diag(s) Vh == A
    ax = "-2"
    lines += _loop(src, [
        "do {",
        "    let r = try Matft.linalg.svd(x, full_matrices: false)",
        f"    XCTAssertClose(r.v *& (r.s.expand_dims(axis: -1) * r.rt), {swift_array(a, 'Double')}, rtol: 1e-9, atol: 1e-9, \"U S Vh {src} \\(name)\")",
        "}",
    ])
u, s, vh = np.linalg.svd(A34)
lines += close("try Matft.linalg.svd(A34F).s", f32(s), mftype="Float", **FLOAT_LAPACK_TOL)
lines += close("try Matft.linalg.svd(A34I).s", f32(s), mftype="Float", **FLOAT_LAPACK_TOL)
lines += close("try Matft.linalg.svd(ONE).s", np.linalg.svd(ONE).S)
test("svd", lines, wasi_skip=W)

# ---------- pinv ----------
lines = []
for src in ["A34", "A43", "A3", "RANK1", "ONE"]:
    a, _ = NP_INPUTS[src]
    lines += close("try Matft.linalg.pinv(x)", np.linalg.pinv(a), layout=src)
lines += close("try Matft.linalg.pinv(x)", f32(np.linalg.pinv(A34)), mftype="Float", layout="A34F", **FLOAT_LAPACK_TOL)
# rcond larger than s_min / s_max drops the smallest singular value
s = np.linalg.svd(A3, compute_uv=False)
rc = float((s[-1] / s[0]) * 1.5)
lines += close(f"try Matft.linalg.pinv(A3, rcond: {rc})", np.linalg.pinv(A3, rcond=rc))
test("pinv", lines, wasi_skip=W)

# ---------- polar ----------
lines = []
for src in ["A3", "SYM", "ONE"]:
    a, _ = NP_INPUTS[src]
    u_r, p_r = scipy.linalg.polar(a, side="right")
    u_l, p_l = scipy.linalg.polar(a, side="left")
    lines += close("try Matft.linalg.polar_right(x).u", u_r, layout=src)
    lines += close("try Matft.linalg.polar_right(x).p", p_r, layout=src)
    # Matft returns (p, l) for a = p l; scipy returns (u, p) for side="left"
    lines += close("try Matft.linalg.polar_left(x).p", p_l, layout=src)
    lines += close("try Matft.linalg.polar_left(x).l", u_l, layout=src)
u_r, p_r = scipy.linalg.polar(A3, side="right")
lines += close("try Matft.linalg.polar_right(A3F).u", f32(u_r), mftype="Float", **FLOAT_LAPACK_TOL)
test("polar", lines, wasi_skip=W)

# ---------- vector norms ----------
lines = []
ORDS = [("2", 2), ("1", 1), ("3", 3), ("0.5", 0.5), ("Float.infinity", inf), ("-Float.infinity", -inf), ("0", 0)]
for src in ["A34", "A34F"]:
    a, mft = NP_INPUTS[src]
    for oname, o in ORDS:
        # axis 1 is the same reduction as -1 on 2-d, so only -1 is used
        for axis in [0, -1]:
            for kd in [False, True]:
                exp = np.linalg.norm(a.astype(np.float64), ord=o, axis=axis, keepdims=kd)
                exp = exp if mft == "Double" else f32(exp)
                lines += close(f"Matft.linalg.normlp_vec(x, ord: {oname}, axis: {axis}, keepDims: {str(kd).lower()})", exp, mftype=mft, layout=src)
# default ord/axis on 1-d; Int -> Float; ord 0 keeps Int (Matft convention)
lines += close("Matft.linalg.normlp_vec(x)", np.linalg.norm(V4), layout="V4")
lines += close("Matft.linalg.normlp_vec(V4I)", f32(np.linalg.norm(V4)), mftype="Float")
lines += close("Matft.linalg.normlp_vec(V4I, ord: 1)", f32(np.linalg.norm(V4, 1)), mftype="Float")
lines += equal("Matft.linalg.normlp_vec(V4I, ord: 0)", np.array(np.linalg.norm(V4, 0)).astype(np.int64))
lines += close("Matft.linalg.normlp_vec(x, axis: 1)", np.linalg.norm(T234, axis=1), layout="T234")
test("normlp_vec", lines)

# ---------- matrix norms ----------
lines = []
MORDS = [("2", 2), ("-2", -2), ("1", 1), ("-1", -1), ("Float.infinity", inf), ("-Float.infinity", -inf), ("nil", None)]
for src, axes_list in [("A34", [(0, 1), (1, 0), (-2, -1), (-1, -2)]), ("T234", [(1, 2), (2, 1), (0, 2), (2, 0)])]:
    a, _ = NP_INPUTS[src]
    for oname, o in MORDS:
        for i, ax in enumerate(axes_list):
            # keepDims with both axis orders (the first two pairs); the reduction order is covered by all pairs
            for kd in ([False, True] if i < 2 else [False]):
                exp = np.linalg.norm(a, ord=o, axis=ax, keepdims=kd)
                lines += close(f"Matft.linalg.normlp_mat(x, ord: {oname}, axes: ({ax[0]}, {ax[1]}), keepDims: {str(kd).lower()})", exp, layout=src)
    for ax in axes_list:
        for kd in [False, True]:
            lines += close(f"Matft.linalg.normfro_mat(x, axes: ({ax[0]}, {ax[1]}), keepDims: {str(kd).lower()})",
                           np.linalg.norm(a, "fro", axis=ax, keepdims=kd), layout=src)
            lines += close(f"Matft.linalg.normnuc_mat(x, axes: ({ax[0]}, {ax[1]}), keepDims: {str(kd).lower()})",
                           np.linalg.norm(a, "nuc", axis=ax, keepdims=kd), layout=src)
# defaults, Float and Int input
lines += close("Matft.linalg.normlp_mat(A34)", np.linalg.norm(A34, 2))
lines += close("Matft.linalg.normfro_mat(A34)", np.linalg.norm(A34, "fro"))
lines += close("Matft.linalg.normnuc_mat(A34)", np.linalg.norm(A34, "nuc"))
lines += close("Matft.linalg.normlp_mat(A34F, ord: 1)", f32(np.linalg.norm(A34, 1)), mftype="Float")
lines += close("Matft.linalg.normfro_mat(A34I)", f32(np.linalg.norm(A34, "fro")), mftype="Float")
lines += close("Matft.linalg.normlp_mat(A34I, ord: 2)", f32(np.linalg.norm(A34, 2)), mftype="Float", **FLOAT_LAPACK_TOL)
test("normlp_mat", lines, wasi_skip=W)

# ---------- matmul ----------
lines = []
lines += close("Matft.matmul(x, B42)", A34 @ B42, layout="A34")
lines += close("x *& B42", A34 @ B42, layout="A34")
lines += close("A34 *& x", A34 @ B42, layout="B42")
lines += close("x *& A34", A43 @ A34, layout="A43")
lines += close("x *& B42F", f32(A34 @ B42), layout="A34F")
lines += equal("x *& B42I", A34I @ B42I, layout="A34I")
# mixed: Float with Double -> Double; Matft convention: Int with Float -> Float (numpy float64)
lines += close("A34F *& B42", A34 @ B42)
lines += close("A34I *& B42F", f32(A34 @ B42), mftype="Float")
# batched and broadcast stacks
lines += close("x *& B42", T234 @ B42, layout="T234")
lines += close("T234[0~<1] *& T234.transpose(axes: [0, 2, 1])", T234[0:1] @ T234.transpose(0, 2, 1))
lines += close("A34 *& T234.transpose(axes: [0, 2, 1])", A34 @ T234.transpose(0, 2, 1))
lines += close("ONE *& ONE", ONE @ ONE)
lines += close("MfArray([[1, 2, 3]] as [[Double]]) *& MfArray([[4], [5], [6]] as [[Double]])", np.array([[1., 2, 3]]) @ np.array([[4.], [5], [6]]))
# empty: the inner dimension 0 gives zeros, an outer 0 gives an empty result
lines += close("MfArray([] as [Double], mftype: .Double, shape: [3, 0]) *& MfArray([] as [Double], mftype: .Double, shape: [0, 4])", np.zeros((3, 0)) @ np.zeros((0, 4)))
lines += shape("MfArray([] as [Double], mftype: .Double, shape: [0, 3]) *& B42[0~<3]", (np.zeros((0, 3)) @ B42[0:3]).shape)
# the inputs are unchanged
lines += close("A34", A34)
test("matmul", lines)

# ---------- dot / inner ----------
lines = []
lines += close("Matft.dot(x, V4)", np.dot(V4, V4).reshape(1), layout="V4")
lines += close("Matft.dot(x, B42)", np.dot(A34, B42), layout="A34")
lines += close("Matft.dot(x, V4)", np.dot(A34, V4), layout="A34")
lines += close("Matft.dot(x, V4)", np.dot(T234, V4), layout="T234")
lines += equal("Matft.dot(V4I, V4I)", np.dot(V4I, V4I).reshape(1))
lines += close("Matft.inner(x, V4)", np.inner(V4, V4).reshape(1), layout="V4")
lines += close("Matft.inner(x, A34[0~<2])", np.inner(A34, A34[0:2]), layout="A34")
lines += close("Matft.inner(x, A34)", np.inner(T234, A34), layout="T234")
lines += close("Matft.inner(A34, x)", np.inner(A34, T234), layout="T234")
lines += equal("Matft.inner(A34I, A34I)", np.inner(A34I, A34I))
lines += close("Matft.inner(A34F, A34F)", f32(np.inner(A34, A34)))
test("dot_inner", lines)

# ---------- cross ----------
lines = []
lines += close("Matft.cross(x, Q3)", np.cross(P3, Q3), layout="P3")
lines += close("Matft.cross(P3, x)", np.cross(P3, Q3), layout="Q3")
lines += equal("Matft.cross(P3I, Q3I)", np.cross(P3I, Q3I))
lines += close("Matft.cross(x, MfArray([1, -1, 2] as [Double]))", np.cross(P3, [1., -1, 2]), layout="P3")
lines += close("Matft.cross(MfArray([1, 0, 0] as [Double]), MfArray([0, 1, 0] as [Double]))", np.cross([1., 0, 0], [0., 1, 0]))
# 2-element vectors: the z-component (numpy 2.0 deprecates this but still returns it)
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    lines += close("Matft.cross(x, Q2)", np.cross(P2, Q2), layout="P2")
test("cross", lines)


# ============================================================
# Complex inputs
# ============================================================
ZV = [[0.5 + 0.3j, -1.2 + 0.8j, 2 - 1j, 0 + 0j], [-3 - 4j, 0 - 2j, 1.5 + 0j, -0.25 + 2.5j], [4 + 1j, -2 - 0.5j, 0.75 - 3j, 1 + 1j]]
WV = [[1 - 2j, 0.5 + 0.5j, -1 + 3j, 2 + 0j], [0 + 1j, -2 - 1j, 3 - 0.5j, 1 + 1j], [-1 - 1j, 4 + 2j, 0.5 - 0.25j, -3 + 2j]]
Z = zinp("Z", ZV, "Double")
ZF = zinp("ZF", ZV, "Float")
Wd = inp("Wre", np.real(WV), "Double")
inp("Wim", np.imag(WV), "Double")
INPUTS["WZ"] = swift_complex(np.array(WV), "Double")
INPUTS["WZF"] = swift_complex(np.array(WV), "Float")
WZ = np.array(WV)
R = inp("R", [[1, -2, 3, 0.5], [4, 0, -1, 2], [-3, 5, 2, -0.5]], "Double")
RF = inp("RF", [[1, -2, 3, 0.5], [4, 0, -1, 2], [-3, 5, 2, -0.5]], "Float")
ROW = WZ[0]
INPUTS["WROW"] = swift_complex(ROW, "Double")
INPUTS["WCOL"] = swift_complex(WZ[:, :1], "Double")


def zcases(zname, z, mft, wname, rname):
    zz = z.astype(np.complex64 if mft == "Float" else np.complex128)
    w = WZ.astype(zz.dtype)
    r = R.astype(np.float32 if mft == "Float" else np.float64)
    with np.errstate(all="ignore"):
        lines = []
        lines += zclose("-x", -zz, mft, layout=zname)
        lines += zclose(f"x + {wname}", zz + w, mft, layout=zname)
        lines += zclose(f"x - {wname}", zz - w, mft, layout=zname)
        lines += zclose(f"x * {wname}", zz * w, mft, layout=zname)
        lines += zclose(f"x / {wname}", zz / w, mft, layout=zname)
        lines += zclose(f"{wname} - x", w - zz, mft, layout=zname)
        lines += zclose("x + x", zz + zz, mft, layout=zname)
        lines += zclose("x * x", zz * zz, mft, layout=zname)
        # complex with real
        lines += zclose(f"x + {rname}", zz + r, mft, layout=zname)
        lines += zclose(f"x * {rname}", zz * r, mft, layout=zname)
        lines += zclose(f"{rname} - x", r - zz, mft, layout=zname)
        # complex with scalars on both sides
        lines += zclose("x + 2", zz + 2, mft, layout=zname)
        # typed scalar: an untyped Double literal promotes a Float array to Double (see the arithmetic tests)
        lines += zclose(f"x * ({-1.5} as {mft})", zz * -1.5, mft, layout=zname)
        lines += zclose("x / 4", zz / 4, mft, layout=zname)
        lines += zclose("3 - x", 3 - zz, mft, layout=zname)
        # abs / angle / conjugate / parts
        lines += close("Matft.complex.abs(x)", np.abs(zz), mftype=mft, layout=zname)
        lines += close("Matft.complex.angle(x)", np.angle(zz), mftype=mft, layout=zname)
        lines += zclose("Matft.complex.conjugate(x)", np.conjugate(zz), mft, layout=zname)
        lines += close("Matft.complex.absarg(x).abs", np.abs(zz), mftype=mft, layout=zname)
        lines += close("Matft.complex.absarg(x).arg", np.angle(zz), mftype=mft, layout=zname)
        lines += close("x.real", zz.real, mftype=mft, layout=zname)
        lines += close("x.imag!", zz.imag, mftype=mft, layout=zname)
        # copies keep the imaginary part
        lines += zclose("x.deepcopy()", zz, mft, layout=zname)
        lines += zclose("x.deepcopy(.Column)", zz, mft, layout=zname)
        lines += zclose("x.to_contiguous(mforder: .Row)", zz, mft, layout=zname)
        lines += zclose("x.to_contiguous(mforder: .Column)", zz, mft, layout=zname)
        lines += zclose("x.flatten()", zz.ravel(), mft, layout=zname)
        lines += zclose("x.T", zz.T, mft, layout=zname)
        lines += zclose("x.reshape([2, 6])", zz.reshape(2, 6), mft, layout=zname)
        other = "Double" if mft == "Float" else "Float"
        lines += zclose(f"x.astype(.{other})", zz, other, layout=zname)
        # elementwise math
        lines += zclose("Matft.math.exp(x)", np.exp(zz), mft, rtol=1e-5 if mft == "Float" else 1e-9, layout=zname)
        lines += zclose("Matft.math.sin(x)", np.sin(zz), mft, rtol=1e-5 if mft == "Float" else 1e-9, layout=zname)
    return lines


test("complex_double", zcases("Z", Z, "Double", "WZ", "R"), wasi_skip=W)
test("complex_float", zcases("ZF", ZF, "Float", "WZF", "RF"), wasi_skip=W)

# ---------- complex broadcasting, mixed precision, empty, aliasing ----------
lines = []
lines += zclose("x + WROW", Z + ROW, "Double", layout="Z")
lines += zclose("x * WCOL", Z * WZ[:, :1], "Double", layout="Z")
lines += zclose("WCOL - x", WZ[:, :1] - Z, "Double", layout="Z")
lines += zclose("x / R[0~<1]", Z / R[0:1], "Double", layout="Z")
# ComplexFloat with ComplexDouble -> Double parts
lines += zclose("ZF + WZ", ZF.astype(np.complex64).astype(np.complex128) + WZ, "Double")
# empty
EZ = "MfArray(real: MfArray([] as [Double], mftype: .Double, shape: [3, 0]), imag: MfArray([] as [Double], mftype: .Double, shape: [3, 0]))"
lines += shape(f"-{EZ}", (3, 0))
lines += shape(f"{EZ} + {EZ}", (3, 0))
lines += shape(f"Matft.complex.abs({EZ})", (3, 0))
lines += shape(f"Matft.complex.conjugate({EZ})", (3, 0))
lines += shape(f"{EZ}.deepcopy()", (3, 0))
# size 1
lines += zclose("MfArray(real: MfArray([3] as [Double]), imag: MfArray([-4] as [Double])) * WZ[0~<1, 0~<1]",
                np.array([3 - 4j]).reshape(1) * WZ[0:1, 0:1], "Double")
lines += close("Matft.complex.abs(MfArray(real: MfArray([3] as [Double]), imag: MfArray([-4] as [Double])))", np.abs(np.array([3 - 4j])))
# a real array: conjugate is a copy, abs is |x|, angle is 0 or pi
lines += close("Matft.complex.conjugate(R)", np.conjugate(R))
lines += close("Matft.complex.abs(R)", np.abs(R))
lines += close("Matft.complex.angle(R)", np.angle(R))
# the input of the non in-place operations is unchanged
lines += raw("do {",
             "    _ = -Z; _ = Z * WZ; _ = Matft.complex.conjugate(Z); _ = Z.deepcopy(); _ = Z.astype(.Float)")
lines += ["    " + l for l in zclose("Z", Z, "Double")]
lines += raw("}")
# deepcopy does not share the buffers; .real is a view like numpy
lines += raw("do {",
             f"    let z = {swift_complex(Z, 'Double')}",
             "    let c = z.deepcopy()",
             "    c.real[0, 0] = MfArray([100] as [Double])",
             "    c.imag![0, 1] = MfArray([-100] as [Double])",
             "    XCTAssertEqual(rowValues(z.real)[0], 0.5, \"deepcopy real is independent\")",
             "    XCTAssertEqual(rowValues(z.imag!)[1], 0.8, \"deepcopy imag is independent\")",
             "    let r = z.real",
             "    r[0, 0] = MfArray([7] as [Double])",
             "    XCTAssertEqual(rowValues(z.real)[0], 7, \"real is a view\")",
             "}")
test("complex_broadcast_empty_alias", lines, wasi_skip=W)


# ---------- write ----------
with open(OUT, "w") as f:
    f.write(f"// Generated by python/{os.path.basename(__file__)} (numpy {np.__version__}, scipy {scipy.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write(f"/// {DOC}\n")
    f.write(f"final class {CLASS}: XCTestCase {{\n")
    for name, expr in INPUTS.items():
        f.write(f"    private let {name} = {expr}\n")
    for name, body, wasi_skip in TESTS:
        f.write("\n")
        if wasi_skip:
            f.write("    #if !os(WASI)\n")
        throws = any("try " in l for l in body)
        f.write(f"    func test_{name}(){' throws' if throws else ''} {{\n")
        for line in body:
            f.write("        " + line + "\n")
        f.write("    }\n")
        if wasi_skip:
            f.write("    #endif\n")
    f.write("}\n")
print("wrote", OUT, sum(len(b) for _, b, _ in TESTS), "lines")
