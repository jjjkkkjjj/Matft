"""Generate Tests/MatftTests/ManipulationCoverageTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_manipulation_coverage.py

Every case is a Swift expression and the numpy expression computing its expected value.
Cases taking `x` run over `layoutVariants(input)` (row/column major, transposed, offset, prefix, strided and reversed views),
so the expected values must not depend on the memory layout.
Covers conversion (astype, reshape, transpose, swapaxes, moveaxis, expand_dims, squeeze, broadcast_to, flatten, flip,
clip, sort, argsort, roll, orderedUnique), joining (concatenate, vstack, hstack, append, insert, take)
and creation (arange, eye, diag, nums, nums_like).
pad / diff / meshgrid are in gen_numpy_gaps_coverage.py. View vs copy semantics are in ManipulationViewTest.swift.
Matft conventions: a reduction over all the axes returns shape [1] (numpy returns a 0-d scalar).
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "ManipulationCoverageTest.swift")
CLASS = "ManipulationCoverageTests"
DOC = "Conversion, manipulation and creation over dtypes, memory layouts (`layoutVariants`) and edge cases. Expected values are numpy outputs"

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


def swift_array(a, mftype, order=None):
    """Swift expression creating `a` as MfArray of mftype. 0-d arrays become shape [1] like Matft's reductions"""
    a = np.asarray(a)
    shape = list(a.shape) if a.ndim > 0 else [1]
    flat = a.ravel()
    o = f", mforder: .{order}" if order else ""
    if a.size == 0:
        cast = "Bool" if mftype == "Bool" else ("Int" if mftype in INT_TYPES else "Double")
        return f"MfArray([] as [{cast}], mftype: .{mftype}, shape: {shape}{o})"
    if mftype == "Bool":
        values = ", ".join("true" if bool(v) else "false" for v in flat)
        return f"MfArray([{values}] as [Bool], shape: {shape})"
    if mftype in INT_TYPES:
        values = ", ".join(str(int(v)) for v in flat)
        return f"MfArray([{values}] as [Int], mftype: .{mftype}, shape: {shape})"
    values = ", ".join(lit(v) for v in flat)
    return f"MfArray([{values}] as [Double], mftype: .{mftype}, shape: {shape})"


def swift_complex(z, mftype):
    return f"MfArray(real: {swift_array(z.real, mftype)}, imag: {swift_array(z.imag, mftype)})"


def swift_escape(s):
    return s.replace("\\", "\\\\").replace("\"", "\\\"")


# ---------- inputs (defined identically in Swift) ----------
INPUTS = {}
CINPUTS = {}


def inp(name, a, mftype):
    """Declare an input. The numpy array is cast to the dtype of mftype so the reference is computed in that type"""
    a = np.asarray(a).astype(NP_DTYPE[mftype])
    INPUTS[name] = (a, mftype)
    return a


def cinp(name, z, mftype):
    """Declare a complex input (numpy complex128 / complex64 for Double / Float)"""
    z = np.asarray(z).astype(np.complex128 if mftype == "Double" else np.complex64)
    CINPUTS[name] = (z, mftype)
    return z


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


def zclose(swift, expected, mftype):
    """Complex result: the real and the imaginary parts (both must exist) and their dtype"""
    label = swift_escape(swift)
    tol = "rtol: 1e-5, atol: 1e-5" if mftype == "Float" else "rtol: 1e-10, atol: 1e-10"
    return ["do {",
            f"    let z = {swift}",
            f"    XCTAssertTrue(z.isComplex, \"{label}\")",
            f"    XCTAssertClose(z.real, {swift_array(expected.real, mftype)}, {tol}, checkType: true, \"{label} real\")",
            f"    if let im = z.imag {{ XCTAssertClose(im, {swift_array(expected.imag, mftype)}, {tol}, checkType: true, \"{label} imag\") }}",
            "}"]


def ordered_unique(a, axis=None):
    """Matft.orderedUnique: unique elements (or rows) in the order of first occurrence"""
    if axis is None:
        flat = a.ravel()
        _, idx = np.unique(flat, return_index=True)
        return flat[np.sort(idx)]
    _, idx = np.unique(a, axis=axis, return_index=True)
    return np.take(a, np.sort(idx), axis=axis)


