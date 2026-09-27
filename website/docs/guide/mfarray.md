---
title: MfArray and MfType
---

# MfArray and MfType

## MfArray

`MfArray` is the n-dimensional array of Matft, like `numpy.ndarray`.

```swift
let a = MfArray([[[ -8,  -7,  -6,  -5],
                  [ -4,  -3,  -2,  -1]],

                 [[ 0,  1,  2,  3],
                  [ 4,  5,  6,  7]]])
let aa = Matft.arange(start: -8, to: 8, by: 1, shape: [2,2,4])
print(a)
print(aa)
/*
mfarray = 
[[[	-8,		-7,		-6,		-5],
[	-4,		-3,		-2,		-1]],

[[	0,		1,		2,		3],
[	4,		5,		6,		7]]], type=Int, shape=[2, 2, 4]
mfarray = 
[[[	-8,		-7,		-6,		-5],
[	-4,		-3,		-2,		-1]],

[[	0,		1,		2,		3],
[	4,		5,		6,		7]]], type=Int, shape=[2, 2, 4]
*/
```

## MfType

You can pass `MfType` as `MfArray`'s argument `mftype: .Hoge`. It is similar to Numpy's `dtype`.

```swift
public enum MfType: Int{
    case None // Unsupported
    case Bool
    case UInt8
    case UInt16
    case UInt32
    case UInt64
    case UInt
    case Int8
    case Int16
    case Int32
    case Int64
    case Int
    case Float
    case Double
    case ComplexFloat
    case ComplexDouble
    case Object // Unsupported
}
```

:::note
The stored data type is `Float` or `Double` only, even if you set `MfType.Int`.
The results of 8/16-bit integer arrays wrap around like Numpy's fixed-width integers (e.g. `UInt8`: -5 → 251),
but big numbers of wider integer types may lose precision or give strange results in calculations (`+`, `-`, `*`, `/`, … etc.), though this is rarely a problem in practical use.
Mixed integer types are promoted like `numpy.result_type` (e.g. `UInt8` + `Int8` → `Int16`).
A Swift scalar works like a Python scalar in Numpy 2 (NEP 50): the array keeps its type unless the scalar is a higher kind
(Bool < integer < floating point), e.g. `UInt8` array + `1` → `UInt8` (out-of-range scalars wrap around, where Numpy raises `OverflowError`)
and `Float` array * `2.5` → `Float`. An integer or `Bool` array with a floating point scalar gives `Float` (Numpy: float64),
and a `Bool` array with an integer scalar gives `Int`.
:::

If `mftype` is not passed, `MfArray` infers it from the given values (`MfType.Int` in the example above).

```swift
let a = MfArray([[[ -8,  -7,  -6,  -5],
                  [ -4,  -3,  -2,  -1]],

                 [[ 0,  1,  2,  3],
                  [ 4,  5,  6,  7]]], mftype: .Float)
print(a)
/*
mfarray = 
[[[	-8.0,		-7.0,		-6.0,		-5.0],
[	-4.0,		-3.0,		-2.0,		-1.0]],

[[	0.0,		1.0,		2.0,		3.0],
[	4.0,		5.0,		6.0,		7.0]]], type=Float, shape=[2, 2, 4]
*/
let aa = MfArray([[[ -8,  -7,  -6,  -5],
                   [ -4,  -3,  -2,  -1]],

                  [[ 0,  1,  2,  3],
                   [ 4,  5,  6,  7]]], mftype: .UInt)
print(aa)
/*
mfarray = 
[[[	4294967288,		4294967289,		4294967290,		4294967291],
[	4294967292,		4294967293,		4294967294,		4294967295]],

[[	0,		1,		2,		3],
[	4,		5,		6,		7]]], type=UInt, shape=[2, 2, 4]
*/
```

The above output is the same as Numpy's:

```python
>>> np.arange(-8, 8, dtype=np.uint32).reshape(2,2,4)
array([[[4294967288, 4294967289, 4294967290, 4294967291],
        [4294967292, 4294967293, 4294967294, 4294967295]],

       [[         0,          1,          2,          3],
        [         4,          5,          6,          7]]], dtype=uint32)
```

### astype

You can convert `MfType` easily using `astype`.

```swift
print(aa.astype(.Float))
/*
mfarray = 
[[[	-8.0,		-7.0,		-6.0,		-5.0],
[	-4.0,		-3.0,		-2.0,		-1.0]],

[[	0.0,		1.0,		2.0,		3.0],
[	4.0,		5.0,		6.0,		7.0]]], type=Float, shape=[2, 2, 4]
*/
```
