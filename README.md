# Matft

![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-success) ![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-outdated-red)  ![Carthage compatible](https://img.shields.io/badge/Carthage-outdated-red) ![license](https://img.shields.io/badge/license-BSD--3-green)

**Matft** is Numpy-like library in Swift. Function name and usage is similar to Numpy.

📖 **Documentation: <https://jjjkkkjjj.github.io/Matft/>**
([Guide](https://jjjkkkjjj.github.io/Matft/docs/intro) · [NumPy Mapping](https://jjjkkkjjj.github.io/Matft/docs/numpy-mapping) · [API Reference](https://jjjkkkjjj.github.io/Matft/api/documentation/matft))

```swift
import Matft

let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
let b = a[1~<3, Matft.all, 0]          // a[1:3, :, 0] in Numpy
let c = Matft.math.sin(a) + a.T        // broadcasting & element-wise math
a[a > 20] = MfArray([0])               // boolean indexing
```

## Features

- **`MfArray`** — an n-dimensional array like `numpy.ndarray`, with many types and pretty print
- **Indexing** — positive / negative indexing, slicing (`~<`), `newaxis`, boolean and fancy indexing, views sharing memory
- **Broadcasting**, transpose, reshape, `astype` and universal function reduction
- **Math, statistics, linear algebra and FFT** backed by the Accelerate framework ([performance](https://jjjkkkjjj.github.io/Matft/docs/performance))
- **Complex numbers**
- **Image processing** compatible with OpenCV, and preprocessing compatible with PIL / Hugging Face transformers ([visual check against OpenCV](https://jjjkkkjjj.github.io/Matft/docs/guide/image#visual-check-against-opencv))
- **Audio features** (STFT, mel spectrogram, Whisper log-mel) compatible with librosa
- **MLX interop** — zero-copy conversion between `MfArray` and `MLXArray` via [MatftMLX](./Extensions/MatftMLX)

See the [NumPy Mapping](https://jjjkkkjjj.github.io/Matft/docs/numpy-mapping) for all functions.

## Matft and MLX

Matft is a **complement** to [mlx-swift](https://github.com/ml-explore/mlx-swift), not a replacement.
In short: **Matft plays the role of NumPy / SciPy / OpenCV / librosa, and MLX plays the role of PyTorch.**
Use Matft for exact, CPU-side pre / post processing and numerical work, and MLX for neural networks on the GPU.

```swift
import Matft
import MLX
import MatftMLX

let pixelValues = Matft.image.clip_preprocess(rgb)        // (1, 3, 224, 224), same as CLIPImageProcessor
let output = model(pixelValues.toMLXArray())              // inference with MLX (GPU)
let result = MfArray(mlx: output)                         // back to Matft without copy (float32 / float64)
```

See [Using Matft with MLX](https://jjjkkkjjj.github.io/Matft/docs/guide/mlx) for the comparison table with mlx-swift and the details of [MatftMLX](./Extensions/MatftMLX).

## Installation

Add Matft with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/jjjkkkjjj/Matft", from: "1.0.1"),
],
```

In Xcode: File > Add Package Dependencies... and enter `https://github.com/jjjkkkjjj/Matft`.
Carthage and CocoaPods are outdated; see [Installation](https://jjjkkkjjj.github.io/Matft/docs/getting-started/installation).

Requirements: Swift 6.1 or later, macOS 10.13+ / iOS 12+. WebAssembly is also supported.

## Development

```bash
./scripts/build-and-test-ios.sh    # build & test on iOS/macOS
./scripts/build-and-test-wasm.sh   # build & test on WebAssembly
./scripts/build-and-test-mlx.sh    # build & test MatftMLX (Xcode with the Metal Toolchain)
./scripts/build-docs.sh            # build the API reference
```

See [Contributing](https://jjjkkkjjj.github.io/Matft/docs/contributing) for the details. The documentation site is in [website/](./website).

## Contact

Feel free to ask this project or anything via <junnosuke.kado.git@gmail.com>
