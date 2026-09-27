"""Generate Tests/MatftTests/EmptyCoverageTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_empty_coverage.py

Arrays with a zero-length dimension ([0], [3, 0], [0, 4], [2, 0, 3]) through creation, elementwise operations,
math functions, reductions and statistics, sort, searching and set operations.
Every case is a Swift expression and the numpy expression computing its expected value (shape, mftype and values).
Cases taking `x` (and `y`) run over `emptyVariants(shape, mftype)`: row major, column major, a zero-length slice view
of a non-empty array and a transposed view, so the results must not depend on the memory layout.

Out of bounds writes on empty arrays corrupt the heap silently: run this class under Guard Malloc when it changes
(see the test-design skill, viewpoints.md §6).

Matft conventions (not bugs, the expected values follow them):
- A reduction over all the axes returns shape [1] (numpy returns a 0-d scalar).
- sum / squaresum keep the input mftype (.Bool gives .Float); cumsum of .Bool gives .Int; mean, var, std, median,
  percentile, sumsqrt and the math functions give .Double for .Double and .Float otherwise.
- Division of Float-stored types (integers, Bool, Float) gives Float (numpy: float64 for integers).

numpy raises for these on an empty lane, so they are not generated (Matft stops with a precondition instead):
max / min / argmax / argmin / nanmax / nanmin / nanargmax / nanargmin / ufuncReduce(maximum, minimum) over a
zero-length axis or over all the axes of an empty array.
np.percentile / np.quantile raise IndexError on an empty lane, and np.nanpercentile / np.nanquantile ignore the shape of an array q
for empty input: Matft gives NaN like np.median, with the shape rule of non-empty input (see nan_lanes).
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "EmptyCoverageTest.swift")
CLASS = "EmptyCoverageTests"
DOC = ("Arrays with a zero-length dimension through creation, elementwise operations, math, reductions, statistics, "
       "sort, searching and set operations, over dtypes, axes and memory layouts (`emptyVariants`). Expected values are numpy outputs")

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


TESTS = []  # (name, [lines], wasi_skip)


def test(name, lines, wasi_skip=False):
    TESTS.append((name, lines, wasi_skip))


def variants(shape, mftype):
    """The Swift loop header over the layouts of the empty array of `shape` and `mftype`"""
    return f"emptyVariants({list(shape)}, .{mftype})"


def tol(mftype):
    if mftype in INT_TYPES or mftype == "Bool":
        return 0, 0
    return (1e-5, 1e-5) if mftype == "Float" else (1e-10, 1e-10)


def assertion(swift, expected, mftype, label):
    rtol, atol = tol(mftype)
    return f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: {rtol}, atol: {atol}, checkType: true, \"{label}\")"


def close(swift, expected, mftype=None, x=None, y=None):
    """XCTAssertClose of values, shape and mftype. `x` / `y`: (shape, mftype) of the empty inputs whose layouts are iterated
    by the `check` helpers of the test class (one line per case)"""
    mftype = mftype or mftype_of(expected)
    label = swift_escape(swift)
    rtol, atol = tol(mftype)
    exp = swift_array(expected, mftype)
    if x and y:
        return [f"check2({list(x[0])}, .{x[1]}, {list(y[0])}, .{y[1]}, {exp}, rtol: {rtol}, atol: {atol}, \"{label}\"){{ x, y in {swift} }}"]
    if x:
        return [f"check({list(x[0])}, .{x[1]}, {exp}, rtol: {rtol}, atol: {atol}, \"{label}\"){{ x in {swift} }}"]
    return [assertion(swift, expected, mftype, label)]


def zeros(shape, mftype):
    return np.zeros(shape, NP_DTYPE[mftype])


SHAPES = [(0,), (3, 0), (0, 4), (2, 0, 3)]


def axes_of(shape):
    """nil, every axis and the negative last axis"""
    return [None] + list(range(len(shape))) + [-1]


def ax_arg(axis, kd=False):
    s = "" if axis is None else f", axis: {axis}"
    if kd:
        s += ", keepDims: true"
    return s


def empty_axis(shape, axis):
    """Whether the reduction over `axis` reduces a zero-length lane (numpy raises for max / argmax there)"""
    if axis is None:
        return True
    return shape[axis] == 0


# ---------- Matft's type rules (same as gen_arithmetic_coverage.py) ----------
PRIORITY = ["Bool", "UInt8", "UInt16", "UInt32", "UInt64", "UInt", "Int8", "Int16", "Int32", "Int64", "Int", "Float", "Double"]


def array_type(a, b):
    """MfType.result_type: numpy's promotion between integer arrays, otherwise the priority"""
    if a in INT_TYPES and b in INT_TYPES:
        return mftype_of(np.empty(0, np.result_type(NP_DTYPE[a], NP_DTYPE[b])))
    return a if PRIORITY.index(a) >= PRIORITY.index(b) else b


