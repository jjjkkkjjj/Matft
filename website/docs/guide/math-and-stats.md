---
title: Math and Statistics
---

# Math and Statistics

## Math functions

Basic math functions such as `sin`, `cos`, `tan`, `log` and `exp` are in `Matft.math`.

```swift
let a = Matft.arange(start: 0, to: 4, by: 1)
print(a)
print(Matft.math.sin(a))
print(Matft.math.cos(a))
print(Matft.math.tan(a))
print(Matft.math.log(a))
print(Matft.math.exp(a))
/*
mfarray = 
[	0,		1,		2,		3], type=Int, shape=[4]
mfarray = 
[	0.0,		0.84147096,		0.9092974,		0.14112], type=Float, shape=[4]
mfarray = 
[	1.0,		0.5403023,		-0.4161468,		-0.9899925], type=Float, shape=[4]
mfarray = 
[	0.0,		1.5574077,		-2.18504,		-0.14254653], type=Float, shape=[4]
mfarray = 
[	-inf,		0.0,		0.6931472,		1.0986123], type=Float, shape=[4]
mfarray = 
[	1.0,		2.7182817,		7.389056,		20.085537], type=Float, shape=[4]
*/
let b = MfArray([0.23, -0.7, 1.7, 2.1])
print(Matft.math.power(bases: a, exponents: b))
/*
mfarray = 
[	0.0,		1.0,		3.249009585424942,		10.04510856630514], type=Double, shape=[4]
*/
```

## Approximation

```swift
let b = MfArray([0.23, -0.7, 1.7, 2.1])
print(Matft.math.floor(b))
print(Matft.math.ceil(b))
print(Matft.math.nearest(b))
/*
mfarray = 
[	0.0,		-1.0,		1.0,		2.0], type=Double, shape=[4]
mfarray = 
[	1.0,		-0.0,		2.0,		3.0], type=Double, shape=[4]
mfarray = 
[	0.0,		-1.0,		2.0,		2.0], type=Double, shape=[4]
*/
```

## Statistics (reduction)

Maximum, minimum, mean, … are in `Matft.stats`. You can reduce along a specific axis too.

```swift
let a = MfArray([[[-5, 3, 2, 6],
                  [3, 7, -2, 0]],

                 [[7, 10, -9, 5],
                  [1, 1, 7, 0]]])
print(Matft.stats.max(a))
print(Matft.stats.min(a))
print(Matft.stats.argmax(a))
print(Matft.stats.argmin(a))
/*
mfarray = 
[	10], type=Int, shape=[1]
mfarray = 
[	-9], type=Int, shape=[1]
mfarray = 
[	9], type=Int, shape=[1]
mfarray = 
[	10], type=Int, shape=[1]
*/

print(Matft.stats.max(a, axis: -1)) // negative axis is OK!
print(Matft.stats.min(a, axis: 0))
print(Matft.stats.argmax(a, axis: -1))
print(Matft.stats.argmin(a, axis: 0))
/*
mfarray = 
[[	6,		7],
[	10,		7]], type=Int, shape=[2, 2]
mfarray = 
[[	-5,		3,		-9,		5],
[	1,		1,		-2,		0]], type=Int, shape=[2, 4]
mfarray = 
[[	3,		1],
[	1,		2]], type=Int, shape=[2, 2]
mfarray = 
[[	0,		0,		1,		1],
[	1,		1,		0,		0]], type=Int, shape=[2, 4]
*/
```

## Universal function reduction

`Matft.ufuncReduce` and `Matft.ufuncAccumulate` correspond to Numpy's `np.add.reduce` and `np.add.accumulate`.

```swift
Matft.ufuncReduce(mfarray: a, ufunc: Matft.add)     // np.add.reduce(a)
Matft.ufuncAccumulate(mfarray: a, ufunc: Matft.add) // np.add.accumulate(a)
```

See [NumPy Mapping › Math](../numpy-mapping/math.md) and [Statistics](../numpy-mapping/stats.md) for all functions.
