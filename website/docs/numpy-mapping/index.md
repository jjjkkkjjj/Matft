---
title: NumPy Mapping
slug: /numpy-mapping
---

# NumPy Mapping

The list of Matft's functions and their counterparts in Numpy (and Scipy, OpenCV, librosa, PIL / transformers).
Almost all functions have the same names and behaviors as Numpy's, and use the Accelerate framework inside.

## Legend

| Column | Meaning |
| --- | --- |
| **Method** ✓ | The method version exists too, e.g. `a.shallowcopy()` as well as `Matft.shallowcopy(a)` where `a` is an `MfArray`. |
| **Method** only | Only the method version exists, e.g. `a.toArray()`, **not** `Matft.toArray(a)`. |
| **Complex** ✓ | Supports complex arrays. |

For the exact signatures, see the **API Reference** in the navbar.

## Categories

- [Creation](./creation.md) — `arange`, `eye`, `concatenate`, window functions, …
- [Conversion and Search](./conversion.md) — `astype`, `transpose`, `reshape`, `sort`, `unique`, `where`, `histogram`, …
- [Operation](./operation.md) — arithmetic / comparison operators and ufunc reduction
- [Math](./math.md) — `sin`, `exp`, `round`, `isnan`, complex functions, …
- [Statistics](./stats.md) — `mean`, `std`, `median`, `nan*`, `cov`, …
- [Linear Algebra](./linalg.md) — `solve`, `inv`, `eig`, `svd`, `lstsq`, norms, …
- [FFT and Audio](./fft-and-audio.md) — `rfft`, `stft`, mel spectrogram, …
- [Interpolation](./interpolation.md) — `interp`, `polyfit`, `interp1d`, …
- [Image](./image.md) — OpenCV and PIL / transformers compatible functions
- [File and Random](./file-and-random.md) — `loadtxt`, `savetxt`, `random.rand`, …
