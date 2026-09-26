# Plan 2: VLM 画像前処理（PIL / transformers 互換）

## 目的
mlx-swift-lm は VLM 前処理を CoreImage（CIFilter の Lanczos/bicubic）と手書き Metal bicubic カーネルで実装しており，
Python（PIL + transformers ImageProcessor）と **数値が一致しない**．Matft で「Python と同じ前処理を CPU で決定的に再現」できるようにする．

対象 processor（優先順）:
1. `CLIPImageProcessor`（resize shortest_edge → center_crop → rescale → normalize）— SigLIP/LLaVA 系の基本形
2. `Qwen2VLImageProcessor`（smart_resize → rescale → normalize → patchify）
3. `SiglipImageProcessor`（固定サイズ resize）

## 現状（コード確認済み）
- `Matft.image.resize(_:width:height:interpolation:)`: `.Nearest/.Linear` = cv2 互換（remap），`.Lanczos` = vImage．**PIL 互換 bicubic は無い**．
- OpenCV の cubic（a = -0.75，縮小時アンチエイリアス無し）と PIL の BICUBIC（a = -0.5，**縮小時はサポートを scale 倍に広げる=アンチエイリアス**）は別物．
- `Matft.image.color`, `warpAffine`, `cgimage2mfarray`（コピー，CoreGraphics 必須）あり．

## API 設計（案）

| API | 参照 | 備考 |
|---|---|---|
| `MfInterpolation` に `.Cubic`（cv2 互換）を追加 | `cv2.INTER_CUBIC` | ついでに OpenCV 互換を埋める |
| `Matft.image.resize_pil(_:width:height:resample:)` もしくは `resize(..., backend: .pil)` | `PIL.Image.resize` | resample: `.nearest, .bilinear, .bicubic, .lanczos`．**PIL の 2 パス分離畳み込み（水平→垂直）＋ support 拡張＋ uint8 丸め** を再現 |
| `Matft.image.center_crop(_:height:width:)` | transformers `center_crop` | 奇数差の丸め方向を transformers に合わせる．小さい場合は 0 パディング |
| `Matft.image.rescale(_:scale:)` / `normalize(_:mean:std:)` | transformers | 既存 `Matft.image.color.normalize`（cv2.normalize 相当）と名前衝突に注意 → `Matft.image.normalize_meanstd` 等で回避するか namespace 分け |
| `Matft.vision.smart_resize(height:width:factor: 28, min_pixels:, max_pixels:) -> (h, w)` | `transformers.models.qwen2_vl.image_processing_qwen2_vl.smart_resize` | 純粋な整数計算 |
| `Matft.vision.qwen2vl_patchify(_:patch_size: 14, temporal_patch_size: 2, merge_size: 2) -> (pixel_values, grid_thw)` | `Qwen2VLImageProcessor._preprocess` | reshape/transpose のみで実装可 |
| 便利関数 `Matft.vision.clip_preprocess(_:size:crop_size:mean:std:)` | `CLIPImageProcessor` | 定数 `OPENAI_CLIP_MEAN/STD`, `IMAGENET_*` も提供 |

namespace は `Matft.vision`（ML 前処理用）を新設し，汎用画像処理（cv2 相当）の `Matft.image` と分ける案を推奨．

## TDD 手順
1. **参照データ生成** `python/gen_vlm_fixtures.py`（Pillow, numpy, transformers, opencv-python）:
   - 決定的な小画像（例: 17×13 のグラデーション＋固定シード乱数 RGB uint8）と `Tests/MatftTests/files/images/` の既存画像．
   - 各 resample × 拡大/縮小（非整数倍含む）での `PIL.Image.resize` 結果を `.npy` or CSV で保存．
   - `cv2.resize(INTER_CUBIC)` 結果．
   - CLIP / Qwen2-VL processor の `pixel_values`（と `image_grid_thw`）．
2. **テスト** `Tests/MatftTests/VisionTest.swift`（cubic は既存 `ImageTest.swift` に追記）．順番:
   1. `smart_resize`（整数のみ，境界ケース: min/max_pixels 超過，アスペクト比 200 超で例外）
   2. `.Cubic`（cv2 互換）
   3. PIL resize: nearest → bilinear → bicubic → lanczos（uint8 出力で **完全一致**，float 入力は許容誤差）
   4. center_crop, rescale, normalize
   5. `clip_preprocess` / Qwen2-VL 全体（許容誤差 1e-5）
3. 目視確認は `image-visual-check` スキル（OpenCV/PIL と並べた比較画像）を使う．

## 実装メモ
- PIL の resample 実装（`libImaging/Resample.c`）を読み，係数計算（`precompute_coeffs`: support = filter_support * max(scale, 1), 係数正規化, 固定小数点 22bit `PRECISION_BITS` での uint8 丸め）を忠実に移植する．uint8 の完全一致にはこの固定小数点丸めの再現が必須．
- 実装は水平パス→垂直パスの分離畳み込み．係数行列を作れば行列積（BLAS）でも計算可能 → 速度が必要なら後で最適化．
- 入力は HWC（Matft.image の既存規約）．出力 `pixel_values` は CHW / NCHW．
- CoreGraphics 非依存で実装（WASI でも動く）．

## 完了条件
- CLIP / Qwen2-VL の `pixel_values` が transformers と許容誤差内で一致．PIL bicubic/bilinear が uint8 で完全一致．
- mlx-swift-lm の `MediaProcessing` を Matft 版で置き換えるサンプル（Plan 3 のデモで使う）．

## 未決事項
- PIL 互換 resize を `resize` の引数で切り替えるか別関数にするか（既存 `resize` のデフォルトが Lanczos=vImage なので，**別関数 `resize_pil` か `Matft.vision.resize`** が安全）．
- `Matft.vision` を新設するか `Matft.image` に統合するか．
- 動画（temporal 次元）対応はスコープ外．
