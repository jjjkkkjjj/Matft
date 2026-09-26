- Arithmetic

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a+aneg` | `50.5μs` | `a+aneg` | `197μs` | 0.26x |
| `let _ = b+aT` | `707μs` | `b+aT` | `819μs` | 0.86x |
| `let _ = c+aT` | `777μs` | `c+aT` | `765μs` | **1.02x** |

- Math

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = Matft.math.sin(a)` | `312μs` | `np.sin(a)` | `2.81ms` | 0.11x |
| `let _ = Matft.math.sin(b)` | `314μs` | `np.sin(b)` | `2.80ms` | 0.11x |
| `let _ = Matft.math.sign(a)` | `278μs` | `np.sign(a)` | `153μs` | **1.82x** |
| `let _ = Matft.math.sign(b)` | `280μs` | `np.sign(b)` | `144μs` | **1.94x** |

- Bool

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a > 0` | `142μs` | `a > 0` | `73.5μs` | **1.93x** |
| `let _ = ad > 0` | `277μs` | `ad > 0` | `156μs` | **1.78x** |
| `let _ = a > b` | `521μs` | `a > b` | `388μs` | **1.34x** |
| `let _ = a === 0` | `212μs` | `a == 0` | `74.7μs` | **2.84x** |
| `let _ = a === b` | `652μs` | `a == b` | `389μs` | **1.68x** |

- Indexing

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a[posb]` | `343μs` | `a[posb]` | `362μs` | 0.95x |
| `let _ = a[a > 0]` | `484μs` | `a[a > 0]` | `434μs` | **1.12x** |

Measured on Apple M5, macOS 26.5.1, Swift version 6.2.3, Python 3.9.6, numpy 2.0.2 (Matft `0.3.3-35-gd7469ce`, 2026-09-26).

Matft: median of XCTest `measure {}` in release build (`swift test -c release`), after a warm-up and with several calls per sample (like `timeit`). Numpy: median of `timeit`. Ratios > 1 (Matft slower) are shown in bold.

Regenerate with `python3 scripts/benchmark.py --update-readme`.
