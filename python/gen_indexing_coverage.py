"""Generate Tests/MatftTests/IndexingCoverageTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_indexing_coverage.py

Every case is a Swift subscript expression and the numpy indexing computing its expected value.
Cases taking `x` run over `layoutVariants(input)` (row/column major, transposed, offset, prefix, strided and reversed views),
so the expected values must not depend on the memory layout. Setters assign into `x` itself (a fresh array per layout),
which also checks that writes go through strided / negative-stride / offset views.
"""
import os

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "IndexingCoverageTest.swift")
CLASS = "IndexingCoverageTests"
DOC = ("Subscript getters and setters (int, slice, step, all/reverse/newaxis, fancy and boolean indexing) over dtypes, "
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


def ints(values, shape=None):
    """Swift `.Int` index array"""
    a = np.asarray(values, dtype=np.int64)
    return swift_array(a if shape is None else a.reshape(shape), "Int")


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


def _loop(layout, body):
    if layout:
        return [f"for (name, x) in layoutVariants({layout}){{"] + ["    " + b for b in body] + ["}"]
    return body


def equal(swift, expected, mftype=None, layout=None):
    """Exact comparison: values, shape and mftype (not `==`, which ignores the mftype and wraps integers)"""
    mftype = mftype or mftype_of(expected)
    label = swift_escape(swift) + (" \\(name)" if layout else "")
    return _loop(layout, [f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, rtol: 0, atol: 0, checkType: true, \"{label}\")"])


def get(src, index, np_index, cast=""):
    """Getter `x[index]` over the layouts of `src`, compared exactly with numpy's `a[np_index]` (same dtype as the input)"""
    a, mftype = INPUTS[src]
    return equal(f"x[{index}]{cast}", a[np_index], mftype, layout=src)


def setitem(src, stmt, np_set):
    """Setter statement on `x` (a fresh array per layout of `src`), then `x` compared with numpy after `np_set(a)`.
    numpy's `a[...] = array` casts unsafely (wraps / truncates), which is also what Matft's `astype` does"""
    a, mftype = INPUTS[src]
    e = a.copy()
    np_set(e)
    label = swift_escape(stmt) + " \\(name)"
    return _loop(src, [stmt, f"XCTAssertClose(x, {swift_array(e, mftype)}, rtol: 0, atol: 0, checkType: true, \"{label}\")"])


# ---------- inputs ----------
# 3x4 (non-square) with negatives and ties
BASE = [[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]]
A = inp("A", BASE, "Double")
AF = inp("AF", BASE, "Float")
AI = inp("AI", BASE, "Int")
U8 = inp("U8", [[0, 1, 127, 128], [254, 255, 3, 9], [200, 5, 0, 77]], "UInt8")
B = inp("B", [[True, False, False, True], [False, True, True, False], [True, True, False, False]], "Bool")
# 3-d / 4-d for multi-axis and non-adjacent fancy indexing
C = inp("C", np.arange(-12, 12).reshape(2, 3, 4), "Double")
D = inp("D", np.arange(48).reshape(2, 3, 2, 4), "Double")
# 5x4 base for view write-through checks
V = inp("V", np.arange(20).reshape(5, 4), "Double")

# ---------- getters: int / slice / step / special indices ----------
BASIC = [
    ("1", "", (1,), " as! MfArray"),
    ("-1", "", (-1,), " as! MfArray"),
    ("1~<", "", np.s_[1:], ""),
    ("~<-1", "", np.s_[:-1], ""),
    ("(-2)~<", "", np.s_[-2:], ""),
    ("~<<-1", "", np.s_[::-1], ""),
    ("~<<2", "", np.s_[::2], ""),
    ("1~<3, 1~<", "", np.s_[1:3, 1:], ""),
    ("0~<3~<5", "", np.s_[0:3:5], ""),
    ("Matft.all, 1~<4~<2", "", np.s_[:, 1:4:2], ""),
    ("Matft.all, 3~<0~<-1", "", np.s_[:, 3:0:-1], ""),
    ("Matft.all, ~<<-2", "", np.s_[:, ::-2], ""),
    ("Matft.all, 2~<~<-1", "", np.s_[:, 2::-1], ""),
    ("Matft.all, (-1)~<~<-3", "", np.s_[:, -1::-3], ""),
    ("Matft.all, (-2)~<(-4)~<-1", "", np.s_[:, -2:-4:-1], ""),
    # out-of-range bounds are clamped like Python
    ("10~<", "", np.s_[10:], ""),
    ("(-10)~<", "", np.s_[-10:], ""),
    ("~<10", "", np.s_[:10], ""),
    ("Matft.all, ~<-10", "", np.s_[:, :-10], ""),
    ("Matft.all, 4~<~<-1", "", np.s_[:, 4::-1], ""),
    ("Matft.all, 10~<~<-1", "", np.s_[:, 10::-1], ""),
    ("Matft.all, (-10)~<~<-1", "", np.s_[:, -10::-1], ""),
    ("Matft.all, 1~<10~<-1", "", np.s_[:, 1:10:-1], ""),
    ("Matft.all, 10~<(-10)~<-2", "", np.s_[:, 10:-10:-2], ""),
    ("2~<1", "", np.s_[2:1], ""),
    ("Matft.reverse", "", np.s_[::-1], ""),
    ("Matft.all, Matft.reverse", "", np.s_[:, ::-1], ""),
    ("Matft.newaxis", "", np.s_[None], ""),
    ("Matft.all, Matft.newaxis, 1~<", "", np.s_[:, None, 1:], ""),
    ("Matft.newaxis, 2, ~<<-1", "", np.s_[None, 2, ::-1], ""),
    ("1, Matft.newaxis", "", np.s_[1, None], ""),
    ("1, ~<<2", "", np.s_[1, ::2], ""),
    ("Matft.all, -1", "", np.s_[:, -1], ""),
    ("1~<, 2", "", np.s_[1:, 2], ""),
]

lines = []
for index, _, np_index, cast in BASIC:
    lines += get("A", index, np_index, cast)
test("slicing_layouts", lines)

lines = []
for src in ["AF", "AI", "U8", "B"]:
    for index, _, np_index, cast in [BASIC[i] for i in (0, 5, 7, 10, 20, 26, 28)]:
        lines += get(src, index, np_index, cast)
test("slicing_dtypes", lines)

lines = []
for index, np_index, cast in [
    ("1", (1,), " as! MfArray"),
    ("-1, 1", (-1, 1), " as! MfArray"),
    ("Matft.all, 1, Matft.reverse", np.s_[:, 1, ::-1], ""),
    ("Matft.all, Matft.all, 1~<3", np.s_[:, :, 1:3], ""),
    ("-1, ~<<-1, 0", np.s_[-1, ::-1, 0], ""),
    ("Matft.reverse, Matft.newaxis, ~<<2, (-1)~<~<-2", np.s_[::-1, None, ::2, -1::-2], ""),
    ("Matft.all, 5~<", np.s_[:, 5:], ""),
]:
    lines += get("C", index, np_index, cast)
test("slicing_3d", lines)

lines = []
lines += ["XCTAssertEqual(A[1, -1] as! Double, 6.0)",
          "XCTAssertEqual(AF[-1, 0] as! Float, 5.0)",
          "XCTAssertEqual(AI[0, -3] as! Int, -1)",
          "XCTAssertEqual(C[1, -1, 2] as! Double, " + repr(float(C[1, -1, 2])) + ")"]
test("scalar_getter", lines)

# ---------- getters: fancy (integer array) indexing ----------
FANCY = [
    (ints([2, 0, -1, 0]), np.s_[[2, 0, -1, 0]]),
    (ints([1, 0, 2, 2], [2, 2]), np.s_[np.array([[1, 0], [2, 2]])]),
    ("Matft.all, " + ints([3, 0, -1]), np.s_[:, [3, 0, -1]]),
    (ints([0, 2]) + ", " + ints([1, -1]), np.s_[[0, 2], [1, -1]]),
    (ints([0, 2], [2, 1]) + ", " + ints([1, 3, 0]), np.s_[np.array([[0], [2]]), [1, 3, 0]]),
    (ints([2, 0]) + ", 1~<3", np.s_[[2, 0], 1:3]),
    ("1~<, " + ints([3, 1]), np.s_[1:, [3, 1]]),
    ("~<<-1, " + ints([3, 1]), np.s_[::-1, [3, 1]]),
    ("Matft.newaxis, " + ints([2, 0]), np.s_[None, [2, 0]]),
    ("MfArray([] as [Int], mftype: .Int, shape: [0])", np.s_[np.array([], dtype=np.int64)]),
]
lines = []
for index, np_index in FANCY:
    lines += get("A", index, np_index)
for src in ["AF", "AI", "U8", "B"]:
    for index, np_index in [FANCY[0], FANCY[2], FANCY[3]]:
        lines += get(src, index, np_index)
test("fancy_getter", lines)

lines = []
for index, np_index in [
    (ints([1, 0, 1]), np.s_[[1, 0, 1]]),
    ("Matft.all, " + ints([2, 0]), np.s_[:, [2, 0]]),
    ("Matft.all, " + ints([2, 0]) + ", " + ints([1, 3]), np.s_[:, [2, 0], [1, 3]]),
    (ints([1, 0]) + ", Matft.all, " + ints([3, 3]), np.s_[[1, 0], :, [3, 3]]),
    ("Matft.all, Matft.all, " + ints([-1, 0], [2, 1]), np.s_[:, :, np.array([[-1], [0]])]),
    ("Matft.all, " + ints([2, 0], [2, 1]) + ", " + ints([1, 3, 0]), np.s_[:, np.array([[2], [0]]), [1, 3, 0]]),
    # an integer counts as an advanced index: next to the index array it stays in place, apart from it goes first
    ("Matft.all, 1, " + ints([0, 2]), np.s_[:, 1, [0, 2]]),
    ("1, Matft.all, " + ints([0, 2]), np.s_[1, :, [0, 2]]),
]:
    lines += get("C", index, np_index)
# non-adjacent fancy indices after a slice: numpy puts the broadcast index dimensions first
for index, np_index in [
    ("Matft.all, " + ints([0, 2]) + ", Matft.all, " + ints([1, 3]), np.s_[:, [0, 2], :, [1, 3]]),
    ("Matft.all, " + ints([0, 2]) + ", " + ints([1, 0]), np.s_[:, [0, 2], [1, 0]]),
]:
    lines += get("D", index, np_index)
test("fancy_getter_nd", lines)

# ---------- getters: boolean masks ----------
lines = []
for src in ["A", "AF", "AI", "U8"]:
    a, _ = INPUTS[src]
    lines += equal("x[x > 3]", a[a > 3], layout=src)
    lines += equal("x[x > 1000]", a[a > 1000], layout=src)
    lines += equal("x[x >= 0]", a[a >= 0], layout=src)
    lines += get(src, "MfArray([true, false, true])", np.array([True, False, True]))
lines += equal("x[x]", B[B], layout="B")
cmask = (C % 3 == 0)[:, :, 0]
lines += get("C", swift_array(cmask, "Bool"), cmask)
test("bool_getter", lines)

# ---------- setters ----------
S23 = np.array([[10, 20, 30], [40, 50, 60]])
lines = []
for src in ["A", "AF", "AI", "U8", "B"]:
    def st(stmt, fn):
        return setitem(src, stmt, fn)
    if src == "B":
        lines += st("x[1] = MfArray([true])", lambda e: e.__setitem__(1, True))
        lines += st("x[Matft.all, 1~<3] = MfArray([false, true])", lambda e: e.__setitem__(np.s_[:, 1:3], [False, True]))
        lines += st("x[~<<-1, ~<<-2] = MfArray([true])", lambda e: e.__setitem__(np.s_[::-1, ::-2], True))
        continue
    lines += st("x[1] = MfArray([100])", lambda e: e.__setitem__(1, 100))
    lines += st("x[-1] = MfArray([10, 20, 30, 40])", lambda e: e.__setitem__(-1, [10, 20, 30, 40]))
    lines += st("x[Matft.all, 1] = MfArray([7, 8, 9])", lambda e: e.__setitem__(np.s_[:, 1], [7, 8, 9]))
    lines += st("x[Matft.all, 1~<2] = " + swift_array(np.array([[7], [8], [9]]), "Int"),
                lambda e: e.__setitem__(np.s_[:, 1:2], [[7], [8], [9]]))
    lines += st("x[1~<3, 1~<] = " + swift_array(S23, "Int"), lambda e: e.__setitem__(np.s_[1:3, 1:], S23))
    lines += st("x[1~<, ~<<2] = MfArray([1, 2])", lambda e: e.__setitem__(np.s_[1:, ::2], [1, 2]))
    lines += st("x[~<<-1, 3~<0~<-2] = " + swift_array(np.array([[1, 2], [3, 4], [5, 6]]), "Int"),
                lambda e: e.__setitem__(np.s_[::-1, 3:0:-2], [[1, 2], [3, 4], [5, 6]]))
    lines += st("x[Matft.reverse] = " + swift_array(np.arange(12).reshape(3, 4), "Int"),
                lambda e: e.__setitem__(np.s_[::-1], np.arange(12).reshape(3, 4)))
    lines += st("x[Matft.all, 10~<~<-1] = MfArray([77])", lambda e: e.__setitem__(np.s_[:, 10::-1], 77))
    lines += st("x[2~<1] = MfArray([55])", lambda e: e.__setitem__(np.s_[2:1], 55))
    lines += st("x[Matft.all, 1~<10~<-1] = MfArray([55])", lambda e: e.__setitem__(np.s_[:, 1:10:-1], 55))
test("slice_setter", lines)

lines = []
lines += setitem("C", "x[Matft.all, 1, Matft.reverse] = MfArray([1, 2, 3, 4])",
                 lambda e: e.__setitem__(np.s_[:, 1, ::-1], [1, 2, 3, 4]))
lines += setitem("C", "x[-1, ~<<2] = MfArray([100])", lambda e: e.__setitem__(np.s_[-1, ::2], 100))
lines += setitem("C", "x[Matft.all, Matft.all, 1~<3] = " + swift_array(np.array([[-1], [-2], [-3]]), "Int"),
                 lambda e: e.__setitem__(np.s_[:, :, 1:3], [[-1], [-2], [-3]]))
test("slice_setter_3d", lines)

# assigning values of another dtype: numpy casts unsafely (truncation toward zero, wrap-around, nonzero -> true)
lines = []
lines += setitem("AI", "x[0] = MfArray([2.7, -2.7, 0.5, -0.5] as [Double])", lambda e: e.__setitem__(0, np.array([2.7, -2.7, 0.5, -0.5])))
lines += setitem("U8", "x[0] = MfArray([300, -1, 256, 255] as [Int])", lambda e: e.__setitem__(0, np.array([300, -1, 256, 255]).astype(np.uint8)))
lines += setitem("U8", "x[x > 100] = MfArray([300] as [Int])", lambda e: e.__setitem__(e > 100, np.uint8(300 % 256)))
lines += setitem("U8", "x[" + ints([2, 0]) + "] = MfArray([-2] as [Int])", lambda e: e.__setitem__([2, 0], np.uint8(254)))
lines += setitem("B", "x[0] = MfArray([0.0, 2.5, -1, 0] as [Double])", lambda e: e.__setitem__(0, np.array([0.0, 2.5, -1, 0])))
lines += setitem("AF", "x[1, 1~<3] = MfArray([0.1, -1e-3] as [Double])", lambda e: e.__setitem__(np.s_[1, 1:3], np.array([0.1, -1e-3])))
lines += setitem("A", "x[Matft.all, 0] = MfArray([true, false, true])", lambda e: e.__setitem__(np.s_[:, 0], [True, False, True]))
test("setter_dtype_conversion", lines)

# boolean-mask setters
lines = []
for src in ["A", "AF", "AI", "U8"]:
    a, _ = INPUTS[src]
    n = int((a > 3).sum())
    vals = np.arange(1, n + 1) * 10
    lines += setitem(src, "x[x > 3] = MfArray([0])", lambda e: e.__setitem__(e > 3, 0))
    lines += setitem(src, "x[x > 1000] = MfArray([7])", lambda e: e.__setitem__(e > 1000, 7))
    lines += setitem(src, "x[x >= 0] = MfArray([2])", lambda e: e.__setitem__(e >= 0, 2))
    lines += setitem(src, f"x[x > 3] = {swift_array(vals, 'Int')}", lambda e, v=vals: e.__setitem__(e > 3, v))
    lines += setitem(src, "x[MfArray([true, false, true])] = MfArray([1, 2, 3, 4])",
                     lambda e: e.__setitem__(np.array([True, False, True]), [1, 2, 3, 4]))
lines += setitem("B", "x[x] = MfArray([false])", lambda e: e.__setitem__(e.copy(), False))
lines += setitem("C", "x[" + swift_array(cmask, "Bool") + "] = MfArray([-7])", lambda e: e.__setitem__(cmask, -7))
test("bool_setter", lines)

# fancy setters
lines = []
for src in ["A", "AF", "AI"]:
    lines += setitem(src, "x[" + ints([2, 0]) + "] = MfArray([-5])", lambda e: e.__setitem__([2, 0], -5))
    lines += setitem(src, "x[" + ints([-1, 1]) + "] = " + swift_array(np.array([[1, 2, 3, 4], [5, 6, 7, 8]]), "Int"),
                     lambda e: e.__setitem__([-1, 1], [[1, 2, 3, 4], [5, 6, 7, 8]]))
    # duplicated indices: the last assignment wins
    lines += setitem(src, "x[" + ints([0, 0]) + "] = " + swift_array(np.array([[1, 2, 3, 4], [5, 6, 7, 8]]), "Int"),
                     lambda e: e.__setitem__([0, 0], [[1, 2, 3, 4], [5, 6, 7, 8]]))
    lines += setitem(src, "x[" + ints([0, 2]) + ", " + ints([1, -1]) + "] = MfArray([100, 200])",
                     lambda e: e.__setitem__(([0, 2], [1, -1]), [100, 200]))
    lines += setitem(src, "x[" + ints([0, 2], [2, 1]) + ", " + ints([1, 3]) + "] = MfArray([9])",
                     lambda e: e.__setitem__((np.array([[0], [2]]), [1, 3]), 9))
    lines += setitem(src, "x[MfArray([] as [Int], mftype: .Int, shape: [0])] = MfArray([9])",
                     lambda e: e.__setitem__(np.array([], dtype=np.int64), 9))
test("fancy_setter", lines)

# fancy index mixed with slices in a setter
lines = []
lines += setitem("A", "x[Matft.all, " + ints([3, 0]) + "] = MfArray([-1, -2])", lambda e: e.__setitem__(np.s_[:, [3, 0]], [-1, -2]))
lines += setitem("A", "x[1~<, " + ints([2]) + "] = MfArray([50])", lambda e: e.__setitem__(np.s_[1:, [2]], 50))
lines += setitem("C", "x[Matft.all, " + ints([2, 0]) + "] = MfArray([100])", lambda e: e.__setitem__(np.s_[:, [2, 0]], 100))
test("fancy_setter_mixed", lines)

# self-aliasing: numpy copies the right-hand side when it overlaps the destination
lines = []
lines += setitem("A", "x[~<<-1] = x", lambda e: e.__setitem__(np.s_[::-1], e.copy()))
lines += setitem("A", "x[1~<3] = x[0~<2]", lambda e: e.__setitem__(np.s_[1:3], e[0:2].copy()))
lines += setitem("A", "x[0~<2] = x[1~<3]", lambda e: e.__setitem__(np.s_[0:2], e[1:3].copy()))
lines += setitem("A", "x[Matft.all, 1~<] = x[Matft.all, ~<-1]", lambda e: e.__setitem__(np.s_[:, 1:], e[:, :-1].copy()))
lines += setitem("A", "x[Matft.all, ~<3] = x[Matft.all, 1~<]", lambda e: e.__setitem__(np.s_[:, :3], e[:, 1:].copy()))
lines += setitem("A", "x[" + ints([2, 0, 1]) + "] = x", lambda e: e.__setitem__([2, 0, 1], e.copy()))
lines += setitem("A", "x[x > 3] = x[x > 3] * 2", lambda e: e.__setitem__(e > 3, e[e > 3] * 2))
test("setter_self_aliasing", lines)

# ---------- views and copies ----------
lines = []


def view_case(stmts, np_set):
    e = V.copy()
    np_set(e)
    return (["do {", "    let base = V.deepcopy()"] + ["    " + s for s in stmts] +
            [f"    XCTAssertClose(base, {swift_array(e, 'Double')}, rtol: 0, atol: 0, checkType: true, \"{swift_escape(' ; '.join(stmts))}\")", "}"])


# basic slicing returns a view: writing to it changes the base
lines += view_case(["let r = base[1~<3]", "r[0, 0] = MfArray([77])"], lambda e: e.__setitem__((1, 0), 77))
lines += view_case(["let r = base[1] as! MfArray", "r[Matft.reverse] = MfArray([1, 2, 3, 4])"], lambda e: e.__setitem__(1, [4, 3, 2, 1]))
lines += view_case(["let r = base[Matft.newaxis]", "r[0, 2, 1] = MfArray([77])"], lambda e: e.__setitem__((2, 1), 77))
lines += view_case(["let r = base.T", "r[1~<3] = MfArray([-1])"], lambda e: e.__setitem__(np.s_[:, 1:3], -1))
lines += view_case(["let r = base[1~<4, ~<<-1]", "r[r > 10] = MfArray([0])"], lambda e: e[1:4, ::-1].__setitem__(e[1:4, ::-1] > 10, 0))
lines += view_case(["let r = base[~<<2]", "r[" + ints([1]) + "] = MfArray([-3])"], lambda e: e.__setitem__(2, -3))
lines += view_case(["let r = base[1~<4]", "r[Matft.all, 1~<3] = r[Matft.all, 0~<2]"],
                   lambda e: e[1:4].__setitem__(np.s_[:, 1:3], e[1:4, 0:2].copy()))
# fancy and boolean indexing return copies: writing to them does not change the base
lines += view_case(["let r = base[" + ints([1, 2]) + "]", "r[0, 0] = MfArray([77])"], lambda e: None)
lines += view_case(["let r = base[Matft.all, " + ints([1, 2]) + "]", "r[0, 0] = MfArray([77])"], lambda e: None)
lines += view_case(["let r = base[base > 5]", "r[0] = MfArray([77])"], lambda e: None)
# a getter does not change its input
lines += view_case(["_ = base[~<<-1, " + ints([0, 3]) + "]", "_ = base[base > 3]", "_ = base[1~<, ~<<-2]"], lambda e: None)
test("views_and_copies", lines)

# ---------- complex ----------
ZR = np.array(BASE, dtype=np.float64)
ZI = -2 * ZR + 1
Z = ZR + 1j * ZI
ZSWIFT = f"MfArray(real: {swift_array(ZR, 'Double')}, imag: {swift_array(ZI, 'Double')})"


def zequal(swift, expected):
    return [f"do {{", f"    let r = {swift}",
            f"    XCTAssertClose(r.real, {swift_array(expected.real, 'Double')}, rtol: 0, atol: 0, checkType: true, \"real {swift_escape(swift)}\")",
            f"    XCTAssertClose(r.imag!, {swift_array(expected.imag, 'Double')}, rtol: 0, atol: 0, checkType: true, \"imag {swift_escape(swift)}\")", "}"]


def zset(stmt, np_set):
    e = Z.copy()
    np_set(e)
    return ["do {", f"    let z = {ZSWIFT}", f"    {stmt}"] + zequal("z", e)[1:-1] + ["}"]


lines = []
lines += zequal(f"{ZSWIFT}[1~<, ~<<-1]", Z[1:, ::-1])
lines += zequal(f"{ZSWIFT}.T[Matft.all, 2~<0~<-1]", Z.T[:, 2:0:-1])
lines += zequal(f"{ZSWIFT}[Matft.newaxis, -1]", Z[None, -1])
lines += zset("z[1~<, 1~<3] = MfArray([1, 2])", lambda e: e.__setitem__(np.s_[1:, 1:3], [1, 2]))
lines += zset("z[~<<-1, 0] = MfArray(real: MfArray([1.5, 2.5, 3.5] as [Double]), imag: MfArray([-1, -2, -3] as [Double]))",
              lambda e: e.__setitem__(np.s_[::-1, 0], np.array([1.5, 2.5, 3.5]) + 1j * np.array([-1, -2, -3])))
lines += zset("z[z.real > 3] = MfArray(real: MfArray([0.5] as [Double]), imag: MfArray([9] as [Double]))",
              lambda e: e.__setitem__(e.real > 3, 0.5 + 9j))
test("complex_slicing_mask", lines)

lines = []
lines += zequal(f"{ZSWIFT}[{ints([2, 0, -1])}]", Z[[2, 0, -1]])
lines += zequal(f"{ZSWIFT}[{ints([0, 2])}, {ints([1, -1])}]", Z[[0, 2], [1, -1]])
lines += zequal(f"{ZSWIFT}[Matft.all, {ints([3, 0])}]", Z[:, [3, 0]])
lines += zset(f"z[{ints([2, 0])}] = MfArray(real: MfArray([1.5] as [Double]), imag: MfArray([-4] as [Double]))",
              lambda e: e.__setitem__([2, 0], 1.5 - 4j))
lines += zset(f"z[{ints([0, 2])}, {ints([1, -1])}] = MfArray([7, 8])", lambda e: e.__setitem__(([0, 2], [1, -1]), [7, 8]))
test("complex_fancy", lines, wasi_skip=True)


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
