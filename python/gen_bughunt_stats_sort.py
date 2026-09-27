"""Generate Tests/MatftTests/BugHuntStatsSortTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_bughunt_stats_sort.py

Regression tests for the stats / ordering bugs found by the 2026-09-27 bug hunt:
sort / argsort with NaN (numpy puts NaN last; `.Descending` is the exact reverse, NaN first),
cov with ddof > N and rowvar=False on a single row, unique_all / unique_counts / unique_inverse keeping every NaN,
and pinv on stacked matrices (the cutoff is per matrix).
Matft conventions: `.Descending` is `np.flip(np.sort(x, axis), axis)`; cov of a single variable returns shape [1].
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "BugHuntStatsSortTest.swift")
CLASS = "BugHuntStatsSortTests"
DOC = ("Regression tests for sort / argsort with NaN, cov (ddof > N, rowvar on a single row), unique_* with NaN and "
       "stacked pinv. Expected values are numpy outputs")

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
SN = inp("SN", [3, nan, 1, 2, nan, 0.5], "Double")
SNF = inp("SNF", [3, nan, 1, 2, nan, 0.5], "Float")
SINF = inp("SINF", [inf, -inf, 1, nan, -0.5], "Double")
# distinct non-NaN values in every lane, so argsort is unique apart from the NaN (numpy keeps NaN in index order)
M = inp("M", [[4, nan, -1, 7], [nan, nan, 2, -3], [0.5, 9, inf, nan]], "Double")
MF = inp("MF", [[4, nan, -1, 7], [nan, nan, 2, -3], [0.5, 9, inf, nan]], "Float")
M3 = inp("M3", np.array([7, nan, 2, 0, 5, -5, -8, 1, nan, 6, -2, 9,
                         3, 4, -1, nan, 2.5, 8, -6, -4, 1.5, -7, nan, 12]).reshape(2, 3, 4), "Double")
# long lanes with a few NaN in the middle (vDSP's sort path for longer inputs)
L = inp("L", np.where(np.isin(np.arange(40), [7, 23, 31]), nan, (np.arange(40) * 17) % 41 - 20.0), "Double")
LF = inp("LF", L, "Float")
ALLNAN = inp("ALLNAN", [[nan, nan, nan], [1, nan, 0]], "Double")
NONAN = inp("NONAN", [[3, -1, 2], [0, 5, 4]], "Double")


def desc_sort(a, axis):
    if axis is None:
        return np.sort(a, axis=None)[::-1]
    return np.flip(np.sort(a, axis=axis), axis=axis)


def desc_argsort(a, axis):
    if axis is None:
        return np.argsort(a, axis=None, kind="stable")[::-1]
    return np.flip(np.argsort(a, axis=axis, kind="stable"), axis=axis)


def sort_lines(src, a, axes, layout=True):
    lines = []
    mftype = INPUTS[src][1]
    for axis in axes:
        arg = "nil" if axis is None else str(axis)
        x = "x" if layout else src
        lo = src if layout else None
        lines += close(f"Matft.sort({x}, axis: {arg})", np.sort(a, axis=axis), mftype=mftype, rtol=0, atol=0, layout=lo)
        lines += close(f"Matft.sort({x}, axis: {arg}, order: .Descending)", desc_sort(a, axis), mftype=mftype, rtol=0, atol=0, layout=lo)
        lines += equal(f"Matft.argsort({x}, axis: {arg})", np.argsort(a, axis=axis, kind="stable"), mftype="Int", layout=lo)
        lines += equal(f"Matft.argsort({x}, axis: {arg}, order: .Descending)", desc_argsort(a, axis), mftype="Int", layout=lo)
    return lines


test("sort_nan_1d", sort_lines("SN", SN, [None, -1], layout=False) + sort_lines("SNF", SNF, [None, -1], layout=False)
     + sort_lines("SINF", SINF, [None], layout=False))
test("sort_nan_2d", sort_lines("M", M, [None, 0, 1, -1]) + sort_lines("MF", MF, [None, 0, 1]))
test("sort_nan_3d", sort_lines("M3", M3, [None, 0, 1, 2]))
test("sort_nan_long", sort_lines("L", L, [None], layout=False) + sort_lines("LF", LF, [None], layout=False))
test("sort_all_nan_lane", sort_lines("ALLNAN", ALLNAN, [None, 0, 1]))
test("sort_no_nan", sort_lines("NONAN", NONAN, [None, 0, 1]))

# ---------- cov ----------
CV1 = inp("CV1", [1.0, 2.0], "Double")
CV2 = inp("CV2", [[1.0, 2.0, 4.0], [3.0, 1.0, 0.0]], "Double")
ROW = inp("ROW", [[1.0, 2.0, 4.0]], "Double")
ROWY = inp("ROWY", [[2.0, -1.0, 0.5]], "Double")
lines = []
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    for ddof in [2, 3, 5]:
        lines += close(f"Matft.stats.cov(CV1, ddof: {ddof})", np.atleast_1d(np.cov(CV1, ddof=ddof)), mftype="Double")
    for ddof in [3, 4, 5]:
        lines += close(f"Matft.stats.cov(CV2, ddof: {ddof})", np.cov(CV2, ddof=ddof), mftype="Double")
test("cov_ddof_larger_than_n", lines)

lines = []
lines += close("Matft.stats.cov(ROW, rowvar: false)", np.atleast_1d(np.cov(ROW, rowvar=False)), mftype="Double")
lines += close("Matft.stats.cov(ROW, y: ROWY, rowvar: false)", np.cov(ROW, ROWY, rowvar=False), mftype="Double")
lines += close("Matft.stats.cov(ROW, rowvar: true)", np.atleast_1d(np.cov(ROW, rowvar=True)), mftype="Double")
lines += close("Matft.stats.corrcoef(ROW, y: ROWY, rowvar: false)", np.corrcoef(ROW, ROWY, rowvar=False), mftype="Double")
lines += close("Matft.stats.cov(CV2, rowvar: false)", np.cov(CV2, rowvar=False), mftype="Double")
test("cov_rowvar_false_single_row", lines)

# ---------- unique_* with NaN ----------
UN = inp("UN", [nan, 1.0, nan, 0.0], "Double")
UNF = inp("UNF", [[nan, 2.0, 1.0], [nan, 2.0, nan]], "Float")
lines = []
for src in ["UN", "UNF"]:
    a, mftype = INPUTS[src]
    r = np.unique_all(a)
    lines += close(f"Matft.unique_all({src}).values", r.values, mftype=mftype, rtol=0, atol=0)
    lines += equal(f"Matft.unique_all({src}).indices", r.indices, mftype="Int")
    lines += equal(f"Matft.unique_all({src}).inverse_indices", r.inverse_indices, mftype="Int")
    lines += equal(f"Matft.unique_all({src}).counts", r.counts, mftype="Int")
    c = np.unique_counts(a)
    lines += close(f"Matft.unique_counts({src}).values", c.values, mftype=mftype, rtol=0, atol=0)
    lines += equal(f"Matft.unique_counts({src}).counts", c.counts, mftype="Int")
    i = np.unique_inverse(a)
    lines += close(f"Matft.unique_inverse({src}).values", i.values, mftype=mftype, rtol=0, atol=0)
    lines += equal(f"Matft.unique_inverse({src}).inverse_indices", i.inverse_indices, mftype="Int")
    # plain unique still collapses NaN (equal_nan=True)
    lines += close(f"Matft.unique({src})", np.unique(a), mftype=mftype, rtol=0, atol=0)
test("unique_keeps_each_nan", lines)

# ---------- pinv on stacked matrices ----------
# matrix 0 is tiny and matrix 1 is huge: a cutoff over all singular values at once would zero matrix 0
P0 = np.array([[1.0, 2.0, 0.5], [0.0, 1.0, 3.0]]) * 1e-6
P1 = np.array([[4.0, -1.0, 2.0], [1.0, 3.0, 0.0]]) * 1e6
P = inp("P", np.stack([P0, P1]), "Double")
# rank-deficient members, 4-d batch
Q = inp("Q", np.array([[[1, 2], [2, 4], [0, 1]], [[3, 0], [0, 2], [1, 1]],
                       [[1, 1], [1, 1], [1, 1]], [[2, -1], [0, 5], [7, 3]]], dtype=float).reshape(2, 2, 3, 2), "Double")
QF = inp("QF", Q, "Float")
R3 = inp("R3", (np.arange(24) * 7 % 5 - 2.0).reshape(2, 3, 4), "Double")
lines = []
lines += close("try Matft.linalg.pinv(P)", np.linalg.pinv(P), mftype="Double", rtol=1e-8, atol=0)
lines += close("try Matft.linalg.pinv(P, rcond: 1e-3)", np.linalg.pinv(P, rcond=np.float32(1e-3).item()), mftype="Double", rtol=1e-8, atol=0)
lines += close("try Matft.linalg.pinv(x)", np.linalg.pinv(Q), mftype="Double", rtol=1e-8, atol=1e-10, layout="Q")
lines += close("try Matft.linalg.pinv(QF, rcond: 1e-5)", np.linalg.pinv(Q, rcond=1e-5).astype(np.float32), mftype="Float", rtol=1e-4, atol=1e-5)
lines += close("try Matft.linalg.pinv(R3)", np.linalg.pinv(R3), mftype="Double", rtol=1e-8, atol=1e-10)
lines += close("try Matft.linalg.pinv(R3, rcond: 0.5)", np.linalg.pinv(R3, rcond=0.5), mftype="Double", rtol=1e-8, atol=1e-10)
test("pinv_stacked", lines, wasi_skip=True)


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
        f.write(f"    func test_{name}() throws {{\n")
        for line in body:
            f.write("        " + line + "\n")
        f.write("    }\n")
        if wasi_skip:
            f.write("    #endif\n")
    f.write("}\n")
print("wrote", OUT, sum(len(b) for _, b, _ in TESTS), "lines")
