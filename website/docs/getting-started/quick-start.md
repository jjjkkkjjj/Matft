---
title: Quick Start
---

# Quick Start

This page shows the basic flow of Matft: create an array, compute, slice and read values back.
If you know Numpy, the table below is almost everything you need.

| Numpy | Matft |
| --- | --- |
| `import numpy as np` | `import Matft` |
| `np.array([[1, 2], [3, 4]])` | `MfArray([[1, 2], [3, 4]])` |
| `np.arange(0, 6).reshape(2, 3)` | `Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])` |
| `a.dtype = np.float32` | `a.astype(.Float)` |
| `a[:, 1]` | `a[Matft.all, 1]` or `a[0~<, 1]` |
| `a[1:3]` / `a[::-1]` | `a[1~<3]` / `a[Matft.reverse]` |
| `a @ b` | `a *& b` |
| `np.sin(a)` | `Matft.math.sin(a)` |
| `a.sum(axis=0)` | `a.sum(axis: 0)` |
| `a.tolist()` | `a.toArray()` |

## Create

```swift
import Matft

let a = MfArray([[1, 2, 3],
                 [4, 5, 6]])
let b = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])
print(a)
/*
mfarray = 
[[	1,		2,		3],
[	4,		5,		6]], type=Int, shape=[2, 3]
*/
```

## Compute

Operators work element-wise, and arrays with different shapes are [broadcast](../guide/arithmetic.md#broadcasting).

```swift
print(a + b)
/*
mfarray = 
[[	1,		3,		5],
[	7,		9,		11]], type=Int, shape=[2, 3]
*/
print(a * MfArray([10, 100, 1000]))
/*
mfarray = 
[[	10,		200,		3000],
[	40,		500,		6000]], type=Int, shape=[2, 3]
*/
print(a.sum(axis: 0))
/*
mfarray = 
[	5,		7,		9], type=Int, shape=[3]
*/
```

## Slice

Use `~<` instead of Python's `:`. The result is a [view](../guide/views.md) of the original array.

```swift
print(a[Matft.all, 1~<3]) // a[:, 1:3]
/*
mfarray = 
[[	2,		3],
[	5,		6]], type=Int, shape=[2, 2]
*/
```

## Read values back

```swift
print(a.toArray() as! [[Int]])
// [[1, 2, 3], [4, 5, 6]]
print(a.item(index: 4, type: Int.self))
// 5
```

Next, read the [Guide](../guide/mfarray.md) or look up a function in the [NumPy Mapping](../numpy-mapping/index.md).
