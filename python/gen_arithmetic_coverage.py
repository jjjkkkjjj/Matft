"""Generate Tests/MatftTests/ArithmeticCoverageTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_arithmetic_coverage.py

Every case is a Swift expression and the numpy expression computing its expected value.
Cases taking `x` run over `layoutVariants(input)` (row/column major, transposed, offset, prefix, strided and reversed views),
so the expected values must not depend on the memory layout.
Matft conventions (not bugs, the expected values follow them):
- Array-array integer promotion follows np.result_type; otherwise the higher `MfType.priority` wins, so
  Int + Float -> Float (numpy: float64).
- A Swift scalar is a NEP 50 "weak" Python scalar (UInt8 array + 1 -> UInt8, Float array * 2.5 -> Float), except that
  an integer / Bool array with a fractional scalar gives Float (numpy: float64) and an out of range integer scalar
  wraps (UInt8 array + 300 -> UInt8; numpy raises OverflowError).
- Division of Float-stored types (integers, Bool, Float) gives Float (numpy: float64 for integers).
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "ArithmeticCoverageTest.swift")
CLASS = "ArithmeticCoverageTests"
DOC = "Arithmetic (+ - * /), comparison, logical_not, negation and maximum/minimum over dtypes, memory layouts (`layoutVariants`) and edge cases. Expected values are numpy outputs"

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
    TESTS.append((name, _merge_loops(lines), wasi_skip))


def _merge_loops(lines):
    """Put consecutive assertions over the same layout loop(s) into one loop"""
    blocks = []  # [headers, body] or a plain line
    i = 0
    while i < len(lines):
        depth = 0
        while i + depth < len(lines) and lines[i + depth].lstrip().startswith("for ("):
            depth += 1
        if depth == 0:
            blocks.append(lines[i])
            i += 1
            continue
        headers = [l.strip() for l in lines[i:i + depth]]
        body = lines[i + depth].strip()
        i += 2 * depth + 1
        if blocks and isinstance(blocks[-1], list) and blocks[-1][0] == headers:
            blocks[-1][1].append(body)
        else:
            blocks.append([headers, [body]])
    out = []
    for b in blocks:
        if isinstance(b, str):
            out.append(b)
            continue
        headers, body = b
        out += ["    " * d + h for d, h in enumerate(headers)]
        out += ["    " * len(headers) + l for l in body]
        out += ["    " * d + "}" for d in reversed(range(len(headers)))]
    return out


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


# ---------- Matft's type rules ----------
PRIORITY = ["Bool", "UInt8", "UInt16", "UInt32", "UInt64", "UInt", "Int8", "Int16", "Int32", "Int64", "Int", "Float", "Double"]


def priority(a, b):
    return a if PRIORITY.index(a) >= PRIORITY.index(b) else b


def array_type(a, b):
    """MfType.result_type: numpy's promotion between integer arrays, otherwise the priority"""
    if a in INT_TYPES and b in INT_TYPES:
        return mftype_of(np.empty(0, np.result_type(NP_DTYPE[a], NP_DTYPE[b])))
    return priority(a, b)


def div_type(t):
    """Division of Float-stored types gives Float, Double stays Double"""
    return "Double" if t == "Double" else "Float"


def as_np(a, t):
    return np.asarray(a).astype(NP_DTYPE[t])


def close2(swift, expected, mftype=None, lx="A", ly="B", rtol=None, atol=None):
    """XCTAssertClose over layoutVariants of both operands (`x` and `y`)"""
    mftype = mftype or mftype_of(expected)
    rtol = rtol if rtol is not None else (1e-5 if mftype == "Float" else 1e-10)
    atol = atol if atol is not None else (1e-5 if mftype == "Float" else 1e-10)
    if mftype in INT_TYPES or mftype == "Bool":
        rtol, atol = 0, 0
    label = swift_escape(swift) + " \\(n1) \\(n2)"
    return [f"for (n1, x) in layoutVariants({lx}){{",
            f"    for (n2, y) in layoutVariants({ly}){{",
            f"        XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: {rtol}, atol: {atol}, checkType: true, \"{label}\")",
            "    }", "}"]


