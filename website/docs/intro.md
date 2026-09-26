---
slug: /intro
title: Introduction
sidebar_position: 1
---

# Matft

**Matft** is a Numpy-like multi-dimensional array library in Swift.
Function names, arguments and behaviors follow Numpy (e.g. `np.expand_dims` → `Matft.expand_dims`), so you can port Python code almost line by line.

```swift
import Matft

let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
let b = a[1~<3, Matft.all, 0]          // a[1:3, :, 0] in Numpy
let c = Matft.math.sin(a) + a.T        // broadcasting & element-wise math
```

## Features

- **`MfArray`** — an n-dimensional array like `numpy.ndarray`, with many types (`Bool`, `UInt8`…`Int64`, `Float`, `Double`, complex) and pretty print.
- **Indexing** — positive / negative indexing, slicing (`~<`), `newaxis`, **boolean** and **fancy** indexing.
- **Views** — slicing returns a view that shares memory with the original array, as in Numpy.
- **Broadcasting**, transpose, reshape, `astype` and universal function reduction.
- **Math, statistics, linear algebra, FFT** backed by Apple's Accelerate framework.
- **Complex numbers**.
- **Image processing** compatible with OpenCV (`cv2`), and preprocessing compatible with PIL / Hugging Face transformers.
- **Audio features** (STFT, mel spectrogram, Whisper log-mel) compatible with librosa.
- **MLX interop** — zero-copy conversion between `MfArray` and `MLXArray` via the separate [MatftMLX](./guide/mlx.md) package.

## Where to go next

- [Installation](./getting-started/installation.md) and [Quick Start](./getting-started/quick-start.md)
- [Guide](./guide/mfarray.md) — how to use `MfArray` step by step
- [NumPy Mapping](./numpy-mapping/index.md) — the list of Matft functions and their Numpy / OpenCV / librosa counterparts
- **API Reference** — every public symbol, generated from the source by Swift-DocC (see the navbar)
