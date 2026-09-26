---
title: Using Matft with MLX
---

# Using Matft with MLX

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
