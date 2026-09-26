---
title: Linear Algebra
---

# Linear Algebra

## Matrix multiplication

Use `Matft.matmul` or the operator `*&`.

If the dimension of the input is 3 or more, it is treated as a stack of matrices residing in the last two indexes and broadcast accordingly (see [numpy.matmul](https://numpy.org/doc/stable/reference/generated/numpy.matmul.html)).

```swift
let a = Matft.arange(start: 1, to: 5, by: 1, shape: [2,2])
let b = Matft.arange(start: 5, to: 9, by: 1, shape: [2,2])
print(Matft.matmul(a, b))
print(a*&b)
/*
mfarray = 
[[	19,		22],
[	43,		50]], type=Int, shape=[2, 2]
mfarray = 
[[	19,		22],
[	43,		50]], type=Int, shape=[2, 2]
*/
```

## Simultaneous equations

Solve them by `Matft.linalg.solve`. The result's `mftype` is converted to `Float` or `Double`.

```swift
let coef = MfArray([[3,2],[1,2]])
let b = MfArray([7,1])
let ans = try! Matft.linalg.solve(coef, b: b)
print(ans)
/*
mfarray = 
[	3.0,		-1.0000002], type=Float, shape=[2]
*/
```

The shape of the result is aligned to `b`'s one; `b` of shape `[2, 1]` returns the result of shape `[2, 1]`.

## Inverse

```swift
let a = MfArray([[1,3,2],[-1,0,1],[2,3,0]])
let ainv = try! Matft.linalg.inv(a)
print(ainv)
print(a*&ainv)
/*
mfarray = 
[[	1.0,		-2.0,		-1.0],
[	-0.6666666,		1.3333334,		1.0],
[	1.0,		-1.0,		-1.0]], type=Float, shape=[3, 3]
mfarray = 
[[	1.0000001,		0.0,		0.0],
[	0.0,		1.0,		0.0],
[	1.1920929e-07,		1.1920929e-07,		1.0]], type=Float, shape=[3, 3]
*/
```

If the inverse matrix does not exist, `MfError.LinAlgError.factorizationError` or `MfError.LinAlgError.singularMatrix` is thrown.

## Eigenvalues and eigenvectors

`Matft.linalg.eigen` returns the tuple `(valRe, valIm, lvecRe, lvecIm, rvecRe, rvecIm)`,
where `val` is the eigenvalues, `lvec` is the **left** eigenvectors, `rvec` is the **right** eigenvectors, and `Re` / `Im` are the real / imaginary parts.

```swift
let a = MfArray([[1, -1], [1, 1]])
let ret = try! Matft.linalg.eigen(a)

print(ret.valRe)
print(ret.valIm)
print(ret.lvecRe)
print(ret.lvecIm)
print(ret.rvecRe)
print(ret.rvecIm)
/*
mfarray = 
[	1.0,		1.0], type=Float, shape=[2]
mfarray = 
[	1.0,		-1.0], type=Float, shape=[2]
mfarray = 
[[	-0.70710677,		-0.70710677],
[	0.0,		0.0]], type=Float, shape=[2, 2]
mfarray = 
[[	0.0,		-0.0],
[	0.70710677,		-0.70710677]], type=Float, shape=[2, 2]
mfarray = 
[[	0.70710677,		0.70710677],
[	0.0,		0.0]], type=Float, shape=[2, 2]
mfarray = 
[[	0.0,		-0.0],
[	-0.70710677,		0.70710677]], type=Float, shape=[2, 2]
*/
```

## Singular value decomposition

`Matft.linalg.svd` returns the tuple `(v, s, rt)` (see [numpy.linalg.svd](https://numpy.org/doc/stable/reference/generated/numpy.linalg.svd.html)).

```swift
let a = MfArray([[1, 2],
                 [3, 4]])
let ret = try! Matft.linalg.svd(a)

print(ret.v)
print(ret.s)
print(ret.rt)
print((ret.v *& Matft.diag(v: ret.s) *& ret.rt).nearest())
/*
mfarray = 
[[	-0.40455368,		-0.91451436],
[	-0.9145144,		0.4045536]], type=Float, shape=[2, 2]
mfarray = 
[	5.4649854,		0.36596614], type=Float, shape=[2]
mfarray = 
[[	-0.5760485,		-0.81741554],
[	0.81741554,		-0.5760485]], type=Float, shape=[2, 2]
mfarray = 
[[	1.0,		2.0],
[	3.0,		4.0]], type=Float, shape=[2, 2]
*/
```

## Polar decomposition

`Matft.linalg.polar_right` returns `(u, p)`, where `u` is an orthonormal matrix and `p` is a positive definite matrix.
`Matft.linalg.polar_left` returns `(p, l)`, where `l` is an orthonormal matrix and `p` is a positive definite matrix.

```swift
let a = MfArray([[0.5, 1, 2],
                 [1.5, 3, 4],
                 [2, 3.5, 1]])
let retR = try! Matft.linalg.polar_right(a)

print(retR.u)
print(retR.p)
/*
mfarray = 
[[	0.7279401870626366,		-0.4224602202449294,		0.5400281903473371],
[	-0.28527166525638337,		0.529599993193229,		0.7988391103417394],
[	0.6234766724273361,		0.7355618325608915,		-0.26500118757960134]], type=Double, shape=[3, 3]
mfarray = 
[[	1.1830159405014165,		2.054293544789163,		0.9382703855270752],
[	2.054293544789163,		3.7408061732978783,		2.009041364843949],
[	0.938270385527075,		2.0090413648439487,		4.01041163448203]], type=Double, shape=[3, 3]
*/
```

See [NumPy Mapping › Linear Algebra](../numpy-mapping/linalg.md) for all functions (`det`, `pinv`, `lstsq`, `matrix_rank`, norms, …).
