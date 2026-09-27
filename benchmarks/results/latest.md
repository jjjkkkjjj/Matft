- Arithmetic

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a+aneg` | `52.1μs` | `a+aneg` | `197μs` | 0.26x |
| `let _ = b+aT` | `689μs` | `b+aT` | `959μs` | 0.72x |
| `let _ = c+aT` | `864μs` | `c+aT` | `735μs` | **1.18x** |
| `let _ = a + Float(0.5)` | `30.3μs` | `a + np.float32(0.5)` | `319μs` | 0.10x |

- Math

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = Matft.math.sin(a)` | `290μs` | `np.sin(a)` | `2.80ms` | 0.10x |
| `let _ = Matft.math.sin(b)` | `289μs` | `np.sin(b)` | `2.81ms` | 0.10x |
| `let _ = Matft.math.sign(a)` | `265μs` | `np.sign(a)` | `128μs` | **2.08x** |
| `let _ = Matft.math.sign(b)` | `266μs` | `np.sign(b)` | `128μs` | **2.09x** |
| `let _ = Matft.math.power(bases: ad, exponents: 2)` | `125μs` | `np.power(ad, 2)` | `4.06ms` | 0.03x |
| `let _ = Matft.math.arctan2(x1: ad, x2: ad)` | `1.93ms` | `np.arctan2(ad, ad)` | `1.09ms` | **1.76x** |

- Stats

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a.mean()` | `34.0μs` | `a.mean()` | `347μs` | 0.10x |
| `let _ = Matft.stats.cumsum(a, axis: 0)` | `31.3μs` | `np.cumsum(a, axis=0)` | `645μs` | 0.05x |
| `let _ = Matft.stats.cumsum(a, axis: 5)` | `371μs` | `np.cumsum(a, axis=5)` | `686μs` | 0.54x |
| `let _ = Matft.stats.cumsum(v)` | `16.1μs` | `np.cumsum(v)` | `15.0μs` | **1.07x** |
| `let _ = a.argmax(axis: 5)` | `961μs` | `np.argmax(a, axis=5)` | `211μs` | **4.56x** |
| `let _ = a.argmax(axis: 0)` | `916μs` | `np.argmax(a, axis=0)` | `562μs` | **1.63x** |

- Conversion

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = aneg.argsort(axis: -1)` | `7.02ms` | `np.argsort(aneg, axis=-1)` | `2.41ms` | **2.91x** |
| `let _ = a.astype(.Double)` | `122μs` | `a.astype(np.float64)` | `236μs` | 0.52x |
| `let _ = Matft.deepcopy(a)` | `49.2μs` | `a.copy()` | `128μs` | 0.38x |
| `let _ = a.reshape([1000, 1000])` | `49.4μs` | `a.reshape((1000, 1000)).copy()` | `132μs` | 0.37x |

- Creation

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = MfArray(nested)` | `3.95ms` | `np.array(nested, dtype=np.float32)` | `1.19ms` | **3.31x** |
| `let _ = Matft.nums(Float(1), shape: [1000, 1000])` | `47.7μs` | `np.full((1000, 1000), 1, dtype=np.float32)` | `48.6μs` | 0.98x |

- LinAlg

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = try! Matft.linalg.inv(m)` | `490μs` | `np.linalg.inv(m)` | `506μs` | 0.97x |

- Bool

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a > 0` | `122μs` | `a > 0` | `75.9μs` | **1.60x** |
| `let _ = ad > 0` | `248μs` | `ad > 0` | `156μs` | **1.59x** |
| `let _ = a > b` | `474μs` | `a > b` | `394μs` | **1.20x** |
| `let _ = a === 0` | `184μs` | `a == 0` | `75.6μs` | **2.43x** |
| `let _ = a === b` | `551μs` | `a == b` | `407μs` | **1.36x** |
| `let _ = a === 5` | `232μs` | `a == 5` | `76.6μs` | **3.03x** |
| `let _ = a !== 0` | `187μs` | `a != 0` | `87.6μs` | **2.13x** |
| `let _ = Matft.logical_not(posb)` | `28.7μs` | `np.logical_not(posb)` | `17.8μs` | **1.62x** |
| `let _ = a == a` | `114μs` | `np.array_equal(a, a)` | `110μs` | **1.03x** |

- FFT

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = Matft.fft.rfft(signal)` | `1.98ms` | `np.fft.rfft(signal)` | `1.43ms` | **1.39x** |
| `let _ = Matft.fft.rfft(signal, vDSP: true)` | `629μs` | `np.fft.rfft(signal)` | `1.45ms` | 0.43x |

- Indexing

| Matft | time | Numpy | time | Matft / Numpy |
| --- | --- | --- | --- | --- |
| `let _ = a[posb]` | `319μs` | `a[posb]` | `391μs` | 0.82x |
| `let _ = a[a > 0]` | `443μs` | `a[a > 0]` | `448μs` | 0.99x |
| `let _ = aT[aT > 0]` | `3.47ms` | `aT[aT > 0]` | `1.55ms` | **2.24x** |
| `let _ = a[idx]` | `11.3μs` | `a[idx]` | `50.0μs` | 0.23x |
| `let x = Matft.deepcopy(a); x[x > 0] = MfArray([0])` | `360μs` | `x = a.copy(); x[x > 0] = 0` | `556μs` | 0.65x |
| `let x = Matft.deepcopy(a); x[posb] = values` | `667μs` | `x = a.copy(); x[posb] = values` | `529μs` | **1.26x** |
| `let x = Matft.deepcopy(a).T; x[x > 0] = MfArray([0])` | `3.88ms` | `x = a.copy().T; x[x > 0] = 0` | `1.73ms` | **2.24x** |

Measured on Apple M5, macOS 26.5.1, Swift version 6.2.3, Python 3.9.6, numpy 2.0.2 (Matft `1.0.0`, 2026-09-27).

Matft: median of XCTest `measure {}` in release build (`swift test -c release`), after a warm-up and with several calls per sample (like `timeit`). Numpy: median of `timeit`. Ratios > 1 (Matft slower) are shown in bold.

Regenerate with `python3 scripts/benchmark.py --update-docs`.