# ---------- inputs ----------
# negatives, ties, a non-square shape
BASE = [[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]]
A = inp("A", BASE, "Double")
AF = inp("AF", BASE, "Float")
AI = inp("AI", BASE, "Int")
U8 = inp("U8", [[0, 1, 127], [128, 254, 255]], "UInt8")
BL = inp("BL", [[True, False, True], [False, False, True]], "Bool")
AN = inp("AN", [[1, nan, 3, 4], [2, 5, nan, 1], [nan, 7, 2, -inf]], "Double")
A3 = inp("A3", np.arange(24).reshape(2, 3, 4) * np.where(np.arange(24).reshape(2, 3, 4) % 3 == 0, -1, 1), "Double")
V = inp("V", [7, -3, 0, 2], "Double")
C = inp("C", [[1], [-2], [3]], "Double")                                  # 3x1 column
B = inp("B", [[10, 11, 12, 13], [14, 15, 16, 17]], "Double")              # 2x4 (concat along axis 0 with A)
A2 = inp("A2", [[-7, 8], [9, -10], [11, 12]], "Double")                   # 3x2 (concat along axis 1 with A)
A3b = inp("A3b", np.arange(16).reshape(2, 2, 4) + 100, "Double")          # concat along the middle axis with A3
P = inp("P", [[0.5, -3, 2, 7], [4, 1, -8, 0], [6, -1, 3, 9]], "Double")    # no ties (argsort)
E = inp("E", np.arange(12).reshape(1, 3, 1, 4) - 5, "Double")              # size-1 axes for squeeze
D = inp("D", [[1, 2], [3, 4], [1, 2], [0, 0], [3, 4]], "Double")           # duplicated rows
# integer boundaries (all below 2^24 so that the Float storage is exact)
IB = inp("IB", [-32769, -129, -128, -1, 0, 1, 127, 128, 255, 256, 32767, 65535, 65536], "Int")
# float -> int truncates toward zero (values stay inside every target range: out of range is undefined in C)
FV = inp("FV", [-2.7, -1.5, -0.5, -0.0, 0.5, 1.5, 2.5, 2.7, 100.9], "Double")
FVF = inp("FVF", [-2.7, -1.5, -0.5, -0.0, 0.5, 1.5, 2.5, 2.7, 100.9], "Float")
SP = inp("SP", [nan, inf, -inf, 0, -0.0, 1e-30], "Double")

Z = cinp("Z", np.array([[1, -2, 3], [4, 5, -6]]) + 1j * np.array([[0.5, 7, -1], [2, -3, 9]]), "Double")
ZF = cinp("ZF", np.array([[1, -2, 3], [4, 5, -6]]) + 1j * np.array([[0.5, 7, -1], [2, -3, 9]]), "Float")

REAL = [("A", "Double"), ("AF", "Float"), ("AI", "Int")]


def assert_by_type(swift, expected, layout=None):
    """equal for integer / bool results, close otherwise"""
    if mftype_of(expected) in INT_TYPES + ("Bool",):
        return equal(swift, expected, layout=layout)
    return close(swift, expected, layout=layout)


# ---------- astype ----------
lines = []
for dst in ["UInt8", "Int8", "UInt16", "Int16", "Int32", "Int", "Float", "Double", "Bool"]:
    lines += assert_by_type(f"IB.astype(.{dst})", IB.astype(NP_DTYPE[dst]))
test("astype_int_boundaries_wrap", lines)

lines = []
for src, arr in [("FV", FV), ("FVF", FVF)]:
    for dst in ["Int8", "Int16", "Int32", "Int", "Bool", "Float", "Double"]:
        lines += assert_by_type(f"{src}.astype(.{dst})", arr.astype(NP_DTYPE[dst]))
    # non-negative values only: a negative float -> unsigned is undefined in C
    lines += equal(f"{src}[4~<].astype(.UInt8)", arr[4:].astype(np.uint8))
test("astype_float_truncates_toward_zero", lines)

lines = []
with np.errstate(invalid="ignore"):
    lines += equal("SP.astype(.Bool)", SP.astype(np.bool_))
    lines += close("SP.astype(.Float)", SP.astype(np.float32))
for dst in ["Int8", "Int", "Float", "Double"]:
    lines += assert_by_type(f"U8.astype(.{dst})", U8.astype(NP_DTYPE[dst]))
for dst in ["UInt8", "Int", "Float", "Double"]:
    lines += assert_by_type(f"BL.astype(.{dst})", BL.astype(NP_DTYPE[dst]))
test("astype_special_uint8_bool", lines)

lines = []
for src, _ in REAL:
    a = INPUTS[src][0]
    for dst in ["Int", "Float", "Double", "Bool", "UInt8"]:
        if dst == "UInt8" and a.min() < 0:
            continue
        lines += assert_by_type(f"x.astype(.{dst})", a.astype(NP_DTYPE[dst]), layout=src)
    lines += assert_by_type(f"x.astype(.Double, mforder: .Column)", a.astype(np.float64), layout=src)
test("astype_layouts", lines)

# ---------- reshape ----------
lines = []
for src, _ in REAL:
    a = INPUTS[src][0]
    for ns in [[4, 3], [2, -1], [-1], [2, 2, 3], [12, 1]]:
        lines += assert_by_type(f"x.reshape({ns})", a.reshape(ns), layout=src)
    for ns in [[4, 3], [2, 3, 2]]:
        lines += assert_by_type(f"Matft.reshape(x, newshape: {ns}, order: .Column)", a.reshape(ns, order="F"), layout=src)
