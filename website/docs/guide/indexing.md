---
title: Indexing and Slicing
---

# Indexing and Slicing

## MfSlice

You can access specific data using subscript. The following can be set to the subscript:

| Matft | Python | Description |
| --- | --- | --- |
| `MfSlice(start: Int? = nil, to: Int? = nil, by: Int = 1)` | `slice(start, stop, step)` | explicit slice |
| `~<` | `:` | prefix, postfix and infix slice operator |
| `Matft.newaxis` | `np.newaxis` | insert a new axis |
| `Matft.all` | `:` | same as `0~<` |
| `Matft.reverse` | `::-1` | same as `~<<-1` |

## Positive indexing

```swift
let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
print(a)
/*
mfarray = 
[[[	0,		1,		2],
[	3,		4,		5],
[	6,		7,		8]],

[[	9,		10,		11],
[	12,		13,		14],
[	15,		16,		17]],

[[	18,		19,		20],
[	21,		22,		23],
[	24,		25,		26]]], type=Int, shape=[3, 3, 3]
*/
print(a[2,1,0])
// 21
```

:::caution
`MfArray` conforms to the `Collection` protocol, so indexing a 1D `MfArray` returns an `MfArray`, not a scalar.
Use `item` to get a scalar.

```swift
let a = Matft.arange(start: 0, to: 27, by: 1, shape: [27])
print(a[0])
/*
0 // a[0] is an MfArray, though it is printed as a scalar
*/
print(a[0] + 4)
/*
mfarray = 
[    4], type=Int, shape=[1]
*/

// Workaround
print(a.item(index: 0, type: Int.self))
// 0
print(a.item(index: 0, type: Int.self) + 4)
// 4
```
:::

## Slicing

Replace Python's `:` with `~<` to get a sliced `MfArray`.
Note that you should use `a[0~<]` instead of `a[:]` to get all elements along an axis.

```swift
print(a[~<1])  // same as a[:1] for numpy
/*
mfarray = 
[[[	0,		1,		2],
[	3,		4,		5],
[	6,		7,		8]]], type=Int, shape=[1, 3, 3]
*/
print(a[1~<3]) // same as a[1:3] for numpy
/*
mfarray = 
[[[	9,		10,		11],
[	12,		13,		14],
[	15,		16,		17]],

[[	18,		19,		20],
[	21,		22,		23],
[	24,		25,		26]]], type=Int, shape=[2, 3, 3]
*/
print(a[~<~<2]) // same as a[::2] for numpy
//print(a[~<<2]) // alias
/*
mfarray = 
[[[	0,		1,		2],
[	3,		4,		5],
[	6,		7,		8]],

[[	18,		19,		20],
[	21,		22,		23],
[	24,		25,		26]]], type=Int, shape=[2, 3, 3]
*/

print(a[Matft.all, 0]) // same as a[:, 0] for numpy
/*
mfarray = 
[[	0,		1,		2],
[	9,		10,		11],
[	18,		19,		20]], type=Int, shape=[3, 3]
*/
```

## Negative indexing

```swift
print(a[~<-1])
/*
mfarray = 
[[[	0,		1,		2],
[	3,		4,		5],
[	6,		7,		8]],

[[	9,		10,		11],
[	12,		13,		14],
[	15,		16,		17]]], type=Int, shape=[2, 3, 3]
*/
print(a[-1~<-3])
/*
mfarray = 
	[], type=Int, shape=[0, 3, 3]
*/
print(a[Matft.reverse])
//print(a[~<~<-1]) // alias
//print(a[~<<-1]) // alias
/*
mfarray = 
[[[	18,		19,		20],
[	21,		22,		23],
[	24,		25,		26]],

[[	9,		10,		11],
[	12,		13,		14],
[	15,		16,		17]],

[[	0,		1,		2],
[	3,		4,		5],
[	6,		7,		8]]], type=Int, shape=[3, 3, 3]
*/
```

## Boolean indexing

```swift
let img = MfArray([[1, 2, 3],
                   [4, 5, 6],
                   [7, 8, 9]], mftype: .UInt8)
img[img > 3] = MfArray([10], mftype: .UInt8)
print(img)
/*
mfarray = 
[[	1,		2,		3],
[	10,		10,		10],
[	10,		10,		10]], type=UInt8, shape=[3, 3]
*/
```

See [Performance](../performance.md) for the speed comparison with Numpy.

## Fancy indexing

```swift
let a = MfArray([[1, 2], [3, 4], [5, 6]])

a[MfArray([0, 1, 2]), MfArray([0, -1, 0])] = MfArray([999,888,777])
print(a)
/*
mfarray = 
[[	999,		2],
[	3,		888],
[	777,		6]], type=Int, shape=[3, 2]
*/

a.T[MfArray([0, 1, -1]), MfArray([0, 1, 0])] = MfArray([-999,-888,-777])
print(a)
/*
mfarray = 
[[	-999,		-777],
[	3,		-888],
[	777,		6]], type=Int, shape=[3, 2]
*/
```
