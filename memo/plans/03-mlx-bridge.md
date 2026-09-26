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

## 実装結果（2026-09-27, branch `feature/mlx-bridge`）
配置は (a) `Extensions/MatftMLX` で確定．本体の `Package.swift` / 最小 OS は変更なし．テストは `scripts/build-and-test-mlx.sh`（20 件 Green）．

### スパイク結果（mlx-swift 0.31.4, macOS 26.2, Apple Silicon, Xcode 26.2）
- **ページアラインは不要**．`UnsafeMutableRawPointer.allocate(alignment: 4)` や +4 バイトずらしたポインタでも `MLXArray(rawPointer:)` はゼロコピーで受け取り，CPU・GPU ともに正しく計算（作成後の書き換えも GPU から見える）．
  - MLX core（`array.cpp`）は `allocator::make_buffer` が失敗すると **自動でコピーして deleter を即時呼ぶ** ため，どの環境でも正しさは保証される．→ Matft 本体にアライン確保オプションは追加しない．
- float64 は CPU stream で動作．
- **バッファ donation の罠**: `MLXArray(rawPointer:)` で包んだ配列が一時値として演算に渡ると，MLX は出力を入力バッファに書き込む（`is_donatable`: desc と data の use_count が 1）．→ Matft→MLX の共有は **オプトイン（デフォルト `share: false`）**．MLX→Matft は `MLXArrayOwner` が MLXArray を保持するので donation されない（ミューテーションテストで確認）．
- `Data(bytesNoCopy:)` は **14 バイト以下を inline コピー**するため，`asData(access: .noCopy)` のアドレスが実体と異なる．MLX に生ポインタを返す公開 API は無い → 14 バイト以下は常にコピー（`dataKeepsAddress` で実行時判定）．
- SwiftPM CLI（`swift test`）は **CPU デフォルトでも起動時に metallib ロードで失敗**（`Device.setDefault(.cpu)` でも不可）→ xcodebuild 必須．Metal Toolchain（`xcodebuild -downloadComponent MetalToolchain`, 約 700MB）が必要．
- `xcodebuild test`（test-without-building 含む）を **リポジトリ内のスクリプトから** 呼ぶと "Failed to create a bundle instance" で失敗する現象があり原因不明（スクリプトを /tmp に置くと成功）．→ スクリプトは `build-for-testing` + `xcrun xctest` で実行．
- mlx-swift 0.31.5 以降は `swift-tools-version: 6.3`．`from: "0.30.0"` 指定で Swift 6.2 では 0.31.4 に解決される（SwiftPM が非対応版をスキップ）．

### API（実装済み）
- `MfArray(mlx:share: = true)` / `MLXArray(matft:share: = false)` / `mfArray.toMLXArray(share: = false, dtype:)` / `mfArray.isSharingMemory(with:)`
- complex128 → `toMLXArray(dtype: .complex64)` の明示指定時のみ縮小（未指定は precondition failure）．

### 配布（決定: 当面ローカル checkout 経由）
- SwiftPM はリモートリポジトリのサブディレクトリのパッケージを参照できないため，submodule 等で checkout して `.package(path: ".../Extensions/MatftMLX")`．手順は `Extensions/MatftMLX/README.md`．
- 利用者が Matft を URL でも追加すると "multiple similar targets 'Matft', 'pocketFFT'" エラー → Matft も同じ checkout を path 参照する（検証済み）．
- 配布を重視する段階で (b) 別リポジトリ化を再検討．

### デモ（実装済み）
- `Examples/MatftMLXDemo`（`scripts/run-mlx-demo.sh`）: whisper_log_mel → Whisper encoder stem / clip_preprocess → CLIP ViT-B/32 patch embedding / qwen2vl_preprocess → Qwen2-VL patch embed + merger．重みはランダム．
- 罠: `mfarray * 0.5`（Double リテラル）で Float が Double に昇格し，MLX GPU で "float64 is not supported on the GPU" の fatalError．

### 残課題
- CI（GitHub Actions の macOS runner で Metal Toolchain を入れて回す）未整備．
- 学習済み重みを使うデモ（mlx-swift-lm 連携）．