for ns in [[4, 6], [-1, 4], [3, -1, 2], [24]]:
    lines += close(f"x.reshape({ns})", A3.reshape(ns), layout="A3")
    lines += close(f"Matft.reshape(x, newshape: {ns}, order: .Column)", A3.reshape(ns, order="F"), layout="A3")
test("reshape", lines)

# ---------- transpose / swapaxes / moveaxis ----------
lines = []
for src, _ in REAL:
    a = INPUTS[src][0]
    lines += assert_by_type("Matft.transpose(x)", a.T, layout=src)
    lines += assert_by_type("x.transpose(axes: [-1, 0])", a.T, layout=src)
for axes in [None, [0, 2, 1], [2, 0, 1], [1, 0, 2], [-1, 0, -2]]:
    arg = "" if axes is None else f", axes: {axes}"
    exp = np.transpose(A3, axes)
    lines += close(f"Matft.transpose(x{arg})", exp, layout="A3")
    # chain an op that walks the strides of the returned view
    lines += close(f"Matft.transpose(x{arg}).flatten()", exp.ravel(), layout="A3")
    lines += close(f"Matft.transpose(x{arg}).reshape([4, -1])", exp.reshape(4, -1), layout="A3")
test("transpose", lines)

lines = []
for a1, a2 in [(0, 2), (-1, 0), (1, 1), (0, -2)]:
    lines += close(f"Matft.swapaxes(x, axis1: {a1}, axis2: {a2})", np.swapaxes(A3, a1, a2), layout="A3")
for s, d in [(0, -1), (-1, 0), (1, 2), (2, 1), (0, 0)]:
    lines += close(f"Matft.moveaxis(x, src: {s}, dst: {d})", np.moveaxis(A3, s, d), layout="A3")
for s, d in [([0, 1], [-1, -2]), ([0, 2], [2, 0]), ([2, 0], [0, 1]), ([-1], [0])]:
    lines += close(f"Matft.moveaxis(x, src: {s}, dst: {d})", np.moveaxis(A3, s, d), layout="A3")
lines += equal("Matft.swapaxes(x, axis1: 0, axis2: 1)", np.swapaxes(AI, 0, 1), layout="AI")
lines += equal("Matft.moveaxis(x, src: 0, dst: 1)", np.moveaxis(U8, 0, 1), layout="U8")
test("swapaxes_moveaxis", lines)

# ---------- expand_dims / squeeze ----------
lines = []
for ax in [0, 1, 2, -1, -3]:
    lines += close(f"Matft.expand_dims(x, axis: {ax})", np.expand_dims(A, ax), layout="A")
for axes in [[0, 2], [0, -1], [-1, -2], [1, 3]]:
    lines += close(f"Matft.expand_dims(x, axes: {axes})", np.expand_dims(A, tuple(axes)), layout="A")
for ax in [0, -1]:
    lines += close(f"Matft.expand_dims(x, axis: {ax})", np.expand_dims(V, ax), layout="V")
lines += equal("Matft.expand_dims(x, axis: 1)", np.expand_dims(U8, 1), layout="U8")
lines += close("Matft.expand_dims(x, axis: 0).flatten()", np.expand_dims(A, 0).ravel(), layout="A")
test("expand_dims", lines)

lines = []
for arg, exp in [("", np.squeeze(E)), (", axis: 0", np.squeeze(E, 0)), (", axis: -2", np.squeeze(E, -2)),
                 (", axis: 2", np.squeeze(E, 2))]:
    lines += close(f"Matft.squeeze(x{arg})", exp, layout="E")
for axes in [[0, 2], [2, 0], [-2, 0]]:
    lines += close(f"Matft.squeeze(x, axes: {axes})", np.squeeze(E, tuple(axes)), layout="E")
lines += close("Matft.squeeze(x, axis: 1)", np.squeeze(C, 1), layout="C")
lines += close("Matft.squeeze(x).flatten()", np.squeeze(E).ravel(), layout="E")
test("squeeze", lines)

# ---------- broadcast_to ----------
lines = []
for src, arr, shp in [("V", V, [3, 4]), ("V", V, [2, 3, 4]), ("C", C, [3, 4]), ("C", C, [2, 3, 5]), ("A", A, [2, 3, 4]),
                      ("A", A, [3, 4]), ("E", E, [2, 3, 5, 4])]:
    exp = np.broadcast_to(arr, shp)
    lines += close(f"Matft.broadcast_to(x, shape: {shp})", exp, layout=src)
    lines += close(f"Matft.broadcast_to(x, shape: {shp}).flatten()", exp.ravel(), layout=src)
