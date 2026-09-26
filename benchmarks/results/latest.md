- Arithmetic

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a+aneg` | `58.5μs` | `a+aneg` | `190μs` | 0.31x |
| `let _ = b+aT` | `680μs` | `b+aT` | `797μs` | 0.85x |
| `let _ = c+aT` | `787μs` | `c+aT` | `750μs` | **1.05x** |

- Math

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = Matft.math.sin(a)` | `308μs` | `np.sin(a)` | `2.79ms` | 0.11x |
| `let _ = Matft.math.sin(b)` | `1.45ms` | `np.sin(b)` | `2.81ms` | 0.52x |
| `let _ = Matft.math.sign(a)` | `937μs` | `np.sign(a)` | `128μs` | **7.34x** |
| `let _ = Matft.math.sign(b)` | `2.09ms` | `np.sign(b)` | `128μs` | **16.32x** |

- Bool

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a > 0` | `137μs` | `a > 0` | `70.3μs` | **1.95x** |
| `let _ = ad > 0` | `288μs` | `ad > 0` | `155μs` | **1.85x** |
| `let _ = a > b` | `2.24ms` | `a > b` | `383μs` | **5.84x** |
| `let _ = a === 0` | `193μs` | `a == 0` | `73.7μs` | **2.62x** |
| `let _ = a === b` | `1.99ms` | `a == b` | `384μs` | **5.18x** |

- Indexing

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a[posb]` | `340μs` | `a[posb]` | `352μs` | 0.97x |
| `let _ = a[a > 0]` | `477μs` | `a[a > 0]` | `419μs` | **1.14x** |

Measured on Apple M5, macOS 26.5.1, Swift version 6.2.3, Python 3.9.6, numpy 2.0.2 (Matft `0.3.3-29-g5a0727f`, 2026-09-26).

Matft: median of XCTest `measure {}` in release build (`swift test -c release`), after a warm-up and with several calls per sample (like `timeit`). Numpy: median of `timeit`. Ratios > 1 (Matft slower) are shown in bold.

Regenerate with `python3 scripts/benchmark.py --update-readme`.
