# Test viewpoints for Matft

Go through every section for the function under test. Mark each **cover** (with concrete cases) or **N/A**
(with a reason). The "Why" lines are the bugs that motivated the viewpoint — use them to judge relevance.

## Contents
1. Values and boundaries
2. dtype (types)
3. Shape, axis and keepDims
4. Memory layout and views
5. Special floating values (NaN, ±inf, -0.0)
6. Empty and degenerate arrays
7. Broadcasting and scalar operands
8. Parameters and options
9. Complex numbers
10. Mutation, aliasing and returned views
11. Agreement with NumPy (output contract)
12. Platform (x86_64, WASI, iOS)
13. Performance
14. Regression

---

## 1. Values and boundaries

- Zero, ±1, small negatives, values straddling a threshold (for comparisons, `clip`, `digitize`, `searchsorted`: exactly on the edge, just below via `nextDown`, just above via `nextUp`).
- Ties and duplicates (sort stability, argmax picks the first, unique/counts, median of an even count).
- Already sorted / reverse sorted / constant input (histogram of all-equal values uses `[v-0.5, v+0.5]`).
- Domain boundaries of math functions: `log(0)`, `sqrt(-1)`, `arcsin(1+ε)`, `power(0, 0)`, `0/0`, `x/0` with sign.
- Integer boundaries per type: `Int8` −128/127, `UInt8` 0/255, `Int16`, `UInt16` 65535, `UInt32` 2^32−1; results that overflow must wrap like numpy (`(a - b)` of UInt8 → 251).
- Magnitude: values above 2^24 in Float storage (precision loss is expected; use `.Double` or assert the documented behaviour), very large/small Double (1e308, 5e-324) for overflow to inf / underflow.
- Size boundaries of kernels: 1 element, sizes around internal block sizes (e.g. conversion kernels process 1024-element blocks → 1023, 1024, 1025), odd sizes for FFT, sizes that are not a multiple of SIMD width.

*Why:* integer wrap relied on vDSP conversions that saturate on x86_64; block-based kernels break at block edges.

## 2. dtype (types)

- Run the same logical input in at least: `.Float`, `.Double`, one signed int (`.Int`), one small unsigned int (`.UInt8`), and `.Bool` when meaningful. Add complex if the function accepts it (§9).
- **Output dtype** must equal numpy's: `np.result_type`, `np.mean(int) -> float64`, `argmax -> int`, comparisons `-> bool`. Assert `mftype` (or `checkType: true`) and compute it in Python. For Float inputs numpy gives float32 — cast the expected value with `.astype(np.float32)` and use Float tolerances.
- Mixed-type binary ops: Int + Float, UInt8 + Int8 (→ Int16), UInt64 + signed (→ Double), Bool + Int, Float + Double.
- `astype` round trips where the function converts internally (e.g. a kernel that only exists for Float).
- Scalars of a different type than the array (`intArray + 0.5`, `floatArray * 2`).

*Why:* integer arrays are stored as Float, so kernels written for Float silently return the wrong dtype or skip wrapping.

## 3. Shape, axis and keepDims

- ndim 1, 2, 3 (and ≥4 if the function has a generic N-d path; `PerfFixtures.a` is 6-d).
- Every axis including negative ones (`axis: -1`), and `axis: nil` / all axes (Matft returns shape `[1]`).
- `keepDims: true/false`; the output shape assertion is as important as the values.
- Non-square shapes so that swapped dimensions are detected (use 3×4, not 3×3).
- Shapes with size-1 dimensions (`[1, n]`, `[n, 1]`), which hit broadcasting and squeeze paths.

## 4. Memory layout and views

- Loop over `layoutVariants(input)`: contiguous, column-major, offset view, prefix view, strided view, reversed view, transposed view. Expected values must not depend on the layout.
- Views that do not start at 0 or do not cover the whole storage (`a[1~<2]`): kernels that use `storedSize` or the start pointer read past the view.
- Result layout: the returned array must be usable (e.g. `to_contiguous`, `.T`, further ops) — chain one op after the function when a kernel writes strides by hand.
- Both operands in different layouts for binary ops (`a + a[Matft.reverse]`, `a.T + b`).

*Why:* `Matft.roll(a[1~<2])` returned 24 elements; several complex kernels read the base buffer.

## 5. Special floating values

- NaN in every row / column, NaN at the first and last position, all-NaN slices (`nanmean` of all-NaN → NaN with a warning in numpy).
- `±inf`, `inf - inf`, `-0.0` (sign of `1/-0.0`, `sign(-0.0)`, `maximum(-0.0, 0.0)`).
- Propagation rules: `max/min/argmax` propagate NaN (numpy returns the first NaN index), `nan*` functions skip it, comparisons with NaN are false, `isnan/isinf/isfinite` on integer arrays are all false/true.
- `XCTAssertClose` treats NaN == NaN and requires inf to match exactly; use it rather than `==`.

*Why:* `vDSP_maxmgv` drops NaN on x86_64.

## 6. Empty and degenerate arrays

- Zero-length dimensions: shapes `[0]`, `[3, 0]`, `[0, 4]`, `[2, 0, 3]`, in Row and Column order. Assert the shape numpy returns (broadcast `[3,0] + [3,1] -> [3,0]`), `data.count == 0`, and that nothing crashes.
- Functions that produce empty output from non-empty input (`diff(n: len)`, `setdiff1d` with everything removed, a mask selecting nothing).
- Reductions of empty input: numpy's value (`sum -> 0`, `prod -> 1`, `max` → error) — test what Matft documents.
- Size-1 arrays and 1×1 matrices.