lines += equal("Matft.broadcast_to(x, shape: [2, 2, 3])", np.broadcast_to(U8, (2, 2, 3)), layout="U8")
lines += close("Matft.broadcast_to(x, shape: [3, 4]).T", np.broadcast_to(C, (3, 4)).T, layout="C")
test("broadcast_to", lines)

# ---------- flatten / to_contiguous ----------
lines = []
for src, _ in REAL + [("A3", "Double"), ("U8", "UInt8"), ("BL", "Bool")]:
    a = INPUTS[src][0]
    lines += assert_by_type("x.flatten()", a.ravel(), layout=src)
    lines += assert_by_type("x.flatten(.Column)", a.ravel(order="F"), layout=src)
    lines += assert_by_type("x.to_contiguous(mforder: .Column)", a, layout=src)
test("flatten_to_contiguous", lines)

# ---------- flip ----------
lines = []
for arg, axes in [("", None), (", axis: 0", 0), (", axis: 1", 1), (", axis: -1", -1), (", axes: [0, 2]", (0, 2)),
                  (", axes: [-1, -2]", (-1, -2))]:
    exp = np.flip(A3, axes)
    lines += close(f"Matft.flip(x{arg})", exp, layout="A3")
    lines += close(f"Matft.flip(x{arg}).flatten()", exp.ravel(), layout="A3")
lines += close("Matft.flip(Matft.flip(x, axis: 1), axis: 1)", A3, layout="A3")
lines += equal("Matft.flip(x)", np.flip(AI), layout="AI")
lines += equal("x.flip(axis: -1)", np.flip(U8, -1), layout="U8")
test("flip", lines)

# ---------- clip ----------
lines = []
for src, _ in REAL:
    a = INPUTS[src][0]
    lines += assert_by_type("Matft.clip(x, min: -1, max: 5)", np.clip(a, -1, 5), layout=src)
    lines += assert_by_type("Matft.clip(x, min: 2)", np.clip(a, 2, None), layout=src)
    lines += assert_by_type("Matft.clip(x, max: 2)", np.clip(a, None, 2), layout=src)
    # min > max: numpy returns max everywhere (minimum(maximum(a, min), max))
    lines += assert_by_type("Matft.clip(x, min: 4, max: 1)", np.clip(a, 4, 1), layout=src)
lines += close("Matft.clip(x, min: -0.5, max: 4.5)", np.clip(AF, -0.5, 4.5), layout="AF")
lines += equal("Matft.clip(x, min: 10, max: 250)", np.clip(U8, 10, 250), layout="U8")
lines += close("Matft.clip(x, min: 0, max: 5)", np.clip(AN, 0, 5), layout="AN")
# the bounds are weak scalars (NEP 50) like the arithmetic operators: an Int array with fractional bounds gives Float
# (Matft convention; numpy: float64), a Bool array with integer bounds gives Int
lines += close("Matft.clip(x, min: 0.5, max: 4.5)", np.clip(AI.astype(np.float32), 0.5, 4.5), layout="AI")
lines += equal("Matft.clip(x, min: 0, max: 1)", np.clip(BL, 0, 1), layout="BL")
lines += close("Matft.clip(x, min: Float(0.5))", np.clip(A, np.float64(np.float32(0.5)), None), layout="A")
test("clip", lines)

# ---------- sort / argsort ----------
lines = []
for src, _ in REAL + [("U8", "UInt8")]:
    a = INPUTS[src][0]
    for arg, axis in [("", -1), (", axis: 0", 0), (", axis: 1", 1), (", axis: nil", None)]:
        exp = np.sort(a, axis=axis)
        lines += assert_by_type(f"Matft.sort(x{arg})", exp, layout=src)
        # descending == the ascending result reversed along the axis
        lines += assert_by_type(f"Matft.sort(x{arg}, order: .Descending)", np.flip(exp, -1 if axis is None else axis), layout=src)
for arg, axis in [("", -1), (", axis: 0", 0), (", axis: 2", 2), (", axis: nil", None)]:
    lines += close(f"Matft.sort(x{arg})", np.sort(A3, axis=axis), layout="A3")
# argsort on input without ties: the order of ties is not specified (numpy's default quicksort is not stable)
for arg, axis in [("", -1), (", axis: 0", 0), (", axis: nil", None)]:
    exp = np.argsort(P, axis=axis, kind="stable")
    lines += equal(f"Matft.argsort(x{arg})", exp, layout="P")
    lines += equal(f"Matft.argsort(x{arg}, order: .Descending)", np.argsort(-P, axis=axis, kind="stable"), layout="P")
lines += equal("Matft.argsort(x, axis: 1)", np.argsort(A3, axis=1, kind="stable"), layout="A3")
test("sort_argsort", lines)

