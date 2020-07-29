# Matft

![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-success) ![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-success)  ![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-success) ![license](https://img.shields.io/badge/license-BSD--3-green)

**Matft** is Numpy-like library in Swift. Function name and usage is similar to Numpy.

- [Matft](#matft)
  * [Feature & Usage](#feature---usage)
    + [Declaration](#declaration)
      - [MfArray](#mfarray)
      - [MfType](#mftype)
    + [Subscription](#subscription)
      - [MfSlice](#mfslice)
      - [(Positive) Indexing](#-positive--indexing)
      - [Slicing](#slicing)
      - [Negative Indexing](#negative-indexing)
      - [Boolean Indexing(*New!!!*)](#boolean-indexing--new-----)
      - [View](#view)
  * [Function List](#function-list)
  * [Performance](#performance)
  * [Installation](#installation)
    + [SwiftPM](#swiftpm)
    + [Carthage](#carthage)
    + [CocoaPods](#cocoapods)

Note: You can use [Protocol version(beta version)](https://github.com/jjjkkkjjj/Matft/tree/protocol) too.

## Feature & Usage

- Many types

- Pretty print

- Indexing

  - Positive
  - Negative
  - Boolean

- Slicing

  - Start / To / By
  - New Axis

- View

  - Assignment

- Conversion

  - Broadcast
  - Transpose
  - Reshape
  - Astype

- Mathematic

  - Arithmetic
  - Statistic
  - Linear Algebra

...etc.

See [Function List](#Function-List) for all functions.

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
    ~< //this is prefix, postfix and infix operator. same as python's slice, ":"
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

- If you replace ``:`` with ``~<``, you can get sliced mfarray.
Note that use `a[0~<]` instead of `a[:]` to get all elements along axis.
  
  ```swift
  print(a[~<1])  //same as a[:1] for numpy
  /*
  mfarray = 
  [[[	9,		10,		11],
  [	12,		13,		14],
  [	15,		16,		17]]], type=Int, shape=[1, 3, 3]
  */
  print(a[1~<3]) //same as a[1:3] for numpy
  /*
  mfarray = 
  [[[	9,		10,		11],
  [	12,		13,		14],
  [	15,		16,		17]],
  
  [[	18,		19,		20],
  [	21,		22,		23],
  [	24,		25,		26]]], type=Int, shape=[2, 3, 3]
  */
  print(a[~<~<2]) //same as a[::2] for numpy
  //print(a[~<<2]) //alias
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
  print(a[~<~<-1])
  //print(a[~<<-1]) //alias
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

#### Boolean Indexing(*New!!!*)

- You can use boolean indexing.

  Caution! I don't check performance, so this boolean indexing may be slow

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

  

#### View

- Note that returned subscripted mfarray will have `base` property (is similar to `view` in Numpy). See [numpy doc](https://docs.scipy.org/doc/numpy/reference/generated/numpy.ndarray.view.html) in detail.

  ```swift
  let a = Matft.arange(start: 0, to: 4*4*2, by: 1, shape: [4,4,2])
              
  let b = a[0~<, 1]
  b[~<<-1] = MfArray([9999]) // cannot pass Int directly such like 9999
  
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

\* means method function exists too. Shortly, you can use `a.shallowcopy()` where `a` is `MfArray`.

^ means method function only. Shortly, you can use `a.tolist()` **not** `Matft.tolist` where `a` is `MfArray`.

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
| ^MfArray.toArray | ^numpy.ndarray.tolist |

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
| Matft.less<br />< | numpy.less<br />< |
| Matft.less_equal<br /><= | numpy.less_equal<br /><= |
| Matft.greater<br />> | numpy.greater<br />> |
| Matft.greater_equal<br />>= | numpy.greater_equal<br />>= |
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
| Matft.math.sqrt | numpy.sqrt |
| Matft.math.rsqrt | numpy.rsqrt |
| Matft.math.exp | numpy.exp |
| Matft.math.log | numpy.log |
| Matft.math.log2 | numpy.log2 |
| Matft.math.log10 | numpy.log10 |
| *Matft.math.ceil | numpy.ceil |
| *Matft.math.floor | numpy.floor |
| *Matft.math.trunc | numpy.trunc |
| *Matft.math.nearest | numpy.nearest |
| *Matft.math.round | numpy.round |
| Matft.math.abs | numpy.abs |
| Matft.math.reciprocal | numpy.reciprocal |
| Matft.math.power | numpy.power |
| Matft.math.square | numpy.square |
| Matft.math.sign | numpy.sign |

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
| Matft.stats.sumsqrt | n/a |
| Matft.stats.squaresum | n/a |


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

### Carthage

- Set Cartfile

	```/bin/bash
  echo 'github "jjjkkkjjj/Matft"' > Cartfile
	carthage update ###or append '--platform ios'
	```

- Import Matft.framework made by above process to your project

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

  
