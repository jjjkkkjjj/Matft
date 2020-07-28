
### Conversion

#### Transpose

- You can get transposed mfarray by using method ``T``, ``transpose(axes: [Int]? = nil)`` or ``Matft.transpose(axes: [Int]? = nil)``

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

#### Reshape

- Reshape is also available. Use method ``reshape(_ axis: [Int])`` or ``Matft.reshape(_ axis: [Int])``

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

### Arithmetic

#### Element-wise Operation

- Element-wise arithmetic operation is available.

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
  print(a/b)
  /*
  mfarray = 
  [[	1,		1],
  [	1,		1]], type=Int, shape=[2, 2]
  */
  ```


#### Broadcasting

- When either mfarray is insufficient data for element-wise operation, the one will be broadcasted automatically and calculated.

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

### Math

#### Basic Math function

- You can create mfarray with basic math function such like ``sin, cos, tan, log, exp,...etc.``

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
  [	0.0,		0.841471,		0.9092974,		0.14112], type=Float, shape=[4]
  mfarray = 
  [	1.0,		0.5403023,		-0.4161468,		-0.9899925], type=Float, shape=[4]
  mfarray = 
  [	0.0,		1.5574079,		-2.18504,		-0.14254653], type=Float, shape=[4]
  mfarray = 
  [	-inf,		0.0,		0.6931472,		1.0986123], type=Float, shape=[4]
  mfarray = 
  [	1.0,		2.7182817,		7.389056,		20.085537], type=Float, shape=[4]
  */
  let b = MfArray([0.23, -0.7, 1.7, 2.1])
  print(Matft.math.power(a, exponents: b))
  /*
  mfarray = 
  [	1.0,		-0.7,		2.89,		9.261000000000003], type=Double, shape=[4]
  */
  ```


#### Approximation

- Basic approximation is also available.
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

### Stats(Reducing)

- You can get maximum, minimum, mean... value's from mfarray.

- You can get these values along specific axis too.

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

### Linear Algebra

※These are developing now...

#### Matrix multiplication

- You can calculate matrix multiplication using ``Matft.matmul`` or operator ``*&``

  ※Note that if you input mfarray's dimension is more than 3, it is treated as a stack of matrices residing in the last two indexes and broadcast accordingly. (See [numpy doc](https://docs.scipy.org/doc/numpy/reference/generated/numpy.matmul.html) in detail)

  ```swift
  let a = Matft.arange(start: 1, to: 5, by: 1, shape: [2,2])
  let b = Matft.arange(start: 5, to: 9, by: 1, shape: [2,2])
  print(a)
  print(b)
  /*
  mfarray = 
  [[	1,		2],
  [	3,		4]], type=Int, shape=[2, 2]
  mfarray = 
  [[	5,		6],
  [	7,		8]], type=Int, shape=[2, 2]
  */
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

#### Simultaneous Equation

- You can solve Simultaneous Equation Problem by ``Matft.linalg.solve``.

  ※Result's mftype will be converted to Float or Double properly

  ```swift
  let coef = MfArray([[3,2],[1,2]])
  let b = MfArray([[7,1]]).T
  let ans = try! Matft.linalg.solve(coef, b: b)
  /*
  mfarray = 
  [[	3.0],
  [	-1.0000001]], type=Float, shape=[2, 1]
  mfarray = 
  [[	7.0],
  [	0.99999976]], type=Float, shape=[2, 1]
  */
  //As you can see below, return's shape will be aligned to input's one
  let coef = MfArray([[3,2],[1,2]])
  let b = MfArray([7,1])
  let ans = try! Matft.linalg.solve(coef, b: b)
  print(ans)
  /*
  mfarray = 
  [	3.0,		-1.0000001], type=Float, shape=[2]
  */
  ```

- Or use ``Matft.linalg.inv``

  ※Result's mftype will be converted to Float or Double properly

  ```swift
  let a = MfArray([[1,3,2],[-1,0,1],[2,3,0]])
  let ainv = try! Matft.linalg.inv(a) // if input mfarray's inverse matrix does not exist, raise MfError.LinAlgError.factorizationError or MfError.LinAlgError.singularMatrix
  print(ainv)
  print(a*&ainv)
  /*
  mfarray = 
  [[	1.0,		-2.0,		-1.0],
  [	-0.6666667,		1.3333334,		1.0],
  [	1.0,		-1.0,		-1.0]], type=Float, shape=[3, 3]
  mfarray = 
  [[	1.0,		0.0,		0.0],
  [	0.0,		1.0,		0.0],
  [	0.0,		0.0,		1.0]], type=Float, shape=[3, 3]
  */
  ```

#### Eigen

- Matft can calculate Eigen values and vectors.
  

Use `Matft.linalg.eigen`

Note that returned value is tuple which consists of `(valRe, valIm, lvecRe, lvecIm, rvecRe, rvecIm)`. In `(valRe, valIm, lvecRe, lvecIm, rvecRe, rvecIm)`, `val` is eigenvalues, `lvec` is **left** eigenvecors, `rvec` is **right** eigenvectors, `Re` is real part, `Im` is imaginary part respectively.

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

#### Singular value decomposition

- Matft can calculate singular value decomposition.

  Use `Matft.linalg.svd`

  Note that returned value is tuple which consists of `(v, s, rt)`. See [numpy doc](https://docs.scipy.org/doc/numpy/reference/generated/numpy.linalg.svd.html)
  
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

#### Polar decomposition

- Polar decomposition is also available.
  

Use `Matft.linalg.polar_right` or `Matft.linalg.polar_left`.

  Note that returned value by `polar_right` is tuple which consists of `(u, p)`. In `(u, p)`, `u` is orthonormal matrix, `p` is positive definite respectively. Returned value by `polar_left` is tuple which consists of `(p, ;)`. In `(p, l)`, `l` is orthonormal matrix, `p` is positive definite respectively.

  ```swift
  let a = MfArray([[0.5, 1, 2],
                   [1.5, 3, 4],
                   [2, 3.5, 1]])
  let retR = try! Matft.linalg.polar_right(a)
  
  print(retR.u)
  print(retR.p)
  /*
  mfarray = 
  [[	0.7279401870626365,		-0.4224602202449294,		0.5400281903473372],
  [	-0.28527166525638326,		0.5295999931932289,		0.7988391103417398],
  [	0.6234766724273363,		0.7355618325608919,		-0.26500118757960145]], type=Double, shape=[3, 3]
  mfarray = 
  [[	1.1830159405014156,		2.0542935447891617,		0.9382703855270744],
  [	2.0542935447891617,		3.7408061732978766,		2.0090413648439474],
  [	0.9382703855270742,		2.0090413648439465,		4.010411634482028]], type=Double, shape=[3, 3]
  */
  ```