# ---------- roll ----------
lines = []
for src, _ in REAL + [("U8", "UInt8")]:
    a = INPUTS[src][0]
    for shift in [1, -1, 5, -13, 0]:
        for arg, axis in [("", None), (", axis: 0", 0), (", axis: 1", 1), (", axis: -1", -1)]:
            lines += assert_by_type(f"Matft.roll(x, shift: {shift}{arg})", np.roll(a, shift, axis=axis), layout=src)
for shift, arg, axis in [(2, "", None), (-1, ", axis: 1", 1), (4, ", axis: 0", 0), (3, ", axis: -1", -1)]:
    lines += close(f"Matft.roll(x, shift: {shift}{arg})", np.roll(A3, shift, axis=axis), layout="A3")
test("roll", lines)

# ---------- orderedUnique ----------
lines = []
lines += close("Matft.orderedUnique(x)", ordered_unique(A), layout="A")
lines += equal("Matft.orderedUnique(x)", ordered_unique(AI), layout="AI")
lines += close("Matft.orderedUnique(x, axis: 0)", ordered_unique(D, 0), layout="D")
test("ordered_unique", lines)

# ---------- concatenate / vstack / hstack ----------
lines = []
lines += close("Matft.concatenate([x, B], axis: 0)", np.concatenate([A, B], 0), layout="A")
lines += close("Matft.concatenate([B, x, x], axis: 0)", np.concatenate([B, A, A], 0), layout="A")
lines += close("Matft.concatenate([x, A2], axis: 1)", np.concatenate([A, A2], 1), layout="A")
lines += close("Matft.concatenate([A2, x, A2], axis: -1)", np.concatenate([A2, A, A2], -1), layout="A")
lines += close("Matft.concatenate([x, A3b], axis: 1)", np.concatenate([A3, A3b], 1), layout="A3")
lines += close("Matft.concatenate([A3, x], axis: 2)", np.concatenate([A3, A3], 2), layout="A3")
lines += close("Matft.concatenate([A3, x], axis: -3)", np.concatenate([A3, A3], 0), layout="A3")
lines += close("Matft.concatenate([x, V])", np.concatenate([V, V]), layout="V")
lines += close("Matft.concatenate([x])", A, layout="A")
test("concatenate", lines)

lines = []
# array-array promotion like np.result_type
lines += equal("Matft.concatenate([U8, MfArray([-1, -128, 127] as [Int], mftype: .Int8, shape: [1, 3])], axis: 0)",
               np.concatenate([U8, np.array([[-1, -128, 127]], np.int8)], 0))
lines += equal("Matft.concatenate([MfArray([-1, 2, 3] as [Int], mftype: .Int8, shape: [1, 3]), MfArray([200, 255, 0] as [Int], mftype: .UInt8, shape: [1, 3])], axis: 1)",
               np.concatenate([np.array([[-1, 2, 3]], np.int8), np.array([[200, 255, 0]], np.uint8)], 1))
lines += equal("Matft.concatenate([AI, BL.astype(.Bool).reshape([3, 2])], axis: 1)",
               np.concatenate([AI, BL.reshape(3, 2)], 1))
lines += close("Matft.concatenate([AI, A], axis: 0)", np.concatenate([AI, A], 0))
lines += close("Matft.concatenate([AF, A], axis: 1)", np.concatenate([AF, A], 1))
# Matft convention: integers don't widen with Float (numpy gives float64)
lines += close("Matft.concatenate([AI, AF], axis: 0)", np.concatenate([AI, AF], 0).astype(np.float32), mftype="Float")
lines += equal("Matft.vstack([U8, MfArray([-3, 4, 5] as [Int], mftype: .Int8, shape: [1, 3])])",
               np.vstack([U8, np.array([[-3, 4, 5]], np.int8)]))
lines += equal("Matft.hstack([MfArray([1, 2] as [Int], mftype: .UInt16), MfArray([-1] as [Int], mftype: .Int8)])",
               np.hstack([np.array([1, 2], np.uint16), np.array([-1], np.int8)]))
test("concatenate_dtypes", lines)

lines = []
lines += close("Matft.vstack([x, x])", np.vstack([V, V]), layout="V")
lines += close("Matft.vstack([x, B])", np.vstack([A, B]), layout="A")
lines += close("Matft.vstack([x, V])", np.vstack([A, V]), layout="A")
lines += close("Matft.hstack([x, x])", np.hstack([V, V]), layout="V")
lines += close("Matft.hstack([x, C])", np.hstack([A, C]), layout="A")
lines += close("Matft.hstack([C, x, A2])", np.hstack([C, A, A2]), layout="A")
lines += equal("Matft.vstack([x, x])", np.vstack([AI, AI]), layout="AI")
test("vstack_hstack", lines)

