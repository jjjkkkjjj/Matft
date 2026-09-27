"""Generate Tests/MatftTests/EmptyManipulationCoverageTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_empty_manipulation_coverage.py

Arrays with a zero-length dimension through conversion, manipulation, indexing, linalg, fft, audio and interpolation.
Every case is a Swift expression and the numpy expression computing its expected value (shape, dtype and values).
Cases taking `x` run over `emptyVariants(shape, mftype)`: row major, column major, a transposed view and an offset view
(a view of a non-empty array that starts at a non-zero offset), so a kernel reading `storedSize` elements or the base
buffer shows up as a wrong size or as garbage. Cases taking a non-empty `x` run over `layoutVariants`.
Elementwise ops, math, reductions, stats, sort, search, set operations and creation are in EmptyArrayTest.swift and its
generator. Setter mutation and view identity are in EmptyViewSetterTest.swift.
Where numpy raises, the case is not generated; those are listed in RAISES (printed when the generator runs).
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "EmptyManipulationCoverageTest.swift")
CLASS = "EmptyManipulationCoverageTests"
DOC = ("Empty arrays (zero-length dimensions) through conversion, manipulation, indexing, linalg, fft, audio and interpolation, "
       "over dtypes and memory layouts (`emptyVariants`). Expected values are numpy outputs")

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
RAISES = []  # (numpy expression, error) : not generated


def test(name, lines, wasi_skip=False):
    TESTS.append((name, lines, wasi_skip))


def variants(shape, mftype):
    return f"emptyVariants({list(shape)}, .{mftype})"


def _loop(layout, assertion):
    if layout is None:
        return [assertion]
    it = layout if layout.startswith("emptyVariants") else f"layoutVariants({layout})"
    return [f"for (name, x) in {it}{{", f"    {assertion}", "}"]


def _label(swift, layout):
    if layout is None:
        return swift_escape(swift)
    tag = layout.replace("emptyVariants(", "").replace(")", "") if layout.startswith("emptyVariants") else layout
    return swift_escape(f"{swift} [{tag}]") + " \\(name)"


def close(swift, expected, mftype=None, layout=None):
    """Values, shape and mftype (mftype defaults to numpy's result dtype). Exact for integer / bool results"""
    mftype = mftype or mftype_of(expected)
    if mftype in INT_TYPES + ("Bool",):
        tol = "rtol: 0, atol: 0"
    elif mftype == "Float":
        tol = "rtol: 1e-5, atol: 1e-5"
    else:
        tol = "rtol: 1e-10, atol: 1e-10"
    return _loop(layout, f"XCTAssertClose({swift}, {swift_array(expected, mftype)}, {tol}, checkType: true, \"{_label(swift, layout)}\")")


def shape(swift, expected_shape, layout=None):
    return _loop(layout, f"XCTAssertEqual(({swift}).shape, {list(expected_shape)}, \"{_label(swift, layout)}\")")


def empty_storage(swift, layout=None):
    """A new array made from an empty one must not hold any elements (a kernel copying `storedSize` elements of a view would)"""
    return _loop(layout, f"XCTAssertEqual(({swift}).data.count, 0, \"{_label(swift, layout)} data\")")


def ref(fn, desc):
    """numpy result, or None when numpy raises (recorded in RAISES and not generated)"""
    try:
        with warnings.catch_warnings(), np.errstate(all="ignore"):
            warnings.simplefilter("ignore")
            return fn()
    except Exception as e:  # noqa: BLE001
        RAISES.append((desc, f"{type(e).__name__}: {e}"))
        return None


def zeros(shape, mftype):
    return np.zeros(shape, NP_DTYPE[mftype])


def typed(swift, fn, shp, types):
    """`swift` over `types` (the input mftype) and their emptyVariants. When numpy's results are empty arrays of one shape
    whose dtype is the input's (or one fixed dtype), a single Swift loop over the types is written; otherwise one loop per type"""
    results = {}
    for t in types:
        r = ref(lambda: fn(zeros(shp, t)), f"{swift} of np.zeros({shp}, {t})")
        if r is None:
            return []
        results[t] = np.asarray(r)
    dts = {t: mftype_of(r) for t, r in results.items()}
    shapes = {r.shape for r in results.values()}
    if len(shapes) == 1 and all(r.size == 0 and r.ndim > 0 for r in results.values()):
        if all(dts[t] == t for t in types):
            mt = "t"
        elif len(set(dts.values())) == 1:
            mt = "." + next(iter(dts.values()))
        else:
            mt = None
        if mt:
            tl = ", ".join("." + t for t in types)
            label = swift_escape(f"{swift} [{shp}]") + " \\(t) \\(name)"
            return [f"for t in [{tl}] as [MfType]{{",
                    f"    for (name, x) in emptyVariants({list(shp)}, t){{",
                    f"        XCTAssertClose({swift}, MfArray([] as [Double], mftype: {mt}, shape: {list(next(iter(shapes)))}), rtol: 0, atol: 0, checkType: true, \"{label}\")",
                    "    }", "}"]
    out = []
    for t in types:
        out += close(swift, results[t], layout=variants(shp, t))
    return out


def typed_storage(exprs, shp, types):
    """New arrays made from an empty one of each type hold no elements (`exprs`: one or more Swift expressions of x)"""
    exprs = [exprs] if isinstance(exprs, str) else exprs
    tl = ", ".join("." + t for t in types)
    body = [f"        XCTAssertEqual(({e}).data.count, 0, \"{swift_escape(f'{e} [{shp}]')} \\(t) \\(name) data\")" for e in exprs]
    return [f"for t in [{tl}] as [MfType]{{", f"    for (name, x) in emptyVariants({list(shp)}, t){{"] + body + ["    }", "}"]


SHAPES = [[0], [3, 0], [0, 4], [2, 0, 3]]
TYPES = ["Double", "Float", "Int", "UInt8", "Bool"]

# ---------- non-empty inputs ----------
BASE = [[3, -1, 4, 1], [5, 9, -2, 6], [5, 3, 5, 8]]
A = inp("A", BASE, "Double")
AI8 = inp("AI8", BASE, "Int8")
A3 = inp("A3", np.arange(24).reshape(2, 3, 4) - 7, "Double")
V = inp("V", [7, -3, 0, 2], "Double")
R14 = inp("R14", [[1, 2, 3, 4]], "Double")
C31 = inp("C31", [[1], [2], [3]], "Double")
EI = inp("EI", np.zeros(0, np.int64), "Int")            # an empty index array
EI2 = inp("EI2", np.zeros((0, 2), np.int64), "Int")     # an empty 2-d index array
M00 = inp("M00", np.zeros((0, 0)), "Double")           # a 0x0 matrix
M200 = inp("M200", np.zeros((2, 0, 0)), "Double")      # a stack of 0x0 matrices


# ---------- conversion: astype / copies over every dtype pair ----------
lines = []
for shp in SHAPES:
    for dst in TYPES:
        lines += typed(f"x.astype(.{dst})", lambda z: z.astype(NP_DTYPE[dst]), shp, TYPES)
test("astype", lines)

lines = []
for shp in SHAPES:
    lines += typed("x", lambda z: z, shp, TYPES)
    lines += typed("x.to_contiguous(mforder: .Row)", lambda z: z, shp, TYPES)
    lines += typed("x.to_contiguous(mforder: .Column)", lambda z: z, shp, TYPES)
    lines += typed("Matft.deepcopy(x)", lambda z: z.copy(), shp, TYPES)
    lines += typed("Matft.deepcopy(x, order: .Column)", lambda z: z.copy(order="F"), shp, TYPES)
    lines += typed("x.flatten()", lambda z: z.ravel(), shp, TYPES)
    lines += typed("x.flatten(.Column)", lambda z: z.ravel(order="F"), shp, TYPES)
    lines += typed_storage(["Matft.deepcopy(x)", "x.to_contiguous(mforder: .Row)", "x.to_contiguous(mforder: .Column)",
                            "x.astype(.Double)", "x.astype(.Float)", "x.flatten()"], shp, TYPES)
test("copies", lines)


# ---------- shape manipulation ----------
lines = []
RESHAPES = {
    (0,): [[0], [0, 3], [3, 0, 2], [-1], [2, -1]],
    (3, 0): [[0], [0, 3], [-1], [5, -1], [3, 0, 1]],
    (0, 4): [[4, 0], [-1, 4], [2, -1], [0, 2, 2]],
    (2, 0, 3): [[0, 6], [6, 0], [-1, 3], [2, -1, 3], [0]],
}
# numpy can't infer -1 when the other dimensions contain 0 (e.g. np.zeros((3, 0)).reshape(0, -1)): a precondition in Matft
ref(lambda: np.zeros((3, 0)).reshape(0, -1), "np.zeros((3, 0)).reshape(0, -1)")
SHAPE_TYPES = ["Double", "Int", "Bool"]
for shp in SHAPES:
    for ns in RESHAPES[tuple(shp)]:
        lines += typed(f"x.reshape({ns})", lambda z: z.reshape(ns), shp, SHAPE_TYPES)
    lines += typed("x.T", lambda z: z.T, shp, SHAPE_TYPES)
    lines += typed("Matft.expand_dims(x, axis: 0)", lambda z: np.expand_dims(z, 0), shp, SHAPE_TYPES)
    lines += typed("Matft.expand_dims(x, axis: -1)", lambda z: np.expand_dims(z, -1), shp, SHAPE_TYPES)
    lines += typed("Matft.expand_dims(x, axes: [0, 2])", lambda z: np.expand_dims(z, (0, 2)), shp, SHAPE_TYPES)
    lines += typed("Matft.flip(x)", lambda z: np.flip(z), shp, SHAPE_TYPES)
    lines += typed("Matft.flip(x, axis: 0)", lambda z: np.flip(z, 0), shp, SHAPE_TYPES)
    lines += typed("Matft.flip(x, axis: -1)", lambda z: np.flip(z, -1), shp, SHAPE_TYPES)
    lines += typed("Matft.squeeze(x)", lambda z: np.squeeze(z), shp, SHAPE_TYPES)
    if len(shp) >= 2:
        lines += typed("Matft.transpose(x, axes: nil)", lambda z: np.transpose(z), shp, SHAPE_TYPES)
        lines += typed("Matft.swapaxes(x, axis1: 0, axis2: -1)", lambda z: np.swapaxes(z, 0, -1), shp, SHAPE_TYPES)
        lines += typed("Matft.moveaxis(x, src: 0, dst: -1)", lambda z: np.moveaxis(z, 0, -1), shp, SHAPE_TYPES)
        lines += typed("x.T.flatten()", lambda z: z.T.ravel(), shp, SHAPE_TYPES)
        lines += typed("x.T.to_contiguous(mforder: .Row)", lambda z: z.T, shp, SHAPE_TYPES)
    if len(shp) == 3:
        lines += typed("Matft.transpose(x, axes: [1, 2, 0])", lambda z: np.transpose(z, (1, 2, 0)), shp, SHAPE_TYPES)
        lines += typed("Matft.moveaxis(x, src: [0, 1], dst: [2, 0])", lambda z: np.moveaxis(z, [0, 1], [2, 0]), shp, SHAPE_TYPES)
test("shape_manipulation", lines)

lines = []
# size-1 axes around an empty axis
Z1 = inp("Z1", np.zeros((1, 0, 1)), "Double")
lines += close("Matft.squeeze(Z1)", np.squeeze(np.zeros((1, 0, 1))))
lines += close("Matft.squeeze(Z1, axis: 0)", np.squeeze(np.zeros((1, 0, 1)), 0))
lines += close("Matft.squeeze(Z1, axis: -1)", np.squeeze(np.zeros((1, 0, 1)), -1))
lines += close("Matft.squeeze(Z1, axes: [0, 2])", np.squeeze(np.zeros((1, 0, 1)), (0, 2)))
test("squeeze_around_empty", lines)

lines = []
# broadcasting into and out of empty shapes
Z10 = inp("Z10", np.zeros((1, 0)), "Double")
lines += close("Matft.broadcast_to(x, shape: [3, 0])", np.broadcast_to(np.zeros(0), (3, 0)), layout=variants([0], "Double"))
lines += close("Matft.broadcast_to(x, shape: [2, 0, 4])", np.broadcast_to(np.zeros((0, 4)), (2, 0, 4)), layout=variants([0, 4], "Double"))
lines += close("Matft.broadcast_to(x, shape: [2, 3, 0])", np.broadcast_to(np.zeros((3, 0)), (2, 3, 0)), layout=variants([3, 0], "Double"))
lines += close("Matft.broadcast_to(Z10, shape: [3, 0])", np.broadcast_to(np.zeros((1, 0)), (3, 0)))
lines += close("Matft.broadcast_to(R14, shape: [0, 4])", np.broadcast_to(R14, (0, 4)))
lines += close("Matft.broadcast_to(C31, shape: [3, 0])", np.broadcast_to(C31, (3, 0)))
lines += close("Matft.broadcast_to(C31, shape: [2, 3, 0])", np.broadcast_to(C31, (2, 3, 0)))
lines += close("Matft.broadcast_to(R14, shape: [0, 4]).T", np.broadcast_to(R14, (0, 4)).T)
lines += close("Matft.broadcast_to(C31, shape: [3, 0]).to_contiguous(mforder: .Column)", np.broadcast_to(C31, (3, 0)))
lines += empty_storage("Matft.broadcast_to(C31, shape: [3, 0]).to_contiguous(mforder: .Row)")
lines += close("Matft.broadcast_to(x[1~<2], shape: [0, 4])", np.broadcast_to(A[1:2], (0, 4)), layout="A")
lines += close("Matft.broadcast_to(x[Matft.all, 1~<2], shape: [3, 0])", np.broadcast_to(A[:, 1:2], (3, 0)), layout="A")
test("broadcast_to", lines)

lines = []
# clip / roll keep the shape and the dtype
for shp in SHAPES:
    lines += typed("x.clip(min: 0.0, max: 1.0)", lambda z: np.clip(z, 0, 1).astype(z.dtype), shp, ["Double", "Float"])
    lines += typed("x.clip(min: 0, max: 1)", lambda z: np.clip(z, 0, 1), shp, ["Int", "UInt8"])
    for expr, fn in [("Matft.roll(x, shift: 1)", lambda z: np.roll(z, 1)),
                     ("Matft.roll(x, shift: -3, axis: 0)", lambda z: np.roll(z, -3, axis=0)),
                     ("Matft.roll(x, shift: 2, axis: -1)", lambda z: np.roll(z, 2, axis=-1))]:
        lines += typed(expr, fn, shp, ["Double", "Float", "Int", "UInt8"])
    lines += typed_storage("Matft.roll(x, shift: 1)", shp, ["Double", "Float", "Int", "UInt8"])
test("clip_roll", lines)


# ---------- joining ----------
lines = []
# empty operands are dropped from the result, but they still take part in the dtype
for t in ["Double", "Int8", "UInt8"]:
    z04 = zeros([0, 4], t)
    lay = variants([0, 4], t)
    lines += close("Matft.concatenate([x, A], axis: 0)", np.concatenate([z04, A], axis=0), layout=lay)
    lines += close("Matft.concatenate([A, x, A], axis: 0)", np.concatenate([A, z04, A], axis=0), layout=lay)
    lines += close("Matft.concatenate([x, AI8], axis: 0)", np.concatenate([z04, AI8], axis=0), layout=lay)
    lines += close("Matft.concatenate([x, x], axis: 0)", np.concatenate([z04, z04], axis=0), layout=lay)
    lines += close("Matft.concatenate([x, x], axis: 1)", np.concatenate([z04, z04], axis=1), layout=lay)
    lines += close("Matft.concatenate([x, x], axis: -1)", np.concatenate([z04, z04], axis=-1), layout=lay)
    lines += close("Matft.vstack([x, A])", np.vstack([z04, A]), layout=lay)
    lines += close("Matft.vstack([x, x])", np.vstack([z04, z04]), layout=lay)
    z30 = zeros([3, 0], t)
    lay = variants([3, 0], t)
    lines += close("Matft.concatenate([A, x], axis: 1)", np.concatenate([A, z30], axis=1), layout=lay)
    lines += close("Matft.concatenate([x, AI8, x], axis: -1)", np.concatenate([z30, AI8, z30], axis=-1), layout=lay)
    lines += close("Matft.concatenate([x, x], axis: 0)", np.concatenate([z30, z30], axis=0), layout=lay)
    lines += close("Matft.hstack([x, A])", np.hstack([z30, A]), layout=lay)
    lines += close("Matft.hstack([x, x])", np.hstack([z30, z30]), layout=lay)
    z203 = zeros([2, 0, 3], t)
    lay = variants([2, 0, 3], t)
    lines += close("Matft.concatenate([x, A3.transpose(axes: [0, 2, 1])], axis: 1)", np.concatenate([z203, np.transpose(A3, (0, 2, 1))], axis=1), layout=lay)
    lines += close("Matft.concatenate([x, x], axis: 2)", np.concatenate([z203, z203], axis=2), layout=lay)
    z0 = zeros([0], t)
    lay = variants([0], t)
    lines += close("Matft.concatenate([x, V], axis: 0)", np.concatenate([z0, V]), layout=lay)
    lines += close("Matft.hstack([V, x])", np.hstack([V, z0]), layout=lay)
    lines += close("Matft.hstack([x, x])", np.hstack([z0, z0]), layout=lay)
test("concatenate_stack", lines)

lines = []
for shp in SHAPES:
    z = zeros(shp, "Double")
    lay = variants(shp, "Double")
    lines += close("Matft.append(x, values: V)", np.append(z, V), layout=lay)
    lines += close("Matft.append(x, value: 2.5)", np.append(z, 2.5), layout=lay)
    lines += close("Matft.append(V, values: x)", np.append(V, z), layout=lay)
    lines += close("Matft.append(x, values: x, axis: 0)", np.append(z, z, axis=0), layout=lay)
    lines += close("Matft.append(x, values: x, axis: -1)", np.append(z, z, axis=-1), layout=lay)
    lines += close("Matft.insert(x, indices: [0], value: 5.0)", np.insert(z, [0], 5.0), layout=lay)
lines += close("Matft.append(x, values: A, axis: 0)", np.append(np.zeros((0, 4)), A, axis=0), layout=variants([0, 4], "Double"))
lines += close("Matft.append(A, values: x, axis: 1)", np.append(A, np.zeros((3, 0)), axis=1), layout=variants([3, 0], "Double"))
lines += close("Matft.insert(x, indices: [0], values: R14, axis: 0)", np.insert(np.zeros((0, 4)), [0], R14, axis=0), layout=variants([0, 4], "Double"))
lines += close("Matft.insert(x, indices: [0, 0], value: 7.0, axis: 0)", np.insert(np.zeros((0, 4)), [0, 0], 7.0, axis=0), layout=variants([0, 4], "Double"))
lines += close("Matft.insert(x, indices: [0], value: 7.0, axis: 1)", np.insert(np.zeros((3, 0)), [0], 7.0, axis=1), layout=variants([3, 0], "Double"))
lines += close("Matft.insert(x, indices: [0], value: 7.0, axis: 0)", np.insert(np.zeros((3, 0)), [0], 7.0, axis=0), layout=variants([3, 0], "Double"))
lines += close("Matft.insert(x, indices: [0], value: 7, axis: 1)", np.insert(zeros([2, 0, 3], "Int"), [0], 7, axis=1), layout=variants([2, 0, 3], "Int"))
test("append_insert", lines)

lines = []
# take with empty indices and from empty arrays
lines += close("Matft.take(x, indices: EI, axis: 0)", np.take(A, EI, axis=0), layout="A")
lines += close("Matft.take(x, indices: EI, axis: 1)", np.take(A, EI, axis=1), layout="A")
lines += close("Matft.take(x, indices: EI2, axis: -1)", np.take(A, EI2, axis=-1), layout="A")
lines += close("Matft.take(x, indices: EI)", np.take(A, EI), layout="A")
lines += close("Matft.take(x, indices: EI2)", np.take(A, EI2), layout="A")
lines += close("Matft.take(x, indices: MfArray([0, 2, 0]), axis: 0)", np.take(np.zeros((3, 0)), [0, 2, 0], axis=0), layout=variants([3, 0], "Double"))
lines += close("Matft.take(x, indices: MfArray([[1], [2]]), axis: 0)", np.take(zeros([3, 0], "Int"), [[1], [2]], axis=0), layout=variants([3, 0], "Int"))
lines += close("Matft.take(x, indices: EI, axis: 0)", np.take(np.zeros((0, 4)), EI, axis=0), layout=variants([0, 4], "Double"))
lines += close("Matft.take(x, indices: EI, axis: 1)", np.take(np.zeros((3, 0)), EI, axis=1), layout=variants([3, 0], "Double"))
lines += close("Matft.take(x, indices: EI)", np.take(np.zeros((2, 0, 3)), EI), layout=variants([2, 0, 3], "Double"))
ref(lambda: np.take(np.zeros((0, 4)), [0], axis=0), "np.take(np.zeros((0, 4)), [0], axis=0)")
test("take", lines)

lines = []
# pad an empty array with a constant (the other modes raise in numpy)
for shp in SHAPES:
    z = zeros(shp, "Double")
    lay = variants(shp, "Double")
    lines += close("Matft.pad(x, pad_width: 1, constant_values: 7)", np.pad(z, 1, constant_values=7).astype(np.float64), layout=lay)
    widths = [(1, 2)] + [(0, 1)] * (len(shp) - 1)
    lines += close(f"Matft.pad(x, pad_width: {widths})", np.pad(z, widths), layout=lay)
    for mode in ["edge", "reflect", "symmetric", "wrap"]:
        r = ref(lambda: np.pad(z, 1, mode=mode), f"np.pad(np.zeros({shp}), 1, mode='{mode}')")
        if r is not None:
            lines += close(f"Matft.pad(x, pad_width: 1, mode: .{mode})", r, layout=lay)
# the non-empty axes can use every mode when the empty axis is not padded
for mode in ["edge", "reflect", "symmetric", "wrap"]:
    lines += close(f"Matft.pad(x, pad_width: [(0, 0), (2, 1)], mode: .{mode})", np.pad(np.zeros((0, 4)), [(0, 0), (2, 1)], mode=mode), layout=variants([0, 4], "Double"))
lines += close("Matft.pad(x, pad_width: 2, constant_values: 1)", np.pad(zeros([3, 0], "Int"), 2, constant_values=1), layout=variants([3, 0], "Int"))
lines += close("Matft.pad(x, pad_width: 1)", np.pad(zeros([0, 4], "Bool"), 1), layout=variants([0, 4], "Bool"))
test("pad", lines)

lines = []
# diff of empty arrays and meshgrid with an empty vector
for shp in [[3, 0], [0, 4], [2, 0, 3]]:
    z = zeros(shp, "Double")
    lay = variants(shp, "Double")
    for axis in range(len(shp)):
        for n in [1, 2]:
            r = ref(lambda: np.diff(z, n=n, axis=axis), f"np.diff(np.zeros({shp}), n={n}, axis={axis})")
            if r is not None:
                lines += close(f"Matft.diff(x, n: {n}, axis: {axis})", r, layout=lay)
lines += close("Matft.diff(x)", np.diff(zeros([3, 0], "Int")), layout=variants([3, 0], "Int"))
ref(lambda: np.diff(np.zeros(0)), "np.diff(np.zeros(0))")
for ix in ["xy", "ij"]:
    gx, gy = np.meshgrid(np.zeros(0), V, indexing=ix)
    lines += close(f"Matft.meshgrid(x, V, indexing: .{ix})[0]", gx, layout=variants([0], "Double"))
    lines += close(f"Matft.meshgrid(x, V, indexing: .{ix})[1]", gy, layout=variants([0], "Double"))
    gx, gy = np.meshgrid(V, np.zeros(0), indexing=ix)
    lines += close(f"Matft.meshgrid(V, x, indexing: .{ix})[0]", gx, layout=variants([0], "Double"))
    lines += close(f"Matft.meshgrid(V, x, indexing: .{ix})[1]", gy, layout=variants([0], "Double"))
test("diff_meshgrid", lines)


# ---------- indexing: getters ----------
lines = []
# non-empty arrays -> empty results
lines += close("x[2~<2]", A[2:2], layout="A")
lines += close("x[3~<1]", A[3:1], layout="A")
lines += close("x[10~<]", A[10:], layout="A")
lines += close("x[Matft.all, 4~<]", A[:, 4:], layout="A")
lines += close("x[Matft.all, 1~<1]", A[:, 1:1], layout="A")
lines += close("x[0~<0, 1~<3]", A[0:0, 1:3], layout="A")
lines += close("x[1, 5~<]", A[1, 5:], layout="A")
lines += close("x[1~<1, 2]", A[1:1, 2], layout="A")
lines += close("x[1~<1, Matft.newaxis]", A[1:1, np.newaxis], layout="A")
lines += close("x[1~<1][Matft.reverse]", A[1:1][::-1], layout="A")
lines += close("x[EI]", A[EI], layout="A")
lines += close("x[EI2]", A[EI2], layout="A")
lines += close("x[EI, EI]", A[EI, EI], layout="A")
lines += close("x[Matft.all, EI]", A[:, EI], layout="A")
lines += close("x[1~<, EI]", A[1:, EI], layout="A")
lines += close("x[x > 100]", A[A > 100], layout="A")
lines += close("x[MfArray([false, false, false])]", A[np.array([False, False, False])], layout="A")
lines += close("x[2~<2].T", A[2:2].T, layout="A")
lines += close("x[Matft.all, 4~<].to_contiguous(mforder: .Column)", A[:, 4:], layout="A")
lines += close("x[Matft.all, 4~<].flatten()", A[:, 4:].ravel(), layout="A")
lines += empty_storage("x[Matft.all, 4~<].flatten()", layout="A")
lines += empty_storage("Matft.deepcopy(x[1~<1])", layout="A")
lines += close("x[1~<1, 1~<, 2~<]", A3[1:1, 1:, 2:], layout="A3")
lines += close("x[Matft.all, 2~<2, Matft.all]", A3[:, 2:2, :], layout="A3")
lines += close("x[Matft.all, Matft.all, EI]", A3[:, :, EI], layout="A3")
lines += close("x[x < -100]", A3[A3 < -100], layout="A3")
test("getters_to_empty", lines)

lines = []
# getters on empty arrays
GT = ["Double", "Int", "Bool"]
GETTERS = {
    (3, 0): [("x[0~<]", lambda z: z[0:]), ("x[1~<]", lambda z: z[1:]), ("x[Matft.reverse]", lambda z: z[::-1]),
             ("x[~<~<-1, Matft.all]", lambda z: z[::-1, :]), ("x[1] as! MfArray", lambda z: z[1]),
             ("x[-1] as! MfArray", lambda z: z[-1]), ("x[Matft.newaxis]", lambda z: z[np.newaxis]),
             ("x[Matft.all, Matft.newaxis]", lambda z: z[:, np.newaxis]),
             ("x[MfArray([0, 2, -1])]", lambda z: z[np.array([0, 2, -1])]),
             ("x[MfArray([[0], [2]])]", lambda z: z[np.array([[0], [2]])]), ("x[EI]", lambda z: z[EI]),
             ("x[x.astype(.Bool)]", lambda z: z[z.astype(bool)]),
             ("x[MfArray([true, false, true])]", lambda z: z[np.array([True, False, True])])],
    (0, 4): [("x[Matft.all, 1~<3]", lambda z: z[:, 1:3]), ("x[Matft.all, 2]", lambda z: z[:, 2]),
             ("x[Matft.all, Matft.reverse]", lambda z: z[:, ::-1]), ("x[EI]", lambda z: z[EI]),
             ("x[Matft.all, MfArray([3, 0])]", lambda z: z[:, np.array([3, 0])]),
             ("x[x.astype(.Bool)]", lambda z: z[z.astype(bool)])],
    (2, 0, 3): [("x[1] as! MfArray", lambda z: z[1]), ("x[Matft.all, Matft.all, 2]", lambda z: z[:, :, 2]),
                ("x[MfArray([1, 0])]", lambda z: z[np.array([1, 0])]),
                ("x[Matft.all, Matft.all, MfArray([2, 0])]", lambda z: z[:, :, np.array([2, 0])]),
                ("x[x.astype(.Bool)]", lambda z: z[z.astype(bool)])],
    (0,): [("x[0~<]", lambda z: z[0:]), ("x[Matft.reverse]", lambda z: z[::-1]), ("x[EI]", lambda z: z[EI]),
           ("x[x.astype(.Bool)]", lambda z: z[z.astype(bool)])],
}
for shp, cases in GETTERS.items():
    for expr, fn in cases:
        lines += typed(expr, fn, list(shp), GT)
test("getters_on_empty", lines)


# ---------- indexing: setters ----------
def setter(target, assign, expected, layout):
    """`target` (an expression of x) = `assign`, then compare x with numpy's result"""
    label = _label(f"{target} = {assign}", layout)
    mft = mftype_of(expected)
    tol = "rtol: 0, atol: 0" if mft in INT_TYPES + ("Bool",) else "rtol: 1e-10, atol: 1e-10"
    it = layout if layout.startswith("emptyVariants") else f"layoutVariants({layout})"
    return [f"for (name, x) in {it}{{",
            f"    {target} = {assign}",
            f"    XCTAssertClose(x, {swift_array(expected, mft)}, {tol}, checkType: true, \"{label}\")",
            "}"]


def after(a, fn):
    a = a.copy()
    fn(a)
    return a


lines = []
# empty selections of non-empty arrays: nothing changes
lines += setter("x[2~<2]", "MfArray([5.0])", A, "A")
lines += setter("x[2~<2]", "MfArray([] as [Double], mftype: .Double, shape: [0, 4])", A, "A")
lines += setter("x[Matft.all, 4~<]", "MfArray([5.0])", A, "A")
lines += setter("x[Matft.all, 4~<]", "MfArray([] as [Double], mftype: .Double, shape: [3, 0])", A, "A")
lines += setter("x[Matft.all, 4~<]", "MfArray([] as [Double], mftype: .Double, shape: [0])", A, "A")
lines += setter("x[1, 5~<]", "MfArray([5.0])", A, "A")
lines += setter("x[x > 100]", "MfArray([5.0])", A, "A")
lines += setter("x[MfArray([false, false, false])]", "MfArray([5.0])", A, "A")
lines += setter("x[EI]", "MfArray([5.0])", A, "A")
lines += setter("x[EI]", "MfArray([] as [Double], mftype: .Double, shape: [0, 4])", A, "A")
lines += setter("x[EI, EI]", "MfArray([5.0])", A, "A")
lines += setter("x[Matft.all, EI]", "MfArray([5.0])", A, "A")
lines += setter("x[1~<, EI]", "MfArray([5.0])", A, "A")
lines += setter("x[1~<1, 1~<, 2~<]", "MfArray([5.0])", A3, "A3")
lines += setter("x[x < -100]", "MfArray([5.0])", A3, "A3")
# a non-empty selection next to an empty one still works
lines += setter("x[Matft.all, 4~<]", "MfArray([5.0])", A, "A")
lines += setter("x[1~<2]", "MfArray([5.0])", after(A, lambda a: a.__setitem__(slice(1, 2), 5.0)), "A")
test("setters_empty_selection", lines)

lines = []
# setters on empty arrays: nothing is written (and nothing outside the view either)
for t in ["Double", "Int"]:
    for shp in SHAPES:
        z = zeros(shp, t)
        lay = variants(shp, t)
        one = "MfArray([1.0])" if t == "Double" else "MfArray([1])"
        lines += setter("x[0~<]", one, z, lay)
        lines += setter("x[Matft.reverse]", one, z, lay)
        lines += setter("x[x.astype(.Bool)]", one, z, lay)
        lines += setter("x[EI]", one, z, lay)
        lines += setter("x[0~<]", f"MfArray([] as [Double], mftype: .{t}, shape: {shp})", z, lay)
    lines += setter("x[1]", "MfArray([] as [Double], mftype: .Double, shape: [0])", zeros([3, 0], t), variants([3, 0], t))
    lines += setter("x[MfArray([0, 2])]", "MfArray([1.0])", zeros([3, 0], t), variants([3, 0], t))
    lines += setter("x[Matft.all, MfArray([0, 2])]", "MfArray([1.0])", zeros([0, 4], t), variants([0, 4], t))
    lines += setter("x[Matft.all, 1~<3]", "MfArray([1.0, 2.0])", zeros([0, 4], t), variants([0, 4], t))
test("setters_on_empty", lines)


# ---------- linalg ----------
lines = []
# matmul / dot / inner with a zero-length contracted axis give zeros; other zero axes give empty results
Z30 = inp("Z30", np.zeros((3, 0)), "Double")
Z04 = inp("Z04", np.zeros((0, 4)), "Double")
Z03 = inp("Z03", np.zeros((0, 3)), "Double")
Z40 = inp("Z40", np.zeros((4, 0)), "Double")
Z0 = inp("Z0", np.zeros(0), "Double")
Z230 = inp("Z230", np.zeros((2, 3, 0)), "Double")
Z204 = inp("Z204", np.zeros((2, 0, 4)), "Double")
A34F = inp("A34F", BASE, "Float")
for t in ["Double", "Float"]:
    z30, z04 = zeros([3, 0], t), zeros([0, 4], t)
    lines += close("Matft.matmul(x, Z04.astype(x.mftype))", np.matmul(z30, z04), layout=variants([3, 0], t))
    lines += close("Matft.matmul(Z30.astype(x.mftype), x)", np.matmul(z30, z04), layout=variants([0, 4], t))
    lines += close("Matft.dot(x, Z04.astype(x.mftype))", np.dot(z30, z04), layout=variants([3, 0], t))
    lines += close("Matft.inner(x, Z40.astype(x.mftype))", np.inner(z30, np.zeros((4, 0), NP_DTYPE[t])), layout=variants([3, 0], t))
lines += close("Matft.matmul(x, A)", np.matmul(np.zeros((0, 3)), A), layout=variants([0, 3], "Double"))
lines += close("Matft.matmul(A.T, x)", np.matmul(A.T, np.zeros((3, 0))), layout=variants([3, 0], "Double"))
# (Matft.matmul needs 2-d operands, so numpy's 1-d matmul isn't covered)
lines += close("Matft.dot(x, Z0)", np.dot(np.zeros(0), np.zeros(0)).reshape(1), layout=variants([0], "Double"))
lines += close("Matft.inner(x, Z0)", np.inner(np.zeros(0), np.zeros(0)).reshape(1), layout=variants([0], "Double"))
lines += close("Matft.matmul(Z230, x)", np.matmul(np.zeros((2, 3, 0)), np.zeros((2, 0, 4))), layout=variants([2, 0, 4], "Double"))
lines += close("Matft.matmul(x, Z204)", np.matmul(np.zeros((2, 3, 0)), np.zeros((2, 0, 4))), layout=variants([2, 3, 0], "Double"))
lines += close("Matft.matmul(x, A34F)", np.matmul(np.zeros((0, 3), np.float32), A34F), layout=variants([0, 3], "Float"))
lines += close("Matft.matmul(x, Z04.astype(.Int))", np.matmul(zeros([3, 0], "Int"), zeros([0, 4], "Int")), layout=variants([3, 0], "Int"))
lines += close("Matft.cross(x, Z03)", np.cross(np.zeros((0, 3)), np.zeros((0, 3))), layout=variants([0, 3], "Double"))
test("matmul", lines)

lines = []
# norms of empty vectors and matrices (sums are 0; ord ±inf / 0 reduce with max / min / count)
for shp in [[0], [3, 0], [0, 4]]:
    z = np.zeros(shp)
    lay = variants(shp, "Double")
    for ordv in [2, 1, 3]:
        r = ref(lambda: np.linalg.norm(z, ord=ordv, axis=-1), f"np.linalg.norm(np.zeros({shp}), ord={ordv}, axis=-1)")
        if r is not None:
            r = np.asarray(r)
            lines += close(f"Matft.linalg.normlp_vec(x, ord: {ordv})", r if r.ndim else r.reshape(1), layout=lay)
    for ordv in ["inf", "-inf", "0"]:
        o = {"inf": np.inf, "-inf": -np.inf, "0": 0}[ordv]
        r = ref(lambda: np.linalg.norm(z, ord=o, axis=-1), f"np.linalg.norm(np.zeros({shp}), ord={ordv}, axis=-1)")
        if r is not None:
            r = np.asarray(r)
            sw = {"inf": "Float.infinity", "-inf": "-Float.infinity", "0": "0"}[ordv]
            lines += close(f"Matft.linalg.normlp_vec(x, ord: {sw})", r if r.ndim else r.reshape(1), layout=lay)
for shp in [[3, 0], [0, 4], [2, 0, 3]]:
    z = np.zeros(shp)
    lay = variants(shp, "Double")
    r = np.linalg.norm(z, ord="fro", axis=(-2, -1))
    r = np.asarray(r)
    lines += close("Matft.linalg.normfro_mat(x)", r if r.ndim else r.reshape(1), layout=lay)
    for ordv in [1, -1, "inf"]:
        o = np.inf if ordv == "inf" else ordv
        r = ref(lambda: np.linalg.norm(z, ord=o, axis=(-2, -1)), f"np.linalg.norm(np.zeros({shp}), ord={ordv}, axis=(-2, -1))")
        if r is not None:
            r = np.asarray(r)
            sw = "Float.infinity" if ordv == "inf" else ordv
            lines += close(f"Matft.linalg.normlp_mat(x, ord: {sw})", r if r.ndim else r.reshape(1), layout=lay)
test("norm", lines)

lines = []
# LAPACK on 0x0 matrices: numpy returns empty results (det is 1, the empty product)
lines += close("try! Matft.linalg.inv(M00)", np.linalg.inv(np.zeros((0, 0))))
lines += close("try! Matft.linalg.inv(M200)", np.linalg.inv(np.zeros((2, 0, 0))))
lines += close("try! Matft.linalg.det(M00)", np.asarray(np.linalg.det(np.zeros((0, 0)))).reshape(1))
lines += close("try! Matft.linalg.det(M200)", np.linalg.det(np.zeros((2, 0, 0))))
lines += close("try! Matft.linalg.solve(M00, b: Z0)", np.linalg.solve(np.zeros((0, 0)), np.zeros(0)))
lines += close("try! Matft.linalg.solve(M00, b: Z03)", np.linalg.solve(np.zeros((0, 0)), np.zeros((0, 3))))
lines += close("try! Matft.linalg.pinv(Z30)", np.linalg.pinv(np.zeros((3, 0))))
lines += close("try! Matft.linalg.pinv(Z04)", np.linalg.pinv(np.zeros((0, 4))))
lines += close("try! Matft.linalg.pinv(M00)", np.linalg.pinv(np.zeros((0, 0))))
ev = np.linalg.eigvals(np.zeros((0, 0)))
lines += shape("try! Matft.linalg.eigen(M00).valRe", ev.shape)
lines += shape("try! Matft.linalg.eigen(M00).rvecRe", (0, 0))
for name, m in [("M00", np.zeros((0, 0))), ("Z30", np.zeros((3, 0))), ("Z04", np.zeros((0, 4)))]:
    for full in [True, False]:
        u, s, vh = np.linalg.svd(m, full_matrices=full)
        f = "true" if full else "false"
        lines += close(f"try! Matft.linalg.svd({name}, full_matrices: {f}).s", s)
        lines += shape(f"try! Matft.linalg.svd({name}, full_matrices: {f}).v", u.shape)
        lines += shape(f"try! Matft.linalg.svd({name}, full_matrices: {f}).rt", vh.shape)
test("lapack_0x0", lines, wasi_skip=True)


# ---------- fft / audio / interpolation ----------
lines = []
# numpy needs at least one output point, but a zero-length other axis is fine
lines += shape("Matft.fft.rfft(x, axis: 0)", np.fft.rfft(np.zeros((3, 0)), axis=0).shape, layout=variants([3, 0], "Double"))
lines += shape("Matft.fft.rfft(x)", np.fft.rfft(np.zeros((0, 4))).shape, layout=variants([0, 4], "Double"))
lines += shape("Matft.fft.irfft(x)", np.fft.irfft(np.zeros((0, 4))).shape, layout=variants([0, 4], "Double"))
lines += shape("Matft.fft.irfft(x, axis: 0)", np.fft.irfft(np.zeros((3, 0)), axis=0).shape, layout=variants([3, 0], "Double"))
# an empty signal zero-padded to `number` points (Matft convention: pocketFFT always returns .Double, vDSP keeps .Float)
r = np.fft.rfft(np.zeros(0), n=4)
for t in ["Double", "Float"]:
    lines += close("Matft.fft.rfft(x, number: 4).real", r.real, layout=variants([0], t))
    lines += close("Matft.fft.rfft(x, number: 4).imag!", r.imag, layout=variants([0], t))
# a real (non-complex) half spectrum is allowed like numpy
lines += close("Matft.fft.irfft(x)", np.fft.irfft(V), layout="V")
lines += close("Matft.fft.irfft(x, number: 5, axis: 0)", np.fft.irfft(A, n=5, axis=0), layout="A")
ref(lambda: np.fft.rfft(np.zeros(0)), "np.fft.rfft(np.zeros(0))")
ref(lambda: np.fft.irfft(np.zeros(0)), "np.fft.irfft(np.zeros(0))")
test("fft", lines)

lines = []
# vDSP (unavailable on WASI) keeps .Float
r = np.fft.rfft(np.zeros(0), n=4)
for t in ["Double", "Float"]:
    lines += close("Matft.fft.rfft(x, number: 4, vDSP: true).real", r.real.astype(NP_DTYPE[t]), layout=variants([0], t))
    lines += close("Matft.fft.rfft(x, number: 4, vDSP: true).imag!", r.imag.astype(NP_DTYPE[t]), layout=variants([0], t))
lines += shape("Matft.fft.rfft(x, axis: 0, vDSP: true)", np.fft.rfft(np.zeros((4, 0)), axis=0).shape, layout=variants([4, 0], "Float"))
test("fft_vDSP", lines, wasi_skip=True)

lines = []
for t in ["Double", "Float"]:
    lines += close("Matft.audio.pad_or_trim(x, length: 5)", np.zeros(5, NP_DTYPE[t]), layout=variants([0], t))
    lines += close("Matft.audio.pad_or_trim(x, length: 3)", np.zeros((0, 3), NP_DTYPE[t]), layout=variants([0, 4], t))
    lines += close("Matft.audio.pad_or_trim(x, length: 2, axis: 0)", np.zeros((2, 0), NP_DTYPE[t]), layout=variants([3, 0], t))
lines += close("Matft.audio.pad_or_trim(x, length: 0)", A[:, :0], layout="A")
lines += close("Matft.audio.pad_or_trim(x, length: 0, axis: 0)", A[:0], layout="A")
lines += close("Matft.audio.pad_or_trim(x, length: 0)", V[:0], layout="V")
test("audio_pad_or_trim", lines)

lines = []
XP = inp("XP", [0, 1, 2, 3], "Double")
FP = inp("FP", [10, -1, 4, 0], "Double")
# Matft convention: interp always returns .Float
for t in ["Double", "Float"]:
    lines += close("Matft.interp(x, xp: XP, fp: FP)", np.interp(np.zeros(0), XP, FP).astype(np.float32), layout=variants([0], t))
lines += close("Matft.interp(x, xp: XP, fp: FP)", np.interp(np.zeros((3, 0)), XP, FP).astype(np.float32), layout=variants([3, 0], "Double"))
ref(lambda: np.interp(V, np.zeros(0), np.zeros(0)), "np.interp(x, xp=[], fp=[])")
test("interp", lines)


# ---------- complex ----------
lines = []
for t in ["Double", "Float"]:
    for shp in [[3, 0], [0, 4]]:
        mk = f"MfArray(real: MfArray([] as [Double], mftype: .{t}, shape: {shp}), imag: MfArray([] as [Double], mftype: .{t}, shape: {shp}))"
        lines += ["do {", f"    let z = {mk}", f"    XCTAssertTrue(z.isComplex, \"{swift_escape(mk)}\")"]
        for expr, s in [("z.T", shp[::-1]), ("Matft.deepcopy(z)", shp), ("z.to_contiguous(mforder: .Column)", shp),
                        ("z.flatten()", [0]), ("z.reshape([-1])", [0]), ("z[Matft.reverse]", shp),
                        ("z.astype(.Double)", shp),
                        ("-z", shp), ("z + z", shp)]:
            lines += [f"    XCTAssertEqual(({expr}).shape, {s}, \"{swift_escape(expr)} {t} {shp}\")",
                      f"    XCTAssertTrue(({expr}).isComplex, \"{swift_escape(expr)} {t} {shp}\")"]
        lines += ["}"]
test("complex", lines, wasi_skip=True)  # complex arithmetic is unavailable on WASI

lines = []
# complex fancy indexing (unavailable on WASI)
for t in ["Double", "Float"]:
    mk = f"MfArray(real: MfArray([] as [Double], mftype: .{t}, shape: [3, 0]), imag: MfArray([] as [Double], mftype: .{t}, shape: [3, 0]))"
    lines += ["do {", f"    let z = {mk}",
              f"    XCTAssertEqual(z[MfArray([0, 2])].shape, [2, 0], \"complex fancy {t}\")",
              f"    XCTAssertEqual(z[EI].shape, [0, 0], \"complex empty fancy {t}\")",
              "}"]
    zc = f"MfArray(real: A.astype(.{t}), imag: (A * 2).astype(.{t}))"
    lines += ["do {", f"    let z = {zc}",
              f"    XCTAssertEqual(z[EI].shape, [0, 4], \"complex empty fancy of non-empty {t}\")",
              f"    XCTAssertEqual(z[Matft.all, EI].shape, [3, 0], \"complex empty fancy axis 1 {t}\")",
              "}"]
test("complex_fancy", lines, wasi_skip=True)


# ---------- write ----------
HELPER = '''
    /// The same empty array in different memory layouts: row major, column major, a transposed view,
    /// and an offset view (`1~<1` of a non-empty base moved to the zero-length axis, so the view doesn't start at 0)
    private func emptyVariants(_ shape: [Int], _ mftype: MfType) -> [(name: String, array: MfArray)] {
        let k = shape.firstIndex(of: 0)!
        var baseShape = shape
        baseShape.remove(at: k)
        baseShape.insert(3, at: 0)
        let base = Matft.arange(start: 0, to: baseShape.reduce(1, *), by: 1, shape: baseShape).astype(mftype)
        return [
            ("row", MfArray([] as [Double], mftype: mftype, shape: shape)),
            ("column", MfArray([] as [Double], mftype: mftype, shape: shape, mforder: .Column)),
            ("transposed view", MfArray([] as [Double], mftype: mftype, shape: shape.reversed()).T),
            ("offset view", Matft.moveaxis(base[1~<1], src: 0, dst: k)),
        ]
    }
'''

with open(OUT, "w") as f:
    f.write(f"// Generated by python/{os.path.basename(__file__)} (numpy {np.__version__}). Do not edit by hand.\n")
    f.write("import XCTest\n\nimport Matft\n\n")
    f.write(f"/// {DOC}\n")
    f.write(f"final class {CLASS}: XCTestCase {{\n")
    for name, (a, mftype) in INPUTS.items():
        f.write(f"    private let {name} = {swift_array(a, mftype)}\n")
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
print("numpy raises (not generated):")
for desc, err in RAISES:
    print(f"  {desc}: {err}")