def float_type(t):
    """.Double stays .Double, the other types (stored as Float) give .Float"""
    return "Double" if t == "Double" else "Float"


BINOPS = {"+": np.add, "-": np.subtract, "*": np.multiply, "/": np.divide}
CMPS = {">": np.greater, ">=": np.greater_equal, "<": np.less, "<=": np.less_equal, "===": np.equal, "!==": np.not_equal}
EXTREMA = {"Matft.stats.maximum": np.maximum, "Matft.stats.minimum": np.minimum}


def binary_cases(sx, tx, sy, ty, ops=None):
    """Array-array operations between empty (or broadcast) operands; x / y are iterated over their layouts when empty"""
    ops = ops or list(BINOPS) + list(CMPS) + list(EXTREMA)
    a, b = zeros(sx, tx), zeros(sy, ty)
    t = array_type(tx, ty)
    xl = (sx, tx) if a.size == 0 else None
    yl = (sy, ty) if b.size == 0 else None
    xs = "x" if xl else swift_array(np.ones(sx), tx)
    ys = "y" if yl else swift_array(np.ones(sy), ty)
    if xl is None:
        # only the right operand is empty: it is the one iterated, as `x`
        xl, yl, ys = yl, None, "x"
    lines = []
    for op in ops:
        if op in BINOPS:
            if op == "-" and t == "Bool":
                continue  # numpy: TypeError for bool - bool
            rt = float_type(t) if op == "/" else t
            exp = BINOPS[op](a.astype(NP_DTYPE[t]), b.astype(NP_DTYPE[t])).astype(NP_DTYPE[rt])
            swift = f"{xs} {op} {ys}"
        elif op in CMPS:
            rt = "Bool"
            exp = CMPS[op](a, b)
            swift = f"{xs} {op} {ys}"
        else:
            rt = t
            exp = EXTREMA[op](a.astype(NP_DTYPE[t]), b.astype(NP_DTYPE[t]))
            swift = f"{op}({xs}, {ys})"
        lines += close(swift, exp, rt, x=xl, y=yl)
    return lines


# ---------- creation ----------
lines = []
for swift_t, t in [("Double", "Double"), ("Float", "Float"), ("Int", "Int"), ("Bool", "Bool"), ("UInt8", "UInt8"), ("Int8", "Int8")]:
    # the mftype comes from the Swift element type (numpy: np.array([], dtype))
    lines += close(f"MfArray([] as [{swift_t}])", zeros((0,), t), t)
lines += close("MfArray([] as [Double], shape: [3, 0])", zeros((3, 0), "Double"))
lines += close("MfArray([] as [Double], shape: [2, 0, 3], mforder: .Column)", zeros((2, 0, 3), "Double"))
lines += close("MfArray([] as [Int], mftype: .UInt8, shape: [0, 4], mforder: .Column)", zeros((0, 4), "UInt8"))
# nested empty lists: np.array([[]]).shape -> (1, 0)
lines += close("MfArray([[]] as [[Double]])", np.array([[]], np.float64))
lines += close("MfArray([[], []] as [[Double]])", np.array([[], []], np.float64))
lines += close("MfArray([[], []] as [[Float]], mforder: .Column)", np.array([[], []], np.float32))
lines += close("MfArray([[[]], [[]]] as [[[Int]]])", np.array([[[]], [[]]], np.int64))
for shp in SHAPES:
    lines += close(f"Matft.nums(Float(1), shape: {list(shp)})", np.full(shp, 1, np.float32))
    lines += close(f"Matft.nums(2, shape: {list(shp)}, mforder: .Column)", np.full(shp, 2, np.int64))
    lines += close(f"Matft.nums(true, shape: {list(shp)})", np.full(shp, True))
    lines += close(f"Matft.nums(1.5, shape: {list(shp)}, mftype: .UInt8)", np.full(shp, 1, np.uint8))
for t in ["Double", "Int", "Bool"]:
    lines += close("Matft.nums_like(7, mfarray: x)", np.full_like(zeros((3, 0), t), 7), t, x=((3, 0), t))
