"""Generate Tests/MatftTests/BugHuntComplexTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_bughunt_complex.py

Regression tests of the complex bugs found by the bug hunt of 2026-09-27, where the imaginary part was ignored or dropped:
comparisons (numpy compares both parts for == / != and is lexicographic for the others),
logical_not / astype(.Bool), vstack / hstack / concatenate with a complex array, diag of a complex vector,
and abs of complex numbers that overflow or underflow when squared (numpy uses hypot).

Every case is a Swift expression and the numpy expression computing its expected value.
Cases taking `x` run over the complex layouts declared by `zinp` (row/column major, offset, prefix, strided, reversed and transposed views).
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "BugHuntComplexTest.swift")
CLASS = "BugHuntComplexTests"
DOC = "The imaginary part of complex arrays in comparisons, Bool conversion, joining, diag and abs. Expected values are numpy outputs"

nan = np.nan
inf = np.inf

NP_DTYPE = {"Bool": np.bool_, "Int": np.int64, "Float": np.float32, "Double": np.float64}


def lit(v):
    v = float(v)
    if np.isnan(v):
        return ".nan"
    if np.isinf(v):
        return ".infinity" if v > 0 else "-.infinity"
    return repr(v)


def swift_array(a, mftype):
    """Swift expression creating `a` as MfArray of mftype"""
    a = np.asarray(a)
    shape = list(a.shape) if a.ndim > 0 else [1]
    flat = a.ravel()
    if mftype == "Bool":
        values = ", ".join("true" if bool(v) else "false" for v in flat)
        return f"MfArray([{values}] as [Bool], shape: {shape})"
    if mftype == "Int":
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
ZLAYOUTS = {}  # name -> Swift expression of the [(name, array)] list


def inp(name, a, mftype):
    """Declare a real input"""
    a = np.asarray(a).astype(NP_DTYPE[mftype])
    INPUTS[name] = swift_array(a, mftype)
    return a


def cplx(z, mftype):
    z = np.asarray(z)
    t = NP_DTYPE[mftype]
    # set the parts directly: `re + 1j * im` gives NaN parts for infinities
    ret = np.empty(z.shape, dtype=np.complex64 if mftype == "Float" else np.complex128)
    ret.real = z.real.astype(t)
    ret.imag = z.imag.astype(t)
    return ret


def zinp(name, z, mftype):
    """Declare a complex input and its layouts: the same logical values as a column-major copy and
    as views with an offset, a smaller size, a stride, reversed rows and a transposed view (all built from literals)"""
    z = cplx(z, mftype)
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
    return z


TESTS = []  # (name, [lines])


def test(name, lines):
    TESTS.append((name, lines))


def _loop(layout, assertions):
    if layout is None:
        return assertions
    head = f"for (name, x) in {ZLAYOUTS[layout]} as [(String, MfArray)]{{"
    return [head] + ["    " + a for a in assertions] + ["}"]


def _label(swift, layout):
    return swift_escape(swift) + (" \\(name)" if layout else "")


def _tol(mftype, rtol, atol):
    rtol = rtol if rtol is not None else (1e-6 if mftype == "Float" else 1e-12)
    atol = atol if atol is not None else 0
    return rtol, atol


def close(swift, expected, mftype, rtol=None, atol=None, layout=None):
    """The result is real, of mftype, and close to numpy"""
    rtol, atol = _tol(mftype, rtol, atol)
    return _loop(layout, [f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: {rtol}, atol: {atol}, checkType: true, \"{_label(swift, layout)}\")"])


def equal(swift, expected, layout=None):
    """Exact comparison of a Bool result"""
    return _loop(layout, [f"XCTAssertClose({swift}, {swift_array(expected, 'Bool')}, rtol: 0, atol: 0, checkType: true, \"{_label(swift, layout)}\")"])


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


# ============================================================
# Comparisons
# ============================================================
# equal real parts with different imaginary parts, ties, NaN in either part and infinities
ZA_values = [[1 + 2j, 2 + 0j, -1j, 3 + 1j],
             [0j, 1 - 1j, complex(nan, 0), complex(inf, 0)],
             [complex(inf, 1), 2 + 2j, complex(2, nan), -1 + 5j]]
ZB_values = [[1 + 3j, 2 + 0j, 0j, 3 - 1j],
             [1j, 1 - 1j, complex(nan, 0), complex(inf, 0)],
             [complex(inf, 0), 1 + 5j, complex(1, 0), -1 + 5j]]
ZA = zinp("ZA", ZA_values, "Double")
ZB = cplx(ZB_values, "Double")
INPUTS["ZB"] = swift_complex(ZB, "Double")
ZAF = zinp("ZAF", ZA_values, "Float")
ZBF = cplx(ZB_values, "Float")
INPUTS["ZBF"] = swift_complex(ZBF, "Float")
# a real array compared with a complex one: the real array has 0 imaginary part
R = inp("R", [[1, 2, 0, 3], [0, 0, nan, inf], [inf, 2, 2, -1]], "Double")

OPS = [("===", np.equal), ("!==", np.not_equal), ("<", np.less), ("<=", np.less_equal),
       (">", np.greater), (">=", np.greater_equal)]

with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    lines = []
    for op, f in OPS:
        lines += equal(f"x {op} ZB", f(ZA, ZB), layout="ZA")
        lines += equal(f"ZB {op} x", f(ZB, ZA), layout="ZA")
        lines += equal(f"x {op} ZBF", f(ZAF, ZBF), layout="ZAF")
    test("compare_complex_arrays", lines)

    lines = []
    for op, f in OPS:
        lines += equal(f"x {op} R", f(ZA, R), layout="ZA")
        lines += equal(f"R {op} x", f(R, ZA), layout="ZA")
    # broadcasting a complex row against a complex matrix
    ROW = cplx([1 + 1j, 2 + 0j, 0j, 3 + 1j], "Double")
    INPUTS["ROW"] = swift_complex(ROW, "Double")
    for op, f in OPS:
        lines += equal(f"ZA {op} ROW", f(ZA, ROW))
    test("compare_complex_real_and_broadcast", lines)

    lines = []
    for op, f in OPS:
        for s in (0, 1, 2):
            lines += equal(f"x {op} {s}", f(ZA, s), layout="ZA")
            lines += equal(f"{s} {op} x", f(s, ZA), layout="ZA")
            lines += equal(f"x {op} Float({s})", f(ZAF, np.float32(s)), layout="ZAF")
    test("compare_complex_scalar", lines)

    lines = []
    lines += equal("Matft.logical_not(x)", np.logical_not(ZA), layout="ZA")
    lines += equal("x.astype(.Bool)", ZA.astype(bool), layout="ZA")
    lines += equal("Matft.logical_not(x)", np.logical_not(ZAF), layout="ZAF")
    lines += equal("x.astype(.Bool)", ZAF.astype(bool), layout="ZAF")
    test("complex_to_bool", lines)

# ============================================================
# Joining and diag
# ============================================================
Z23 = zinp("Z23", [[1 + 2j, -3 + 0j, -1j], [2 - 2j, 0j, 4 + 5j]], "Double")
R23 = inp("R23", [[7, 8, 9], [10, 11, 12]], "Double")
R23F = inp("R23F", [[7, 8, 9], [10, 11, 12]], "Float")
Z23F = cplx(Z23, "Float")
INPUTS["Z23F"] = swift_complex(Z23F, "Float")
Z1 = cplx([1 + 1j, 2 - 1j, 3j], "Double")
INPUTS["Z1"] = swift_complex(Z1, "Double")
R1 = inp("R1", [4, 5, 6], "Double")
Z3D = cplx(np.arange(12).reshape(2, 3, 2) + 1j * (np.arange(12).reshape(2, 3, 2) - 5.0), "Double")
INPUTS["Z3D"] = swift_complex(Z3D, "Double")
R3D = inp("R3D", np.arange(8).reshape(2, 2, 2) * 10, "Double")

lines = []
lines += zclose("Matft.vstack([x, R23])", np.vstack([Z23, R23]), "Double", layout="Z23")
lines += zclose("Matft.vstack([R23, x])", np.vstack([R23, Z23]), "Double", layout="Z23")
lines += zclose("Matft.vstack([x, x])", np.vstack([Z23, Z23]), "Double", layout="Z23")
lines += zclose("Matft.vstack([Z1, R1])", np.vstack([Z1, R1]), "Double")
lines += zclose("Matft.hstack([x, R23])", np.hstack([Z23, R23]), "Double", layout="Z23")
lines += zclose("Matft.hstack([R23, x])", np.hstack([R23, Z23]), "Double", layout="Z23")
lines += zclose("Matft.hstack([Z1, R1])", np.hstack([Z1, R1]), "Double")
lines += zclose("Matft.concatenate([x, R23], axis: 0)", np.concatenate([Z23, R23], axis=0), "Double", layout="Z23")
lines += zclose("Matft.concatenate([x, R23], axis: 1)", np.concatenate([Z23, R23], axis=1), "Double", layout="Z23")
lines += zclose("Matft.concatenate([R23, x], axis: -1)", np.concatenate([R23, Z23], axis=-1), "Double", layout="Z23")
lines += zclose("Matft.concatenate([Z3D, R3D], axis: 1)", np.concatenate([Z3D, R3D], axis=1), "Double")
lines += zclose("Matft.concatenate([R3D, Z3D, R3D], axis: 1)", np.concatenate([R3D, Z3D, R3D], axis=1), "Double")
# Float complex with Float real stays Float; with Double gives Double (numpy complex64 + float64 -> complex128)
lines += zclose("Matft.vstack([Z23F, R23F])", np.vstack([Z23F, R23F]), "Float")
lines += zclose("Matft.vstack([Z23F, R23])", np.vstack([Z23F, R23]), "Double")
lines += zclose("Matft.append(Z1, values: R1)", np.append(Z1, R1), "Double")
test("join_complex", lines)

lines = []
lines += zclose("Matft.diag(v: Z1)", np.diag(Z1), "Double")
lines += zclose("Matft.diag(v: Z1, k: 1)", np.diag(Z1, k=1), "Double")
lines += zclose("Matft.diag(v: Z1, k: -2)", np.diag(Z1, k=-2), "Double")
lines += zclose("Matft.diag(v: Z1, mforder: .Column)", np.diag(Z1), "Double")
lines += zclose("Matft.diag(v: Z23[1])", np.diag(Z23[1]), "Double")
lines += zclose("Matft.diag(v: Z23F[0])", np.diag(Z23F[0]), "Float")
test("diag_complex", lines)

# ============================================================
# abs: numpy uses hypot, so squaring does not overflow nor underflow, and |inf + nan j| is inf
# ============================================================
ABS = cplx([1e200 + 1e200j, 1e-200 + 1e-200j, 3e307 + 3e307j, complex(inf, nan), complex(nan, inf),
            3 + 4j, 0j, complex(nan, 1), complex(-inf, 0), -5e-320 + 0j, 1e300 + 1e-300j, 1e-170 + 1e-160j], "Double")
INPUTS["ABS"] = swift_complex(ABS, "Double")
ABSF = cplx([1e20 + 1e20j, 1e-25 + 1e-25j, 3e38 + 3e38j, complex(inf, nan), 3 + 4j, 0j, complex(nan, 1),
             1e-40 + 0j, 3e19 - 4e19j], "Float")
INPUTS["ABSF"] = swift_complex(ABSF, "Float")
ABS2 = zinp("ABS2", [[1e200 + 1e200j, 3 + 4j], [1e-200 + 1e-200j, complex(inf, nan)]], "Double")

with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    lines = []
    lines += close("Matft.complex.abs(ABS)", np.abs(ABS), "Double")
    lines += close("Matft.math.abs(ABS)", np.abs(ABS), "Double")
    lines += close("Matft.complex.abs(ABSF)", np.abs(ABSF), "Float")
    lines += close("Matft.complex.abs(x)", np.abs(ABS2), "Double", layout="ABS2")
    lines += close("Matft.complex.absarg(ABS).abs", np.abs(ABS), "Double")
    LOGZ = cplx([1e200 + 1e200j, 1e-200 + 1e-200j], "Double")
    INPUTS["LOGZ"] = swift_complex(LOGZ, "Double")
    lines += zclose("Matft.math.log(LOGZ)", np.log(LOGZ), "Double")
    test("abs_complex_hypot", lines)


# ---------- write ----------
with open(OUT, "w") as f:
    f.write(f"// Generated by python/{os.path.basename(__file__)} (numpy {np.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write(f"/// {DOC}\n")
    f.write("/// Complex operations need Accelerate, so the tests are skipped on WASI\n")
    f.write("#if !os(WASI)\n")
    f.write(f"final class {CLASS}: XCTestCase {{\n")
    for name, expr in INPUTS.items():
        f.write(f"    private let {name} = {expr}\n")
    for name, body in TESTS:
        f.write("\n")
        f.write(f"    func test_{name}() {{\n")
        for line in body:
            f.write("        " + line + "\n")
        f.write("    }\n")
    f.write("}\n")
    f.write("#endif\n")
print("wrote", OUT, sum(len(b) for _, b in TESTS), "lines")
