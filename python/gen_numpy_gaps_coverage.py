"""Generate Tests/MatftTests/NumpyGapsCoverageTest.swift from numpy / scipy.

Requirements: numpy (2.x), scipy

    python python/gen_numpy_gaps_coverage.py

Every case is a Swift expression and the numpy expression computing its expected value.
Cases taking `x` run over `layoutVariants(input)` (row/column major, transposed, offset, prefix, strided and reversed views),
so the expected values must not depend on the memory layout.
Matft conventions: a reduction over all the axes returns shape [1] (numpy returns a 0-d scalar).
"""
import os
import warnings

import numpy as np
import scipy.interpolate

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "NumpyGapsCoverageTest.swift")

nan = np.nan
inf = np.inf


def lit(v):
    v = float(v)
    if np.isnan(v):
        return ".nan"
    if np.isinf(v):
        return ".infinity" if v > 0 else "-.infinity"
    r = repr(v)
    return r


def swift_array(a, mftype):
    """Swift expression creating `a` as MfArray of mftype. 0-d arrays become shape [1] like Matft's reductions"""
    a = np.asarray(a)
    shape = list(a.shape) if a.ndim > 0 else [1]
    flat = a.ravel()
    if mftype == "Bool":
        values = ", ".join("true" if bool(v) else "false" for v in flat)
        return f"MfArray([{values}] as [Bool], shape: {shape})"
    if mftype in ("Int", "Int8", "UInt8", "Int16"):
        values = ", ".join(str(int(v)) for v in flat)
        return f"MfArray([{values}] as [Int], mftype: .{mftype}, shape: {shape})"
    values = ", ".join(lit(v) for v in flat)
    return f"MfArray([{values}] as [Double], mftype: .{mftype}, shape: {shape})"


# ---------- inputs (defined identically in Swift) ----------
INPUTS = {}


def inp(name, a, mftype):
    INPUTS[name] = (np.asarray(a), mftype)
    return np.asarray(a)


A = inp("A", [[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]], "Double")         # ties and negatives
AF = inp("AF", A, "Float")
AI = inp("AI", A, "Int")
AN = inp("AN", [[1, nan, 3, 4], [2, 5, nan, 1], [nan, 7, 2, 2]], "Double")  # NaN in every row
S = inp("S", [-3, -1, -1, 0, 2, 5, 5, 9], "Double")                        # sorted
C3 = inp("C3", np.arange(24).reshape(2, 3, 4) % 7 - 3, "Double")
B = inp("B", [[True, False, True], [False, False, True]], "Bool")

TESTS = []  # (name, [lines])


def test(name, lines):
    TESTS.append((name, lines))


def close(swift, expected, mftype="Double", rtol=None, atol=None, layout=None):
    """XCTAssertClose line. `layout`: the input whose layouts are iterated (the expression uses `x`)"""
    rtol = rtol if rtol is not None else (1e-5 if mftype == "Float" else 1e-10)
    atol = atol if atol is not None else (1e-5 if mftype == "Float" else 1e-10)
    exp = swift_array(expected, mftype if mftype != "Bool" else "Bool")
    if layout:
        return [f"for (name, x) in layoutVariants({layout}){{",
                f"    XCTAssertClose({swift}, {exp}, rtol: {rtol}, atol: {atol}, \"{swift_escape(swift)} \\(name)\")",
                "}"]
    return [f"XCTAssertClose({swift}, {exp}, rtol: {rtol}, atol: {atol}, \"{swift_escape(swift)}\")"]


def swift_escape(s):
    return s.replace("\\", "\\\\").replace("\"", "\\\"")


def equal(swift, expected, mftype, layout=None):
    exp = swift_array(expected, mftype)
    if layout:
        return [f"for (name, x) in layoutVariants({layout}){{",
                f"    XCTAssertEqual({swift}, {exp}, \"{swift_escape(swift)} \\(name)\")",
                "}"]
    return [f"XCTAssertEqual({swift}, {exp})"]


