---
title: Performance
---

# Performance

Matft uses Apple's `Accelerate` framework, so `MfArray` operations keep high performance.
The tables below compare Matft with Numpy on the same inputs, prepared as follows.

```swift
let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
let ad = a.astype(.Double)
let aneg = Matft.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10])
let aT = a.T
let b = a.transpose(axes: [0,3,4,2,1,5])
let c = a.transpose(axes: [1,2,3,4,5,0])
let posb = a > 0
let idx = MfArray([1, 3, 5, 7, 9])
let values = a[posb]
let signal = Matft.arange(start: 0, to: 1024*1024, by: 1, shape: [1024, 1024], mftype: .Float)
let v = Matft.arange(start: 0, to: 10000, by: 1)
let nested: [[Float]] = (0..<1000).map{ i in (0..<100).map{ Float(i*100 + $0) } }
let m = MfArray((0..<256).map{ (i: Int) -> [Double] in (0..<256).map{ (j: Int) -> Double in i == j ? 256 : Double((i*256 + j) % 7) } })
```

```python
import numpy as np

a = np.arange(10**6).reshape((10,10,10,10,10,10))
ad = a.astype(np.float64)
aneg = np.arange(0, -10**6, -1).reshape((10,10,10,10,10,10))
aT = a.T
b = a.transpose((0,3,4,2,1,5))
c = a.transpose((1,2,3,4,5,0))
posb = a > 0
idx = np.array([1, 3, 5, 7, 9])
values = a[posb]
signal = np.arange(1024*1024, dtype=np.float32).reshape((1024,1024))
v = np.arange(10000)
nested = np.arange(100000, dtype=np.float32).reshape(1000, 100).tolist()
m = np.fromfunction(lambda i, j: np.where(i == j, 256, (i*256 + j) % 7), (256, 256))
```

<!-- BENCHMARK:START -->
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
<!-- BENCHMARK:END -->

Performance improvements are always welcome ([Issue #18](https://github.com/jjjkkkjjj/Matft/issues/18))!!
