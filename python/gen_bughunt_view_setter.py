"""Generate Tests/MatftTests/BugHuntViewSetterTest.swift from numpy.

Requirements: see python/requirements-test.txt

    .venv/bin/python python/gen_bughunt_view_setter.py

Regression tests for the setter and view bugs found by the 2026-09-27 bug hunt:
- values with extra leading size-1 dimensions assigned through int, slice, bool-mask, fancy and mixed setters
  (numpy drops the leading 1s),
- boolean masks whose shape matches the leading axes (the shape check that rejects the others is a precondition),
- `MfArray(real:imag:)` with a single part that is a view with an offset,
- complex values assigned into real arrays and views (numpy casts them to the real part and keeps the dtype),
- `deepcopy` of a dense, permuted array that is not a view.
Each case runs Swift statements and the same numpy statements, then compares the listed variables
(shape, dtype and values; complex results are compared by their real and imaginary parts).
"""
import os
import warnings

import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "Tests", "MatftTests", "BugHuntViewSetterTest.swift")
CLASS = "BugHuntViewSetterTests"
DOC = "Setter, view and copy regressions found by the 2026-09-27 bug hunt. Expected values are numpy outputs"

NP_DTYPE = {"Bool": np.bool_, "UInt8": np.uint8, "Int8": np.int8, "Int": np.int64, "Float": np.float32, "Double": np.float64}
COMPLEX_PART = {np.complex64: "Float", np.complex128: "Double"}


def mftype_of(a):
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
    a = np.asarray(a)
    shape = list(a.shape) if a.ndim > 0 else [1]
    values = ", ".join(lit(v) for v in a.ravel())
    return f"MfArray([{values}] as [Double], shape: {shape}).astype(.{mftype})"


def checks(name, value):
    """Swift assertions that the Swift variable `name` equals the numpy value"""
    value = np.asarray(value)
    if np.iscomplexobj(value):
        part = COMPLEX_PART[value.dtype.type]
        return [
            f"XCTAssertTrue({name}.isComplex, \"{name} must be complex\")",
            f"XCTAssertClose({name}.real, {swift_array(value.real, part)}, checkType: true)",
            f"XCTAssertClose({name}.imag!, {swift_array(value.imag, part)}, checkType: true)",
        ]
    return [
        f"XCTAssertTrue({name}.isReal, \"{name} must stay real\")",
        f"XCTAssertClose({name}, {swift_array(value, mftype_of(value))}, checkType: true)",
    ]


A34 = "let a = Matft.arange(start: 0.0, to: 12.0, by: 1.0, shape: [3, 4], mftype: .Double)"
PY_A34 = "a = np.arange(12.0).reshape(3, 4)"
Z = "MfArray(real: MfArray([7.5] as [Double]), imag: MfArray([8.0] as [Double]))"