# ---------- orderstats ----------
lines = []
for axis in [None, 0, 1, -1]:
    ax = "" if axis is None else f", axis: {axis}"
    lines += close(f"Matft.stats.median(x{ax})", np.median(A, axis=axis), layout="A")
    lines += close(f"Matft.stats.median(x{ax})", np.median(A, axis=axis).astype(np.float32), "Float", layout="AF")
for method in ["linear", "lower", "higher", "nearest", "midpoint"]:
    for axis in [0, 1]:
        lines += close(f"Matft.stats.percentile(x, q: 30, axis: {axis}, method: .{method})", np.percentile(A, 30, axis=axis, method=method), layout="A")
lines += close("Matft.stats.quantile(x, q: [0.1, 0.9], axis: 1, keepDims: true)", np.quantile(A, [0.1, 0.9], axis=1, keepdims=True), layout="A")
lines += close("Matft.stats.percentile(x, q: [0, 100])", np.percentile(A, [0, 100]), layout="A")
# size 1
lines += close("Matft.stats.median(MfArray([7.5] as [Double]))", np.median([7.5]))
lines += close("Matft.stats.percentile(MfArray([[7.5]] as [[Double]]), q: 40, axis: 0)", np.percentile([[7.5]], 40, axis=0))
test("orderstats_layouts", lines)

lines = []
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    for axis in [None, 0, 1]:
        ax = "" if axis is None else f", axis: {axis}"
        for f in ["nansum", "nanmean", "nanmax", "nanmin", "nanmedian"]:
            lines += close(f"Matft.stats.{f}(x{ax})", getattr(np, f)(AN, axis=axis), layout="AN")
        for f in ["nanargmax", "nanargmin"]:
            lines += equal(f"Matft.stats.{f}(x{ax})", getattr(np, f)(AN, axis=axis), "Int", layout="AN")
        for ddof in [0, 1]:
            lines += close(f"Matft.stats.nanvar(x{ax}, keepDims: true, ddof: {ddof})", np.nanvar(AN, axis=axis, keepdims=True, ddof=ddof), layout="AN")
            lines += close(f"Matft.stats.nanstd(x.astype(.Float){ax}, ddof: {ddof})", np.nanstd(AN, axis=axis, ddof=ddof).astype(np.float32), "Float", layout="AN")
        lines += close(f"Matft.stats.nanpercentile(x, q: [20, 75]{ax})", np.nanpercentile(AN, [20, 75], axis=axis), layout="AN")
        lines += close(f"Matft.stats.nanquantile(x, q: 0.4{ax}, method: .nearest)", np.nanquantile(AN, 0.4, axis=axis, method="nearest"), layout="AN")
test("nan_functions_layouts", lines)

# ---------- argmax / argmin ----------
# numpy returns int64 indices for every input dtype -> Matft must return .Int. Ties and NaN: the first index wins (numpy returns the first NaN).
# Not covered (precondition / convention): an empty lane (numpy raises ValueError), integers above 2^24 stored as Float.


def arg_equal(swift, expected, layout=None):
    exp = swift_array(expected, "Int")
    label = swift_escape(swift) + (" \\(name)" if layout else "")
    # exact values and mftype (MfArray == ignores the mftype and wraps integers, e.g. UInt8 index 299 == 43)
    body = [f"XCTAssertClose({swift}, {exp}, rtol: 0, atol: 0, checkType: true, \"{label}\")"]
    if layout:
        return [f"for (name, x) in layoutVariants({layout}){{"] + ["    " + b for b in body] + ["}"]
    return body


U8 = inp("U8", [[0, 255, 7, 255], [128, 0, 0, 254]], "UInt8")                        # boundaries of UInt8 and ties
EXT = inp("EXT", [[-inf, 0.0, -0.0, inf], [-0.0, 0.0, -inf, -inf], [inf, inf, 1.0, -1.0]], "Double")  # ±inf, ±0 ties
long_row = np.full(300, 10)
long_row[280] = 0
long_row[299] = 255
L8 = inp("L8", np.stack([long_row, long_row[::-1]]), "UInt8")                        # indices above 255
long_ties = ((np.arange(1025) * 37) % 101 - 50).astype(float)                          # the max / min repeat, longer than the SIMD blocks
LT = inp("LT", np.stack([long_ties, long_ties[::-1]]), "Double")
long_nan = np.arange(1025, dtype=float)
long_nan[500] = nan
long_nan[700] = nan
LN = inp("LN", np.stack([long_nan, -long_nan]), "Double")                              # NaN far from the start of the lane

