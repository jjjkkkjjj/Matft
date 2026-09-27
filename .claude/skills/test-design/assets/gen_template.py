"""Generate Tests/MatftTests/<Area>CoverageTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_<area>_coverage.py

Every case is a Swift expression and the numpy expression computing its expected value.
Cases taking `x` run over `layoutVariants(input)` (row/column major, transposed, offset, prefix, strided and reversed views),
so the expected values must not depend on the memory layout.
Matft conventions: a reduction over all the axes returns shape [1] (numpy returns a 0-d scalar).
"""
import os
import warnings

import numpy as np

# TODO: set the output file and the class name
OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "AreaCoverageTest.swift")
CLASS = "AreaCoverageTests"
DOC = "<Area> over dtypes, memory layouts (`layoutVariants`) and edge cases. Expected values are numpy outputs"

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
# Pick inputs that hit several viewpoints at once: negatives, ties, non-square shape, NaN, integer boundaries
BASE = [[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]]
A = inp("A", BASE, "Double")
AF = inp("AF", BASE, "Float")
AI = inp("AI", BASE, "Int")
AN = inp("AN", [[1, nan, 3, 4], [2, 5, nan, 1], [nan, 7, 2, 2]], "Double")
U8 = inp("U8", [[0, 1, 127], [128, 254, 255]], "UInt8")

# ---------- cases ----------
# TODO: replace `np.cumsum` / `Matft.stats.cumsum` with the function under test and add sections per viewpoint
lines = []
for src in ["A", "AF", "AI"]:
    a, _ = INPUTS[src]
    for axis in [None, 0, 1, -1]:
        ax = "" if axis is None else f", axis: {axis}"
        lines += close(f"Matft.stats.cumsum(x{ax})", np.cumsum(a, axis=axis), layout=src)
test("cumsum_dtypes_axes_layouts", lines)

lines = []
with warnings.catch_warnings(), np.errstate(all="ignore"):
    lines += close("Matft.stats.cumsum(x, axis: 1)", np.cumsum(AN, axis=1), layout="AN")
test("cumsum_nan", lines)

lines = []
lines += shape("Matft.stats.cumsum(MfArray([] as [Double], shape: [3, 0]), axis: 1)", np.cumsum(np.zeros((3, 0)), axis=1).shape)
test("cumsum_empty", lines)


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