OPS = {"+": ("add", np.add), "-": ("sub", np.subtract), "*": ("mul", np.multiply), "/": ("div", np.divide)}
CMPS = {">": ("greater", np.greater), ">=": ("greater_equal", np.greater_equal), "<": ("less", np.less),
        "<=": ("less_equal", np.less_equal), "===": ("equal", np.equal), "!==": ("not_equal", np.not_equal)}


def binop(op, a, ta, b, tb):
    """(expected, mftype) of the array-array operation in Matft's type rules, computed by numpy in that type"""
    t = array_type(ta, tb)
    with np.errstate(all="ignore"):
        if op == "/":
            rt = div_type(t)
            return np.divide(as_np(a, t).astype(NP_DTYPE[rt]), as_np(b, t).astype(NP_DTYPE[rt])), rt
        return OPS[op][1](as_np(a, t), as_np(b, t)), t


def fl(v, t):
    """Swift scalar literal of type t"""
    v = float(v)
    if np.isnan(v):
        return f"{t}.nan"
    if np.isinf(v):
        return f"{t}.infinity" if v > 0 else f"-{t}.infinity"
    return repr(v) if t == "Double" else f"Float({v!r})"


# ---------- inputs ----------
# 3x4 (non-square), negatives, zero, ties; B has no zero so that every division is finite
BASE_A = [[3, -1, 0, 1], [5, 9, -2, 6], [5, -3, 5, 8]]
BASE_B = [[2, 4, -1, 1], [5, -9, 3, 2], [1, 7, 5, -8]]
for t, suffix in [("Double", ""), ("Float", "F"), ("Int", "I"), ("Int8", "I8"), ("Int16", "I16")]:
    inp("A" + suffix, BASE_A, t)
    inp("B" + suffix, BASE_B, t)
# boundaries of the small integer types so that + - * wrap
inp("U8A", [[0, 1, 127, 255], [128, 254, 255, 3], [2, 200, 16, 100]], "UInt8")
inp("U8B", [[255, 1, 128, 1], [128, 2, 255, 0], [3, 100, 16, 200]], "UInt8")
inp("U16A", [[0, 1, 65535, 300], [40000, 2, 65534, 3], [256, 1000, 7, 65000]], "UInt16")
inp("U16B", [[1, 65535, 1, 300], [30000, 65535, 2, 5], [256, 70, 9, 1000]], "UInt16")
inp("I8E", [[-128, -1, 0, 127], [1, 126, -127, 64], [100, -100, 2, -64]], "Int8")
inp("I8F", [[-1, -128, 127, 1], [127, 2, -2, 64], [100, 100, -3, -65]], "Int8")
inp("BA", [[True, False, True, False], [True, True, False, False], [False, True, True, True]], "Bool")
inp("BB", [[True, True, False, False], [False, True, False, True], [True, True, False, True]], "Bool")
# broadcasting operands
inp("COL", [[2], [-3], [0.5]], "Double")
inp("ROW", [[1, -2, 4, 0.25]], "Double")
inp("VEC", [0.5, -1, 2, 3], "Double")
inp("A3", np.arange(24).reshape(2, 3, 4) - 11, "Double")
inp("A3NZ", np.arange(24).reshape(2, 3, 4) - 11.5, "Double")
inp("COLI", [[2], [-3], [7]], "Int")
# positive values (for power with fractional exponents) including 0.1, which is not exact in Float
POS = [[0.1, 0.5, 2.0], [3.0, 10.0, 0.25]]
inp("P", POS, "Double")
inp("PF", POS, "Float")
inp("PI", [[1, 2, 3], [4, 10, 7]], "Int")
# special floating values; with the second operand they hit inf-inf, 0*inf, 0/0, x/±0 and NaN in every row
SP = [[nan, inf, -inf, 0.0, -0.0, 1.0], [-1.0, inf, 2.0, -0.0, nan, -inf]]
SQ = [[1.0, inf, inf, 0.0, 0.0, -0.0], [0.0, -inf, nan, -0.0, 3.0, -inf]]
inp("SP", SP, "Double")
inp("SQ", SQ, "Double")
inp("SPF", SP, "Float")
inp("SQF", SQ, "Float")
# values on, just below and just above a threshold
inp("T", [[1.0, np.nextafter(1.0, 0), np.nextafter(1.0, 2)], [-0.0, 0.0, 5e-324]], "Double")

