//
//  main.swift
//  MatftMLXDemo
//
//  Pre-processing with Matft (CPU, Numpy / transformers compatible) -> inference with MLX (GPU) -> post-processing with Matft.
//
//  The models below are the first layers of Whisper / CLIP / Qwen2-VL with RANDOM weights,
//  because this demo does not ship any checkpoint. Load the real weights (e.g. with mlx-swift-lm) to get meaningful outputs.
//
//  Usage: MatftMLXDemo [whisper|clip|qwen2vl|all] [image path]
//

import Foundation
import ImageIO
import Matft
import MLX
import MLXNN
import MLXRandom
import MatftMLX

// MARK: - inputs

/// 2 seconds of a 440 Hz sine wave at 16 kHz
func makeAudio() -> MfArray {
    let sr: Float = 16000
    let t = Matft.arange(start: 0, to: 2 * Int(sr), by: 1, mftype: .Float) / sr
    return Matft.math.sin(t * (2 * Float.pi * 440)) * Float(0.5)
}

/// An RGB UInt8 image (h, w, 3) from a file, or a synthetic gradient
func makeImage(path: String?) -> MfArray {
    if let path = path {
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
              let cgimage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            fatalError("Cannot load \(path)")
        }
        let rgba = Matft.image.cgimage2mfarray(cgimage, mftype: .UInt8)
        return rgba[Matft.all, Matft.all, 0~<3].to_contiguous(mforder: .Row)
    }
    let ys = Matft.arange(start: 0, to: 480, by: 1, mftype: .Float).reshape([480, 1, 1])
    let xs = Matft.arange(start: 0, to: 640, by: 1, mftype: .Float).reshape([1, 640, 1])
    let channels = MfArray([0, 60, 120] as [Float]).reshape([1, 1, 3])
    return Matft.clip(xs * 0.25 + ys * 0.2 + channels, min: Float(0), max: Float(255)).astype(.UInt8)
}

func describe(_ name: String, _ mfarray: MfArray) {
    let mean = Matft.stats.mean(mfarray).astype(.Double).scalar(Double.self)!
    print("  \(name): shape=\(mfarray.shape) mftype=\(mfarray.mftype) mean=\(String(format: "%.4f", mean))")
}

// MARK: - demos

/// Matft: Whisper log-mel -> MLX: the convolution stem of Whisper's audio encoder
func whisperDemo() {
    print("[Whisper] log-mel (Matft) -> encoder stem (MLX)")
    // Same as whisper.audio.log_mel_spectrogram: (n_mels, n_frames)
    let mel = Matft.audio.whisper_log_mel(makeAudio(), n_mels: 80)
    describe("log-mel (Matft)", mel)

    // MLX convolution takes NLC: (1, n_frames, n_mels). The transposed view is copied into a contiguous MLXArray
    let x = mel.T.toMLXArray().expandedDimensions(axis: 0)

    // whisper-tiny: n_audio_state = 384
    let conv1 = Conv1d(inputChannels: 80, outputChannels: 384, kernelSize: 3, padding: 1)
    let conv2 = Conv1d(inputChannels: 384, outputChannels: 384, kernelSize: 3, stride: 2, padding: 1)
    let hidden = gelu(conv2(gelu(conv1(x))))
    eval(hidden)

    // Back to Matft without copy
    let features = MfArray(mlx: hidden)
    describe("encoder stem output (MLX -> Matft)", features)
    print("  zero-copy: \(features.isSharingMemory(with: hidden))")
}

/// Matft: CLIP pre-processing -> MLX: the patch embedding of CLIP ViT-B/32
func clipDemo(image: MfArray) {
    print("[CLIP] CLIPImageProcessor (Matft) -> ViT-B/32 patch embedding (MLX)")
    // Same as transformers.CLIPImageProcessor: (1, 3, 224, 224)
    let pixelValues = Matft.image.clip_preprocess(image)
    describe("pixel_values (Matft)", pixelValues)

    // MLX convolution takes NHWC
    let x = pixelValues.toMLXArray().transposed(0, 2, 3, 1)

    let width = 768
    let patchEmbedding = Conv2d(inputChannels: 3, outputChannels: width, kernelSize: 32, stride: 32, bias: false)
    let classEmbedding = MLXRandom.normal([1, 1, width])
    let positionalEmbedding = MLXRandom.normal([1, 50, width]) * 0.02

    var tokens = patchEmbedding(x).reshaped([1, 49, width]) // (1, 7 * 7, width)
    tokens = concatenated([classEmbedding, tokens], axis: 1) + positionalEmbedding
    let normed = LayerNorm(dimensions: width)(tokens)
    eval(normed)

    // Post-processing with Matft: the L2 norm of each token
    let embeddings = MfArray(mlx: normed)
    describe("tokens (MLX -> Matft)", embeddings)
    let norms = Matft.linalg.normlp_vec(embeddings[0], ord: 2, axis: -1)
    describe("token L2 norms (Matft)", norms)
}

/// Matft: Qwen2-VL pre-processing -> MLX: the patch embedding and the patch merger of Qwen2-VL's vision encoder
func qwen2vlDemo(image: MfArray) {
    print("[Qwen2-VL] Qwen2VLImageProcessor (Matft) -> patch embedding + merger (MLX)")
    // Same as transformers.Qwen2VLImageProcessor: (grid_h * grid_w, 3 * 2 * 14 * 14)
    let (pixelValues, grid) = Matft.image.qwen2vl_preprocess(image)
    describe("pixel_values (Matft)", pixelValues)
    print("  image_grid_thw: \(grid)")

    // Conv3d(kernel = stride = (2, 14, 14)) over flattened patches is a Linear layer
    let embedDim = 1280, hiddenSize = 1536 // Qwen2-VL-2B
    let patchEmbedding = Linear(3 * 2 * 14 * 14, embedDim, bias: false)
    var hidden = patchEmbedding(pixelValues.toMLXArray())

    // PatchMerger: 2x2 neighbor patches are adjacent thanks to the patchify order
    hidden = LayerNorm(dimensions: embedDim)(hidden).reshaped([-1, embedDim * 4])
    let merger = Sequential(layers: Linear(embedDim * 4, embedDim * 4), GELU(), Linear(embedDim * 4, hiddenSize))
    let visionTokens = merger(hidden)
    eval(visionTokens)

    let tokens = MfArray(mlx: visionTokens)
    describe("vision tokens (MLX -> Matft)", tokens)
    print("  number of <|image_pad|> tokens: \(tokens.shape[0]) (= grid_h * grid_w / 4)")
}

// MARK: - main

let arguments = CommandLine.arguments.dropFirst()
let demo = arguments.first ?? "all"
let imagePath = arguments.dropFirst().first

switch demo {
case "whisper":
    whisperDemo()
case "clip":
    clipDemo(image: makeImage(path: imagePath))
case "qwen2vl":
    qwen2vlDemo(image: makeImage(path: imagePath))
case "all":
    let image = makeImage(path: imagePath)
    whisperDemo()
    clipDemo(image: image)
    qwen2vlDemo(image: image)
default:
    print("Usage: MatftMLXDemo [whisper|clip|qwen2vl|all] [image path]")
    exit(1)
}