# arange with an empty range: np.arange(0, 0) / np.arange(5, 0) / np.arange(0, 5, -1)
lines += close("Matft.arange(start: 0, to: 0, by: 1)", np.arange(0, 0, 1))
lines += close("Matft.arange(start: 5, to: 0, by: 1)", np.arange(5, 0, 1))
lines += close("Matft.arange(start: 0, to: 5, by: -1)", np.arange(0, 5, -1))
lines += close("Matft.arange(start: 0.0, to: 0.0, by: 0.5)", np.arange(0.0, 0.0, 0.5))
lines += close("Matft.arange(start: 0, to: 0, by: 1, shape: [0, 3])", np.arange(0, 0, 1).reshape(0, 3))
lines += close("Matft.eye(dim: 0, mftype: .Double)", np.eye(0))
# diag of an empty vector gives |k| x |k| zeros (Matft.diag doesn't extract the diagonal of a 2-D array; it requires 1-D input)
lines += close("Matft.diag(v: x)", np.diag(np.zeros(0)), "Double", x=((0,), "Double"))
lines += close("Matft.diag(v: x, k: 2)", np.diag(np.zeros(0), k=2), "Double", x=((0,), "Double"))
lines += close("Matft.diag(v: x, k: -1)", np.diag(np.zeros(0, np.int64), k=-1), "Int", x=((0,), "Int"))
test("creation", lines)

lines = []
for shp in SHAPES:
    for t in ["Double", "Float", "Int", "Bool"]:
        e = zeros(shp, t)
        lines += close("Matft.deepcopy(x)", e, t, x=(shp, t))
        lines += close("x.deepcopy(.Column)", e, t, x=(shp, t))
        lines += close("Matft.shallowcopy(x)", e, t, x=(shp, t))
test("copy", lines)

# ---------- elementwise array-array: every shape (Double), every op ----------
lines = []
for shp in SHAPES:
    lines += binary_cases(shp, "Double", shp, "Double")
test("binary_shapes", lines)

# every op over the dtypes and mixed dtypes, shape [3, 0]
lines = []
for tx, ty in [("Float", "Float"), ("Int", "Int"), ("UInt8", "UInt8"), ("Bool", "Bool"), ("Int", "Float"),
               ("UInt8", "Int8"), ("Bool", "Int"), ("Float", "Double")]:
    lines += binary_cases((3, 0), tx, (3, 0), ty, ops=["+", "-", "*", "/", ">", "===", "Matft.stats.maximum"])
test("binary_dtypes", lines)

# broadcasting with a zero-length dimension: np.ones((3, 0)) + np.ones((3, 1)) -> (3, 0), (0, 1) + (1, 5) -> (0, 5)
lines = []
for sx, sy in [((3, 0), (3, 1)), ((3, 1), (3, 0)), ((0,), (1,)), ((1,), (0,)), ((1, 4), (0, 4)), ((0, 4), (4,)),
               ((2, 0, 3), (3,)), ((2, 0, 3), (0, 1)), ((3, 0), (0,)), ((0, 1), (1, 5)), ((3, 1), (1, 0)), ((0,), (0,))]:
    lines += binary_cases(sx, "Double", sy, "Double", ops=["+", "*", "/", ">", "!==", "Matft.stats.minimum"])
lines += binary_cases((3, 0), "Int", (3, 1), "Float", ops=["-", "<="])
test("binary_broadcast", lines)

# array-scalar of the same kind (the promotion of other kinds is covered by the arithmetic tests)
lines = []
for shp in SHAPES:
    e = zeros(shp, "Double")
    lines += close("x + 1.5", e + 1.5, x=(shp, "Double"))
    lines += close("1.5 - x", 1.5 - e, x=(shp, "Double"))
    lines += close("x * 2.0", e * 2.0, x=(shp, "Double"))
    lines += close("2.0 / x", np.zeros(shp), "Double", x=(shp, "Double"))
    lines += close("x > 0.5", e > 0.5, x=(shp, "Double"))
    lines += close("0.5 === x", e == 0.5, x=(shp, "Double"))
    lines += close("-x", -e, x=(shp, "Double"))
    f = zeros(shp, "Float")
    lines += close("x * Float(2)", f * np.float32(2), x=(shp, "Float"))
    lines += close("Float(3) - x", np.float32(3) - f, x=(shp, "Float"))
    lines += close("-x", -f, x=(shp, "Float"))
    i = zeros(shp, "Int")
    lines += close("x + 1", i + 1, x=(shp, "Int"))
    lines += close("3 - x", 3 - i, x=(shp, "Int"))
    lines += close("x * 2", i * 2, x=(shp, "Int"))
    lines += close("x / 2", np.zeros(shp, np.float32), "Float", x=(shp, "Int"))
    lines += close("x <= 1", i <= 1, x=(shp, "Int"))
    lines += close("-x", -i, x=(shp, "Int"))
    for t in ["Double", "Bool"]:
        lines += close("Matft.logical_not(x)", np.logical_not(zeros(shp, t)), x=(shp, t))
test("scalar_and_unary", lines)

# ---------- math ----------
UNARY = ["sin", "asin", "sinh", "asinh", "cos", "acos", "cosh", "acosh", "tan", "atan", "tanh", "atanh", "sqrt", "rsqrt",
         "exp", "exp2", "expm1", "log1p", "log", "log2", "log10", "ceil", "floor", "trunc", "nearest", "abs", "reciprocal"]
