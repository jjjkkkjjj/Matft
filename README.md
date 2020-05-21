# Matft

**Matft** is Numpy-like library in Swift. Function name and usage is similar to Numpy.

## Feature & Usage

### Declaration

#### MfArray

- The **MfArray** such like a numpy.ndarray

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

#### MfType

- You can pass **MfType** as MfArray's argument ``mftype: .Hoge ``. It is similar to  `dtype`.
  
  ※Note that stored data type will be Float or Double only even if you set MfType.Int.
So, if you input big number to MfArray, it may be cause to overflow or strange results in any calculation (+, -, *, /,...  etc.). But I believe this is not problem in practical use.
  
- MfType's list is below
  
  ```swift
	public enum MfType: Int{
      case None // Unsupportted
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
      case Object // Unsupported
  }
  ```
  
- Also, you can convert MfType easily using ``astype``

  ```swift
  let a = MfArray([[[ -8,  -7,  -6,  -5],
                    [ -4,  -3,  -2,  -1]],
          
                   [[ 0,  1,  2,  3],
                    [ 4,  5,  6,  7]]])
  print(a)//See above. if mftype is not passed, MfArray infer MfType. In this example, it's MfType.Int
  
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
  //Above output is same as numpy!
  /*
  >>> np.arange(-8, 8, dtype=np.uint32).reshape(2,2,4)
  array([[[4294967288, 4294967289, 4294967290, 4294967291],
          [4294967292, 4294967293, 4294967294, 4294967295]],
  
         [[         0,          1,          2,          3],
          [         4,          5,          6,          7]]], dtype=uint32)
  */
  
  print(aa.astype(.Float))
  /*
  mfarray = 
  [[[	-8.0,		-7.0,		-6.0,		-5.0],
  [	-4.0,		-3.0,		-2.0,		-1.0]],
  
  [[	0.0,		1.0,		2.0,		3.0],
  [	4.0,		5.0,		6.0,		7.0]]], type=Float, shape=[2, 2, 4]
  */
  ```

### Subscription

#### MfSlice

- You can access specific data using subscript.
  

