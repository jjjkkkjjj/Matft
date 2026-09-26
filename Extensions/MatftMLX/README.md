# MatftMLX

Conversion between [Matft](../../README.md)'s `MfArray` and [mlx-swift](https://github.com/ml-explore/mlx-swift)'s `MLXArray`.

Do the pre / post processing with Matft (CPU, float64, Numpy compatible), and the inference with MLX (GPU).

This is a separate package so that Matft itself does not depend on MLX
(MLX requires macOS 14 / iOS 17, Apple Silicon, a Metal toolchain and a large C++ build).

## Installation (via a local checkout)

SwiftPM cannot refer to a package in a subdirectory of a remote repository,
so check out Matft locally and add `Extensions/MatftMLX` as a local package.

### 1. Check out Matft

As a git submodule of your repository (recommended, the version is pinned by the submodule commit):

```sh
git submodule add https://github.com/jjjkkkjjj/Matft.git ThirdParty/Matft
git -C ThirdParty/Matft checkout <tag or commit>   # pin a version
git add ThirdParty/Matft && git commit -m "Add Matft"
```

Or simply clone it next to your project (`git clone https://github.com/jjjkkkjjj/Matft.git`).
Anyone who builds your project needs the checkout too (`git clone --recursive` or `git submodule update --init`).

### 2-a. Swift package

```swift
dependencies: [
    .package(path: "ThirdParty/Matft/Extensions/MatftMLX"),
    // If you also use Matft directly, refer to the same checkout by path.
    // Adding Matft by URL as well fails with "multiple similar targets 'Matft', 'pocketFFT' appear in package ...".
    .package(path: "ThirdParty/Matft"),
],
// Note: a path package is named after its directory, so `package: "Matft"` below assumes the checkout directory is `Matft`.
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "MatftMLX", package: "MatftMLX"),
        .product(name: "Matft", package: "Matft"),
    ]),
]
```

### 2-b. Xcode app project

File > Add Package Dependencies... > Add Local... > select `ThirdParty/Matft/Extensions/MatftMLX`,
then add the `MatftMLX` library to your app target. `Matft` comes along with it.

### Requirements

- Apple Silicon, macOS 14+ / iOS 17+ (MLX's requirements; MLX does not support the iOS simulator)
- Build with Xcode / `xcodebuild` with the Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`).
  `swift build` cannot build MLX's Metal shaders.
- Tested with mlx-swift 0.31.4 on Swift 6.2 (Xcode 26.2). mlx-swift 0.31.5 or later requires Swift 6.3;
  SwiftPM skips the versions which your toolchain does not support.

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
  MLX has no complex128, so a complex Double MfArray needs `toMLXArray(dtype: .complex64)` explicitly.
- Tiny arrays (up to 14 bytes) are always copied, because MLX does not expose their backing address.
- A shared MfArray keeps the MLXArray alive, so the memory stays valid after the MLXArray is released.
- A MLXArray made in share mode keeps the MfArray alive.

> [!IMPORTANT]
> Sharing Matft memory with MLX (`share: true` in Matft → MLX) lets MLX **write** into it.
> MLX reuses an input buffer for the output when the input array is released before the evaluation
> (buffer donation), e.g. `MLXArray(matft: a, share: true) + 1` can overwrite `a`.
> This is why Matft → MLX copies by default.

> [!NOTE]
> MLX supports float64 only on the CPU stream. Convert with `toMLXArray(dtype: .float32)` before using it on the GPU.

## Demo

[`Examples/MatftMLXDemo`](Examples/MatftMLXDemo/main.swift) pre-processes with Matft, runs the first layers of the models with MLX (GPU),
and post-processes the outputs with Matft.

| Demo | Matft (pre-processing) | MLX |
|---|---|---|
| `whisper` | `Matft.audio.whisper_log_mel` | the convolution stem of Whisper's audio encoder |
| `clip` | `Matft.image.clip_preprocess` | the patch embedding of CLIP ViT-B/32 |
| `qwen2vl` | `Matft.image.qwen2vl_preprocess` | the patch embedding and the patch merger of Qwen2-VL |

The model weights are random because no checkpoint is shipped. Load the real weights (e.g. with mlx-swift-lm) for meaningful outputs.

```sh
scripts/run-mlx-demo.sh                          # all demos with a synthetic image and a 440 Hz tone
scripts/run-mlx-demo.sh clip path/to/image.png   # whisper | clip | qwen2vl | all
```

## Test

The SwiftPM CLI (`swift test`) cannot build MLX's Metal shaders, and MLX fails to start without them even on the CPU.
Use Xcode's build system with the Metal toolchain installed.

```sh
xcodebuild -downloadComponent MetalToolchain  # only once
scripts/build-and-test-mlx.sh                  # from the repository root
scripts/build-and-test-mlx.sh MatftMLXTests.MLXToMatftTests
```
