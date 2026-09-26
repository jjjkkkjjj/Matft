---
title: Shape Manipulation
---

# Shape Manipulation

## Transpose

Use the property `T`, the method `transpose(axes: [Int]? = nil)` or `Matft.transpose(_:axes:)`.

```swift
let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
print(a.T)
print(a.transpose(axes: [0,2,1]))
/*
mfarray = 
[[[	0,		9,		18],
[	3,		12,		21],
[	6,		15,		24]],

[[	1,		10,		19],
[	4,		13,		22],
[	7,		16,		25]],

[[	2,		11,		20],
[	5,		14,		23],
[	8,		17,		26]]], type=Int, shape=[3, 3, 3]
mfarray = 
[[[	0,		3,		6],
[	1,		4,		7],
[	2,		5,		8]],

[[	9,		12,		15],
[	10,		13,		16],
[	11,		14,		17]],

[[	18,		21,		24],
[	19,		22,		25],
[	20,		23,		26]]], type=Int, shape=[3, 3, 3]
*/
```

## Reshape

Use the method `reshape(_:)` or `Matft.reshape(_:newshape:)`.

```swift
let b = Matft.arange(start: 0, to: 16, by: 1, shape: [2,4,2])
print(b.reshape([4,4]))
print(b.reshape([1,2,1,8]))
/*
mfarray = 
[[	0,		1,		2,		3],
[	4,		5,		6,		7],
[	8,		9,		10,		11],
[	12,		13,		14,		15]], type=Int, shape=[4, 4]
mfarray = 
[[[[	0,		1,		2,		3,		4,		5,		6,		7]],

[[	8,		9,		10,		11,		12,		13,		14,		15]]]], type=Int, shape=[1, 2, 1, 8]
*/
```

## Others

`expand_dims`, `squeeze`, `broadcast_to`, `flatten`, `flip`, `swapaxes`, `moveaxis`, `roll`, `pad`, `concatenate`, `vstack`, `hstack` and more are available.
See [NumPy Mapping › Conversion](../numpy-mapping/conversion.md) and [Creation](../numpy-mapping/creation.md) for the full list.