lines = []
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    for f in ["argmax", "argmin"]:
        for src in ["A", "AF", "AI", "U8", "B", "EXT", "AN", "L8", "LT", "LN"]:
            a, mftype = INPUTS[src]
            if mftype == "Bool":
                a = a.astype(bool)
            axes = [None, 0, 1, -1] if a.ndim == 2 else [None]
            for axis in axes:
                ax = "" if axis is None else f", axis: {axis}"
                lines += arg_equal(f"Matft.stats.{f}(x{ax})", getattr(np, f)(a, axis=axis), layout=src)
        for src in ["LT", "LN"]:
            a, _ = INPUTS[src]
            lines += arg_equal(f"Matft.stats.{f}(x.astype(.Float), axis: 1)", getattr(np, f)(a.astype(np.float32), axis=1), layout=src)
        # 3-d, every axis
        for axis in [None, 0, 1, 2, -1, -2, -3]:
            ax = "" if axis is None else f", axis: {axis}"
            lines += arg_equal(f"Matft.stats.{f}(x{ax})", getattr(np, f)(C3, axis=axis), layout="C3")
        # 1-d with an axis: numpy returns a 0-d scalar -> shape [1] in Matft
        for axis in [None, 0, -1]:
            ax = "" if axis is None else f", axis: {axis}"
            lines += arg_equal(f"Matft.stats.{f}(x{ax})", getattr(np, f)(S, axis=axis), layout="S")
        # method version
        lines += arg_equal(f"x.{f}(axis: 0)", getattr(np, f)(A, axis=0), layout="A")
        # size 1
        lines += arg_equal(f"Matft.stats.{f}(MfArray([[7.5]] as [[Double]]), axis: 1)", getattr(np, f)([[7.5]], axis=1))
        # zero-length dimension that is not reduced
        for shp, axis in [((0, 3), 1), ((2, 0, 3), 2), ((2, 0, 3), -1)]:
            res = getattr(np, f)(np.zeros(shp), axis=axis)
            swift = f"Matft.stats.{f}(MfArray([] as [Double], shape: {list(shp)}), axis: {axis})"
            lines += [f"XCTAssertEqual(({swift}).shape, {list(res.shape)}, \"{swift_escape(swift)}\")",
                      f"XCTAssertEqual(({swift}).mftype, .Int, \"{swift_escape(swift)}\")"]
test("argmax_argmin", lines)

# ---------- max / min with NaN ----------
# numpy propagates NaN along every axis (vDSP drops it for strided lanes and on x86_64)
AN1 = inp("AN1", [[1, 2, 3, 4], [5, nan, 7, 8], [9, 10, 11, 12]], "Double")  # one NaN: only row 1 / column 1 become NaN
C3N = C3.astype(float)
C3N[1, 2, 3] = nan
inp("C3N", C3N, "Double")
for pos in [0, 1024]:  # NaN at the first / last element of a lane longer than the SIMD blocks
    v = np.arange(1025, dtype=float).reshape(1025, 1)
    v[pos, 0] = nan
    inp(f"LNaN{pos}", v, "Double")