# ---------- append / insert / take ----------
lines = []
lines += close("Matft.append(x, values: B)", np.append(A, B), layout="A")
lines += close("Matft.append(x, values: B, axis: 0)", np.append(A, B, axis=0), layout="A")
lines += close("Matft.append(x, values: C, axis: 1)", np.append(A, C, axis=1), layout="A")
lines += close("Matft.append(x, values: C, axis: -1)", np.append(A, C, axis=-1), layout="A")
lines += close("Matft.append(x, value: 7.5)", np.append(A, 7.5), layout="A")
lines += equal("Matft.append(x, value: 7)", np.append(AI, 7), layout="AI")
lines += close("x.append(values: V)", np.append(V, V), layout="V")
test("append", lines)

lines = []
lines += close("Matft.insert(x, indices: [1], value: 9.0)", np.insert(V, [1], 9.0), layout="V")
lines += close("Matft.insert(x, indices: [0, 2, 4], values: MfArray([10, 20, 30] as [Double]))",
               np.insert(V, [0, 2, 4], [10, 20, 30]), layout="V")
lines += close("Matft.insert(x, indices: [-1], value: 9.0)", np.insert(V, [-1], 9.0), layout="V")
lines += close("Matft.insert(x, indices: [1, 1], values: MfArray([10, 20] as [Double]))",
               np.insert(V, [1, 1], [10, 20]), layout="V")
lines += close("Matft.insert(x, indices: [3, 0], values: MfArray([10, 20] as [Double]))",
               np.insert(V, [3, 0], [10, 20]), layout="V")
lines += close("Matft.insert(x, indices: [1], values: MfArray([-5, -6, -7, -8] as [Double], shape: [1, 4]), axis: 0)",
               np.insert(A, [1], [[-5, -6, -7, -8]], axis=0), layout="A")
lines += close("Matft.insert(x, indices: [2], value: 0.5, axis: 1)", np.insert(A, [2], 0.5, axis=1), layout="A")
lines += close("Matft.insert(x, indices: [0, 4], values: MfArray([100, 200] as [Double]), axis: -1)",
               np.insert(A, [0, 4], np.array([100, 200])[None, :].repeat(3, 0), axis=-1), layout="A")
lines += close("Matft.insert(x, indices: [5], value: -1.0)", np.insert(A, [5], -1.0), layout="A")
lines += close("Matft.insert(x, indices: [1], value: 0.0, axis: 1)", np.insert(A3, [1], 0.0, axis=1), layout="A3")
# the values are cast into the type of the array (truncated toward zero)
lines += equal("Matft.insert(x, indices: [1, 3], values: MfArray([2.7, -2.7] as [Double]))", np.insert(AI, [1, 3], [2.7, -2.7]), layout="AI")
lines += equal("Matft.insert(x, indices: [0], value: 2.5, axis: 1)", np.insert(AI, [0], 2.5, axis=1), layout="AI")
lines += equal("Matft.insert(x, indices: [2], values: MfArray([7, -8, 9] as [Int], mftype: .Int8), axis: 0)",
               np.insert(U8, [2], np.array([7, -8, 9], np.int8), axis=0), layout="U8")
test("insert", lines)

lines = []
for arg, axis in [("", None), (", axis: 0", 0), (", axis: 1", 1), (", axis: -1", -1)]:
    lines += close(f"Matft.take(x, indices: MfArray([2, 0, -1]){arg})", np.take(A, [2, 0, -1], axis=axis), layout="A")
lines += close("Matft.take(x, indices: MfArray([[0, 1], [2, 3]]))", np.take(A, [[0, 1], [2, 3]]), layout="A")
lines += close("Matft.take(x, indices: MfArray([[0, 1], [2, 3]]), axis: 1)", np.take(A, [[0, 1], [2, 3]], axis=1), layout="A")
lines += close("Matft.take(x, indices: MfArray([1, 1, 0]), axis: 2)", np.take(A3, [1, 1, 0], axis=2), layout="A3")
lines += equal("x.take(indices: MfArray([1, 0]), axis: 0)", np.take(U8, [1, 0], axis=0), layout="U8")
test("take", lines)

# ---------- creation ----------
lines = []
lines += equal("Matft.arange(start: 0, to: 5, by: 1)", np.arange(0, 5, 1))
lines += equal("Matft.arange(start: 5, to: -5, by: -3)", np.arange(5, -5, -3))
lines += close("Matft.arange(start: 0.0, to: 1.0, by: 0.25)", np.arange(0.0, 1.0, 0.25))
lines += close("Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3], mftype: .Float)", np.arange(6, dtype=np.float32).reshape(2, 3))
# Matft convention: with mforder .Column the values are laid out in column major order (np.reshape(order="F"))
lines += equal("Matft.arange(start: 0, to: 24, by: 1, shape: [2, 3, 4], mforder: .Column)", np.arange(24).reshape((2, 3, 4), order="F"))
lines += shape("Matft.arange(start: 3, to: 3, by: 1)", np.arange(3, 3, 1).shape)
test("arange", lines)

