---
title: Complex Numbers
---

# Complex Numbers

Matft supports complex numbers. Create a complex `MfArray` from its real and imaginary parts.

:::info Beta
Complex support is a beta version. Please report bugs on the [issue](https://github.com/jjjkkkjjj/Matft/issues/24).
:::

```swift
let real = Matft.arange(start: 0, to: 16, by: 1).reshape([2,2,4])
let imag = Matft.arange(start: 0, to: -16, by: -1).reshape([2,2,4])
let a = MfArray(real: real, imag: imag)
print(a)
/*
mfarray = 
[[[	0 +0j,		1 -1j,		2 -2j,		3 -3j],
[	4 -4j,		5 -5j,		6 -6j,		7 -7j]],

[[	8 -8j,		9 -9j,		10 -10j,		11 -11j],
[	12 -12j,		13 -13j,		14 -14j,		15 -15j]]], type=Int, shape=[2, 2, 4]
*/

print(a+a)
/*
mfarray = 
[[[	0 +0j,		2 -2j,		4 -4j,		6 -6j],
[	8 -8j,		10 -10j,		12 -12j,		14 -14j]],

[[	16 -16j,		18 -18j,		20 -20j,		22 -22j],
[	24 -24j,		26 -26j,		28 -28j,		30 -30j]]], type=Int, shape=[2, 2, 4]
*/

print(Matft.complex.angle(a))
/*
mfarray = 
[[[	-0.0,		-0.7853982,		-0.7853982,		-0.7853982],
[	-0.7853982,		-0.7853982,		-0.7853982,		-0.7853982]],

[[	-0.7853982,		-0.7853982,		-0.7853982,		-0.7853982],
[	-0.7853982,		-0.7853981,		-0.7853982,		-0.7853981]]], type=Float, shape=[2, 2, 4]
*/

print(Matft.complex.conjugate(a))
/*
mfarray = 
[[[	0 +0j,		1 +1j,		2 +2j,		3 +3j],
[	4 +4j,		5 +5j,		6 +6j,		7 +7j]],

[[	8 +8j,		9 +9j,		10 +10j,		11 +11j],
[	12 +12j,		13 +13j,		14 +14j,		15 +15j]]], type=Int, shape=[2, 2, 4]
*/
```

## Supported operations

- [x] Arithmetic operation
- [x] Angle, conjugate and absolute
- [x] Math (partial: `sin`, `cos`, `tan`, `exp`, `log`)
- [x] Basic subscription getter / setter
- [x] Boolean indexing getter
- [ ] Boolean indexing setter
- [x] Fancy indexing getter
- [ ] Fancy indexing setter

Functions marked with `#` in the [NumPy Mapping](../numpy-mapping/index.md) support complex arrays.
