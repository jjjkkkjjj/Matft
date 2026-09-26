- Arithmetic

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a+aneg` | `99.5μs` | `a+aneg` | `197μs` | 0.51x |
| `let _ = b+aT` | `1.55ms` | `b+aT` | `869μs` | **1.78x** |
| `let _ = c+aT` | `1.54ms` | `c+aT` | `861μs` | **1.79x** |

- Math

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = Matft.math.sin(a)` | `310μs` | `np.sin(a)` | `2.85ms` | 0.11x |
| `let _ = Matft.math.sin(b)` | `3.23ms` | `np.sin(b)` | `2.81ms` | **1.15x** |
| `let _ = Matft.math.sign(a)` | `1.98ms` | `np.sign(a)` | `128μs` | **15.52x** |
| `let _ = Matft.math.sign(b)` | `2.52ms` | `np.sign(b)` | `129μs` | **19.59x** |

- Bool

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a > 0` | `2.92ms` | `a > 0` | `70.8μs` | **41.19x** |
| `let _ = a > b` | `5.50ms` | `a > b` | `386μs` | **14.25x** |
| `let _ = a === 0` | `3.01ms` | `a == 0` | `72.9μs` | **41.35x** |
| `let _ = a === b` | `5.61ms` | `a == b` | `384μs` | **14.61x** |

- Indexing

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a[posb]` | `906μs` | `a[posb]` | `376μs` | **2.41x** |

Measured on Apple M5, macOS 26.5.1, Swift version 6.2.3, Python 3.9.6, numpy 2.0.2 (Matft `0.3.3-23-g98e2589-dirty`, 2026-09-26).

Matft: median of XCTest `measure {}` in release build (`swift test -c release`). Numpy: median of `timeit`. Ratios > 1 (Matft slower) are shown in bold.

Regenerate with `python3 scripts/benchmark.py --update-readme`.
