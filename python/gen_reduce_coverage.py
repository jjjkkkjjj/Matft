"""Generate Tests/MatftTests/ReduceCoverageTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_reduce_coverage.py

Every case is a Swift expression and the numpy expression computing its expected value.
Cases taking `x` run over `layoutVariants(input)` (row/column major, transposed, offset, prefix, strided and reversed views),
so the expected values must not depend on the memory layout.
Matft conventions: a reduction over all the axes returns shape [1] (numpy returns a 0-d scalar).
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "ReduceCoverageTest.swift")
CLASS = "ReduceCoverageTests"
DOC = ("Reductions (sum, squaresum, sumsqrt, mean, cumsum, ufuncReduce, ufuncAccumulate) over dtypes, axes, keepDims, "
       "memory layouts (`layoutVariants`) and edge cases. Expected values are numpy outputs")

nan = np.nan
inf = np.inf

# numpy dtype <-> MfType
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


def swift_escape(s):
    return s.replace("\\", "\\\\").replace("\"", "\\\"")


# ---------- inputs (defined identically in Swift) ----------
INPUTS = {}


def inp(name, a, mftype):
    """Declare an input. The numpy array is cast to the dtype of mftype so the reference is computed in that type"""
    a = np.asarray(a).astype(NP_DTYPE[mftype])
    INPUTS[name] = (a, mftype)
    return a


TESTS = []  # (name, [lines], wasi_skip)


def test(name, lines, wasi_skip=False):
    TESTS.append((name, lines, wasi_skip))


def _loop(layout, assertion):
    if layout:
        return [f"for (name, x) in layoutVariants({layout}){{", f"    {assertion}", "}"]
    return [assertion]


def close(swift, expected, mftype=None, rtol=None, atol=None, layout=None, check_type=True):
    """XCTAssertClose line. mftype defaults to numpy's result dtype, and the Matft dtype is asserted too (check_type).
    `layout`: the input whose layouts are iterated (the expression uses `x`)"""
    mftype = mftype or mftype_of(expected)
    rtol = rtol if rtol is not None else (1e-5 if mftype == "Float" else 1e-10)
    atol = atol if atol is not None else (1e-5 if mftype == "Float" else 1e-10)
    label = swift_escape(swift) + (" \\(name)" if layout else "")
    ct = ", checkType: true" if check_type else ""
    return _loop(layout, f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: {rtol}, atol: {atol}{ct}, \"{label}\")")


def equal(swift, expected, mftype=None, layout=None):
    """Exact comparison for Int / Bool results: values, shape and mftype.
    Not `XCTAssertEqual(MfArray, MfArray)`: `==` ignores the mftype, allows 1e-5 for floats and wraps integers
    (UInt8 43 == 299), so it passes wrong dtypes and out-of-range indices"""
    mftype = mftype or mftype_of(expected)
    label = swift_escape(swift) + (" \\(name)" if layout else "")
    return _loop(layout, f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: 0, atol: 0, checkType: true, \"{label}\")")


def shape(swift, expected_shape, layout=None):
    label = swift_escape(swift) + (" \\(name)" if layout else "")
    return _loop(layout, f"XCTAssertEqual(({swift}).shape, {list(expected_shape)}, \"{label}\")")


# ---------- inputs ----------
# A is 3x4 with negatives and ties, A3 is 2x3x4 (generic N-d path), U8/I8 overflow when summed (numpy wraps with dtype=)
BASE = [[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]]
A = inp("A", BASE, "Double")
AF = inp("AF", BASE, "Float")
AI = inp("AI", BASE, "Int")
U8 = inp("U8", [[250, 1, 127], [10, 254, 255]], "UInt8")
I8 = inp("I8", [[127, -128, 100], [1, -1, 100]], "Int8")
B = inp("B", [[True, False, True, True], [False, False, True, False], [True, True, True, False]], "Bool")
A3 = inp("A3", np.array([7, -3, 2, 0, 5, 5, -8, 1, 4, 6, -2, 9, 3, 3, -1, 0, 2, 8, -6, 4, 1, -5, 7, 2]).reshape(2, 3, 4), "Double")
AN = inp("AN", [[1, nan, 3, 4], [2, 5, nan, 1], [nan, 7, 2, 2]], "Double")
ANF = inp("ANF", [[1, nan, 3, 4], [2, 5, nan, 1], [nan, 7, 2, 2]], "Float")
AINF = inp("AINF", [[1, inf, 2, -inf], [inf, 1, 2, 3], [-1, -2, -3, -inf]], "Double")
# 4x17: cumsum along axis 0 has rows of >= 16 elements (vectorized vadd path) instead of the sequential loop
W = inp("W", (np.arange(68) % 7 - 3).reshape(4, 17), "Float")

AXES2 = [None, 0, 1, -1, -2]
AXES3 = [None, 0, 1, 2, -1]


def ax_arg(axis, kd=False):
    s = "" if axis is None else f", axis: {axis}"
    if kd:
        s += ", keepDims: true"
    return s


def red_arg(axis, kd=False):
    """ufuncReduce defaults to axis 0 like numpy, so axis nil is passed explicitly"""
    s = ", axis: nil" if axis is None else f", axis: {axis}"
    if kd:
        s += ", keepDims: true"
    return s


def sum_expected(a, axis, kd):
    """Matft convention: the sum keeps the input mftype (numpy widens small ints to int64), wrapping like numpy
    with dtype=, and .Bool is summed as .Float"""
    dt = np.float32 if a.dtype == np.bool_ else a.dtype
    return np.sum(a, axis=axis, keepdims=kd, dtype=dt)


# ---------- sum / squaresum / sumsqrt over dtypes, axes, keepDims and layouts ----------
lines = []
for src in ["A", "AF", "AI", "U8", "I8", "B"]:
    a, _ = INPUTS[src]
    for axis in AXES2:
        for kd in [False, True]:
            lines += close(f"Matft.stats.sum(x{ax_arg(axis, kd)})", sum_expected(a, axis, kd), layout=src)
test("sum_dtypes_axes_layouts", lines)

lines = []
for axis in AXES3:
    for kd in [False, True]:
        lines += close(f"Matft.stats.sum(x{ax_arg(axis, kd)})", np.sum(A3, axis=axis, keepdims=kd), layout="A3")
test("sum_3d", lines)

lines = []
for src in ["A", "AF", "AI", "U8", "B"]:
    a, _ = INPUTS[src]
    for axis in [None, 0, -1]:
        sq = np.square(a.astype(np.float32)) if a.dtype == np.bool_ else np.square(a)
        lines += close(f"Matft.stats.squaresum(x{ax_arg(axis)})", sum_expected(sq, axis, False), layout=src)
test("squaresum", lines)

lines = []
with np.errstate(invalid="ignore"):
    for src in ["A", "AF", "AI"]:
        a, _ = INPUTS[src]
        for axis in [None, 0, 1]:
            s = np.sum(a, axis=axis)
            # the sqrt of a negative sum is NaN; Matft returns .Float for non-Double inputs
            exp = np.sqrt(s) if src == "A" else np.sqrt(s.astype(np.float32))
            lines += close(f"Matft.stats.sumsqrt(x{ax_arg(axis)})", exp, layout=src)
test("sumsqrt", lines)

# ---------- mean: Matft returns .Float for every non-Double input (numpy gives float64 for integers) ----------
lines = []
for src in ["A", "AF", "AI", "U8", "B"]:
    a, _ = INPUTS[src]
    for axis in AXES2:
        for kd in [False, True]:
            m = np.mean(a.astype(np.float64), axis=axis, keepdims=kd)
            exp = m if src == "A" else m.astype(np.float32)
            lines += close(f"Matft.stats.mean(x{ax_arg(axis, kd)})", exp, layout=src)
for axis in AXES3:
    lines += close(f"Matft.stats.mean(x{ax_arg(axis)})", np.mean(A3, axis=axis), layout="A3")
test("mean_dtypes_axes_layouts", lines)

# ---------- cumsum: keeps the mftype (wraps), .Bool is summed as .Int like numpy ----------
lines = []
for src in ["A", "AF", "AI", "U8", "I8", "B"]:
    a, _ = INPUTS[src]
    dt = np.int64 if a.dtype == np.bool_ else a.dtype
    for axis in AXES2:
        lines += close(f"Matft.stats.cumsum(x{ax_arg(axis)})", np.cumsum(a, axis=axis, dtype=dt), layout=src)
for axis in AXES3:
    lines += close(f"Matft.stats.cumsum(x{ax_arg(axis)})", np.cumsum(A3, axis=axis), layout="A3")
for axis in [0, 1]:
    lines += close(f"Matft.stats.cumsum(x{ax_arg(axis)})", np.cumsum(W, axis=axis), layout="W")
test("cumsum_dtypes_axes_layouts", lines)

# ---------- ufuncReduce / ufuncAccumulate (np.<ufunc>.reduce / accumulate with dtype= the input type) ----------
UFUNCS = [("Matft.add", np.add), ("Matft.mul", np.multiply), ("Matft.stats.maximum", np.maximum), ("Matft.stats.minimum", np.minimum)]
lines = []
for src in ["A", "AF", "AI", "U8"]:
    a, _ = INPUTS[src]
    for sw, uf in UFUNCS:
        for axis in [None, 0, 1, -1]:
            for kd in [False, True]:
                exp = uf.reduce(a, axis=axis, keepdims=kd, dtype=a.dtype)
                lines += close(f"Matft.ufuncReduce(mfarray: x, ufunc: {sw}{red_arg(axis, kd)})", exp, layout=src)
test("ufuncReduce_dtypes_axes_layouts", lines)

lines = []
for sw, uf in UFUNCS:
    for axis in AXES3:
        for kd in [False, True]:
            lines += close(f"Matft.ufuncReduce(mfarray: x, ufunc: {sw}{red_arg(axis, kd)})", uf.reduce(A3, axis=axis, keepdims=kd), layout="A3")
# initial is combined with the first element (ignored for axis nil, see the doc)
for sw, uf in UFUNCS:
    for axis in [0, 1, -1]:
        lines += close(f"Matft.ufuncReduce(mfarray: x, ufunc: {sw}, axis: {axis}, initial: MfArray([4] as [Double]))",
                       uf.reduce(A, axis=axis, initial=4.0), layout="A")
# the method form defaults to axis 0 like numpy
lines += close("x.ufuncReduce(Matft.add)", np.add.reduce(A), layout="A")
test("ufuncReduce_3d_initial", lines)

lines = []
for src in ["A", "AF", "AI", "U8"]:
    a, _ = INPUTS[src]
    for sw, uf in UFUNCS:
        for axis in [0, 1, -1]:
            lines += close(f"Matft.ufuncAccumulate(mfarray: x, ufunc: {sw}, axis: {axis})", uf.accumulate(a, axis=axis, dtype=a.dtype), layout=src)
for sw, uf in UFUNCS:
    for axis in [0, 1, 2, -1]:
        lines += close(f"Matft.ufuncAccumulate(mfarray: x, ufunc: {sw}, axis: {axis})", uf.accumulate(A3, axis=axis), layout="A3")
lines += close("x.ufuncAccumulate(Matft.add)", np.add.accumulate(A), layout="A")
test("ufuncAccumulate", lines)

# ---------- NaN / inf propagate like numpy ----------
lines = []
with warnings.catch_warnings(), np.errstate(all="ignore"):
    for src in ["AN", "ANF", "AINF"]:
        a, _ = INPUTS[src]
        for axis in [None, 0, 1]:
            lines += close(f"Matft.stats.sum(x{ax_arg(axis)})", np.sum(a, axis=axis), layout=src)
            lines += close(f"Matft.stats.mean(x{ax_arg(axis)})", np.mean(a, axis=axis), layout=src)
            lines += close(f"Matft.stats.squaresum(x{ax_arg(axis)})", np.sum(np.square(a), axis=axis), layout=src)
            lines += close(f"Matft.stats.cumsum(x{ax_arg(axis)})", np.cumsum(a, axis=axis), layout=src)
        for sw, uf in UFUNCS:
            lines += close(f"Matft.ufuncReduce(mfarray: x, ufunc: {sw}, axis: 1)", uf.reduce(a, axis=1), layout=src)
            lines += close(f"Matft.ufuncAccumulate(mfarray: x, ufunc: {sw}, axis: 1)", uf.accumulate(a, axis=1), layout=src)
test("nan_inf", lines)

# ---------- integer wraparound ----------
lines = []
lines += close("Matft.stats.sum(MfArray([200, 100, 250] as [Int], mftype: .UInt8))", np.sum(np.array([200, 100, 250], np.uint8), dtype=np.uint8))
lines += close("Matft.stats.sum(MfArray([127, 1] as [Int], mftype: .Int8))", np.sum(np.array([127, 1], np.int8), dtype=np.int8))
lines += close("Matft.stats.cumsum(MfArray([200, 100, 250] as [Int], mftype: .UInt8))", np.cumsum(np.array([200, 100, 250], np.uint8), dtype=np.uint8))
lines += close("Matft.stats.cumsum(MfArray([-100, -100, 50] as [Int], mftype: .Int8))", np.cumsum(np.array([-100, -100, 50], np.int8), dtype=np.int8))
lines += close("Matft.ufuncReduce(mfarray: MfArray([16, 16, 3] as [Int], mftype: .UInt8), ufunc: Matft.mul)", np.multiply.reduce(np.array([16, 16, 3], np.uint8), dtype=np.uint8))
test("integer_wrap", lines)

# ---------- empty and size-1 arrays ----------
EMPTY = {
    "[3, 0]": np.zeros((3, 0)),
    "[0, 4]": np.zeros((0, 4)),
    "[2, 0, 3]": np.zeros((2, 0, 3)),
}
lines = []
with warnings.catch_warnings(), np.errstate(all="ignore"):
    warnings.simplefilter("ignore")
    for shp, e in EMPTY.items():
        for mftype in ["Double", "Float"]:
            ev = e.astype(NP_DTYPE[mftype])
            sw = f"MfArray([] as [Double], mftype: .{mftype}, shape: {shp})"
            for axis in [None] + list(range(e.ndim)):
                lines += close(f"Matft.stats.sum({sw}{ax_arg(axis)})", np.sum(ev, axis=axis))
                lines += close(f"Matft.stats.squaresum({sw}{ax_arg(axis)})", np.sum(np.square(ev), axis=axis))
                # numpy: the mean of an empty slice is NaN (RuntimeWarning)
                lines += close(f"Matft.stats.mean({sw}{ax_arg(axis)})", np.mean(ev, axis=axis))
                lines += close(f"Matft.stats.cumsum({sw}{ax_arg(axis)})", np.cumsum(ev, axis=axis))
    lines += close("Matft.stats.sum(MfArray([] as [Int], mftype: .Int, shape: [3, 0]), axis: 1, keepDims: true)",
                   np.sum(np.zeros((3, 0), np.int64), axis=1, keepdims=True))
test("empty", lines)

lines = []
ONE = np.array([[5.0]])
for axis in [None, 0, 1]:
    for kd in [False, True]:
        lines += close(f"Matft.stats.sum(MfArray([[5.0]] as [[Double]]){ax_arg(axis, kd)})", np.sum(ONE, axis=axis, keepdims=kd))
        lines += close(f"Matft.stats.mean(MfArray([[5.0]] as [[Double]]){ax_arg(axis, kd)})", np.mean(ONE, axis=axis, keepdims=kd))
    if axis is not None:
        lines += close(f"Matft.stats.cumsum(MfArray([[5.0]] as [[Double]]){ax_arg(axis)})", np.cumsum(ONE, axis=axis))
        lines += close(f"Matft.ufuncReduce(mfarray: MfArray([[5.0]] as [[Double]]), ufunc: Matft.add{ax_arg(axis)})", np.add.reduce(ONE, axis=axis))
        lines += close(f"Matft.ufuncAccumulate(mfarray: MfArray([[5.0]] as [[Double]]), ufunc: Matft.add{ax_arg(axis)})", np.add.accumulate(ONE, axis=axis))
lines += close("Matft.stats.sum(MfArray([7.0] as [Double]), axis: 0)", np.sum(np.array([7.0]), axis=0))
lines += close("Matft.stats.cumsum(MfArray([7.0] as [Double]), axis: 0)", np.cumsum(np.array([7.0]), axis=0))
test("size1", lines)

# ---------- method forms (same kernels, checked once) ----------
lines = []
lines += close("x.sum(axis: 1)", np.sum(A, axis=1), layout="A")
lines += close("x.sum(axis: 0, keepDims: true)", np.sum(A, axis=0, keepdims=True), layout="A")
lines += close("x.mean(axis: -1)", np.mean(A, axis=-1), layout="A")
lines += close("x.squaresum()", np.sum(np.square(A)), layout="A")
with np.errstate(invalid="ignore"):
    lines += close("x.sumsqrt(axis: 1)", np.sqrt(np.sum(A, axis=1)), layout="A")
lines += close("x.cumsum(axis: 1)", np.cumsum(A, axis=1), layout="A")
lines += close("x.cumsum()", np.cumsum(A), layout="A")
test("method_forms", lines)

# ---------- the input is not modified ----------
lines = [
    "for (name, x) in layoutVariants(A){",
    "    let before = rowValues(x)",
    "    _ = Matft.stats.cumsum(x, axis: 0); _ = Matft.stats.sum(x, axis: 1); _ = Matft.stats.mean(x)",
    "    _ = Matft.ufuncReduce(mfarray: x, ufunc: Matft.add, axis: 1); _ = Matft.ufuncAccumulate(mfarray: x, ufunc: Matft.add, axis: 1)",
    "    XCTAssertEqual(rowValues(x), before, \"input changed \\(name)\")",
    "}",
]
test("input_unchanged", lines)


# ---------- write ----------
with open(OUT, "w") as f:
    f.write(f"// Generated by python/{os.path.basename(__file__)} (numpy {np.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write(f"/// {DOC}\n")
    f.write(f"final class {CLASS}: XCTestCase {{\n")
    for name, (a, mftype) in INPUTS.items():
        f.write(f"    private let {name} = {swift_array(a, mftype)}\n")
    for name, body, wasi_skip in TESTS:
        f.write("\n")
        if wasi_skip:
            f.write("    #if !os(WASI)\n")
        f.write(f"    func test_{name}() {{\n")
        for line in body:
            f.write("        " + line + "\n")
        f.write("    }\n")
        if wasi_skip:
            f.write("    #endif\n")
    f.write("}\n")
print("wrote", OUT, sum(len(b) for _, b, _ in TESTS), "lines")