*Why:* out-of-bounds writes on empty arrays corrupted the heap silently; run suspicious cases under Guard Malloc
(`xcrun lldb --batch -o "env DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib" -o run -o bt -- $(xcrun -f xctest) -XCTest <Class> .build/arm64-apple-macosx/debug/MatftPackageTests.xctest`).

## 7. Broadcasting and scalar operands

- Array–scalar on both sides (`a - 1`, `1 - a`, `12 / a`), array–array with equal shapes, and broadcasting `[3,1]` with `[1,4]`, `[4]` with `[3,4]`.
- Broadcasting combined with a view operand (§4) and a different dtype (§2).
- Incompatible shapes: precondition (not testable) — note it.

## 8. Parameters and options

- Every parameter at its default and at each non-default value; every case of an enum option (e.g. percentile `method: .linear/.lower/.higher/.nearest/.midpoint`, `side: .left/.right`).
- Parameter boundaries: `ddof` = 0, N−1, N, N+1 (numpy gives inf/NaN), `n` = 0 and ≥ length for `diff`, `bins` = 1, `q` = 0 and 100, `shift` negative and larger than the length.
- Array-valued vs scalar-valued versions of the same parameter (`q: 30` vs `q: [0.1, 0.9]`).
- Errors: only for `throws` APIs (`XCTAssertThrowsError`). Singular matrices for `inv`/`solve`.

## 9. Complex numbers

- If the function accepts complex: real and imaginary parts both non-zero and different (so a real/imag mix-up is visible), `ComplexFloat` and `ComplexDouble`, complex ⊕ real, complex views (§4).
- Copy paths: `deepcopy`, `to_contiguous`, `astype` must keep imag.
- Division by a real array (precision), `abs`/`angle`/`conjugate`.

*Why:* `copy_all_mfarray` copied the real part into imag; `zrvdiv` is 1 ulp off on x86_64.

## 10. Mutation, aliasing and returned views

- Does the function return a view or a copy in numpy? Assert the same: writing to the result must (or must not) change the input.
- The input must be unchanged after a non-in-place call (check `rowValues(input)` before/after), including for views of a shared base.
- In-place setters (`a[mask] = v`, `a[1~<3] = b`) on views, transposed arrays, with broadcast values, with a mask selecting nothing/everything.
- Self-aliasing: `a + a`, `a[...] = a.T`.

## 11. Agreement with NumPy (output contract)

For every case, the expected result comes from numpy and matches in all three: **values** (within tolerance),
**shape**, and **dtype**. Also check:

- Ordering of outputs (`unique` sorted, `argsort` stable for ties — numpy's default `quicksort` is not stable; use `kind="stable"` in the generator when Matft's sort is stable, and say so).
- Tuple outputs (`unique_counts`, `histogram`) — assert each element.
- Function and argument names follow numpy (CLAUDE.md naming rule); a test that reads like the numpy call documents the mapping.
- If the other reference is scipy / librosa / OpenCV / PIL (interp1d, audio, image), generate from that library in the same way.

## 12. Platform

- **x86_64**: when the code adds or changes a vDSP call, check out-of-range conversion, NaN handling and precision on Intel:
  `swift build --build-tests --triple x86_64-apple-macosx` then `arch -x86_64 xcrun xctest <bundle>` (CI also has a `macos-15-intel` job).
- **WASI**: code under `#if canImport(Accelerate)` has a pure-Swift fallback. Expected values must be platform independent so both paths are checked by the same test. LAPACK / interp1d / complex fancy indexing are unavailable on WASI — wrap those tests in `#if !os(WASI)`. Run `./scripts/build-and-test-wasm.sh` (~3 min) when the fallback changes.
- **iOS / CoreML**: only for `toMLMultiArray` and similar APIs (`scripts/build-and-test-ios.sh`).

## 13. Performance

Only for hot paths (see SKILL.md step 6). When covered:

- Add `func testPeformance<Name>()` in `Tests/PerformanceTests/<Area>PefTests.swift` (the existing spelling `Peformance` is kept for the benchmark IDs), with inputs from `PerfFixtures` (`a` 1M Float 6-d, `ad` Double, `aneg`, `v`, `m` 256×256, `signal`), wrapped in `self.measureWithWarmup { let _ = ... }`.
- A variant with a non-contiguous input (`a.transpose(axes: [0,3,4,2,1,5])`) if the kernel has a strided path.
- Register it in `CASES` of `scripts/benchmark.py`: `Case("<Class>.<test>", "<Group>", "<swift expr>", "<numpy expr>")`, using the names defined in `SETUP` so both sides measure the same thing. New fixtures go in both `PerfFixtures` and `SETUP`. Nothing checks that the Swift test and the `Case` stay in sync, so double-check the ID matches `<Class>.<method>` exactly.
- Avoid pure-Swift per-element loops in hot paths: they are 10–60× slower at `-Onone`, which is what apps building Matft in debug see. If the implementation has such a loop, measure `--configuration debug` too (benchmark skill).
- Correctness tests stay small; do not put large arrays in `MatftTests` just to exercise performance.

## 14. Regression

- A reported bug becomes a test that reproduces the exact report (input, shape, layout, dtype) plus the neighbouring cases along the viewpoints the fix touches.
- Name the test after the behaviour, not the issue number; put the issue number in a comment.