# (test name, Swift statements, numpy statements, compared variables)
CASES = [
    # leading size-1 dimensions of the assigned value
    ("LeadingOnes_IntIndex", [A34, "a[0] = MfArray([[1.0, 2, 3, 4]] as [[Double]])"],
     [PY_A34, "a[0] = np.array([[1.0, 2, 3, 4]])"], ["a"]),
    ("LeadingOnes_Slice", [A34, "a[0~<2] = MfArray([[[9.0]]] as [[[Double]]])"],
     [PY_A34, "a[0:2] = np.array([[[9.0]]])"], ["a"]),
    ("LeadingOnes_SliceRow", [A34, "a[1~<3] = MfArray([[[1.0, 2, 3, 4]]] as [[[Double]]])"],
     [PY_A34, "a[1:3] = np.array([[[1.0, 2, 3, 4]]])"], ["a"]),
    ("LeadingOnes_Fancy", [A34, "a[MfArray([0, 2])] = MfArray([[[1.0, 2, 3, 4]]] as [[[Double]]])"],
     [PY_A34, "a[[0, 2]] = np.array([[[1.0, 2, 3, 4]]])"], ["a"]),
    ("LeadingOnes_FancyAll", [A34, "a[MfArray([0, 2]), MfArray([1, 3])] = MfArray([[[5.0, 6.0]]] as [[[Double]]])"],
     [PY_A34, "a[[0, 2], [1, 3]] = np.array([[[5.0, 6.0]]])"], ["a"]),
    ("LeadingOnes_FancyMixed", [A34, "a[1~<, MfArray([0, 2])] = MfArray([[[7.0, 8.0]]] as [[[Double]]])"],
     [PY_A34, "a[1:, [0, 2]] = np.array([[[7.0, 8.0]]])"], ["a"]),
    ("LeadingOnes_BoolMask", [A34, "a[MfArray([true, false, true])] = MfArray([[[1.0, 2, 3, 4]]] as [[[Double]]])"],
     [PY_A34, "a[[True, False, True]] = np.array([[[1.0, 2, 3, 4]]])"], ["a"]),
    # boolean masks matching the leading axes
    ("BoolMask_LeadingAxisGet", [A34, "let r = a[MfArray([false, true, true])]"],
     [PY_A34, "r = a[[False, True, True]]"], ["r"]),
    ("BoolMask_FullShapeGetOnView", [A34, "let v = a[0~<, Matft.reverse]", "let r = v[v > 6]"],
     [PY_A34, "v = a[:, ::-1]", "r = v[v > 6]"], ["r"]),
    ("BoolMask_LeadingAxisSetOnView", [A34, "let v = a.T", "v[MfArray([true, false, false, true])] = MfArray([0.5, 1.5, 2.5] as [Double])"],
     [PY_A34, "v = a.T", "v[[True, False, False, True]] = [0.5, 1.5, 2.5]"], ["a"]),
    # a single part given to MfArray(real:imag:) as a view with an offset
    ("ComplexInit_ImagOnlyOffsetView", [A34, "let z = MfArray(real: nil, imag: a[1~<2])"],
     [PY_A34, "z = 1j * a[1:2]"], ["z"]),
    ("ComplexInit_RealOnlyOffsetView", [A34, "let z = MfArray(real: a[1~<2], imag: nil)"],
     [PY_A34, "z = a[1:2] + 0j"], ["z"]),
    ("ComplexInit_ImagOnlyStridedView", [A34, "let z = MfArray(real: nil, imag: a[0~<, 1~<4~<2])"],
     [PY_A34, "z = 1j * a[:, 1:4:2]"], ["z"]),
    # complex values assigned into real arrays and views are cast to the real part
    ("ComplexIntoReal_NestedView", [A34, "let v = a[1~<]", "let w = v[0~<, 1~<]", f"w[0, 0] = {Z}"],
     [PY_A34, "v = a[1:]", "w = v[:, 1:]", "w[0, 0] = Z[0]"], ["a", "v", "w"]),
    ("ComplexIntoReal_IntArray", ["let a = MfArray([1, 2, 3])", f"a[0] = {Z}"],
     ["a = np.array([1, 2, 3])", "a[0] = Z[0]"], ["a"]),
    ("ComplexIntoReal_Slice", [A34, f"a[0~<2] = {Z}"],
     [PY_A34, "a[0:2] = Z"], ["a"]),
    ("ComplexIntoReal_BoolMask", [A34, f"a[a > 8] = {Z}"],
     [PY_A34, "a[a > 8] = Z"], ["a"]),
    ("ComplexIntoReal_Fancy", [A34, f"a[MfArray([0, 2])] = {Z}"],
     [PY_A34, "a[[0, 2]] = Z"], ["a"]),
    ("ComplexIntoReal_FancyAll", [A34, f"a[MfArray([0, 2]), MfArray([1, 3])] = {Z}"],
     [PY_A34, "a[[0, 2], [1, 3]] = Z"], ["a"]),
    ("ComplexIntoRealPart_OfComplex",
     ["let z = MfArray(real: MfArray([1.0, 2.0] as [Double]), imag: MfArray([3.0, 4.0] as [Double]))", f"let r = z.real", f"r[0] = {Z}"],
     ["z = np.array([1 + 3j, 2 + 4j])", "r = z.real", "r[0] = Z[0]"], ["z"]),
    # deepcopy of a dense permuted array that is not a view
    ("Deepcopy_DensePermutedNonView",
     ["let p = Matft.arange(start: 0.0, to: 24.0, by: 1.0, shape: [2, 3, 4], mftype: .Double).transpose(axes: [0, 2, 1]) + 1", "let c = p.deepcopy()", "p[0, 0, 0] = MfArray([100.0] as [Double])"],
     ["p = np.arange(24.0).reshape(2, 3, 4).transpose(0, 2, 1) + 1", "c = p.copy()", "p[0, 0, 0] = 100.0"], ["c", "p"]),
]


def main():
    lines = [
        "// Generated by python/gen_bughunt_view_setter.py. Do not edit by hand.",
        "import XCTest",
        "",
        "import Matft",
        "",
        f"/// {DOC}",
        f"final class {CLASS}: XCTestCase {{",
    ]
    for name, swift, py, compared in CASES:
        env = {"np": np, "Z": np.array([7.5 + 8j])}  # the complex value `Z` of the Swift cases
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", np.exceptions.ComplexWarning)
            exec("\n".join(py), env)
        lines.append(f"    func test{name}() {{")
        lines += [f"        {s}" for s in swift]
        for var in compared:
            lines += [f"        {c}" for c in checks(var, env[var])]
        lines.append("    }")
        lines.append("")
    lines[-1] = "}"
    with open(OUT, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {len(CASES)} cases to {os.path.normpath(OUT)}")


if __name__ == "__main__":
    main()
