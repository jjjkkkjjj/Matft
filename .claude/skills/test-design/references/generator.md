# Writing expected values with a numpy generator

The generators in `python/` turn "Swift expression + numpy expression" pairs into an XCTest file.
This keeps the expected values honest (numpy computed them) and reviewable (both expressions sit on one line).

## Extend or create?

- The function belongs to an area an existing generator covers → add a section to it:
  - numpy-level functions (stats, search, set ops, pad/diff, math, fit, interp) → `python/gen_numpy_gaps_coverage.py`
  - FFT / audio → `python/gen_fft_audio_coverage.py`
  - `Matft.image` (OpenCV / PIL) → `python/gen_image_coverage.py`
- A new area → copy `assets/gen_template.py` (in this skill) to `python/gen_<area>_coverage.py`,
  set `OUT` and the class name, and add a row to the table in `python/README.md`.
  If it needs a new Python package, pin it in `python/requirements-test.txt`.

## Building blocks (same names in the existing generators and the template)

- `inp(name, array, mftype)` — declares an input that becomes `private let <name> = MfArray(...)` in the test class.
  Pick inputs that exercise the viewpoints at once: negatives, ties, a non-square shape (e.g. `A` is 3×4 with ties and negatives,
  `AN` has a NaN in every row, `S` is sorted with duplicates).
- `close(swift, expected, mftype, rtol, atol, layout=None)` — an `XCTAssertClose` line. With `layout="A"`,
  the Swift expression uses `x` and runs over `layoutVariants(A)`.
- `equal(swift, expected, mftype, layout=None)` — an exact comparison for Int / Bool results (`XCTAssertClose` with `rtol: 0, atol: 0, checkType: true`; `MfArray ==` ignores the dtype and wraps integers, so it is not used).
- `test(name, lines)` — groups lines into `func test_<name>()`.
- `swift_array(a, mftype)` converts a numpy array to a Swift literal; 0-d becomes shape `[1]` (Matft's reduction convention).

In the template, `inp` casts the input to the numpy dtype of its MfType, so the reference is computed in that type
(float32 for `.Float`, int64 for `.Int`), and `close` / `equal` take the expected MfType from numpy's result dtype
(`mftype_of`) and assert it (`checkType: true`). A dtype mismatch therefore fails like a value mismatch.
If Matft deliberately returns another type, pass `mftype=` explicitly (and `check_type=False` for `close`) with a comment.
The older generators do not have `mftype_of`; there, cast Float results with `.astype(np.float32)` and pass `mftype`.

## Typical loops

```python
# dtype × axis × layout in a few lines
for src in ["A", "AF", "AI"]:
    a, _ = INPUTS[src]
    for axis in [None, 0, 1, -1]:
        ax = "" if axis is None else f", axis: {axis}"
        lines += close(f"Matft.stats.cumsum(x{ax})", np.cumsum(a, axis=axis), layout=src)
```

Use `warnings.catch_warnings()` / `np.errstate(...)` around cases that warn in numpy (all-NaN slices, 0/0).
Wrap tests that cannot run on WASI with `#if !os(WASI)` when writing the file (see how `fit` is handled
in `gen_numpy_gaps_coverage.py`).

## Run

```sh
.venv/bin/python python/gen_<area>_coverage.py
swift test --filter MatftTests.<GeneratedClass>
```

Commit the generator and the generated file together. Never edit the generated file by hand; change the generator and rerun.
Regenerating all generators with the pinned versions must produce no diff (`python/README.md`).