SAME_TYPE = ["square", "sign"]
BOOL_RESULT = ["isnan", "isinf", "isfinite"]


def math_cases(shp, t, funcs):
    out = []
    for f in funcs:
        if f in SAME_TYPE:
            rt = t
        elif f in BOOL_RESULT:
            rt = "Bool"
        else:
            rt = float_type(t)
        out += close(f"Matft.math.{f}(x)", zeros(shp, rt), rt, x=(shp, t))
    return out


lines = []
for t in ["Double", "Float"]:
    lines += math_cases((3, 0), t, UNARY + SAME_TYPE + BOOL_RESULT)
    lines += close("Matft.math.round(x, decimals: 2)", zeros((3, 0), t), t, x=((3, 0), t))
test("math_unary", lines)

lines = []
for t in ["Int", "UInt8", "Bool"]:
    lines += math_cases((3, 0), t, ["sin", "sqrt", "exp", "abs", "floor", "square", "sign", "isnan", "isfinite"])
for shp in [(0,), (0, 4), (2, 0, 3)]:
    lines += math_cases(shp, "Double", ["sin", "exp", "log", "sqrt", "abs", "sign", "square", "isinf"])
    lines += math_cases(shp, "Float", ["cos", "tanh", "rsqrt", "reciprocal", "ceil", "isnan"])
# binary math with an empty operand and broadcasting
for shp in SHAPES:
    lines += close("Matft.math.power(bases: x, exponents: y)", zeros(shp, "Double"), "Double", x=(shp, "Double"), y=(shp, "Double"))
    lines += close("Matft.math.arctan2(x1: x, x2: y)", zeros(shp, "Double"), "Double", x=(shp, "Double"), y=(shp, "Double"))
lines += close(f"Matft.math.power(bases: x, exponents: {swift_array(np.ones((3, 1)), 'Float')})", zeros((3, 0), "Float"), "Float", x=((3, 0), "Float"))
lines += close(f"Matft.math.arctan2(x1: {swift_array(np.ones((1, 5)), 'Double')}, x2: x)", zeros((0, 5), "Double"), "Double", x=((0, 1), "Double"))
test("math_dtypes_shapes", lines)

# ---------- reductions ----------


def sum_expected(a, axis, kd):
    dt = np.float32 if a.dtype == np.bool_ else a.dtype
    return np.sum(a, axis=axis, keepdims=kd, dtype=dt)


lines = []
for shp in SHAPES:
    e = zeros(shp, "Double")
    for axis in axes_of(shp):
        for kd in [False, True]:
            lines += close(f"Matft.stats.sum(x{ax_arg(axis, kd)})", np.sum(e, axis=axis, keepdims=kd), x=(shp, "Double"))
            lines += close(f"Matft.stats.squaresum(x{ax_arg(axis, kd)})", np.sum(np.square(e), axis=axis, keepdims=kd), x=(shp, "Double"))
        lines += close(f"Matft.stats.sumsqrt(x{ax_arg(axis)})", np.sqrt(np.sum(e, axis=axis)), x=(shp, "Double"))
        lines += close(f"Matft.stats.cumsum(x{ax_arg(axis)})", np.cumsum(e, axis=axis), x=(shp, "Double"))
test("sum_cumsum_shapes", lines)

lines = []
for t in ["Float", "Int", "UInt8", "Bool"]:
    e = zeros((3, 0), t)
    for axis in [None, 0, 1]:
        lines += close(f"Matft.stats.sum(x{ax_arg(axis)})", sum_expected(e, axis, False), x=((3, 0), t))
        lines += close(f"Matft.stats.squaresum(x{ax_arg(axis)})", sum_expected(e, axis, False), x=((3, 0), t))
        dt = np.int64 if t == "Bool" else NP_DTYPE[t]
        lines += close(f"Matft.stats.cumsum(x{ax_arg(axis)})", np.cumsum(e, axis=axis, dtype=dt), x=((3, 0), t))
        with warnings.catch_warnings(), np.errstate(all="ignore"):
            warnings.simplefilter("ignore")
            lines += close(f"Matft.stats.mean(x{ax_arg(axis)})", np.mean(e.astype(np.float32), axis=axis), "Float", x=((3, 0), t))
test("sum_cumsum_mean_dtypes", lines)