You can set **MfSlice** (see below's list) to subscript.

  - ```swift
    MfSlice(start: Int? = nil, to: Int? = nil, by: Int = 1)
    ```
  
  - ```swift
    Matft.newaxis
    ```

  - ```swift
    ~ //this is prefix, postfix and infix operator. same as python's slice, ":"
    ```

#### (Positive) Indexing

- Normal indexing
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

  #### Slicing

- If you replace ``:`` with ``~``, you can get sliced mfarray.
Note that use `a[0~]` instead of `a[:]` to get all elements along axis.
  
  ```swift
  print(a[~1])  //same as a[:1] for numpy
  /*
  mfarray = 
  [[[	9,		10,		11],
  [	12,		13,		14],
  [	15,		16,		17]]], type=Int, shape=[1, 3, 3]
  */
  print(a[1~3]) //same as a[1:3] for numpy
  /*
  mfarray = 
  [[[	9,		10,		11],
  [	12,		13,		14],
  [	15,		16,		17]],
  
  [[	18,		19,		20],
  [	21,		22,		23],
  [	24,		25,		26]]], type=Int, shape=[2, 3, 3]
  */
  print(a[~~2]) //same as a[::2] for numpy
  /*
  mfarray = 
  [[[	0,		1,		2],
  [	3,		4,		5],
  [	6,		7,		8]],
  
  [[	18,		19,		20],
  [	21,		22,		23],
  [	24,		25,		26]]], type=Int, shape=[2, 3, 3]
  */
  ```

#### Negative Indexing

- Negative indexing is also available
  That's implementation was hardest for me...

  ```swift
  print(a[~-1])
  /*
  mfarray = 
  [[[	0,		1,		2],
  [	3,		4,		5],
  [	6,		7,		8]],
  
  [[	9,		10,		11],
  [	12,		13,		14],
  [	15,		16,		17]]], type=Int, shape=[2, 3, 3]
  */
  print(a[-1~-3])
  /*
  mfarray = 
  	[], type=Int, shape=[0, 3, 3]
  */
  print(a[~~-1])
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
  [	6,		7,		8]]], type=Int, shape=[3, 3, 3]*/
  ```

#### View

- Note that returned subscripted mfarray will have `base` property (is similar to `view` in Numpy). See [numpy doc](https://docs.scipy.org/doc/numpy/reference/generated/numpy.ndarray.view.html) in detail.

  ```swift
  let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
              
  let b = a[0~, 1]
  b[~~-1] = MfArray([9999]) // cannot pass Int directly such like 9999
  
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

## Function List

Below is Matft's function list. As I mentioned above, almost functions are similar to Numpy. Also, these function use Accelerate framework inside, the perfomance may keep high.

\* means method function exists too. Shortly, you can use `a.shallowcopy()` when `a` is `MfArray`.

- Creation

| Matft                      | Numpy             |
| -------------------------- | ---------------- |
| *Matft.shallowcopy | *numpy.copy       |
| *Matft.deepcopy    | copy.deepcopy     |
| Matft.nums         | numpy.ones * N    |
| Matft.arange       | numpy.arange      |
| Matft.eye          | numpy.eye         |
| Matft.diag         | numpy.diag        |
| Matft.vstack       | numpy.vstack      |
| Matft.hstack       | numpy.hstack      |
| Matft.concatenate  | numpy.concatenate |


- Conversion

| Matft                       | Numpy                    |
| --------------------------- | ----------------------- |
| *Matft.astype       | *numpy.astype            |
| *Matft.transpose    | *numpy.transpose         |
| *Matft.expand_dims  | *numpy.expand_dims       |
| *Matft.squeeze      | *numpy.squeeze           |
| *Matft.broadcast_to | *numpy.broadcast_to      |
| *Matft.conv_order   | *numpy.ascontiguousarray |
| *Matft.flatten      | *numpy.flatten           |
| *Matft.flip         | *numpy.flip              |
| *Matft.clip         | *numpy.clip              |
| *Matft.swapaxes     | *numpy.swapaxes          |
| *Matft.moveaxis     | *numpy.moveaxis          |
| *Matft.sort         | *numpy.sort              |
| *Matft.argsort      | *numpy.argsort           |

- File
  save function has not developed yet.

| Matft                         | Numpy            |
| ----------------------------- | :--------------- |
| Matft.file.loadtxt    | numpy.loadtxt    |
| Matft.file.genfromtxt | numpy.genfromtxt |

- Operation

  Line 2 is infix (prefix) operator.

| Matft                          | Numpy                      |
| ------------------------------ | ------------------------- |
| Matft.add<br />+       | numpy.add<br />+           |
| Matft.sub<br />-       | numpy.sub<br />-           |
| Matft.div<br />/       | numpy.div<br />.           |
| Matft.mul<br />*       | numpy.multiply<br />*      |
| Matft.inner<br />*+    | numpy.inner<br />n/a       |
| Matft.cross<br />*^    | numpy.cross<br />n/a       |
|Matft.matmul<br />*&　　　|numpy.matmul<br />@　|
| Matft.equal<br />===   | numpy.equal<br />==        |
| Matft.not_equal<br />!==   | numpy.not_equal<br />!=        |
| Matft.allEqual<br />== | numpy.array_equal<br />n/a |
| Matft.neg<br />-       | numpy.negative<br />-      |

- Math function

| Matft                    | Numpy       |
| ------------------------ | ---------- |
| Matft.math.sin   | numpy.sin   |
| Matft.math.asin  | numpy.asin  |
| Matft.math.sinh  | numpy.sinh  |
| Matft.math.asinh | numpy.asinh |
| Matft.math.sin   | numpy.cos   |
| Matft.math.acos  | numpy.acos  |
| Matft.math.cosh  | numpy.cosh  |
| Matft.math.acosh | numpy.acosh |
| Matft.math.tan   | numpy.tan   |
| Matft.math.atan  | numpy.atan  |
| Matft.math.tanh  | numpy.tanh  |
| Matft.math.atanh | numpy.atanh |

Other function is also available. See [here](https://github.com/jjjkkkjjj/Matft/blob/master/Sources/Matft/core/function/math_func.swift).

- Statistics function

| Matft                       | Numpy         |
| --------------------------- | ------------ |
| *Matft.stats.mean   | *numpy.mean   |
| *Matft.stats.max    | *numpy.max    |
| *Matft.stats.argmax | *numpy.argmax |
| *Matft.stats.min    | *numpy.min    |
| *Matft.stats.argmin | *numpy.argmin |
| *Matft.stats.sum    | *numpy.sum    |
| Matft.stats.maximum | numpy.maximum |
| Matft.stats.minimum | numpy.minimum |


- Linear algebra

| Matft                            | Numpy              |
| -------------------------------- | ----------------- |
| Matft.linalg.solve       | numpy.linalg.solve |
| Matft.linalg.inv         | numpy.linalg.inv   |
| Matft.linalg.det         | numpy.linalg.det   |
| Matft.linalg.eigen       | numpy.linalg.eig   |
| Matft.linalg.svd         | numpy.linalg.svd   |
| Matft.linalg.polar_left  | scipy.linalg.polar |
| Matft.linalg.polar_right | scipy.linalg.polar |
| Matft.linalg.normlp_vec | scipy.linalg.norm |
| Matft.linalg.normfro_mat | scipy.linalg.norm |
| Matft.linalg.normnuc_mat | scipy.linalg.norm |

<!--

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

-->

## Performance

I use ``Accelerate``, so all of MfArray operation may keep high performance.

```swift
func testPefAdd1() {
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = Matft.arange(start: 0, to: -10*10*10*10*10*10, by: -1, shape: [10,10,10,10,10,10])
            
            self.measure {
                let _ = a+b
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd1]' measured [Time, seconds] average: 0.001, relative standard deviation: 23.418%, values: [0.001707, 0.001141, 0.000999, 0.000969, 0.001029, 0.000979, 0.001031, 0.000986, 0.000963, 0.001631]
            1.14ms
             */
        }
    }
    
    func testPefAdd2(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [0,3,4,2,1,5])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd2]' measured [Time, seconds] average: 0.004, relative standard deviation: 5.842%, values: [0.004680, 0.003993, 0.004159, 0.004564, 0.003955, 0.004200, 0.003998, 0.004317, 0.003919, 0.004248]
            4.20ms
             */
        }
    }

    func testPefAdd3(){
        do{
            let a = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
            let b = a.transpose(axes: [1,2,3,4,5,0])
            let c = a.T
            
            self.measure {
                let _ = b+c
            }
            /*
             '-[MatftTests.ArithmeticPefTests testPefAdd3]' measured [Time, seconds] average: 0.004, relative standard deviation: 16.815%, values: [0.004906, 0.003785, 0.003702, 0.005981, 0.004261, 0.003665, 0.004083, 0.003654, 0.003836, 0.003874]
            4.17ms
             */
        }
```
Matft achieved almost same performance as Numpy!!!

※Swift's performance test was conducted in release mode

My codes have several overhead and redundant part so this performance could be better than now.

```python
import numpy as np
#import timeit

a = np.arange(10**6).reshape((10,10,10,10,10,10))
b = np.arange(0, -10**6, -1).reshape((10,10,10,10,10,10))

#timeit.timeit("b+c", repeat=10, globals=globals())
%timeit -n 10 a+b
"""
962 µs ± 273 µs per loop (mean ± std. dev. of 7 runs, 10 loops each)
"""

a = np.arange(10**6).reshape((10,10,10,10,10,10))
b = a.transpose((0,3,4,2,1,5))
c = a.T
#timeit.timeit("b+c", repeat=10, globals=globals())
%timeit -n 10 b+c
"""
5.68 ms ± 1.45 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
"""

a = np.arange(10**6).reshape((10,10,10,10,10,10))
b = a.transpose((1,2,3,4,5,0))
c = a.T
#timeit.timeit("b+c", repeat=10, globals=globals())
%timeit -n 10 b+c
"""
3.92 ms ± 897 µs per loop (mean ± std. dev. of 7 runs, 10 loops each)
"""
```



## Installation

### SwiftPM

- Import
  - Project > Build Setting > + ![Build Setting](https://user-images.githubusercontent.com/16914891/77144994-b0c72280-6aca-11ea-8633-1fb1a13ec74d.png)
  - Select Rules
    ![select](https://user-images.githubusercontent.com/16914891/77144995-b1f84f80-6aca-11ea-8f4d-911bd96013cb.png) 
- Update
  - File >Swift Packages >Update to Latest Package versions
    ![update](https://user-images.githubusercontent.com/16914891/77145225-4367c180-6acb-11ea-98ea-8d7a5a2a669f.png)

<!--

### Carthage

- Set Cartfile

	```/bin/bash
  echo 'github "realm/realm-cocoa"' > Cartfile
	carthage update ###or append '--platform ios'
	```

- Import Matft.framework made by above process to your project

-->

### CocoaPods

- Create Podfile (Skip if you have already done)

  ```bash
  pod init
  ```

- Write `pod 'Matft'` in Podfile such like below

  ```bash
  target 'your project' do
    pod 'Matft'
  end
  ```

- Install Matft

  ```bash
  pod install
  ```

  