# ---------- arithmetic: same shape, per dtype, both operands over the layouts ----------
for suffix in ["", "F", "I", "I8"]:
    lines = []
    a, ta = INPUTS["A" + suffix]
    b, tb = INPUTS["B" + suffix]
    for op, (fname, _) in OPS.items():
        e, t = binop(op, a, ta, b, tb)
        lines += close2(f"x {op} y", e, t, "A" + suffix, "B" + suffix)
        e, t = binop(op, b, tb, a, ta) if op != "/" else binop(op, a, ta, b, tb)
        args = "y, x" if op != "/" else "x, y"
        lines += close2(f"Matft.{fname}({args})", e, t, "A" + suffix, "B" + suffix)
    # self aliasing
    for op in ["+", "-", "*"]:
        e, t = binop(op, a, ta, a, ta)
        lines += close(f"x {op} x", e, t, layout="A" + suffix)
    lines += close("x.T * x.T", binop("*", a.T, ta, a.T, ta)[0], ta, layout="A" + suffix)
    test(f"arithmetic_{ta}_layouts", lines)

# ---------- integer wraparound at the type boundaries (numpy's fixed-width ints) ----------
lines = []
for x, y in [("U8A", "U8B"), ("U16A", "U16B"), ("I8E", "I8F")]:
    a, ta = INPUTS[x]
    b, tb = INPUTS[y]
    for op in ["+", "-", "*"]:
        e, t = binop(op, a, ta, b, tb)
        lines += close2(f"x {op} y", e, t, x, y)
test("arithmetic_integer_wrap", lines)

# ---------- mixed dtypes (array-array) ----------
lines = []
MIXED = [("AI", "BF"), ("BF", "AI"), ("AF", "B"), ("AI", "B"), ("U8A", "I8F"), ("I8F", "U8A"), ("U8A", "AI"),
         ("U16A", "I8F"), ("U8A", "BI16"), ("BA", "AI"), ("BA", "BF"), ("AI8", "BI16")]
for x, y in MIXED:
    a, ta = INPUTS[x]
    b, tb = INPUTS[y]
    for op in ["+", "-", "*", "/"]:
        if op == "/" and np.any(as_np(b, tb) == 0):
            continue
        e, t = binop(op, a, ta, b, tb)
        lines += close2(f"x {op} y", e, t, x, y)
test("arithmetic_mixed_dtypes", lines)

# ---------- Bool with Bool: + is logical or, * is logical and (numpy) ----------
lines = []
lines += close2("x + y", np.add(INPUTS["BA"][0], INPUTS["BB"][0]), "Bool", "BA", "BB")
lines += close2("x * y", np.multiply(INPUTS["BA"][0], INPUTS["BB"][0]), "Bool", "BA", "BB")
test("arithmetic_bool", lines)

# ---------- array with a scalar on both sides ----------
# Swift scalars are numpy 2 (NEP 50) "weak" Python scalars: the kind of the scalar (bool < int < float) only matters
# when it is higher than the array's kind, otherwise the array keeps its type (UInt8 array + 1 -> UInt8).
# Matft conventions: an integer / Bool array with a fractional scalar gives Float (numpy: float64), and an integer scalar
# out of the range of a small integer array wraps around (UInt8 array + 300; numpy raises OverflowError).
def py_scalar(s, ts):
    """The Python scalar numpy sees for a Swift scalar of type ts"""
    if ts == "Bool":
        return bool(s)
    if ts in INT_TYPES:
        return int(s)
    return float(s)