lines = []
with warnings.catch_warnings(), np.errstate(all="ignore"):
    warnings.simplefilter("ignore")
    for shp in SHAPES:
        for t in ["Double", "Float"]:
            e = zeros(shp, t)
            for axis in axes_of(shp):
                for kd in [False, True]:
                    # numpy: the mean of an empty lane is NaN (RuntimeWarning)
                    lines += close(f"Matft.stats.mean(x{ax_arg(axis, kd)})", np.mean(e, axis=axis, keepdims=kd), x=(shp, t))
                for ddof in [0, 1]:
                    lines += close(f"Matft.stats.var(x{ax_arg(axis)}, ddof: {ddof})", np.var(e, axis=axis, ddof=ddof), x=(shp, t))
                    lines += close(f"Matft.stats.std(x{ax_arg(axis, True)}, ddof: {ddof})", np.std(e, axis=axis, keepdims=True, ddof=ddof), x=(shp, t))
test("mean_var_std", lines)

UFUNCS = [("Matft.add", np.add), ("Matft.mul", np.multiply), ("Matft.stats.maximum", np.maximum), ("Matft.stats.minimum", np.minimum)]
lines = []
for shp in SHAPES:
    for t in ["Double", "Int"]:
        e = zeros(shp, t)
        for sw, uf in UFUNCS:
            for axis in axes_of(shp):
                if uf in (np.maximum, np.minimum) and empty_axis(shp, axis):
                    continue  # numpy: ValueError (no identity)
                for kd in ([False, True] if t == "Double" else [False]):
                    red = ", axis: nil" if axis is None else f", axis: {axis}"
                    lines += close(f"Matft.ufuncReduce(mfarray: x, ufunc: {sw}{red}{', keepDims: true' if kd else ''})",
                                   uf.reduce(e, axis=axis, keepdims=kd), x=(shp, t))
                if axis is not None and t == "Double":
                    lines += close(f"Matft.ufuncAccumulate(mfarray: x, ufunc: {sw}, axis: {axis})", uf.accumulate(e, axis=axis), x=(shp, t))
test("ufunc_reduce_accumulate", lines)

# max / min / argmax / argmin over the axes that are not zero-length (the result is empty)
lines = []
for shp in SHAPES:
    for t in ["Double", "Float", "Int", "UInt8"]:
        e = zeros(shp, t)
        for axis in axes_of(shp):
            if empty_axis(shp, axis):
                continue  # numpy: ValueError
            for f in ["max", "min"]:
                for kd in [False, True]:
                    lines += close(f"Matft.stats.{f}(x{ax_arg(axis, kd)})", getattr(np, f)(e, axis=axis, keepdims=kd), x=(shp, t))
            for f in ["argmax", "argmin"]:
                lines += close(f"Matft.stats.{f}(x{ax_arg(axis)})", getattr(np, f)(e, axis=axis), "Int", x=(shp, t))
test("max_min_argmax_nonempty_axes", lines)

# ---------- order statistics and nan-functions ----------


def nan_lanes(e, axis, keepdims=False, q=None):
    """The percentile / quantile of an empty array: NaN for every (zero-length) lane, with shape [len(q)] + reduced shape for an array q.
    numpy gives this for np.median and np.nanpercentile with a scalar q, but np.percentile / np.quantile raise IndexError
    (an internal error) and np.nanpercentile / np.nanquantile ignore the shape of an array q for empty input.
    The shape rule for non-empty input applies here"""
    shape = np.sum(e, axis=axis, keepdims=keepdims).shape
    if q is not None:
        shape = (len(q),) + shape
    return np.full(shape, nan)


lines = []
with warnings.catch_warnings(), np.errstate(all="ignore"):
    warnings.simplefilter("ignore")
    for shp in SHAPES:
        e = zeros(shp, "Double")
        for axis in axes_of(shp):
            a = ax_arg(axis)
            lines += close(f"Matft.stats.median(x{a})", np.median(e, axis=axis), x=(shp, "Double"))
            lines += close(f"Matft.stats.percentile(x, q: 30{a}, keepDims: true)", nan_lanes(e, axis, keepdims=True), x=(shp, "Double"))
            lines += close(f"Matft.stats.quantile(x, q: [0.1, 0.9]{a})", nan_lanes(e, axis, q=[0.1, 0.9]), x=(shp, "Double"))
            lines += close(f"Matft.stats.percentile(x, q: 50{a}, method: .nearest)", nan_lanes(e, axis), x=(shp, "Double"))
    lines += close("Matft.stats.median(x, axis: 1)", np.median(zeros((3, 0), "Float"), axis=1), x=((3, 0), "Float"))
    lines += close("Matft.stats.median(x, axis: 0)", np.median(zeros((3, 0), "Int"), axis=0).astype(np.float32), "Float", x=((3, 0), "Int"))
test("orderstats", lines)