lines = []
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    for f in ["max", "min"]:
        for src in ["AN", "AN1"]:
            a, _ = INPUTS[src]
            for axis in [None, 0, 1, -1]:
                ax = "" if axis is None else f", axis: {axis}"
                lines += close(f"Matft.stats.{f}(x{ax})", getattr(np, f)(a, axis=axis), layout=src)
                lines += close(f"Matft.stats.{f}(x.astype(.Float){ax}, keepDims: true)", getattr(np, f)(a.astype(np.float32), axis=axis, keepdims=True), "Float", layout=src)
        for axis in [None, 0, 1, 2]:
            ax = "" if axis is None else f", axis: {axis}"
            lines += close(f"Matft.stats.{f}(x{ax})", getattr(np, f)(C3N, axis=axis), layout="C3N")
        for pos in [0, 1024]:
            a, _ = INPUTS[f"LNaN{pos}"]
            for axis in [None, 0]:
                ax = "" if axis is None else f", axis: {axis}"
                lines += close(f"Matft.stats.{f}(LNaN{pos}{ax})", getattr(np, f)(a, axis=axis))
                lines += close(f"Matft.stats.{f}(LNaN{pos}.T{ax.replace('0', '1')})", getattr(np, f)(a.T, axis=None if axis is None else 1))
test("max_min_nan", lines)

# ---------- var / std ----------
lines = []
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    for axis in [None, 0, 1]:
        ax = "" if axis is None else f", axis: {axis}"
        for ddof in [0, 1]:
            lines += close(f"Matft.stats.var(x{ax}, ddof: {ddof})", np.var(A, axis=axis, ddof=ddof), layout="A")
            lines += close(f"Matft.stats.std(x{ax}, ddof: {ddof})", np.std(A, axis=axis, ddof=ddof).astype(np.float32), "Float", layout="AF")
            lines += close(f"Matft.stats.std(x{ax}, keepDims: true, ddof: {ddof})", np.std(A, axis=axis, keepdims=True, ddof=ddof), layout="AI", rtol=1e-6, atol=1e-6)
    # ddof >= N: numpy divides by max(N - ddof, 0) -> inf or nan
    lines += close("Matft.stats.var(MfArray([1.0, 2.0] as [Double]), ddof: 2)", np.var([1.0, 2.0], ddof=2))
    lines += close("Matft.stats.var(MfArray([1.0, 2.0] as [Double]), ddof: 3)", np.var([1.0, 2.0], ddof=3))
    lines += close("Matft.stats.std(MfArray([[1.0, 2.0], [3.0, 3.0]] as [[Double]]), axis: 1, ddof: 2)", np.std([[1.0, 2.0], [3.0, 3.0]], axis=1, ddof=2))
test("var_std", lines)

# ---------- searching ----------
lines = []
cond = A > 2
lines += close("Matft.where(x > 2, x, -x)", np.where(cond, A, -A), layout="A")
lines += close("Matft.where(x > 2, x, MfArray([0.5, -0.5, 1.5, -1.5] as [Double]))", np.where(cond, A, [0.5, -0.5, 1.5, -1.5]), layout="A")
lines += close("Matft.where(x > 2, 100.0, x)", np.where(cond, 100.0, A), layout="A")
lines += close("Matft.where(x > 2, x, 0.25)", np.where(cond, A, 0.25), layout="A")
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    lines += close("Matft.where(x > 2, x, MfArray([.nan] as [Double]))", np.where(AN > 2, AN, nan), layout="AN")
v = np.array([-5, -1, 0.5, 5, 10])
for side in ["left", "right"]:
    lines += equal(f"Matft.searchsorted(x, MfArray([-5, -1, 0.5, 5, 10] as [Double]), side: .{side})", np.searchsorted(S, v, side=side), "Int", layout="S")
lines += equal("Matft.searchsorted(MfArray([-5, -1, 0.5, 5, 10] as [Double]), x)", np.searchsorted(v, S), "Int", layout="S")
lines += equal("Matft.digitize(x, bins: MfArray([-1, 2, 5] as [Double]))", np.digitize(A, [-1, 2, 5]), "Int", layout="A")
lines += equal("Matft.digitize(x, bins: MfArray([-1, 2, 5] as [Double]), right: true)", np.digitize(A, [-1, 2, 5], right=True), "Int", layout="A")
h, e = np.histogram(A, bins=4)
lines += ["do {", "    for (name, x) in layoutVariants(A){", "        let (hist, edges) = Matft.histogram(x, bins: 4)",
          f"        XCTAssertEqual(hist, {swift_array(h, 'Int')}, name)",
          f"        XCTAssertClose(edges, {swift_array(e, 'Double')}, rtol: 1e-12, atol: 1e-12, name)", "    }", "}"]
