# Matft

**Matft** is Numpy-like library in Swift

## Feature & Usage

### Declaration

#### MfArray

- The **MfArray** such like a numpy.ndarray

  ```swift
  let a = MfArray([[[ -8,  -7,  -6,  -5],
                    [ -4,  -3,  -2,  -1]],
          
                   [[ 0,  1,  2,  3],
                    [ 4,  5,  6,  7]]])
  let aa = Matft.mfarray.arange(start: -8, stop: 8, step: 1, shape: [2,2,4])
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

- You can pass **MfType** as MfArray's argument ``mftype: .Hoge ``.
  ※Note that stored data type will be Float or Double only even if you set MfType.Int.
  So, if you input big number to MfArray, it may be cause to overflow or strange results in any calculation (+,-,*,/ etc.). But I believe this is not problem in practical use.

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
    Matft.mfarray.newaxis
    ```

  - ```swift
    ~ //this is prefix, postfix and infix operator. same as python's slice, ":"
    ```

#### (Positive) Indexing

- Normal indexing


```swift  
let a = Matft.mfarray.arange(start: 0, stop: 27, step: 1, shape: [3,3,3])
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

<!-- 

#### View

- Note that returned subscripted mfarray will have ``View`` property. See [numpy doc](https://docs.scipy.org/doc/numpy/reference/generated/numpy.ndarray.view.html) in detail.

  ```swift
  let a = Matft.mfarray.arange(start: 0, stop: 27, step: 1, shape: [3,3,3])
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
  let b = a[0~, 1~2]
  b[0~] = MfArray([999999])
      print(b)
      print(a)
  /*
  mfarray = 
  [[[	3,		4,		5]],
  
  [[	12,		13,		14]],
  
  [[	21,		22,		23]]], type=Int, shape=[3, 1, 3]
  */
  /*
  mfarray = 
  [[[	999999,		999999,		999999],
  [	3,		4,		5],
  [	6,		7,		8]],
  
  [[	999999,		999999,		999999],
  [	12,		13,		14],
  [	15,		16,		17]],
  
  [[	999999,		999999,		999999],
  [	21,		22,		23],
  [	24,		25,		26]]], type=Int, shape=[3, 3, 3]*/
  ```
-->

### Conversion

#### Transpose

- You can get transposed mfarray by using method ``T``, ``transpose(axes: [Int]? = nil)`` or ``Matft.mfarray.transpose(axes: [Int]? = nil)``

```swift
let a = Matft.mfarray.arange(start: 0, stop: 27, step: 1, shape: [3,3,3])
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

- Reshape is also available. Use method ``reshape(_ axis: [Int])`` or ``Matft.mfarray.reshape(_ axis: [Int])``

```swift
let b = Matft.mfarray.arange(start: 0, stop: 16, step: 1, shape: [2,4,2])
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
  let a = Matft.mfarray.arange(start: 1, stop: 9, step: 2, shape: [2,2])
  let b = Matft.mfarray.arange(start: 1, stop: 5, step: 1, shape: [2,2])
  print(a)
  /*
  mfarray = 
  [[	1,		3],
  [	5,		7]], type=Int, shape=[2, 2]
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
  let a = Matft.mfarray.arange(start: 1, stop: 9, step: 2, shape: [2,2])
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
  let a = Matft.mfarray.arange(start: 0, stop: 4, step: 1)
  print(a)
  print(Matft.mfarray.math.sin(a))
  print(Matft.mfarray.math.cos(a))
  print(Matft.mfarray.math.tan(a))
  print(Matft.mfarray.math.log(a))
  print(Matft.mfarray.math.exp(a))
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
  print(Matft.mfarray.math.power(a, exponents: b))
  /*
  mfarray = 
  [	1.0,		-0.7,		2.89,		9.261000000000003], type=Double, shape=[4]
  */
  ```

  

#### Approximation

- Basic approximation is also available.
  ```swift
  let b = MfArray([0.23, -0.7, 1.7, 2.1])
  print(Matft.mfarray.math.floor(b))
  print(Matft.mfarray.math.ceil(b))
  print(Matft.mfarray.math.nearest(b))
  /*
  mfarray = 
  [	0.0,		-1.0,		1.0,		2.0], type=Double, shape=[4]
  mfarray = 
  [	1.0,		-0.0,		2.0,		3.0], type=Double, shape=[4]
  mfarray = 
  [	0.0,		-1.0,		2.0,		2.0], type=Double, shape=[4]
  */
  ```


### Reducing

### Linear Algebra



## Performance



## Installation

### SwiftPM

- Import
  - Project > Build Setting > + ![Build Setting](https://user-images.githubusercontent.com/16914891/77144994-b0c72280-6aca-11ea-8633-1fb1a13ec74d.png)
  - Select Rules
    ![select](https://user-images.githubusercontent.com/16914891/77144995-b1f84f80-6aca-11ea-8f4d-911bd96013cb.png) 
- Update
  - File >Swift Packages >Update to Latest Package versions
    ![update](https://user-images.githubusercontent.com/16914891/77145225-4367c180-6acb-11ea-98ea-8d7a5a2a669f.png)

### Carthage

- Set Cartfile

	```/bin/bash
  echo 'github "realm/realm-cocoa"' > Cartfile
	carthage update ###or append '--platform ios'
	```

- Import Matft.framework made by above process to your project