lines = []
with warnings.catch_warnings(), np.errstate(all="ignore"):
    warnings.simplefilter("ignore")
    for shp in SHAPES:
        e = zeros(shp, "Double")
        for axis in axes_of(shp):
            a = ax_arg(axis)
            lines += close(f"Matft.stats.nansum(x{a})", np.nansum(e, axis=axis), x=(shp, "Double"))
            lines += close(f"Matft.stats.nanmean(x{ax_arg(axis, True)})", np.nanmean(e, axis=axis, keepdims=True), x=(shp, "Double"))
            lines += close(f"Matft.stats.nanvar(x{a}, ddof: 1)", np.nanvar(e, axis=axis, ddof=1), x=(shp, "Double"))
            lines += close(f"Matft.stats.nanstd(x{a})", np.nanstd(e, axis=axis), x=(shp, "Double"))
            lines += close(f"Matft.stats.nanmedian(x{a})", np.nanmedian(e, axis=axis), x=(shp, "Double"))
            lines += close(f"Matft.stats.nanpercentile(x, q: [20, 75]{a})", nan_lanes(e, axis, q=[20, 75]), x=(shp, "Double"))
            lines += close(f"Matft.stats.nanquantile(x, q: 0.4{a})", np.nanquantile(e, 0.4, axis=axis), x=(shp, "Double"))
            if not empty_axis(shp, axis):
                for f in ["nanmax", "nanmin"]:
                    lines += close(f"Matft.stats.{f}(x{a})", getattr(np, f)(e, axis=axis), x=(shp, "Double"))
                for f in ["nanargmax", "nanargmin"]:
                    lines += close(f"Matft.stats.{f}(x{a})", getattr(np, f)(e, axis=axis), "Int", x=(shp, "Double"))
    lines += close("Matft.stats.nansum(x, axis: 1)", np.nansum(zeros((3, 0), "Float"), axis=1), x=((3, 0), "Float"))
    lines += close("Matft.stats.nansum(x)", np.nansum(zeros((3, 0), "Int")), x=((3, 0), "Int"))
test("nan_functions", lines)

# ---------- sort / argsort ----------
lines = []
for shp in SHAPES:
    for t in ["Double", "Int", "Bool"]:
        e = zeros(shp, t)
        for axis in [None, 0, -1]:
            a = "axis: nil" if axis is None else f"axis: {axis}"
            lines += close(f"x.sort({a})", np.sort(e, axis=axis), x=(shp, t))
            lines += close(f"x.argsort({a})", np.argsort(e, axis=axis), "Int", x=(shp, t))
        lines += close("x.sort(order: .Descending)", np.sort(e, axis=-1), x=(shp, t))
        lines += close("x.argsort(order: .Descending)", np.argsort(e, axis=-1), "Int", x=(shp, t))
        lines += close("Matft.sort(x)", np.sort(e), x=(shp, t))
test("sort_argsort", lines)

# ---------- searching ----------
lines = []
for shp in SHAPES:
    lines += [f"for (name, x) in {variants(shp, 'Double')}{{",
              "    let r = Matft.nonzero(x)",
              f"    XCTAssertEqual(r.count, {len(shp)}, \"nonzero \\(name)\")",
              "    for i in r{",
              f"        {assertion('i', np.nonzero(np.zeros(shp))[0], 'Int', 'nonzero \\(name)')}",
              "    }",
              f"    XCTAssertEqual(Matft.where(x).count, {len(shp)}, \"where \\(name)\")",
              "}"]
    lines += close("Matft.argwhere(x)", np.argwhere(np.zeros(shp)), "Int", x=(shp, "Double"))
    lines += close("Matft.where(x > 0, x, -x)", np.zeros(shp), "Double", x=(shp, "Double"))
    lines += close("Matft.where(x > 0, x, 2.5)", np.zeros(shp), "Double", x=(shp, "Double"))
    lines += close("Matft.digitize(x, bins: MfArray([-1, 2, 5] as [Double]))", np.digitize(np.zeros(shp), [-1, 2, 5]), "Int", x=(shp, "Double"))