# all the values are equal: numpy uses [v - 0.5, v + 0.5]
h, e = np.histogram([5.0, 5.0, 5.0], bins=4)
lines += ["do {", "    let (hist, edges) = Matft.histogram(MfArray([5.0, 5.0, 5.0] as [Double]), bins: 4)",
          f"    XCTAssertEqual(hist, {swift_array(h, 'Int')})",
          f"    XCTAssertClose(edges, {swift_array(e, 'Double')}, rtol: 1e-12)", "}"]
# with a range, the values outside are ignored
h, e = np.histogram(A, bins=3, range=(0, 6))
lines += ["do {", "    let (hist, edges) = Matft.histogram(A, bins: 3, range: (0, 6))",
          f"    XCTAssertEqual(hist, {swift_array(h, 'Int')})",
          f"    XCTAssertClose(edges, {swift_array(e, 'Double')}, rtol: 1e-12)", "}"]
lines += equal("Matft.bincount(MfArray([] as [Int], shape: [0]))", np.bincount(np.array([], dtype=int)), "Int")
lines += equal("Matft.bincount(MfArray([] as [Int], shape: [0]), minlength: 3)", np.bincount(np.array([], dtype=int), minlength=3), "Int")
lines += equal("Matft.bincount(MfArray([3, 1, 1, 0, 3, 3] as [Int])[Matft.reverse])", np.bincount([3, 1, 1, 0, 3, 3][::-1]), "Int")
test("searching", lines)

# ---------- setops ----------
lines = []
lines += close("Matft.unique(x)", np.unique(A), layout="A")
lines += close("Matft.unique(x)", np.unique(A).astype(np.float32), "Float", layout="AF")
lines += equal("Matft.unique(x)", np.unique(A.astype(int)), "Int", layout="AI")
lines += equal("Matft.unique(x)", np.unique(np.array([[True, False, True], [False, False, True]])), "Bool", layout="B")
vals, counts = np.unique(A, return_counts=True)
lines += ["for (name, x) in layoutVariants(A){", "    let (values, counts) = Matft.unique_counts(x)",
          f"    XCTAssertClose(values, {swift_array(vals, 'Double')}, rtol: 1e-12, name)",
          f"    XCTAssertEqual(counts, {swift_array(counts, 'Int')}, name)", "}"]
vals, inv = np.unique(A, return_inverse=True)
lines += ["for (name, x) in layoutVariants(A){", "    let (_, inverse) = Matft.unique_inverse(x)",
          f"    XCTAssertEqual(inverse, {swift_array(inv.reshape(A.shape), 'Int')}, name)", "}"]
lines += equal("Matft.isin(x, MfArray([5, -1, 100] as [Double]))", np.isin(A, [5, -1, 100]), "Bool", layout="A")
lines += equal("Matft.isin(x, MfArray([5, -1, 100] as [Double]), invert: true)", np.isin(A, [5, -1, 100], invert=True), "Bool", layout="A")
lines += close("Matft.intersect1d(x, MfArray([9, 5, 0, 3] as [Double]))", np.intersect1d(A, [9, 5, 0, 3]), layout="A")
lines += close("Matft.union1d(x, MfArray([10, 0] as [Double]))", np.union1d(A, [10, 0]), layout="A")
lines += close("Matft.setdiff1d(x, MfArray([5, 3, 100] as [Double]))", np.setdiff1d(A, [5, 3, 100]), layout="A")
# empty
empty = "MfArray([] as [Double], shape: [0])"
lines += [f"XCTAssertEqual(Matft.unique({empty}).shape, [0])",
          f"XCTAssertEqual(Matft.isin({empty}, MfArray([1.0] as [Double])).shape, [0])",
          f"XCTAssertEqual(Matft.intersect1d({empty}, MfArray([1.0] as [Double])).shape, [0])",
          f"XCTAssertEqual(Matft.setdiff1d(MfArray([1.0] as [Double]), MfArray([1.0] as [Double])).shape, [0])"]
