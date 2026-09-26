# Plan 3: MfArray ⇄ MLXArray 変換（MatftMLX）

## 目的
「前処理・後処理は Matft（CPU, float64, NumPy 互換），推論は MLX（GPU）」という組み合わせを低コストにする．
可能な限りゼロコピー，不可能な場合は 1 回コピーで正しく変換する．

## 重要な制約（調査で判明）
- **Matft 本体に MLX 依存を入れない**．入れると macOS 14 / iOS 17 以上・Simulator/Intel 非対応・巨大 C++ ビルドが全ユーザーに伝染する．
- Matft の内部保存は Float/Double のみ（Int/Bool も Float 保存）→ **ゼロコピーできるのは float32 / float64 のみ**．int/bool/float16/bfloat16 は変換コピー．
- 複素数: Matft は real/imag 分離，MLX complex64 はインターリーブ → **常にコピー**（vDSP_ztoc / ctoz で変換）．complex128 は MLX に無い → float64 実部/虚部 2 本で返すか complex64 へ縮小（明示オプション）．
- MLX float64 は CPU stream 専用（GPU で使うと例外）．
- `MLXArray(rawPointer:_:dtype:finalizer:)` は **Metal 互換メモリ（ページ境界アラインが必要と思われる，要検証）** を要求．Matft の確保は `MemoryLayout<T>.alignment` アラインなので，そのままでは渡せない可能性 → 検証結果で方針分岐．
- `MLXArray.asData(access: .noCopy)` は内部で `eval()` を呼ぶ．非連続なら `.noCopyIfContiguous` がコピーにフォールバック．
- Matft の view（非連続，offset あり）→ MLX に渡す前に `to_contiguous` が必要な場合あり（MLX 側 strides 指定での受け取りが可能かも要検証）．

## なぜ本体と別パッケージにするのか
SwiftPM はパッケージが宣言した依存を，利用者がその product を使うか否かに関わらず解決・取得する．本体に mlx-swift を足すと MLX を使わない利用者にも以下が波及する:
- **swift-tools-version**: mlx-swift は 6.3 を要求 → 古い Swift ツールチェーンの Matft 利用者が依存解決で失敗する可能性が高い．
- **取得コスト**: mlx / mlx-c サブモジュールを含む巨大リポジトリを全員が clone．
- **OS 要件**: MLX 依存 target は macOS 14 / iOS 17 以上前提．同居させると `platforms` 管理が複雑化．
- **テスト運用**: SwiftPM CLI は MLX の Metal shader をビルドできない．本体の `swift test` 運用を守るため分離．
「別パッケージ」= 別リポジトリではなく，同一リポジトリ内に独自 `Package.swift` を持つサブディレクトリ．
package traits（Swift 6.1+）で optional 依存にする案は，trait 無効時も依存が解決対象になるか未確認．

## 配置（決定: 同一リポジトリ内のサブパッケージ）
```
Extensions/MatftMLX/
  Package.swift         // platforms: macOS 14, iOS 17; deps: Matft(path: "../.."), mlx-swift
  Sources/MatftMLX/
  Tests/MatftMLXTests/
```
代案: (b) 別リポジトリ `Matft-MLX`，(c) Package traits（swift-tools 6.1+）で本体に optional 依存．
→ (a) を推奨（本体の依存解決に影響せず，バージョンを揃えやすい）．

## API 設計（案）
```swift
import Matft
import MLX
import MatftMLX

// MLX -> Matft
let mf = MfArray(mlx: mlxArray, share: true)      // float32/float64 & 連続ならゼロコピー，それ以外はコピー
// Matft -> MLX
let mx = MLXArray(matft: mfArray, share: true)     // 条件を満たせばゼロコピー
let mx2 = mfArray.toMLXArray(dtype: .float16)      // dtype 変換付き（コピー）
```
- `share: true` でも共有できない場合はコピーにフォールバック（`isSharedWith` 等で確認できるテスト用 API も検討）．
- ゼロコピー時の寿命管理: MLX→Matft は MLXArray を保持する `MfDataBasable` 準拠ラッパを `MfData(source:...)` に渡す．Matft→MLX は `finalizer` で MfData の強参照を解放．

## TDD 手順
0. **スパイク（テスト前の調査，使い捨て）**: `MLXArray(rawPointer:)` に通常 `allocate` のポインタ / `posix_memalign(16384)` のポインタを渡して CPU・GPU 演算が正しく動くか確認．結果をこのファイルに追記して方針確定．
1. `Tests/MatftMLXTests/ConversionTests.swift` に Red:
   1. float32 連続: 値一致，shape 一致，**メモリ共有**（一方を書き換えて他方に反映 / ポインタ一致）
   2. float64（MLX CPU stream で計算して一致）
   3. int32/int64/bool/uint8 → 値一致（コピー）
   4. 非連続 view（転置・step スライス・負 stride）→ 値一致
   5. 複素数 → complex64 の往復
   6. 寿命: 元オブジェクトを解放した後も変換先が有効（ASan / 繰り返しテスト）
   7. 0 次元・空配列
2. 最小実装 → Green → リファクタ．
3. **ビルド**: GPU を使うテストは `xcodebuild test`（SwiftPM CLI は Metal shader 不可）．CPU のみのテストは `swift test` でも可か確認し，スクリプト `scripts/build-and-test-mlx.sh` を用意．

## デモ（Plan 1/2 完了後）
- `Extensions/MatftMLX/Examples/`（または MatftDemo）に「Matft で Whisper log-mel → MLX Whisper encoder」「Matft で CLIP 前処理 → MLX VLM」を置く．README（Plan 5）からリンク．

## 完了条件
- float32/float64 の連続配列で双方向ゼロコピーが実証済み（または不可能な理由と代替が文書化）．
- 全 dtype で値が正しく往復．
- Matft 本体の `Package.swift` と最小 OS が変わっていない．

## 未決事項
- 配置 (a)/(b)/(c) の最終決定．
- Matft 本体にページアラインの確保オプション（例: `MfData(size:mftype:alignment:)`）を追加するか — 追加する場合は本体側 TDD．
- CVPixelBuffer ⇄ MfArray（本体側 `#if canImport(CoreVideo)`）もこのプランで扱うか → 本体側の別小タスクとして扱うのを推奨．