# every element is zero / the condition selects nothing: empty result from a non-empty input
Z = np.zeros((2, 3))
lines += [f"XCTAssertEqual(Matft.nonzero({swift_array(Z, 'Double')}).count, 2)"]
lines += close(f"Matft.nonzero({swift_array(Z, 'Double')})[1]", np.nonzero(Z)[1], "Int")
lines += close(f"Matft.argwhere({swift_array(Z, 'Double')})", np.argwhere(Z), "Int")
lines += close(f"Matft.argwhere({swift_array(Z, 'Double')}.T)", np.argwhere(Z.T), "Int")
# where with broadcasting against an empty dimension: np.where(c[3,0], x[3,1], y[1,0]) -> (3, 0)
lines += close(f"Matft.where(x > 0, {swift_array(np.ones((3, 1)), 'Double')}, y)", np.zeros((3, 0)), "Double", x=((3, 0), "Double"), y=((1, 0), "Double"))
lines += close(f"Matft.where({swift_array(np.ones((1, 4)) > 0, 'Bool')}, x, 1.0)", np.zeros((0, 4)), "Double", x=((0, 4), "Double"))
# searchsorted into / of an empty array
lines += close("Matft.searchsorted(x, MfArray([-1, 0, 3] as [Double]))", np.searchsorted(np.zeros(0), [-1, 0, 3]), "Int", x=((0,), "Double"))
lines += close("Matft.searchsorted(x, MfArray([-1, 0, 3] as [Double]), side: .right)", np.searchsorted(np.zeros(0), [-1, 0, 3], side="right"), "Int", x=((0,), "Double"))
lines += close("Matft.searchsorted(MfArray([1, 2, 3] as [Double]), x)", np.searchsorted([1, 2, 3], np.zeros(0)), "Int", x=((0,), "Double"))
lines += close("Matft.searchsorted(MfArray([1, 2, 3] as [Double]), x)", np.searchsorted([1, 2, 3], np.zeros((3, 0))), "Int", x=((3, 0), "Double"))
# digitize with no bins: every value goes to bin 0
lines += close("Matft.digitize(MfArray([1, 2, 3] as [Double]), bins: x)", np.digitize([1, 2, 3], np.zeros(0)), "Int", x=((0,), "Double"))
lines += close("Matft.bincount(x, minlength: 2)", np.bincount(np.zeros(0, np.int64), minlength=2), "Int", x=((0,), "Int"))
lines += close("Matft.bincount(x, weights: y)", np.bincount(np.zeros(0, np.int64), weights=np.zeros(0)), "Double", x=((0,), "Int"), y=((0,), "Double"))
test("searching", lines)

# histogram of an empty array: numpy uses the range (0, 1) and gives zero counts (NaN for density)
lines = []
with warnings.catch_warnings(), np.errstate(all="ignore"):
    warnings.simplefilter("ignore")
    for shp in [(0,), (3, 0)]:
        e = np.zeros(shp)
        cases = [("bins: 3", dict(bins=3), "Int"), ("bins: 2, range: (1, 4)", dict(bins=2, range=(1, 4)), "Int"),
                 ("bins: 3, density: true", dict(bins=3, density=True), "Double"),
                 ("bins: MfArray([0, 1, 2] as [Double])", dict(bins=[0, 1, 2]), "Int")]
        for args, kw, ht in cases:
            h, edges = np.histogram(e, **kw)
            lines += [f"for (name, x) in {variants(shp, 'Double')}{{",
                      f"    let (hist, edges) = Matft.histogram(x, {args})",
                      f"    {assertion('hist', h, ht, f'histogram({args}) hist \\(name)')}",
                      f"    {assertion('edges', edges, 'Double', f'histogram({args}) edges \\(name)')}",
                      "}"]
        h, edges = np.histogram(e, bins=3, weights=e)
        lines += [f"for (name, x) in {variants(shp, 'Double')}{{",
                  "    let (hist, _) = Matft.histogram(x, bins: 3, weights: x)",
                  f"    {assertion('hist', h, 'Double', 'histogram weights \\(name)')}",
                  "}"]
test("histogram", lines)

