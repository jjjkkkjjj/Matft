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