def scalar_type(ta, ts, s):
    """The result type of an array of type ta with a Swift scalar s of type ts, by NEP 50 and the Matft conventions"""
    try:
        with warnings.catch_warnings(), np.errstate(all="ignore"):
            warnings.simplefilter("ignore")
            dt = (np.zeros(1, NP_DTYPE[ta]) + py_scalar(s, ts)).dtype
    except OverflowError:
        return ta  # Matft wraps an out of range integer scalar
    t = mftype_of(np.empty(0, dt))
    if t == "Double" and ta != "Double":
        t = "Float"  # integer / Bool array with a fractional scalar
    return t


def scalar_op(op, a, ta, s, ts, scalar_first=False):
    """(expected, mftype) of `a op s` (or `s op a`) with NEP 50 promotion, computed by numpy in the result type"""
    t = scalar_type(ta, ts, s)
    f = OPS[op][1]
    with np.errstate(all="ignore"):
        if op == "/":
            # true division like the array-array version: Float for Float-stored types, Double for Double
            rt = div_type(t)
            x, y = as_np(a, rt), NP_DTYPE[rt](py_scalar(s, ts))
            return (y / x if scalar_first else x / y), rt
        if t in INT_TYPES:
            # computed in int64 and wrapped into t like numpy's fixed-width integers
            x, y = as_np(a, t).astype(np.int64), np.int64(py_scalar(s, ts))
            return (f(y, x) if scalar_first else f(x, y)).astype(NP_DTYPE[t]), t
        x, y = as_np(a, t), NP_DTYPE[t](py_scalar(s, ts))
        return (f(y, x) if scalar_first else f(x, y)), t


lines = []
SCALARS = [("2", 2, "Int"), ("-3", -3, "Int"), ("300", 300, "Int"), ("2.5", 2.5, "Double"), ("2.0", 2.0, "Double"),
           ("Float(0.5)", 0.5, "Float"), ("UInt8(200)", 200, "UInt8"), ("Int8(-1)", -1, "Int8"), ("true", True, "Bool")]
for src in ["A", "AF", "AI", "U8A", "U16A", "I8E", "BA"]:
    a, ta = INPUTS[src]
    for sw, s, ts in SCALARS:
        bool_bool = ta == "Bool" and ts == "Bool"
        for op in ["+", "-", "*", "/"]:
            if bool_bool and op == "-":
                continue  # numpy: boolean subtract is not supported
            e, t = scalar_op(op, a, ta, s, ts)
            lines += close(f"x {op} {sw}", e, t, layout=src)
            if op == "/" and (bool_bool or np.any(as_np(a, "Double") == 0)):
                continue  # scalar / 0 is covered below
            e, t = scalar_op(op, a, ta, s, ts, scalar_first=True)
            lines += close(f"{sw} {op} x", e, t, layout=src)
        fop, fname = ("+", "add") if bool_bool else ("-", "sub")
        e, t = scalar_op(fop, a, ta, s, ts)
        lines += close(f"Matft.{fname}(x, {sw})", e, t, layout=src)
test("arithmetic_scalar", lines)

# division by an array containing 0 and by the scalar 0 (x/0 = ±inf, 0/0 = nan)
lines = []
with np.errstate(all="ignore"):
    for src in ["A", "AF"]:
        a, ta = INPUTS[src]
        z = NP_DTYPE[ta]
        lines += close(f"{fl(12, ta)} / x", z(12) / a, ta, layout=src)
        lines += close(f"{fl(0, ta)} / x", z(0) / a, ta, layout=src)
        lines += close(f"x / {fl(0, ta)}", a / z(0), ta, layout=src)
        lines += close(f"x / {fl(-0.0, ta)}", a / z(-0.0), ta, layout=src)
test("arithmetic_division_by_zero", lines)

