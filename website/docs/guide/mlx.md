---
title: Using Matft with MLX
---

# Using Matft with MLX

## Matft and MLX

Matft is a **complement** to [mlx-swift](https://github.com/ml-explore/mlx-swift), not a replacement.
In short: **Matft plays the role of NumPy / SciPy / OpenCV / librosa, and MLX plays the role of PyTorch.**
Use Matft for exact, CPU-side pre / post processing and numerical work, and MLX for neural networks on the GPU.

| | Matft | mlx-swift (as of 2026-09, v0.31.4) |
|---|---|---|
| Backend | CPU (Accelerate) | GPU (Metal) + CPU |
| Hardware | Apple silicon and Intel Mac [^intel] | Apple silicon ([README](https://github.com/ml-explore/mlx-swift#readme), [#133](https://github.com/ml-explore/mlx-swift/issues/133)) |
| iOS Simulator | ✅ [^simulator] | ❌ ([Running on iOS](https://github.com/ml-explore/mlx-swift/blob/main/Source/MLX/Documentation.docc/Articles/running-on-ios.md)) |
| WebAssembly | ✅ ([build script](../contributing.md#webassembly-build--test)) | |
| Minimum OS | macOS 10.13 / iOS 12 | macOS 14 / iOS 17 |
| float64 | ✅ | CPU stream only ("float64 is not supported on the GPU") |
| complex128 | ✅ | ❌ (complex64 only) |
| Writing to a slice | Updates the original array like a NumPy [view](./views.md) | The slice is an independent array |
| Functions whose output shape depends on the data<br />(`unique`, `nonzero`, `argwhere`, `histogram`, `bincount`, `searchsorted`, set routines) | ✅ | ❌ |
| `percentile` / `quantile`, nan-functions, `lstsq`, `polyfit` | ✅ | ❌ (`median` ✅) |
| Image processing (OpenCV-like, PIL-compatible resize, CLIP / Qwen2-VL preprocessing) | ✅ ([Image](./image.md)) | NN layers only (conv, pooling, upsample) |
| Audio features (STFT, mel, Whisper log-mel) | ✅ ([Audio](./audio.md)) | FFT only |
| Autograd / NN layers / GPU training | ❌ | ✅ |

[^intel]: The tests are run on x86_64 under Rosetta. 3 tests (the integer overflow wrap-around of `Int16` and the `NaN` comparison in `==`) currently fail on x86_64.
[^simulator]: All the tests of `MatftTests` pass on the iOS Simulator (iPhone 16 Pro, iOS 18.6).

```swift
import Matft
import MLX
import MatftMLX

let pixelValues = Matft.image.clip_preprocess(rgb)        // (1, 3, 224, 224), same as CLIPImageProcessor
let output = model(pixelValues.toMLXArray())              // inference with MLX (GPU)
let result = MfArray(mlx: output)                         // back to Matft without copy (float32 / float64)
```

## MatftMLX

[MatftMLX](https://github.com/jjjkkkjjj/Matft/tree/main/Extensions/MatftMLX) converts between Matft's `MfArray` and [mlx-swift](https://github.com/ml-explore/mlx-swift)'s `MLXArray`.
Do the pre / post processing with Matft (CPU, float64, Numpy compatible), and the inference with MLX (GPU).

It is a separate package so that Matft itself does not depend on MLX
(MLX requires macOS 14 / iOS 17, Apple Silicon, a Metal toolchain and a large C++ build).

## Installation

SwiftPM cannot refer to a package in a subdirectory of a remote repository,
so check out Matft locally (e.g. as a git submodule) and add `Extensions/MatftMLX` as a local package.

```swift
dependencies: [
    .package(path: "ThirdParty/Matft/Extensions/MatftMLX"),
    // If you also use Matft directly, refer to the same checkout by path.
    .package(path: "ThirdParty/Matft"),
],
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "MatftMLX", package: "MatftMLX"),
        .product(name: "Matft", package: "Matft"),
    ]),
]
```

See the [MatftMLX README](https://github.com/jjjkkkjjj/Matft/blob/main/Extensions/MatftMLX/README.md) for the details (submodule setup, Xcode app projects and requirements).

## Usage

```swift
import Matft
import MLX
import MatftMLX

// MLX -> Matft (shares the memory if possible, by default)
let mf = MfArray(mlx: mlxArray)
let mfCopy = MfArray(mlx: mlxArray, share: false)

// Matft -> MLX (copies, by default)
let mx = MLXArray(matft: mfArray)
let mxShared = mfArray.toMLXArray(share: true)
let mxHalf = mfArray.toMLXArray(dtype: .float16)

mf.isSharingMemory(with: mlxArray) // true if both refer to the same memory
```

## Zero-copy conditions

| Direction | Shared when | Otherwise |
|---|---|---|
| MLX → Matft | `share: true` (default), float32 / float64, row contiguous | copied once |
| Matft → MLX | `share: true`, Float / Double (real), row contiguous | copied once |

- Integers, bool, float16 and bfloat16 are always copied, because Matft stores every type except for Double as Float.
- Complex numbers are always copied, because Matft stores the real / imag parts separately while MLX interleaves them.
  MLX has no complex128, so a complex Double `MfArray` needs `toMLXArray(dtype: .complex64)` explicitly.
- Tiny arrays (up to 14 bytes) are always copied, because MLX does not expose their backing address.
- A shared `MfArray` keeps the `MLXArray` alive, so the memory stays valid after the `MLXArray` is released.
- An `MLXArray` made in share mode keeps the `MfArray` alive.

:::warning
Sharing Matft memory with MLX (`share: true` in Matft → MLX) lets MLX **write** into it.
MLX reuses an input buffer for the output when the input array is released before the evaluation
(buffer donation), e.g. `MLXArray(matft: a, share: true) + 1` can overwrite `a`.
This is why Matft → MLX copies by default.
:::

:::note
MLX supports float64 only on the CPU stream. Convert with `toMLXArray(dtype: .float32)` before using it on the GPU.
:::

## Demo

[`Examples/MatftMLXDemo`](https://github.com/jjjkkkjjj/Matft/blob/main/Extensions/MatftMLX/Examples/MatftMLXDemo/main.swift) pre-processes with Matft, runs the first layers of the models with MLX (GPU),
and post-processes the outputs with Matft.

| Demo | Matft (pre-processing) | MLX |
|---|---|---|
| `whisper` | `Matft.audio.whisper_log_mel` | the convolution stem of Whisper's audio encoder |
| `clip` | `Matft.image.clip_preprocess` | the patch embedding of CLIP ViT-B/32 |
| `qwen2vl` | `Matft.image.qwen2vl_preprocess` | the patch embedding and the patch merger of Qwen2-VL |

```sh
scripts/run-mlx-demo.sh                          # all demos with a synthetic image and a 440 Hz tone
scripts/run-mlx-demo.sh clip path/to/image.png   # whisper | clip | qwen2vl | all
```
