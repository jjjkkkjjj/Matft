# mlx-swift を踏まえた Matft 強化プラン（索引）

作成: 2026-09-27．別セッションから着手する場合はまずこのファイルを読むこと．
実装はすべて CLAUDE.md の TDD ルール（Red→Green→Refactor，期待値は Numpy/Python 実装に合わせる）に従う．

## プラン一覧

| # | ファイル | 概要 | 依存 |
|---|---|---|---|
| 1 | [01-audio-stft-mel.md](01-audio-stft-mel.md) | 窓関数・STFT・mel filterbank・log-mel（Whisper 前処理） | 4 の `pad`（reflect）|
| 2 | [02-vlm-preprocess.md](02-vlm-preprocess.md) | PIL/transformers 互換の VLM 画像前処理（`Matft.image` に統合，PIL bicubic, smart_resize, normalize_meanstd, patchify） | なし |
| 3 | [03-mlx-bridge.md](03-mlx-bridge.md) | `MfArray ⇄ MLXArray` ゼロコピー変換（別パッケージ） | なし（1,2 後のデモ推奨）|
| 4 | [04-numpy-gaps.md](04-numpy-gaps.md)（**4-A 実装済み**） | MLX に無い NumPy 関数（std/var, median/percentile, nan系, nonzero, unique, histogram, lstsq, pad …） | なし |
| 5 | [05-readme-positioning.md](05-readme-positioning.md) | README で MLX との住み分けを明示 | 1〜4 の進捗に応じ随時 |

推奨着手順: **4-A（pad, std/var 等の基礎）→ 1 → 2 → 4 残り → 3 → 5**
（1 が reflect pad を必要とするため 4 の `pad` を先行させる）

各プランは独立したブランチ・PR で進める（例: `feature/numpy-gaps-stats`, `feature/audio-stft-mel`）．

## 背景: mlx-swift 調査結果の要約（2026-09-27 時点，一次ソース確認済み）

- mlx-swift 最新タグ 0.31.6（2026-07），vendored mlx core ≈ v0.32.2．products: MLX, MLXRandom, MLXNN, MLXOptimizers, MLXFFT, MLXLinalg, MLXFast．
- 最小 OS: macOS 14 / iOS 17．**iOS Simulator 非対応，Intel Mac 非対応（#133）**．SwiftPM CLI では Metal shader をビルドできない（README）．C++ 約 260MB をソースビルド（#406）．
- dtype: float64 は **CPU のみ**（GPU で例外），**complex128 無し**，`[Double]` 初期化は Float32 に変換．C++ 例外は Swift に伝播せず基本 fatalError．
- 存在しない NumPy 関数: unique, nonzero, argwhere, where(1引数), nan 系, percentile/quantile, histogram, bincount, digitize, interp, polyfit/polyval, cov/corrcoef, lstsq(#3773), matrix_rank, expm, set 系．boolean mask は代入専用．スライスは copy．
- linalg はほぼ全て CPU stream のみ．FFT はあるが STFT 無し．
- 画像処理は NN 系（conv, pooling, Upsample）のみ．mlx-swift-lm は VLM 前処理を CoreImage + 手書き Metal bicubic カーネルで自前実装（`Libraries/MLXVLM/MediaProcessing.swift`）．
- 音声: mlx-swift-lm に mel/STFT 実装ゼロ（`ProcessedAudio(features:)` の器のみ）．
- Interop: `MLXArray(rawPointer:_:dtype:finalizer:)` で外部メモリをゼロコピー受け取り（Metal 互換メモリ要），`asData(access: .noCopy/.noCopyIfContiguous)` でゼロコピー取り出し．MLMultiArray/CVPixelBuffer/CGImage 変換は本体に無し．

## Matft 側の前提（コード確認済み）

- 内部保存型は Float / Double のみ（Int/Bool も Float or Double で保存）．複素数は real/imag の **分離バッファ**．
- `MfData(source:data_real_ptr:data_imag_ptr:storedSize:mftype:offset:)` で外部ポインタを共有（source 非 nil 時）可能．`MfDataBasable` で寿命管理．
- `MfArray(base: inout MLMultiArray, share:)` は共有，`toMLMultiArray()` はコピー．
- メモリ確保は `UnsafeMutableRawPointer.allocate(alignment: MemoryLayout<T>.alignment)`（ページ境界ではない）．
- 既存: `rfft/irfft`（pocketFFT, 任意長），`Matft.image.resize`（Nearest/Linear=cv2互換, Lanczos=vImage），`interp1d`，`orderedUnique`，`calcHist`（画像用）．
- 未実装: std/var, median, percentile, nan系, nonzero, where, unique, histogram, pad, diff, meshgrid, searchsorted, polyfit, lstsq, cov, 窓関数, stft, mel．
- `Package.swift` は tools 5.9，`platforms` 指定なし．README は Swift 6.1+ と記載．
- テスト用 Python/参照データ置き場: `python/`（現在空），`Tests/MatftTests/files/`，`scripts/`．