# ---------- broadcasting ----------
lines = []
A_ = INPUTS["A"][0]
for y in ["COL", "ROW", "VEC"]:
    b = INPUTS[y][0]
    for op in ["+", "-", "*", "/"]:
        with np.errstate(all="ignore"):
            lines += close2(f"x {op} y", OPS[op][1](A_, b), "Double", "A", y)
            lines += close2(f"y {op} x", OPS[op][1](b, A_), "Double", "A", y)
lines += close2("x + y", INPUTS["COL"][0] + INPUTS["ROW"][0], "Double", "COL", "ROW")
lines += close2("x * y", INPUTS["COL"][0] * INPUTS["VEC"][0], "Double", "COL", "VEC")
lines += close2("x - y", INPUTS["A3"][0] - INPUTS["COL"][0], "Double", "A3", "COL")
lines += close2("y / x", INPUTS["VEC"][0] / INPUTS["A3NZ"][0], "Double", "A3NZ", "VEC")
# broadcasting together with a different dtype
lines += close2("x + y", INPUTS["AF"][0] + INPUTS["COL"][0], "Double", "AF", "COL")
lines += close2("x * y", as_np(INPUTS["U8A"][0], "Int") * INPUTS["COLI"][0], "Int", "U8A", "COLI")
test("arithmetic_broadcast", lines)

# ---------- NaN, ±inf, -0.0 ----------
lines = []
for x, y, t in [("SP", "SQ", "Double"), ("SPF", "SQF", "Float")]:
    a, b, z = INPUTS[x][0], INPUTS[y][0], NP_DTYPE[t]
    with np.errstate(all="ignore"):
        for op in ["+", "-", "*", "/"]:
            lines += close2(f"x {op} y", OPS[op][1](a, b), t, x, y)
        # the sign of zero is visible through 1 / x
        lines += close(f"{fl(1, t)} / (x * {fl(0, t)})", z(1) / (a * z(0)), t, layout=x)
        lines += close(f"{fl(1, t)} / (-x)", z(1) / (-a), t, layout=x)
        lines += close(f"x + {fl(inf, t)}", a + z(inf), t, layout=x)
        lines += close(f"x * {fl(nan, t)}", a * z(nan), t, layout=x)
        lines += close(f"{fl(-inf, t)} - x", z(-inf) - a, t, layout=x)
test("arithmetic_special_values", lines)

# ---------- negation ----------
lines = []
for src in ["A", "AF", "AI", "I8E", "U8A", "SP", "SPF"]:
    a, t = INPUTS[src]
    with np.errstate(all="ignore"):
        lines += close("-x", np.negative(a), t, layout=src)
        lines += close("Matft.neg(x)", np.negative(a), t, layout=src)
with np.errstate(all="ignore"):
    lines += close("1 / (-x)", 1 / np.negative(INPUTS["SP"][0]), "Double", layout="SP")
test("negation", lines)

# ---------- comparisons ----------
lines = []
for suffix in ["", "F", "I", "I8"]:
    a, b = INPUTS["A" + suffix][0], INPUTS["B" + suffix][0]
    for op, (fname, f) in CMPS.items():
        lines += close2(f"x {op} y", f(a, b), "Bool", "A" + suffix, "B" + suffix)
        lines += close2(f"Matft.{fname}(y, x)", f(b, a), "Bool", "A" + suffix, "B" + suffix)
test("compare_dtypes_layouts", lines)

lines = []
# the difference of the operands must not wrap (UInt8 0 - 255) nor lose the sign
for x, y in [("U8A", "U8B"), ("U8A", "I8F"), ("I8E", "I8F"), ("U16A", "U16B"), ("AI", "BF"), ("BA", "BB"), ("BA", "AI")]:
    a, b = INPUTS[x][0], INPUTS[y][0]
    for op, (fname, f) in CMPS.items():
        lines += close2(f"x {op} y", f(a, b), "Bool", x, y)
test("compare_mixed_dtypes", lines)

