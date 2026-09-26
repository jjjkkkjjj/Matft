---
title: Views
---

# Views

A subscripted `MfArray` has the `base` property and shares its memory with the original array, like a [view in Numpy](https://numpy.org/doc/stable/reference/generated/numpy.ndarray.view.html).
So assigning values to a view changes the original array.

```swift
let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])

let b = a[0~<, 1]
b[~<<-1] = MfArray([9999]) // cannot pass Int directly such like 9999

print(a)
/*
mfarray = 
[[[	0,		1],
[	9999,		9999],
[	4,		5],
[	6,		7]],

[[	8,		9],
[	9999,		9999],
[	12,		13],
[	14,		15]],

[[	16,		17],
[	9999,		9999],
[	20,		21],
[	22,		23]],

[[	24,		25],
[	9999,		9999],
[	28,		29],
[	30,		31]]], type=Int, shape=[4, 4, 2]
*/
```

## Copy

To get an independent array, copy it.

| Matft | Numpy |
| --- | --- |
| `a.shallowcopy()` / `Matft.shallowcopy(a)` | `a.copy()` / `np.copy(a)` |
| `a.deepcopy()` / `Matft.deepcopy(a)` | `copy.deepcopy(a)` |
| `a.to_contiguous(mforder: .Row)` | `np.ascontiguousarray(a)` |