lines += close(f"Matft.union1d({empty}, MfArray([2.0, 1.0] as [Double]))", np.union1d([], [2.0, 1.0]))
test("setops", lines)

# ---------- manipulation ----------
lines = []
for mode in ["constant", "edge", "reflect", "symmetric", "wrap"]:
    lines += close(f"Matft.pad(x, pad_width: [(1, 2), (0, 1), (2, 0)], mode: .{mode})", np.pad(C3, [(1, 2), (0, 1), (2, 0)], mode=mode), layout="C3")
lines += close("Matft.pad(x, pad_width: 2, constant_values: -7)", np.pad(A, 2, constant_values=-7).astype(np.float32), "Float", layout="AF")
lines += equal("Matft.pad(x, pad_width: [(1, 0), (0, 2)], mode: .edge)", np.pad(np.array([[True, False, True], [False, False, True]]), [(1, 0), (0, 2)], mode="edge"), "Bool", layout="B")
# wider than the array
lines += close("Matft.pad(x, pad_width: [(4, 5), (5, 0)], mode: .reflect)", np.pad(A, [(4, 5), (5, 0)], mode="reflect"), layout="A")
lines += close("Matft.pad(x, pad_width: [(4, 5), (5, 0)], mode: .wrap)", np.pad(A, [(4, 5), (5, 0)], mode="wrap"), layout="A")
for n, axis in [(1, -1), (2, -1), (1, 0), (0, 1), (3, 1), (4, 1), (5, 1)]:
    lines += close(f"Matft.diff(x, n: {n}, axis: {axis})", np.diff(A, n=n, axis=axis), layout="A")
    lines += close(f"Matft.diff(x, n: {n}, axis: {axis})", np.diff(A, n=n, axis=axis).astype(np.float32), "Float", layout="AF")
xs, ys, zs = np.meshgrid([1, 2], [3, 4, 5], [6.5], indexing="ij")
lines += ["do {", "    let grids = Matft.meshgrid([MfArray([1, 2] as [Double]), MfArray([3, 4, 5] as [Double]), MfArray([6.5] as [Double])], indexing: .ij)",
          "    XCTAssertEqual(grids.count, 3)",
          f"    XCTAssertClose(grids[0], {swift_array(xs, 'Double')})",
          f"    XCTAssertClose(grids[1], {swift_array(ys, 'Double')})",
          f"    XCTAssertClose(grids[2], {swift_array(zs, 'Double')})", "}"]
xs, ys = np.meshgrid(np.array([1, 2, 3.0])[::-1], np.array([4.0, 5.0]))
lines += ["do {", "    let grids = Matft.meshgrid(MfArray([1, 2, 3] as [Double])[Matft.reverse], MfArray([4, 5] as [Double]))",
          f"    XCTAssertClose(grids[0], {swift_array(xs, 'Double')})",
          f"    XCTAssertClose(grids[1], {swift_array(ys, 'Double')})", "}"]
test("manipulation", lines)

# ---------- fit ----------
lines = []
M = np.array([[1.0, 2.0], [1.0, 3.0], [1.0, 5.0], [1.0, 7.0]])
y = np.array([2.0, 2.5, 5.1, 6.9])
inp("M", M, "Double")
x_, res, rank, sv = np.linalg.lstsq(M, y, rcond=None)
lines += ["for (name, x) in layoutVariants(M){", "    let ret = try Matft.linalg.lstsq(x, MfArray([2.0, 2.5, 5.1, 6.9] as [Double]))",
          f"    XCTAssertClose(ret.x, {swift_array(x_, 'Double')}, rtol: 1e-10, atol: 1e-10, name)",
          f"    XCTAssertClose(ret.residuals, {swift_array(res, 'Double')}, rtol: 1e-8, atol: 1e-10, name)",
          f"    XCTAssertEqual(ret.rank, {rank}, name)",
          f"    XCTAssertClose(ret.s, {swift_array(sv, 'Double')}, rtol: 1e-10, name)", "}"]
