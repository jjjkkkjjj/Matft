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
| `MfInterpolation` に PIL 互換ケースを追加: `.PILNearest`, `.PILBilinear`, `.PILBicubic`, `.PILLanczos` | `PIL.Image.resize` | **既存 `Matft.image.resize` の `interpolation` で切り替え（別関数にしない）**．PIL の 2 パス分離畳み込み（水平→垂直）＋縮小時 support 拡張（アンチエイリアス）＋ uint8 固定小数点丸めを再現 |
| `Matft.image.center_crop(_:height:width:)` | transformers `center_crop` | 奇数差の丸め方向を transformers に合わせる．小さい場合は 0 パディング |
| `Matft.image.rescale(_:scale:)` | transformers `rescale` | |
| `Matft.image.normalize_meanstd(_:mean:std:)` | transformers `normalize` | 既存 `Matft.image.color.normalize`（= `cv2.normalize`）と衝突するため名前で区別 |
| `Matft.image.smart_resize(height:width:factor: 28, min_pixels:, max_pixels:) -> (h, w)` | `transformers.models.qwen2_vl.image_processing_qwen2_vl.smart_resize` | 純粋な整数計算 |
| `Matft.image.qwen2vl_patchify(_:patch_size: 14, temporal_patch_size: 2, merge_size: 2) -> (pixel_values, grid_thw)` | `Qwen2VLImageProcessor._preprocess` | reshape/transpose のみで実装可 |
| 便利関数 `Matft.image.clip_preprocess(_:size:crop_size:mean:std:)` | `CLIPImageProcessor` | 定数 `OPENAI_CLIP_MEAN/STD`, `IMAGENET_*` も提供 |

### 決定事項（2026-09-27）
- **namespace は `Matft.image` に統合**（`Matft.vision` は作らない）．cv2 相当と transformers 相当の衝突は関数名で区別する（`normalize_meanstd` 等）．
- **PIL 互換 resize は必要**: HF processor は PIL（または torchvision）で resize する．cv2 `INTER_CUBIC` は a=-0.75・縮小時 4×4 固定サポートでアンチエイリアス無し，PIL BICUBIC は a=-0.5・縮小率に応じてサポートを広げる．大きい縮小（例 1000px→224px）では丸め誤差ではなく明確に異なる出力になり，モデル入力が Python 版からずれるため．
- **cv2 互換 `.Cubic` はスコープ外**（目的に不要）．
- PIL 互換 resize は `resize` の `interpolation` ケース追加で提供（別関数 `resize_pil` は作らない）．

## TDD 手順
1. **参照データ生成** `python/gen_vlm_fixtures.py`（Pillow, numpy, transformers, opencv-python）:
   - 決定的な小画像（例: 17×13 のグラデーション＋固定シード乱数 RGB uint8）と `Tests/MatftTests/files/images/` の既存画像．
   - 各 resample × 拡大/縮小（非整数倍含む）での `PIL.Image.resize` 結果を `.npy` or CSV で保存．
   - CLIP / Qwen2-VL processor の `pixel_values`（と `image_grid_thw`）．
2. **テスト** `Tests/MatftTests/ImagePreprocessTest.swift`．順番:
   1. `smart_resize`（整数のみ，境界ケース: min/max_pixels 超過，アスペクト比 200 超で例外）
   2. PIL resize: nearest → bilinear → bicubic → lanczos（uint8 出力で **完全一致**，float 入力は許容誤差）
   3. center_crop, rescale, normalize_meanstd
   4. `clip_preprocess` / Qwen2-VL 全体（許容誤差 1e-5）
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
- 動画（temporal 次元）対応はスコープ外．
- `.PIL*` ケース名は実装時に再検討可（`MfInterpolation` は cv2.INTER_* 準拠の enum なので，PIL 系を別 enum `MfResample` にする案もある）．
