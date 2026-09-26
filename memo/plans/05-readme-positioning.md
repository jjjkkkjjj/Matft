# Plan 5: README での位置付け（MLX との住み分け）

## 目的
Matft が mlx-swift の代替ではなく **補完** であることを README で明示し，選ばれる理由を伝える．コストほぼゼロで即着手可能．
（ドキュメント変更なので TDD 対象外．ただし記載する事実はコード・テストで裏付けのあるものだけにする）

## 追加する節（案）

### 1. "Matft vs MLX" / "When to use Matft"
| | Matft | mlx-swift |
|---|---|---|
| Backend | CPU (Accelerate), no external deps | GPU (Metal) + CPU |
| float64 / complex128 | ✅ | float64 CPU only / no complex128 |
| iOS Simulator / Intel Mac | ✅ | ❌ |
| Minimum OS | (Package.swift で確定させた値) | macOS 14 / iOS 17 |
| Data-dependent ops (unique, nonzero, histogram…) | ✅（Plan 4 完了分） | ❌ |
| Slicing | View (no copy) | Copy |
| Image processing (cv2-like) | ✅ | ❌ |
| Audio features (STFT, mel) | ✅（Plan 1 完了後） | ❌ |
| Autograd / NN / GPU training | ❌ | ✅ |

→ 「NumPy/SciPy/cv2 の役割は Matft，PyTorch の役割は MLX」という 1 行サマリ．
表中の MLX 側の記述は日付と参照リンク（mlx-swift README, docs/data_types, issue #133）を付ける．

### 2. "Using Matft with MLX"（Plan 3 完了後）
- `MatftMLX` のインストールと変換例，ゼロコピー条件．
- デモへのリンク（Whisper log-mel, CLIP 前処理）．

### 3. 関数一覧の更新
- Plan 1, 2, 4 で追加した関数を README / `memo/usage.md` に追記．

## 手順
1. 現時点で事実として言える項目だけで節 1 を先行追加（float64, Simulator/Intel, view スライス, 画像処理）．
2. **Minimum OS を確定**: Package.swift に `platforms` が無く，podspec は iOS 10．実際に動作確認できる最小 OS を調べて README と揃える（必要なら Package.swift に `platforms` を明示 — これはコード変更なので別 PR）．
3. Plan 1/2/3/4 の各 PR で該当行を ✅ に更新する運用にする（各 PR のチェックリストに「README 更新」を入れる）．

## 完了条件
- README に比較表と使い分けの説明があり，記載内容がすべて検証済み．
- Plan 3 完了後に MLX 連携の節が追加されている．

## 注意
- 他プロジェクトを貶める書き方をしない（事実ベース，リンク付き）．
- MLX 側の状況は変わるので「as of 2026-09」と明記．

## 実装結果（2026-09-27, branch `docs/readme-positioning`）
- README 冒頭に "Matft and MLX"（比較表 + 1 行サマリ）と "Using Matft with MLX"，Build Scripts に MatftMLX を追加．
- 表の各行の裏付け:
  - MLX 側（mlx-swift 0.31.4 のソースで確認）: `platforms` macOS 14 / iOS 17，Simulator 非対応（docc `running-on-ios.md`），complex128 なし（`DType`），float64 GPU 不可（実行時 fatalError を実測），unique/nonzero/argwhere/histogram/bincount/searchsorted/percentile/quantile/nan 系/lstsq なし（median はある），STFT なし，MLXNN に conv/pooling/upsample．スライスへの書き込みが元配列に伝播しないことを実測．
  - Matft 側: x86_64（Rosetta）で全テスト実行 → **3 件失敗**（`IntegerWrapTests.testSigned` の Int16 ラップ，`RedundantCopyTests.testAllEqual` の NaN 比較 ×2）．脚注に明記．iOS Simulator（iPhone 16 Pro, iOS 18.6）で MatftTests 310 件パス．
- Minimum OS は未確定のまま「Package.swift に制限なし」と記載．実測: SwiftPM デフォルトで arm64 macOS は minos 11.0．テストターゲットは `UTType` を使うため iOS 14 未満のデプロイ先ではコンパイル不可（`IPHONEOS_DEPLOYMENT_TARGET=14.0` で実行）．→ `platforms` 明示は別 PR．
- `memo/usage.md` はチュートリアル形式のため未更新（関数一覧は README の Function List が正で，Plan 1/2/4 の関数は各 PR で反映済み）．

### 残課題
- x86_64 の 3 件の失敗修正（別 PR）．
- `Package.swift` に `platforms` を明示するか決定（別 PR）．