lines = []
# the default type is Double like np.eye (float64)
lines += close("Matft.eye(dim: 3)", np.eye(3))
lines += close("Matft.eye(dim: 2, mforder: .Column)", np.eye(2))
for t in ["Double", "Float", "Int", "UInt8"]:
    lines += assert_by_type(f"Matft.eye(dim: 3, mftype: .{t})", np.eye(3, dtype=NP_DTYPE[t]))
lines += close("Matft.eye(dim: 4, mftype: .Double, mforder: .Column)", np.eye(4))
lines += close("Matft.eye(dim: 1, mftype: .Double)", np.eye(1))
test("eye", lines)

lines = []
for k in [0, 1, -2, 3]:
    lines += equal(f"Matft.diag(v: [1, -2, 3], k: {k})", np.diag([1, -2, 3], k))
    lines += equal(f"Matft.diag(v: [1, -2, 3], k: {k}, mforder: .Column)", np.diag([1, -2, 3], k))
    lines += close(f"Matft.diag(v: x, k: {k}, mforder: .Column)", np.diag(V, k), layout="V")
    lines += close(f"Matft.diag(v: x, k: {k})", np.diag(V, k), layout="V")
lines += close("Matft.diag(v: [1.5, 2.5], mftype: .Float)", np.diag(np.array([1.5, 2.5], np.float32)))
lines += equal("Matft.diag(v: x, k: -1)", np.diag(AI[0], -1), layout="AI[0]")
lines += close("Matft.diag(v: x, mforder: .Column)", np.diag(V), layout="V")
lines += close("Matft.diag(v: x, k: 1, mftype: .Double)", np.diag(AI[0], 1).astype(np.float64), layout="AI[0]")
lines += close("Matft.diag(v: x, mftype: .Float)", np.diag(V).astype(np.float32), layout="V")
test("diag", lines)

lines = []
lines += equal("Matft.nums(7, shape: [2, 3])", np.full((2, 3), 7))
lines += close("Matft.nums(2.5, shape: [2, 3], mftype: .Float)", np.full((2, 3), 2.5, np.float32))
lines += close("Matft.nums(-1.25, shape: [3, 1, 2], mforder: .Column)", np.full((3, 1, 2), -1.25))
lines += equal("Matft.nums(300, shape: [2], mftype: .UInt8)", np.full(2, 300).astype(np.uint8))
lines += equal("Matft.nums(true, shape: [2, 2])", np.full((2, 2), True))
lines += close("Matft.nums_like(3, mfarray: A)", np.full_like(A, 3))
lines += equal("Matft.nums_like(3.7, mfarray: AI)", np.full_like(AI, 3.7))
lines += equal("Matft.nums_like(-3.7, mfarray: AI)", np.full_like(AI, -3.7))
lines += equal("Matft.nums_like(-1, mfarray: U8)", np.full_like(U8, np.uint8(255)))  # numpy 2 rejects -1 for uint8; -1 wraps to 255
lines += close("Matft.nums_like(0.1, mfarray: AF)", np.full_like(AF, 0.1))
test("nums", lines)

# ---------- empty / zero-length ----------
lines = []
for order in ["Row", "Column"]:
    e30 = swift_array(np.zeros((3, 0)), "Double", order)
    e203 = swift_array(np.zeros((2, 0, 3)), "Double", order)
    z30, z203 = np.zeros((3, 0)), np.zeros((2, 0, 3))
    lines += close(f"{e30}.reshape([0, 3])", z30.reshape(0, 3))
    lines += close(f"Matft.transpose({e203})", np.transpose(z203))
    lines += close(f"Matft.transpose({e203}, axes: [1, 2, 0])", np.transpose(z203, (1, 2, 0)))
    lines += close(f"Matft.expand_dims({e30}, axis: 1)", np.expand_dims(z30, 1))
    lines += close(f"Matft.squeeze(Matft.expand_dims({e30}, axis: 0))", np.squeeze(np.expand_dims(z30, 0)))
    lines += close(f"Matft.broadcast_to({e30}, shape: [2, 3, 0])", np.broadcast_to(z30, (2, 3, 0)))
    lines += close(f"{e203}.flatten()", z203.ravel())
    lines += close(f"{e203}.flatten(.Column)", z203.ravel(order="F"))
    lines += close(f"Matft.flip({e203})", np.flip(z203))
    lines += close(f"Matft.swapaxes({e203}, axis1: 0, axis2: 2)", np.swapaxes(z203, 0, 2))
    lines += close(f"Matft.clip({e30}, min: 0, max: 1)", np.clip(z30, 0, 1))
    lines += close(f"{e30}.astype(.Float)", z30.astype(np.float32))
    lines += equal(f"{e30}.astype(.Int)", z30.astype(np.int64))
    lines += close(f"Matft.sort({e30}, axis: 0)", np.sort(z30, 0))
    lines += close(f"Matft.roll({e30}, shift: 1)", np.roll(z30, 1))
    lines += close(f"Matft.concatenate([{e30}, A2], axis: 1)", np.concatenate([z30, A2], 1))
    lines += close(f"Matft.concatenate([A2, {e30}, A2], axis: -1)", np.concatenate([A2, z30, A2], -1))
    lines += close(f"Matft.concatenate([{swift_array(np.zeros((0, 4)), 'Double', order)}, A], axis: 0)",
                   np.concatenate([np.zeros((0, 4)), A], 0))
    lines += close(f"Matft.concatenate([{e203}, {e203}], axis: 1)", np.concatenate([z203, z203], 1))
