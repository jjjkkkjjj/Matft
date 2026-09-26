# Plan 4: MLX に無い NumPy 関数を埋める

## 目的
mlx-swift に存在しない（特に「出力 shape がデータ依存」「nan 系」「CPU LAPACK 系」の）NumPy 関数を Matft に揃え，
「MLX で出来ないことは Matft で」という補完関係を明確にする．Matft は eager 評価なのでデータ依存 shape を自然に扱える．

## スコープ（フェーズ分割，各フェーズ = 1 PR）

### 4-A: 基礎（Plan 1 の前提を含むので最優先）
> **実装済み（branch `feature/numpy-gaps-basic`）**: `Matft.pad`（`MfPadMode`: constant/edge/reflect/symmetric/wrap, `pad_width: [(Int,Int)]` or `Int`），
> `Matft.stats.var/std`（`ddof`），`Matft.diff`，`Matft.meshgrid`（`MfMeshIndexing`: xy/ij），`Matft.math.isnan/isinf/isfinite`（既存 namespace に合わせ `Matft.math` 配下）．
> テスト: `PadTest.swift`, `NumpyBasicTest.swift`．`` func `var` `` をキーワード名で宣言し `Matft.stats.var(...)` で呼べることを確認済み → 4-C の `Matft.where` も同方式で可．
> 注意: Matft は Int と Float が混在した配列リテラル（`[1, 2.5]`）を受け付けない（既存仕様）．
| 関数 | NumPy 仕様の要点 |
|---|---|
| `Matft.pad(a, pad_width:, mode:, constant_values:)` | mode: `constant`, `edge`, `reflect`, `symmetric`, `wrap`（最低 constant/reflect/edge）．pad_width は `[(before, after)]` per axis |
| `Matft.stats.std / var(a, axis:, ddof:, keepDims:)` | ddof デフォルト 0 |
| `Matft.diff(a, n:, axis:)` | |
| `Matft.meshgrid(xs..., indexing:)` | `"xy"` デフォルト |
| `Matft.isnan / isinf / isfinite` | Bool 配列を返す |

### 4-B: 順序統計・nan 系
| 関数 | 要点 |
|---|---|
| `Matft.stats.median(a, axis:, keepDims:)` | |
| `Matft.stats.percentile(a, q:, axis:, method:)` / `quantile` | method デフォルト `"linear"`．まず linear/lower/higher/nearest/midpoint |
| `nansum, nanmean, nanmax, nanmin, nanargmax, nanargmin, nanstd, nanvar, nanmedian` | 全 NaN スライスの挙動（NaN + warning）は NaN を返すだけでよい |

### 4-C: データ依存 shape
> **実装済み（branch `feature/numpy-gaps-search`）**: `Matft.nonzero/argwhere/where`（1 引数・3 引数，スカラー版あり），`searchsorted`（`MfSearchSide`），`digitize`，`bincount`，
> `histogram`（bins: Int / MfArray，range，density，weights．NumPy 2 のビン番号補正を再現），`unique/unique_values/unique_counts/unique_inverse/unique_all`（NumPy 2 の Array API 名），`isin`，`intersect1d/union1d/setdiff1d`．
> テスト: `SearchTest.swift`，`SetOpsTest.swift`．`Matft.where` はキーワード名でも宣言・呼び出しできた．
> 速度（100 万要素）: nonzero 8.8ms（NumPy 4.0），unique 22ms（5.0，radix sort），unique_all 76ms（72），histogram 3.6ms（3.8），isin 2.7ms（0.6）．
| 関数 | 要点 |
|---|---|
| `Matft.nonzero(a) -> [MfArray]` | タプル相当を配列で返す |
| `Matft.argwhere(a)` | shape (N, ndim) |
| `Matft.where(cond)`（1引数 = nonzero），`Matft.where(cond, x, y)`（3引数，broadcast） | `where` はキーワード．`` static func `where`(...) `` で宣言し `Matft.where(...)` で呼べるかを最初に検証 |
| `Matft.unique(a, return_index:, return_inverse:, return_counts:, axis: nil)` | ソート済み．戻り値は struct（`values, indices?, inverse?, counts?`）．既存 `orderedUnique` との関係を整理 |
| `Matft.bincount(x, weights:, minlength:)` | |
| `Matft.histogram(a, bins:, range:, density:, weights:)` | bins は Int または edges．戻り値 `(hist, bin_edges)`．最終ビンは右閉 |
| `Matft.digitize(x, bins:, right:)`, `Matft.searchsorted(a, v, side:)` | |
| set 系: `isin, intersect1d, union1d, setdiff1d` | 優先度低 |

### 4-D: 数値計算（LAPACK/補間）
| 関数 | 要点 |
|---|---|
| ~~`Matft.interp`~~ | **既存（`interpolation+static.swift`）**．`period` 引数のみ未対応 |
| `Matft.polyfit(x, y, deg:)`, `Matft.polyval(p, x)` | polyfit は lstsq 経由 |
| `Matft.linalg.lstsq(a, b, rcond:)` | 戻り値 `(x, residuals, rank, s)`．LAPACK `dgelsd`/`sgelsd`（`library/lapack.swift` に追加） |
| `Matft.linalg.matrix_rank`, `Matft.linalg.expm` | expm は優先度低（math に `expm` 名の既存関数があるので衝突確認） |
| `Matft.stats.cov(m, rowvar:, ddof:)`, `corrcoef` | |

## TDD 手順（各関数共通）
1. `python/gen_numpy_gaps.py` で入力と `np.xxx` の出力を表示（または fixture 化）し，テストにリテラルで埋め込む．
   小さい入力はリテラル，大きいものは `Tests/MatftTests/files/` に CSV．
2. `Tests/MatftTests/` に失敗するテストを書く（新ファイル例: `PadTest.swift`, `OrderStatsTest.swift`, `NanFuncTest.swift`, `SetOpsTest.swift`, 既存 `StatsTest.swift`/`LinAlgTest.swift` に追記）．
   各関数で最低限カバー: Float/Double, axis=nil/0/-1, 非連続 view（転置・step スライス）入力, keepDims, 空配列/長さ1.
3. `swift test --filter MatftTests.<Class>` で Red 確認 → 最小実装 → 全テスト Green → リファクタ．
4. 静的関数（`function/static/*+static.swift`）とメソッド（`function/method/*+method.swift`）の両方を既存パターンに合わせて追加．

## 実装メモ
- Int 型も Float/Double で保存されている点に注意（`nonzero` などのインデックス戻り値は `.Int` mftype で返す）．
- ソート系は既存 `sort/argsort`（vDSP）を再利用．median/percentile は軸方向に sort して補間．
- NaN 判定は `x != x`．Accelerate 側の NaN 伝播挙動（vDSP_maxv など）が NumPy と異なる場合があるのでテストで押さえる．
- WASI/非 Accelerate フォールバックでも動くこと（`#if canImport(Accelerate)` パターンに合わせる．`scripts/build-and-test-wasm.sh`）．
- Numpy 命名規則に従う（CLAUDE.md）．

## 完了条件
- 各フェーズの関数が NumPy と一致（浮動小数は許容誤差付き）．
- `swift test` 全 Green，WASI ビルドが壊れていない．
- `memo/usage.md` / README の関数一覧に追記（Plan 5 と連携）．

## 未決事項
- `unique` の戻り値型（struct vs タプル）と `orderedUnique` の扱い（残す/非推奨化）．
- `std/var` を `Matft.stats` に置くか `Matft` 直下に置くか（既存 mean/sum の配置に合わせる → `Matft.stats` が有力）．