lines = []
CSCALARS = [("0", 0), ("5", 5), ("-1", -1), ("2.5", 2.5), ("255", 255), ("-128", -128)]
for src in ["A", "AF", "AI", "U8A", "I8E"]:
    a = INPUTS[src][0]
    for sw, s in CSCALARS:
        for op, (fname, f) in CMPS.items():
            lines += close(f"x {op} {sw}", f(a, s), "Bool", layout=src)
        lines += close(f"{sw} < x", np.less(s, a), "Bool", layout=src)
        lines += close(f"{sw} === x", np.equal(s, a), "Bool", layout=src)
        lines += close(f"Matft.greater_equal({sw}, x)", np.greater_equal(s, a), "Bool", layout=src)
test("compare_scalar", lines)

# a scalar is compared in the array's precision like numpy's weak scalars:
# float32 array == 0.1 is true for float32(0.1), float64 array == Float(0.1) compares with float64(float32(0.1))
lines = []
for src, sw, s in [("PF", "0.1", np.float32(0.1)), ("P", "0.1", 0.1), ("P", "Float(0.1)", np.float64(np.float32(0.1))),
                   ("PF", "Float(0.1)", np.float32(0.1)), ("PI", "2.5", 2.5), ("PI", "3", 3)]:
    a = INPUTS[src][0]
    for op, (fname, f) in CMPS.items():
        lines += close(f"x {op} {sw}", f(a, s), "Bool", layout=src)
test("compare_scalar_precision", lines)

# ---------- power with a scalar exponent / base ----------
# the exponent (base) keeps its precision: a Double exponent with a Double array matches numpy to 1e-12.
# Matft convention: the result is Double for Double arrays and Float otherwise, like division (numpy: int ** int -> int64)
lines = []
EXPONENTS = [("1.0/3", 1 / 3, "Double"), ("-0.5", -0.5, "Double"), ("2", 2, "Int"), ("3", 3, "Int"), ("0", 0, "Int"),
             ("Float(2.5)", 2.5, "Float"), ("2.0", 2.0, "Double")]
for src in ["P", "PF", "PI"]:
    a, ta = INPUTS[src]
    for sw, s, ts in EXPONENTS:
        rt = div_type(scalar_type(ta, ts, s))
        e = np.power(as_np(a, rt), NP_DTYPE[rt](py_scalar(s, ts)))
        lines += close(f"Matft.math.power(bases: x, exponents: {sw})", e, rt, rtol=1e-12 if rt == "Double" else 1e-5, layout=src)
BASES = [("2.0", 2.0, "Double"), ("2", 2, "Int"), ("Float(1.5)", 1.5, "Float"), ("10.0/3", 10 / 3, "Double")]
for src in ["P", "PF", "PI"]:
    a, ta = INPUTS[src]
    for sw, s, ts in BASES:
        rt = div_type(scalar_type(ta, ts, s))
        e = np.power(NP_DTYPE[rt](py_scalar(s, ts)), as_np(a, rt))
        lines += close(f"Matft.math.power(bases: {sw}, exponents: x)", e, rt, rtol=1e-12 if rt == "Double" else 1e-5, layout=src)
test("power_scalar", lines)

lines = []
T = INPUTS["T"][0]
for op, (fname, f) in CMPS.items():
    lines += close(f"x {op} 1.0", f(T, 1.0), "Bool", layout="T")
    lines += close(f"x {op} 0.0", f(T, 0.0), "Bool", layout="T")
    lines += close(f"x {op} x[Matft.reverse]", f(T, T[::-1]), "Bool", layout="T")
test("compare_threshold", lines)

lines = []
for x, y, t in [("SP", "SQ", "Double"), ("SPF", "SQF", "Float")]:
    a, b = INPUTS[x][0], INPUTS[y][0]
    for op, (fname, f) in CMPS.items():
        lines += close2(f"x {op} y", f(a, b), "Bool", x, y)
        for s in [inf, -inf, nan, 0.0]:
            lines += close(f"x {op} {fl(s, t)}", f(a, s), "Bool", layout=x)
        lines += close(f"x {op} x", f(a, a), "Bool", layout=x)
