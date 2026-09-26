- Arithmetic

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a+aneg` | `68.4μs` | `a+aneg` | `190μs` | 0.36x |
| `let _ = b+aT` | `706μs` | `b+aT` | `797μs` | 0.89x |
| `let _ = c+aT` | `826μs` | `c+aT` | `750μs` | **1.10x** |

- Math

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = Matft.math.sin(a)` | `313μs` | `np.sin(a)` | `2.79ms` | 0.11x |
| `let _ = Matft.math.sin(b)` | `1.17ms` | `np.sin(b)` | `2.81ms` | 0.42x |
| `let _ = Matft.math.sign(a)` | `280μs` | `np.sign(a)` | `128μs` | **2.20x** |
| `let _ = Matft.math.sign(b)` | `1.09ms` | `np.sign(b)` | `128μs` | **8.47x** |

- Bool

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a > 0` | `137μs` | `a > 0` | `70.3μs` | **1.94x** |
| `let _ = ad > 0` | `267μs` | `ad > 0` | `155μs` | **1.72x** |
| `let _ = a > b` | `720μs` | `a > b` | `383μs` | **1.88x** |
| `let _ = a === 0` | `226μs` | `a == 0` | `73.7μs` | **3.07x** |
| `let _ = a === b` | `793μs` | `a == b` | `384μs` | **2.07x** |

- Indexing

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a[posb]` | `345μs` | `a[posb]` | `352μs` | 0.98x |
| `let _ = a[a > 0]` | `492μs` | `a[a > 0]` | `419μs` | **1.17x** |

Measured on Apple M5, macOS 26.5.1, Swift version 6.2.3, Python 3.9.6, numpy 2.0.2 (Matft `0.3.3-32-gbf2cf56-dirty`, 2026-09-26).

Matft: median of XCTest `measure {}` in release build (`swift test -c release`), after a warm-up and with several calls per sample (like `timeit`). Numpy: median of `timeit`. Ratios > 1 (Matft slower) are shown in bold.

Regenerate with `python3 scripts/benchmark.py --update-readme`.