lines += ["do {", "    let ret = try Matft.linalg.lstsq(M.astype(.Float), MfArray([2.0, 2.5, 5.1, 6.9] as [Float]))",
          f"    XCTAssertClose(ret.x, {swift_array(x_.astype(np.float32), 'Float')}, rtol: 1e-4, atol: 1e-4)", "}"]
p = np.polyfit([0.0, 1.0, 2.0, 4.0, 5.0], [1.0, 1.8, 4.2, 15.9, 26.1], 2)
lines += ["do {", "    let xs = MfArray([5.0, 4.0, 2.0, 1.0, 0.0] as [Double])[Matft.reverse]", "    let ys = MfArray([26.1, 15.9, 4.2, 1.8, 1.0] as [Double])[Matft.reverse]",
          "    let p = try Matft.polyfit(xs, ys, deg: 2)",
          f"    XCTAssertClose(p, {swift_array(p, 'Double')}, rtol: 1e-9, atol: 1e-10)",
          f"    XCTAssertClose(try Matft.polyfit(xs.astype(.Float), ys.astype(.Float), deg: 2), {swift_array(p.astype(np.float32), 'Float')}, rtol: 1e-4, atol: 1e-4)", "}"]
lines += close("Matft.polyval(MfArray([2.0, -1.0, 0.5] as [Double])[Matft.reverse], x)", np.polyval([0.5, -1.0, 2.0], A), layout="A")
lines += close("Matft.polyval(MfArray([2, -1, 1] as [Int]), x)", np.polyval([2, -1, 1], A).astype(np.float32), "Float", layout="AF")
lines += [f"XCTAssertEqual(try Matft.linalg.matrix_rank(MfArray([0, 3, 0] as [Int])), {np.linalg.matrix_rank(np.array([0, 3, 0]))})",
          f"XCTAssertEqual(try Matft.linalg.matrix_rank(MfArray([0, 0] as [Float])), {np.linalg.matrix_rank(np.array([0.0, 0.0]))})",
          f"XCTAssertEqual(try Matft.linalg.matrix_rank(MfArray([[1, 2], [2, 4]] as [[Int]]).T), {np.linalg.matrix_rank(np.array([[1, 2], [2, 4]]))})"]
lines += close("Matft.stats.cov(x)", np.cov(A), layout="A", rtol=1e-9)
lines += close("Matft.stats.cov(x, rowvar: false)", np.cov(A, rowvar=False), layout="A", rtol=1e-9)
lines += close("Matft.stats.cov(x, y: MfArray([[1, 0, 2, 5]] as [[Double]]), bias: true)", np.cov(A, y=[[1, 0, 2, 5]], bias=True), layout="A", rtol=1e-9)
lines += close("Matft.stats.cov(x, y: MfArray([[1, 0], [4, 4], [0, 1]] as [[Double]]), rowvar: false)", np.cov(A, y=[[1, 0], [4, 4], [0, 1]], rowvar=False), layout="A", rtol=1e-9)
lines += close("Matft.stats.corrcoef(x)", np.corrcoef(A), layout="A", rtol=1e-9)
lines += close("Matft.stats.corrcoef(x, rowvar: false)", np.corrcoef(A, rowvar=False).astype(np.float32), "Float", layout="AF", rtol=1e-4, atol=1e-5)
test("fit", lines)