test("compare_special_values", lines)

lines = []
for y in ["COL", "ROW", "VEC"]:
    for op, (fname, f) in CMPS.items():
        lines += close2(f"x {op} y", f(INPUTS["A"][0], INPUTS[y][0]), "Bool", "A", y)
lines += close2("x > y", INPUTS["A3"][0] > INPUTS["COL"][0], "Bool", "A3", "COL")
lines += close2("x === y", as_np(INPUTS["U8A"][0], "Int") == INPUTS["COLI"][0], "Bool", "U8A", "COLI")
test("compare_broadcast", lines)

# ---------- logical_not ----------
lines = []
for src in ["A", "AF", "AI", "U8A", "BA", "SP", "SPF"]:
    a = INPUTS[src][0]
    lines += close("!x", np.logical_not(a), "Bool", layout=src)
    lines += close("Matft.logical_not(x)", np.logical_not(a), "Bool", layout=src)
lines += close("!(x > 0)", np.logical_not(INPUTS["A"][0] > 0), "Bool", layout="A")
test("logical_not", lines)

# ---------- maximum / minimum ----------
lines = []
for x, y in [("A", "B"), ("AF", "BF"), ("AI", "BI"), ("U8A", "U8B"), ("U8A", "I8F"), ("AI", "BF"), ("A", "COL"), ("ROW", "A")]:
    (a, ta), (b, tb) = INPUTS[x], INPUTS[y]
    t = array_type(ta, tb)
    lines += close2("Matft.stats.maximum(x, y)", np.maximum(as_np(a, t), as_np(b, t)), t, x, y)
    lines += close2("Matft.stats.minimum(x, y)", np.minimum(as_np(a, t), as_np(b, t)), t, x, y)
test("maximum_minimum", lines)

lines = []
# NaN propagates like numpy; ±inf are ordinary values
for x, y, t in [("SP", "SQ", "Double"), ("SPF", "SQF", "Float")]:
    a, b = INPUTS[x][0], INPUTS[y][0]
    lines += close2("Matft.stats.maximum(x, y)", np.maximum(a, b), t, x, y)
    lines += close2("Matft.stats.minimum(x, y)", np.minimum(a, b), t, x, y)
test("maximum_minimum_nan", lines)

# ---------- empty arrays (Row and Column order) ----------
lines = []
EMPTY = {
    "E30": ("MfArray([] as [Double], mftype: .Double, shape: [3, 0])", np.zeros((3, 0))),
    "E30C": ("MfArray([] as [Double], mftype: .Double, shape: [3, 0], mforder: .Column)", np.zeros((3, 0))),
    "E04": ("MfArray([] as [Double], mftype: .Double, shape: [0, 4])", np.zeros((0, 4))),
    "E0": ("MfArray([] as [Double], mftype: .Double, shape: [0])", np.zeros((0,))),
    "E203": ("MfArray([] as [Int], mftype: .Int, shape: [2, 0, 3])", np.zeros((2, 0, 3), dtype=np.int64)),
}
PAIRS = [("E30", "E30"), ("E30C", "E30"), ("E30", "COL"), ("COL", "E30C"), ("E04", "ROW"), ("E04", "VEC"), ("E0", "E0"),
         ("E203", "E203")]
for x, y in PAIRS:
    xs, xa = EMPTY[x] if x in EMPTY else (x, INPUTS[x][0])
    ys, ya = EMPTY[y] if y in EMPTY else (y, INPUTS[y][0])
    integer = xa.dtype == np.int64 and ya.dtype == np.int64
    for op in ["+", "-", "*", "/"]:
        t = ("Float" if op == "/" else "Int") if integer else "Double"
        lines += close(f"{xs} {op} {ys}", OPS[op][1](xa, ya), t)
    lines += close(f"{xs} > {ys}", np.greater(xa, ya), "Bool")
    lines += close(f"{xs} === {ys}", np.equal(xa, ya), "Bool")
