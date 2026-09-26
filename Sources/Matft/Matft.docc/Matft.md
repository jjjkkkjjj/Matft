# ``Matft``

Numpy-like multi-dimensional array library in Swift.

## Overview

Matft provides ``MfArray``, an n-dimensional array like `numpy.ndarray`, and functions whose names, arguments and behaviors follow Numpy, backed by Apple's Accelerate framework.

```swift
import Matft

let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
let b = a[1~<3, Matft.all, 0]          // a[1:3, :, 0] in Numpy
let c = Matft.math.sin(a) + a.T        // broadcasting & element-wise math
```

This is the API reference generated from the source code.
For the guides, the list of Numpy counterparts and the image comparison with OpenCV, see the [Matft documentation](https://jjjkkkjjj.github.io/Matft/).

## Topics

### Arrays

- ``MfArray``
- ``MfType``
- ``MfOrder``
- ``MfSlice``
- ``SubscriptOps``
- ``MfError``

### Namespaces

- ``Matft``
- ``Matft/math``
- ``Matft/stats``
- ``Matft/linalg``
- ``Matft/fft``
- ``Matft/complex``
- ``Matft/random``
- ``Matft/file``
- ``Matft/interp1d``
- ``Matft/image``
- ``Matft/audio``

### Sorting, Searching and Statistics Options

- ``MfSortOrder``
- ``MfSearchSide``
- ``MfQuantileMethod``
- ``MfMeshIndexing``
- ``MfPadMode``

### Interpolation and FFT

- ``Interp1d``
- ``CubicSpline``
- ``MfInterpolation``
- ``FFTNorm``

### Image Processing Options

- ``MfColorConversion``
- ``MfThresholdType``
- ``MfAdaptiveMethod``
- ``MfBorderType``
- ``MfNormType``
- ``MfMorphOp``
- ``MfMorphShape``
- ``MfResample``
- ``MfRotateCode``
- ``MfAffineMode``

### Audio Options

- ``MfWindowType``
- ``MfMelNorm``

### Storage

- ``MfData``
- ``MfStructure``
- ``StoredType``