# the type of an empty array comes from the Swift element type (np.array([], dtype=...)); untyped [] is float64 like np.array([])
for order in ["Row", "Column"]:
    for swift_t, np_t in [("Double", np.float64), ("Float", np.float32), ("Int", np.int64), ("Bool", np.bool_),
                          ("UInt8", np.uint8), ("Int16", np.int16)]:
        lines += assert_by_type(f"MfArray([] as [{swift_t}], shape: [3, 0], mforder: .{order})", np.zeros((3, 0), np_t))
    lines += close(f"MfArray([] as [Any], shape: [0, 2], mforder: .{order})", np.array([]).reshape(0, 2))
lines += equal("MfArray([1, 255] as [UInt8])", np.array([1, 255], np.uint8))
lines += equal("MfArray([-1, 2] as [Int8], shape: [2, 1])", np.array([[-1], [2]], np.int8))
lines += close("Matft.nums(1.0, shape: [0, 3])", np.full((0, 3), 1.0))
lines += close("Matft.diag(v: [] as [Double])", np.diag(np.zeros(0)))
lines += close("Matft.take(A, indices: MfArray([] as [Int], mftype: .Int, shape: [0]), axis: 1)", np.take(A, np.zeros(0, int), axis=1))
lines += close("Matft.append(V, values: MfArray([] as [Double], mftype: .Double, shape: [0]))", np.append(V, np.zeros(0)))
test("empty_arrays", lines)

# ---------- complex ----------
lines = []
for name, mft in [("Z", "Double"), ("ZF", "Float")]:
    z = CINPUTS[name][0]
    other = "Float" if mft == "Double" else "Double"
    lines += zclose(f"{name}.astype(.{other})", z.astype(np.complex64 if other == "Float" else np.complex128), other)
    lines += zclose(f"{name}.astype(.{mft}, mforder: .Column)", z, mft)
    lines += zclose(f"Matft.deepcopy({name})", z, mft)
    lines += zclose(f"{name}.to_contiguous(mforder: .Column)", z, mft)
    lines += zclose(f"{name}.reshape([3, 2])", z.reshape(3, 2), mft)
    lines += zclose(f"Matft.reshape({name}, newshape: [3, 2], order: .Column)", z.reshape((3, 2), order="F"), mft)
    lines += zclose(f"{name}.T", z.T, mft)
    lines += zclose(f"{name}.T.flatten()", z.T.ravel(), mft)
    lines += zclose(f"{name}.flatten(.Column)", z.ravel(order="F"), mft)
    lines += zclose(f"Matft.flip({name}, axis: 1)", np.flip(z, 1), mft)
    lines += zclose(f"Matft.swapaxes({name}, axis1: 0, axis2: 1)", np.swapaxes(z, 0, 1), mft)
    lines += zclose(f"Matft.expand_dims({name}, axis: 1)", np.expand_dims(z, 1), mft)
    lines += zclose(f"Matft.broadcast_to({name}[1~<2], shape: [2, 3])", np.broadcast_to(z[1:2], (2, 3)), mft)
    # a view that doesn't start at 0 / doesn't cover the whole storage
    lines += zclose(f"{name}[1~<2].flatten()", z[1:2].ravel(), mft)
    lines += zclose(f"{name}[1~<2].to_contiguous(mforder: .Column)", z[1:2], mft)
    lines += zclose(f"{name}[Matft.all, ~<<-1].astype(.{other})", z[:, ::-1].astype(np.complex64 if other == "Float" else np.complex128), other)
test("complex", lines)


# ---------- write ----------
with open(OUT, "w") as f:
    f.write(f"// Generated by python/{os.path.basename(__file__)} (numpy {np.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write(f"/// {DOC}\n")
    f.write(f"final class {CLASS}: XCTestCase {{\n")
    for name, (a, mftype) in INPUTS.items():
        f.write(f"    private let {name} = {swift_array(a, mftype)}\n")
    for name, (z, mftype) in CINPUTS.items():
        f.write(f"    private let {name} = {swift_complex(z, mftype)}\n")
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