# ---------- set operations ----------
lines = []
ONE = swift_array(np.array([3.0, 1.0, 3.0]), "Double")
for shp in SHAPES:
    for t in ["Double", "Float", "Int", "Bool"]:
        e = zeros(shp, t)
        lines += close("Matft.unique(x)", np.unique(e), x=(shp, t))
        lines += close("Matft.unique_values(x)", np.unique(e), x=(shp, t))
    e = zeros(shp, "Double")
    lines += [f"for (name, x) in {variants(shp, 'Double')}{{",
              "    let (values, counts) = Matft.unique_counts(x)",
              f"    {assertion('values', np.unique(e), 'Double', 'unique_counts values \\(name)')}",
              f"    {assertion('counts', np.unique_counts(e).counts, 'Int', 'unique_counts counts \\(name)')}",
              "    let (values2, inverse) = Matft.unique_inverse(x)",
              f"    {assertion('values2', np.unique(e), 'Double', 'unique_inverse values \\(name)')}",
              f"    {assertion('inverse', np.unique_inverse(e).inverse_indices, 'Int', 'unique_inverse inverse \\(name)')}",
              "    let all = Matft.unique_all(x)",
              f"    {assertion('all.values', np.unique(e), 'Double', 'unique_all values \\(name)')}",
              f"    {assertion('all.indices', np.unique_all(e).indices, 'Int', 'unique_all indices \\(name)')}",
              f"    {assertion('all.inverse_indices', np.unique_all(e).inverse_indices, 'Int', 'unique_all inverse \\(name)')}",
              f"    {assertion('all.counts', np.unique_all(e).counts, 'Int', 'unique_all counts \\(name)')}",
              "}"]
    lines += close(f"Matft.isin(x, {ONE})", np.isin(e, [3.0, 1.0, 3.0]), x=(shp, "Double"))
    lines += close(f"Matft.isin(x, {ONE}, invert: true)", np.isin(e, [3.0, 1.0, 3.0], invert=True), x=(shp, "Double"))
    lines += close(f"Matft.isin({ONE}, x)", np.isin([3.0, 1.0, 3.0], e), x=(shp, "Double"))
    lines += close(f"Matft.isin({ONE}, x, invert: true)", np.isin([3.0, 1.0, 3.0], e, invert=True), x=(shp, "Double"))
    lines += close(f"Matft.intersect1d(x, {ONE})", np.intersect1d(e, [3.0, 1.0, 3.0]), x=(shp, "Double"))
    lines += close(f"Matft.intersect1d({ONE}, x)", np.intersect1d([3.0, 1.0, 3.0], e), x=(shp, "Double"))
    lines += close("Matft.union1d(x, y)", np.union1d(e, e), x=(shp, "Double"), y=(shp, "Double"))
    lines += close(f"Matft.union1d({ONE}, x)", np.union1d([3.0, 1.0, 3.0], e), x=(shp, "Double"))
    lines += close(f"Matft.setdiff1d(x, {ONE})", np.setdiff1d(e, [3.0, 1.0, 3.0]), x=(shp, "Double"))
    lines += close(f"Matft.setdiff1d({ONE}, x)", np.setdiff1d([3.0, 1.0, 3.0], e), x=(shp, "Double"))
# an empty result from non-empty inputs
lines += close(f"Matft.setdiff1d({ONE}, {ONE})", np.setdiff1d([3.0, 1.0], [3.0, 1.0]))
lines += close(f"Matft.intersect1d({ONE}, MfArray([2.0, 4.0] as [Double]))", np.intersect1d([3.0, 1.0], [2.0, 4.0]))
test("setops", lines)


# ---------- write ----------
HELPER = r'''
    /// The same empty array (shape and mftype) in different memory layouts: row and column major,
    /// a zero-length slice view of a non-empty array (with an offset and the base's strides) and a transposed view
    private func emptyVariants(_ shape: [Int], _ mftype: MfType) -> [(name: String, array: MfArray)] {
        var ret: [(name: String, array: MfArray)] = [
            ("row", MfArray([] as [Double], mftype: mftype, shape: shape)),
            ("column", MfArray([] as [Double], mftype: mftype, shape: shape, mforder: .Column)),
        ]
        let axis = shape.firstIndex(of: 0)!
        var baseShape = shape
        baseShape[axis] = 3
        let base = Matft.nums(Double(1), shape: baseShape, mftype: mftype)
        ret.append(("slice view", base.swapaxes(axis1: 0, axis2: axis)[2~<2].swapaxes(axis1: 0, axis2: axis)))
        if shape.count >= 2 {
            ret.append(("transposed view", MfArray([] as [Double], mftype: mftype, shape: shape.reversed()).T))
        }
        return ret
    }

    /// Assert `f(x) == expected` (values, shape and mftype) for every layout `x` of the empty array of `shape` and `mftype`
    private func check(_ shape: [Int], _ mftype: MfType, _ expected: MfArray, rtol: Double, atol: Double, _ label: String,
                       file: StaticString = #filePath, line: UInt = #line, _ f: (MfArray) -> MfArray) {
        for (name, x) in emptyVariants(shape, mftype) {
            XCTAssertClose(f(x), expected, rtol: rtol, atol: atol, checkType: true, "\(label) \(name)", file: file, line: line)
        }
    }

    /// `check` over the layouts of both operands
    private func check2(_ xshape: [Int], _ xtype: MfType, _ yshape: [Int], _ ytype: MfType, _ expected: MfArray, rtol: Double, atol: Double,
                        _ label: String, file: StaticString = #filePath, line: UInt = #line, _ f: (MfArray, MfArray) -> MfArray) {
        for (n1, x) in emptyVariants(xshape, xtype) {
            for (n2, y) in emptyVariants(yshape, ytype) {
                XCTAssertClose(f(x, y), expected, rtol: rtol, atol: atol, checkType: true, "\(label) \(n1) \(n2)", file: file, line: line)
            }
        }
    }
'''

with open(OUT, "w") as f:
    f.write(f"// Generated by python/{os.path.basename(__file__)} (numpy {np.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write(f"/// {DOC}\n")
    f.write(f"final class {CLASS}: XCTestCase {{\n")
    f.write(HELPER)
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