# ---------- interpolation ----------
lines = []
xp = np.array([0.0, 1.0, 2.5, 4.0])
fp = np.array([1.0, -1.0, 3.0, 2.0])
newx = np.array([-1.0, 0.0, 0.5, 2.0, 2.5, 3.9, 5.0])
inp("NEWX", newx, "Double")
lines += close("Matft.interp(x, xp: MfArray([0.0, 1.0, 2.5, 4.0] as [Double]), fp: MfArray([1.0, -1.0, 3.0, 2.0] as [Double]))", np.interp(newx, xp, fp).astype(np.float32), "Float", layout="NEWX")
lines += close("Matft.interp(x, xp: MfArray([0.0, 1.0, 2.5, 4.0] as [Double])[Matft.reverse][Matft.reverse], fp: MfArray([1.0, -1.0, 3.0, 2.0] as [Double]), left: -9, right: 9)", np.interp(newx, xp, fp, left=-9, right=9).astype(np.float32), "Float", layout="NEWX")
inside = np.array([0.0, 0.5, 1.2, 2.5, 3.9, 4.0])
order = [2, 0, 3, 1]
for kind in ["linear", "nearest", "previous", "next"]:
    f = scipy.interpolate.interp1d(xp, fp, kind=kind)
    lines += close(f"Matft.interp1d.{kind}(x: MfArray({[float(xp[i]) for i in order]} as [Double]), y: MfArray({[float(fp[i]) for i in order]} as [Double]), assume_sorted: false).interpolate(MfArray({[float(v) for v in inside]} as [Double]))",
                   f(inside).astype(np.float32), "Float")
test("interpolation", lines)

# ---------- math / preop ----------
lines = []
lines += equal("Matft.math.isnan(x)", np.isnan(AN), "Bool", layout="AN")
with np.errstate(divide="ignore", invalid="ignore"):
    Z = np.array([[1.0, -inf, 0.0], [inf, nan, -2.0]])
inp("Z", Z, "Double")
lines += equal("Matft.math.isnan(x)", np.isnan(Z), "Bool", layout="Z")
lines += equal("Matft.math.isinf(x)", np.isinf(Z), "Bool", layout="Z")
lines += equal("Matft.math.isfinite(x)", np.isfinite(Z), "Bool", layout="Z")
lines += equal("Matft.math.isnan(x)", np.isnan(A), "Bool", layout="AI")
lines += equal("Matft.math.isfinite(x)", np.isfinite(A), "Bool", layout="AI")
lines += close("Matft.math.power(bases: x, exponents: 3)", np.power(A, 3), layout="A")
lines += close("Matft.math.power(bases: Matft.math.abs(x), exponents: 0.5)", np.power(np.abs(A), 0.5).astype(np.float32), "Float", layout="AF")
lines += close("Matft.math.power(bases: x, exponents: 2)", np.power(A, 2).astype(np.float32), "Float", layout="AI")
for f in ["exp2", "expm1", "log1p", "square"]:
    arg = "x / 4" if f != "log1p" else "Matft.math.abs(x) / 4"
    ref = getattr(np, f)(A / 4 if f != "log1p" else np.abs(A) / 4)
    lines += close(f"Matft.math.{f}({arg})", ref, layout="A", rtol=1e-12, atol=1e-12)
    lines += close(f"Matft.math.{f}({arg})", ref.astype(np.float32), "Float", layout="AF", rtol=1e-6, atol=1e-6)
lines += equal("Matft.logical_not(x)", np.logical_not(np.array([[True, False, True], [False, False, True]])), "Bool", layout="B")
test("math", lines)


# ---------- write ----------
def swift_input(name):
    a, mftype = INPUTS[name]
    return f"    private let {name} = {swift_array(a, mftype)}"


with open(OUT, "w") as f:
    f.write("// Generated by python/gen_numpy_gaps_coverage.py (numpy {}). Do not edit by hand.\n".format(np.__version__))
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write("/// NumPy functions over dtypes, memory layouts (`layoutVariants`) and edge cases. Expected values are numpy / scipy outputs\n")
    f.write("final class NumpyGapsCoverageTests: XCTestCase {\n")
    for name in INPUTS:
        f.write(swift_input(name) + "\n")
    for name, lines in TESTS:
        wasi_skip = name in ("fit", "interpolation")
        f.write("\n")
        if wasi_skip:
            f.write("    #if !os(WASI) // LAPACK / interp1d are not available on WASI\n")
        throws = " throws" if name == "fit" else ""
        f.write(f"    func test_{name}(){throws} {{\n")
        for line in lines:
            f.write("        " + line + "\n")
        f.write("    }\n")
        if wasi_skip:
            f.write("    #endif\n")
    f.write("}\n")
print("wrote", OUT, sum(len(l) for _, l in TESTS), "lines")
