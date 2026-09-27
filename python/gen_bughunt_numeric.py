"""Generate Tests/MatftTests/BugHuntNumericTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_bughunt_numeric.py

Regression tests for the numeric bugs found by the 2026-09-27 bug hunt:
complex and integer matmul, the dtype of det, integer wrap-around of square / power, the integer dtype of abs / round,
round(decimals:) precision, correctly rounded division by a scalar, `==` with infinities and the result type of
where / union1d / intersect1d.

Matft conventions (not bugs, the expected values follow them):
- Integers are stored as Float, so only 8/16 bit integers wrap around (wider integers keep the exact value while it fits in Float).
- A float result of an integer input is .Float (numpy: float64), and .Double stays .Double.
- A negative integer power of an integer array stops with a precondition (numpy raises ValueError), so it is not generated.
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "BugHuntNumericTest.swift")
CLASS = "BugHuntNumericTests"
DOC = ("Numeric bugs found by the 2026-09-27 bug hunt: complex / integer matmul, det dtype, integer square / power / abs / round, "
       "round(decimals:), division by a scalar, `==` with infinities and where / set operation result types. Expected values are numpy outputs")

NP_DTYPE = {"Bool": np.bool_, "UInt8": np.uint8, "UInt16": np.uint16, "UInt32": np.uint32, "Int8": np.int8,
            "Int16": np.int16, "Int32": np.int32, "Int": np.int64, "Float": np.float32, "Double": np.float64}
INT_TYPES = ("Int", "Int8", "Int16", "Int32", "UInt8", "UInt16", "UInt32")


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


TESTS = []  # (name, [lines], wasi_skip)


def test(name, lines, wasi_skip=False):
    TESTS.append((name, lines, wasi_skip))


def _tol(mftype, rtol, atol):
    if mftype in INT_TYPES or mftype == "Bool":
        return 0, 0
    rtol = rtol if rtol is not None else (1e-5 if mftype == "Float" else 1e-10)
    atol = atol if atol is not None else (1e-5 if mftype == "Float" else 1e-10)
    return rtol, atol


def _loop(layout, assertions):
    if layout is None:
        return assertions
    return [f"for (name, x) in layoutVariants({layout}){{"] + ["    " + a for a in assertions] + ["}"]


def _label(swift, layout):
    return swift_escape(swift) + (" \\(name)" if layout else "")


def close(swift, expected, mftype=None, rtol=None, atol=None, layout=None):
    """XCTAssertClose of values, shape and mftype (mftype defaults to numpy's result dtype).
    `layout`: the Swift input whose layouts are iterated (the expression uses `x`)"""
    mftype = mftype or mftype_of(expected)
    rtol, atol = _tol(mftype, rtol, atol)
    return _loop(layout, [f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: {rtol}, atol: {atol}, checkType: true, \"{_label(swift, layout)}\")"])


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


def arr(values, mftype):
    return np.asarray(values).astype(NP_DTYPE[mftype])


# ============================================================
# matmul of complex arrays keeps the imaginary parts
# ============================================================
Z = np.array([[1 + 2j, -3, -1j], [2 - 2j, 0, 4 + 5j]])
W = np.array([[1 + 3j, 2], [-3, 0.5j], [0, 4 + 6j]])
R = np.array([[1.0], [2.0], [3.0]])
Z3 = np.array([[[1 + 1j, 2], [0, -1j]], [[2 - 1j, 1j], [3, 1]]])
lines = []
for t, rt in (("Double", None), ("Float", 1e-5)):
    zs, ws = swift_complex(Z, t), swift_complex(W, t)
    rs = swift_array(R, t)
    lines += zclose(f"{zs} *& {ws}", Z @ W, t)
    lines += zclose(f"Matft.matmul({zs}, {ws})", Z @ W, t)
    lines += zclose(f"Matft.dot({zs}, {ws})", Z @ W, t)
    lines += zclose(f"{zs} *& {swift_complex(Z, t)}.T", Z @ Z.T, t)
    lines += zclose(f"{zs} *& {rs}", Z @ R, t)
    lines += zclose(f"{swift_array(R.T, t)} *& {ws}", R.T @ W, t)
    lines += zclose(f"{swift_complex(Z3, t)} *& {swift_complex(Z3, t)}", Z3 @ Z3, t)
test("matmul_complex", lines, wasi_skip=True)

# ============================================================
# matmul of integer and Bool arrays wraps around / is logical like numpy
# ============================================================
lines = []
MATMUL_INT = [
    ([[200, 100]], "UInt8", [[2], [1]], "UInt8"),
    ([[100, 100]], "Int8", [[1], [1]], "Int8"),
    ([[200, 200], [1, 2]], "Int16", [[200, 1], [200, 3]], "Int16"),
    ([[300, 300]], "UInt16", [[200], [200]], "UInt16"),
    ([[200, 100]], "UInt8", [[-1], [2]], "Int8"),
    ([[3, -4]], "Int", [[5], [6]], "Int"),
]
for a, at, b, bt in MATMUL_INT:
    x, y = arr(a, at), arr(b, bt)
    lines += close(f"{swift_array(x, at)} *& {swift_array(y, bt)}", x @ y)
BOOLS = [([[True, True]], [[True], [True]]), ([[True, False], [False, False]], [[False, True], [True, True]])]
for a, b in BOOLS:
    x, y = np.array(a), np.array(b)
    lines += close(f"{swift_array(x, 'Bool')} *& {swift_array(y, 'Bool')}", x @ y)
test("matmul_integer", lines)

# ============================================================
# det of integer / Bool input is a float array (numpy: float64; Matft: .Float)
# ============================================================
lines = []
DETS = [
    ([[6, 1, 1], [4, -2, 5], [2, 8, 7]], "Int"),
    ([[2, 1, 1], [1, 3, 2], [1, 0, 0]], "Int"),
    ([[1, 2], [3, 4]], "UInt8"),
    ([[1, 2], [3, 4]], "Int8"),
    ([[True, False], [False, True]], "Bool"),
    ([[[1, 2], [3, 4]], [[2, 0], [0, 3]]], "Int16"),
]
for a, t in DETS:
    x = arr(a, t)
    d = np.linalg.det(x)
    lines += close(f"try Matft.linalg.det({swift_array(x, t)})", np.atleast_1d(d), "Float", rtol=1e-5, atol=1e-4)
lines += close("try Matft.linalg.det(MfArray([] as [Int], mftype: .Int, shape: [0, 0]))", np.array([1.0]), "Float")
lines += close(f"try Matft.linalg.det({swift_array(arr([[1, 2], [3, 4]], 'Double'), 'Double')})", np.array([-2.0]), "Double")
lines += close(f"try Matft.linalg.det({swift_array(arr([[1, 2], [3, 4]], 'Float'), 'Float')})", np.array([-2.0]), "Float")
test("det_dtype", lines, wasi_skip=True)  # LAPACK sgetrf is not available on WASI

# ============================================================
# norms of integer input are computed in floating point (numpy casts to float), even though abs / power keep integer types
# ============================================================
lines = []
for a, t in (([-128, 100, 3], "Int8"), ([200, 250, 1], "UInt8"), ([-300, 400], "Int16"), ([True, False, True], "Bool")):
    x = arr(a, t)
    xf = x.astype(np.float64)
    for o, so in ((2, "2"), (1, "1"), (3, "3"), (np.inf, "Float.infinity"), (-np.inf, "-Float.infinity")):
        lines += close(f"Matft.linalg.normlp_vec({swift_array(x, t)}, ord: {so})", np.atleast_1d(np.linalg.norm(xf, o)).astype(np.float32), "Float")
for a, t in (([[-128, 100], [127, -1]], "Int8"), ([[200, 250], [255, 1]], "UInt8"), ([[-300, 400], [1000, 2]], "Int16")):
    x = arr(a, t)
    xf = x.astype(np.float64)
    lines += close(f"Matft.linalg.normfro_mat({swift_array(x, t)})", np.atleast_1d(np.linalg.norm(xf, "fro")).astype(np.float32), "Float")
    for o, so in ((1, "1"), (-1, "-1"), (np.inf, "Float.infinity"), (-np.inf, "-Float.infinity")):
        lines += close(f"Matft.linalg.normlp_mat({swift_array(x, t)}, ord: {so})", np.atleast_1d(np.linalg.norm(xf, o)).astype(np.float32), "Float")
test("norm_integer", lines)

# ============================================================
# square wraps around 8/16 bit integers
# ============================================================
lines = []
for a, t in (([100, -3, 12], "Int8"), ([16, 15, 255], "UInt8"), ([300, 200, -181], "Int16"), ([300, 256, 3], "UInt16"), ([3000, -5], "Int")):
    x = arr(a, t)
    lines += close("Matft.math.square(x)", np.square(x), layout=swift_array(x, t))
test("square_wrap", lines)

# ============================================================
# power of integer arrays keeps the integer type and wraps around
# ============================================================
lines = []
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    # an integer exponent (numpy: a Python int is weak)
    for a, t, e in (([2, 3, -4], "Int", 2), ([16, 3, 0], "UInt8", 2), ([16, 3, 7], "UInt8", 3), ([300, -2], "Int16", 2),
                    ([7, 2], "UInt8", 9), ([5, -1, 0], "Int8", 0), ([2, 3], "Int32", 10)):
        x = arr(a, t)
        lines += close(f"Matft.math.power(bases: x, exponents: {e})", np.power(x, e), layout=swift_array(x, t))
    # a float exponent gives a float array (Matft: .Float for Float-stored types)
    x = arr([4, 9], "Int")
    lines += close(f"Matft.math.power(bases: {swift_array(x, 'Int')}, exponents: 0.5)", np.power(x, 0.5).astype(np.float32), "Float")
    x = arr([1.5, -2], "Float")
    lines += close(f"Matft.math.power(bases: {swift_array(x, 'Float')}, exponents: 2)", np.power(x, 2))
    x = arr([1.5, -2], "Double")
    lines += close(f"Matft.math.power(bases: {swift_array(x, 'Double')}, exponents: 3)", np.power(x, 3))
    # array ** array
    for a, at, b, bt in (([2, 6], "UInt8", [8, 3], "UInt8"), ([2, 6, 7], "UInt8", [2, 6, 3], "UInt8"), ([7, -3], "Int8", [9, 5], "Int8"),
                         ([2, 3], "Int", [10, 3], "Int"), ([3, 2], "UInt8", [5, 4], "Int8"), ([300, 5], "Int16", [2, 3], "UInt8")):
        x, y = arr(a, at), arr(b, bt)
        lines += close(f"Matft.math.power(bases: {swift_array(x, at)}, exponents: {swift_array(y, bt)})", np.power(x, y))
    x, y = np.array([True, False, True]), np.array([True, True, False])
    lines += close(f"Matft.math.power(bases: {swift_array(x, 'Bool')}, exponents: {swift_array(y, 'Bool')})", np.power(x, y))
    x = np.array([True, False])
    lines += close(f"Matft.math.power(bases: {swift_array(x, 'Bool')}, exponents: 2)", np.power(x, 2))
    # an integer base
    for e, t in (([0, 3, 10], "Int"), ([9, 2], "UInt8"), ([1, 2], "Int8")):
        y = arr(e, t)
        lines += close(f"Matft.math.power(bases: 2, exponents: {swift_array(y, t)})", np.power(2, y))
    y = arr([0.5, 2], "Double")
    lines += close(f"Matft.math.power(bases: 2, exponents: {swift_array(y, 'Double')})", np.power(2, y))
    y = arr([1, 3], "Int")
    lines += close(f"Matft.math.power(bases: 2.5, exponents: {swift_array(y, 'Int')})", np.power(2.5, y).astype(np.float32), "Float")
test("power_integer", lines)

# ============================================================
# abs and round keep the integer type
# ============================================================
lines = []
for a, t in (([-128, -3, 5], "Int8"), ([-3, 5, 0], "Int"), ([200, 0], "UInt8"), ([-32768, 7], "Int16"), ([True, False], "Bool")):
    x = arr(a, t)
    lines += close("Matft.math.abs(x)", np.abs(x), layout=swift_array(x, t))
for a, t, d in (([15, 25, -3], "Int", 0), ([15, 25, 1234], "Int", -1), ([126, -125, 15, 25], "Int8", -1), ([250, 5], "UInt8", -1),
                ([1250, 1350], "Int16", -2), ([15, 7], "Int", 2)):
    x = arr(a, t)
    lines += close(f"Matft.math.round(x, decimals: {d})", np.round(x, d), layout=swift_array(x, t))
test("abs_round_integer", lines)

# ============================================================
# round(decimals:) keeps Double precision
# ============================================================
lines = []
for a, d in (([1.5, 2.25], 40), ([1.5, 2.25], 300), ([15, 25, 1234.5678, 1e300], -1), ([2.0015, 0.1234567890123], 3),
             ([123456.789, -0.5], -3), ([1.23456789012345], 12), ([2.5, 3.5, -2.5], 0)):
    x = arr(a, "Double")
    lines += close(f"Matft.math.round(x, decimals: {d})", np.round(x, d), rtol=0, atol=0, layout=swift_array(x, "Double"))
for a, d in (([1.2345, 2.5], 3), ([15, 25, 1234.5678], -1), ([0.125, -2.5], 2)):
    x = arr(a, "Float")
    lines += close(f"Matft.math.round(x, decimals: {d})", np.round(x, d), rtol=1e-7, atol=0, layout=swift_array(x, "Float"))
test("round_decimals", lines)

# ============================================================
# array / scalar is correctly rounded like numpy (not a multiplication by the reciprocal)
# ============================================================
lines = []
for a, s in (([6.0, 2002.0, 1234567890.0, 7.0, -0.3], "10.0"), ([1234567890.0, 3.0], "1e10"), ([1.0, 2.0, 5.0], "3.0")):
    x = arr(a, "Double")
    lines += close(f"x / {s}", x / float(s), rtol=0, atol=0, layout=swift_array(x, "Double"))
for a, s in (([6.0, 2002.0, 7.0, -0.3], "10"), ([1.0, 2.0, 5.0], "3")):
    x = arr(a, "Float")
    lines += close(f"x / Float({s})", x / np.float32(s), rtol=0, atol=0, layout=swift_array(x, "Float"))
# array / array and scalar / array (vDSP_vdiv(D) and vDSP_svdiv are not correctly rounded either, e.g. 255 / 255 -> 0.99999994)
rng = np.random.default_rng(0)
DIVX = np.concatenate([[255.0, 1.0, 7.0, -3.3, 1000.0, 0.0, 5.0], rng.uniform(-1000, 1000, 25)])
DIVY = np.concatenate([[255.0, 3.0, 10.0, 7.3, 0.001, 0.0, -0.0], rng.uniform(0.5, 1000, 25)])
with np.errstate(divide="ignore", invalid="ignore"):
    for t in ("Float", "Double"):
        x, y = arr(DIVX, t), arr(DIVY, t)
        lines += close(f"x / {swift_array(y, t)}", x / y, rtol=0, atol=0, layout=swift_array(x, t))
        s = "Float(7.3)" if t == "Float" else "7.3"
        lines += close(f"{s} / x", NP_DTYPE[t](7.3) / y, rtol=0, atol=0, layout=swift_array(y, t))
    x = arr(DIVX, "Float")
    lines += close("x / Float(3)", x / np.float32(3), rtol=0, atol=0, layout=swift_array(x, "Float"))
for a, s in (([3.0, 10.0, 7.0], "1.0"), ([3.0, 10.0], "2002.0")):
    x = arr(a, "Double")
    lines += close(f"{s} / x", float(s) / x, rtol=0, atol=0, layout=swift_array(x, "Double"))
test("div_scalar_exact", lines)
# numpy divides a complex array by the reciprocal of the divisor: (6+2002j) / 10 -> 0.6000000000000001+200.20000000000002j
z = np.array([6 + 2002j, 7 - 0.3j])
test("div_scalar_complex", zclose(f"{swift_complex(z, 'Double')} / 10.0", z / 10.0, "Double", rtol=0, atol=0), wasi_skip=True)

# ============================================================
# `==` of whole arrays: the same infinities are equal (np.array_equal / np.allclose)
# ============================================================
lines = []
for a, b, t in (([np.inf, -np.inf, 1.0], [np.inf, -np.inf, 1.0], "Double"), ([np.inf, 2.0], [np.inf, 2.0], "Float"),
                ([np.inf], [-np.inf], "Double"), ([np.inf, 1.0], [np.inf, 2.0], "Double"), ([np.nan], [np.nan], "Double"),
                ([np.inf], [1e300], "Double")):
    x, y = arr(a, t), arr(b, t)
    expected = bool(np.array_equal(x, y))
    s = f"{swift_array(x, t)} == {swift_array(y, t)}"
    lines.append(f"XCTAssert{'True' if expected else 'False'}({s}, \"{swift_escape(s)}\")")
test("equal_all_infinity", lines)

# ============================================================
# where / union1d / intersect1d promote integers like numpy's result_type
# ============================================================
lines = []
cond = np.array([True, False])
for x, xt, y, yt in (([200, 3], "UInt8", [-1], "Int8"), ([60000, 3], "UInt16", [-1, -1], "Int16"), ([1, 2], "Int8", [200, 250], "UInt8"),
                     ([5, 6], "Int", [7, 8], "Float")):
    xv, yv = arr(x, xt), arr(y, yt)
    exp = np.where(cond, xv, yv)
    rt = "Float" if "Float" in (xt, yt) else mftype_of(exp)
    lines += close(f"Matft.where({swift_array(cond, 'Bool')}, {swift_array(xv, xt)}, {swift_array(yv, yt)})", exp.astype(NP_DTYPE[rt]), rt)
for x, xt, y, yt in (([200], "UInt8", [-1], "Int8"), ([60000, 1], "UInt16", [-5], "Int16")):
    xv, yv = arr(x, xt), arr(y, yt)
    lines += close(f"Matft.union1d({swift_array(xv, xt)}, {swift_array(yv, yt)})", np.union1d(xv, yv))
for x, xt, y, yt in (([200, 1], "UInt8", [200, -1], "Int16"), ([60000, 3], "UInt16", [60000], "Int16")):
    xv, yv = arr(x, xt), arr(y, yt)
    lines += close(f"Matft.intersect1d({swift_array(xv, xt)}, {swift_array(yv, yt)})", np.intersect1d(xv, yv))
test("where_setops_result_type", lines)


with open(OUT, "w") as f:
    f.write(f"// Generated by python/{os.path.basename(__file__)} (numpy {np.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write(f"/// {DOC}\n")
    f.write(f"final class {CLASS}: XCTestCase {{\n")
    for name, body, wasi_skip in TESTS:
        f.write("\n")
        if wasi_skip:
            f.write("    #if !os(WASI)\n")
        f.write(f"    func test_{name}() throws {{\n")
        for line in body:
            f.write("        " + line + "\n")
        f.write("    }\n")
        if wasi_skip:
            f.write("    #endif\n")
    f.write("}\n")
print("wrote", OUT, sum(len(b) for _, b, _ in TESTS), "lines")