for xs, xa in EMPTY.values():
    t = "Int" if xa.dtype == np.int64 else "Double"
    lines += close(f"{xs} + 1", xa + 1, t)
    lines += close(f"2 * {xs}", 2 * xa, t)
    lines += close(f"-{xs}", -xa, t)
    lines += close(f"{xs} <= 0", xa <= 0, "Bool")
    lines += close(f"!{xs}", np.logical_not(xa), "Bool")
    lines += close(f"Matft.stats.maximum({xs}, {xs})", np.maximum(xa, xa), t)
test("empty", lines)


# ---------- complex ----------
def swift_complex(z, mftype):
    z = np.asarray(z)
    return f"MfArray(real: {swift_array(z.real, mftype)}, imag: {swift_array(z.imag, mftype)})"


def cclose(swift, expected, mftype):
    """XCTAssertClose of the real and the imaginary part (XCTAssertClose alone compares the real part only)"""
    expected = np.asarray(expected)
    tol = 1e-5 if mftype == "Float" else 1e-10
    out = []
    for part, values in [("real", expected.real), ("imag!", expected.imag)]:
        label = swift_escape(swift) + " " + part
        out.append(f"XCTAssertClose(({swift}).{part}, {swift_array(values.astype(NP_DTYPE[mftype]), mftype)}, "
                   f"rtol: {tol}, atol: {tol}, checkType: true, \"{label}\")")
    return out


Z = np.array([[1 + 2j, -3 + 0.5j, 0 - 1j], [2.5 + 0j, -1 - 4j, 3 + 3j]])
W = np.array([[2 - 1j, 1 + 1j, -2 + 3j], [0.5 + 2j, 4 - 1j, -1 + 0.25j]])
R = np.array([[2.0, -1.0, 4.0], [0.5, 3.0, -8.0]])
lines = []
for t, ct in [("Double", np.complex128), ("Float", np.complex64)]:
    ws, rs = swift_complex(W, t), swift_array(R, t)
    z, w, r = Z.astype(ct), W.astype(ct), R.astype(NP_DTYPE[t])
    # a view whose data does not start at 0 (rows 1..<3 of 4x3) and a transposed view
    big = np.concatenate([np.full((1, 3), 9 + 9j), Z, np.full((1, 3), 7 - 7j)])
    for zexpr in [swift_complex(Z, t), f"{swift_complex(big, t)}[1~<3]", f"{swift_complex(Z.T, t)}.T"]:
        with np.errstate(all="ignore"):
            for op in ["+", "-", "*", "/"]:
                f = OPS[op][1]
                lines += cclose(f"{zexpr} {op} {ws}", f(z, w), t)
                lines += cclose(f"{zexpr} {op} {rs}", f(z, r), t)
                lines += cclose(f"{rs} {op} {zexpr}", f(r, z), t)
            lines += cclose(f"{zexpr} + {fl(2, t)}", z + ct(2), t)
            lines += cclose(f"{fl(1.5, t)} - {zexpr}", ct(1.5) - z, t)
            lines += cclose(f"{zexpr} - {fl(1.5, t)}", z - ct(1.5), t)
            lines += cclose(f"{fl(3, t)} * {zexpr}", ct(3) * z, t)
            lines += cclose(f"{zexpr} / {fl(2, t)}", z / ct(2), t)
            lines += cclose(f"{fl(2, t)} / {zexpr}", ct(2) / z, t)
            lines += cclose(f"-{zexpr}", -z, t)
        lines += close(f"{zexpr} === {zexpr}", np.equal(z, z), "Bool")
        lines += close(f"{zexpr} === {ws}", np.equal(z, w), "Bool")
        lines += close(f"{zexpr} !== {ws}", np.not_equal(z, w), "Bool")
    # a complex row broadcast against a real column
    lines += cclose(f"{swift_complex(Z[:1], t)} * {swift_array(R[:, :1], t)}", Z[:1].astype(ct) * r[:, :1], t)
test("complex", lines, wasi_skip=True)

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
