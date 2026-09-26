---
title: Arithmetic and Broadcasting
---

# Arithmetic and Broadcasting

## Element-wise operation

```swift
let a = Matft.arange(start: 1, to: 9, by: 2, shape: [2,2])
let b = Matft.arange(start: 1, to: 5, by: 1, shape: [2,2])
print(a)
/*
mfarray = 
[[	1,		3],
[	5,		7]], type=Int, shape=[2, 2]
*/
print(b)
/*
mfarray = 
[[	1,		2],
[	3,		4]], type=Int, shape=[2, 2]
*/
print(a+b)
/*
mfarray = 
[[	2,		5],
[	8,		11]], type=Int, shape=[2, 2]
*/
print(a-b)
/*
mfarray = 
[[	0,		-1],
[	-2,		-3]], type=Int, shape=[2, 2]
*/
print(a*b)
/*
mfarray = 
[[	1,		6],
[	15,		28]], type=Int, shape=[2, 2]
*/
print(a/b) // true division like Numpy: integer arrays give Float
/*
mfarray = 
[[	1.0,		1.5],
[	1.6666666,		1.75]], type=Float, shape=[2, 2]
*/
```

## Broadcasting

When the shapes of two arrays differ, the one is broadcast automatically as in Numpy.

```swift
let a = Matft.arange(start: 1, to: 9, by: 2, shape: [2,2])
let c = MfArray([-100,100])
print(a+c)
/*
mfarray = 
[[	-99,		103],
[	-95,		107]], type=Int, shape=[2, 2]
*/
```

## Operators

| Matft | Numpy | Description |
| --- | --- | --- |
| `+`, `-`, `*`, `/` | `+`, `-`, `*`, `/` | element-wise arithmetic |
| `-a` | `-a` | negative |
| `*&` | `@` | matrix multiplication |
| `*+` | `np.inner` | inner product |
| `*^` | `np.cross` | cross product |
| `===`, `!==` | `==`, `!=` | element-wise comparison (returns a Bool `MfArray`) |
| `<`, `<=`, `>`, `>=` | `<`, `<=`, `>`, `>=` | element-wise comparison |
| `==` | `np.array_equal` | whether all elements are equal (returns `Bool`) |

:::caution
`==` compares the **whole** arrays and returns a Swift `Bool`. Use `===` for the element-wise comparison (`==` in Numpy).
:::
