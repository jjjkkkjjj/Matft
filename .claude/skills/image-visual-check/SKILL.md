---
name: image-visual-check
description: Matft の画像処理（Matft.image.* や，画像に対するインデックス操作・チャンネル入れ替えなど）のテストを追加し，変換結果を OpenCV の参照画像と並べた比較画像を生成して，目視で正しく変換されているか確認する手順。「画像処理のテスト追加して」「resize / warpAffine / color を目視確認したい」「画像が正しく変換されてるか見て」「OpenCV と見比べたい」「README の画像みたいに確認したい」など，Matft で画像を扱う機能の追加・修正・テスト・確認の話が出たら，明示的に "skill" と言われなくても必ずこのスキルを使うこと。
---

# 画像処理テストの追加と目視確認

画像処理は数値の assert だけでは，上下反転や RGB の取り違え，補間のずれを見落としやすい。
そこで，数値テストで仕様を押さえたうえで，**入力｜Matft｜OpenCV｜差分** を 1 枚に並べた比較画像を作り，Claude とユーザーの両方で目視確認する。
比較画像はリポジトリにコミットし，PR で見返せるようにする。

## 仕組み

| 場所 | 役割 |
|---|---|
| `Tests/MatftTests/files/images/rena.png` | 入力画像（225x225，RGBA）。JPEG だとデコーダの差が混ざるので，可逆な PNG を使う |
| `Tests/MatftTests/ImageSnapshot.swift` | テスト用ヘルパ。`loadFixture()` で CGImage を読み込み，`save(_:as:)` で Matft の出力を PNG で保存する |
| `Tests/MatftTests/ImageTest.swift` | 画像処理のテスト（無ければ作る） |
| `scripts/image_compare.py` | `CASES` に登録した OpenCV 版の変換を実行し，参照画像・比較画像・差分の指標を出力する |
| `files/images/matft/<case>.png` | Matft の出力（コミット対象） |
| `files/images/opencv/<case>.png` | OpenCV の出力（コミット対象） |
| `files/images/compare/<case>.png` | 比較画像（コミット対象）。目視確認ではこれを見る |

`ImageSnapshot.save` は，環境変数 `MATFT_IMAGE_SNAPSHOT=1` を付けて実行したときだけ書き出す。
普段の `swift test` でリポジトリのファイルが変わらないようにするため。

## 0. 事前確認

```sh
python3 -c "import cv2, numpy; print(cv2.__version__, numpy.__version__)"
```

cv2 が無い場合は `pip3 install --user opencv-python-headless` を提案する。インストールはユーザーの了承を得てから行う。

## 1. テストを書く（Red）

CLAUDE.md の方針どおり TDD で進める。`ImageTest.swift` が無ければ次の形で作る。
Accelerate/ImageIO が無い環境（WASI・Linux）でもビルドできるように，ファイル全体を `#if` で囲む。

```swift
#if canImport(Accelerate) && canImport(ImageIO)
import XCTest

@testable import Matft

final class ImageTest: XCTestCase {
    func test_resize() {
        let image = Matft.image.cgimage2mfarray(ImageSnapshot.loadFixture())   // Float [0, 1], RGBA, shape=(225, 225, 4)
        let ret = Matft.image.resize(image, width: 300, height: 150)

        XCTAssertEqual(ret.shape, [150, 300, 4])
        XCTAssertEqual(ret.mftype, .Float)
        // 代表画素の値など，数値で確かめられることを assert する

        ImageSnapshot.save(ret, as: "resize_300x150")
    }
}
#endif
```

数値 assert を書くときのポイント：

- 期待値は Python（numpy / cv2）で `rena.png` から計算して得る。コードに埋め込む値の出どころが分かるよう，コメントに Python の式を書いておく。
- 補間を伴う処理（resize，warpAffine）は，vImage と OpenCV で結果が画素単位では一致しない。そのため shape，dtype，値域，平坦な領域の画素，境界値（warpAffine の borderValue）など，**アルゴリズムに依存しない性質**を assert する。
- 変換が厳密に定まる処理（反転，チャンネル入れ替え，グレー変換）は，代表画素を numpy / cv2 の値と比べる（Float なら `/255` し，許容誤差 1e-2 程度）。
- 1 つのテストメソッドにつき，`save` のケース名は処理と条件が分かる名前にする（例：`warpAffine_rotate30_edgeExtend`）。

`swift test --filter MatftTests.ImageTest` で失敗することを確認する。

## 2. OpenCV 版を登録する

`scripts/image_compare.py` の `CASES` に，同じケース名で OpenCV の処理を追加する。

```python
"resize_300x150": Case("rena.png",
                       lambda x: cv2.resize(x, (300, 150), interpolation=cv2.INTER_LANCZOS4),
                       "Matft.image.resize(width: 300, height: 150) vs cv2.resize(LANCZOS4)"),
```

`op` は RGBA の uint8 配列を受け取る。戻り値は uint8，または [0, 1] の float（自動で uint8 に変換される）のどちらでもよい。
Matft と OpenCV の作法の違いで，本当は正しいのに「ずれている」ように見えることがよくある。次の点に気をつける。

- **チャンネル順**：Matft は RGBA，OpenCV は BGR(A)。スクリプトが RGBA に揃えて渡すので，`op` の中で BGR 前提の変換（`COLOR_BGR2GRAY` など）を使わない。
- **サイズ引数**：`cv2.resize` は `(width, height)` の順，Matft の shape は `(height, width, channel)`。
- **値域**：Matft の Float 画像は [0, 1]，OpenCV は 0–255。`borderValue` などは 255 倍して渡す。
- **補間方式**：vImage の resize は Lanczos 系の補間で，`INTER_LINEAR` とは縁の出方が違う。最も近い補間方式を選び，説明文に何と比べたかを書く。
- **保存できるチャンネル数**：`mfarray2cgimage` が対応しているのは 1 ch と 4 ch だけ。`RGBA2RGB` のように 3 ch になる結果は，`Matft.image.color(ret, conversion: .RGB2RGBA)` で 4 ch に戻してから `save` する。OpenCV 側も同じように 4 ch に揃える。

## 3. 実装してテストを通す（Green）

テストを通す最小限の実装を行い，`swift test` で全テストが通ることを確認する。
Matft 本体の実装が不要なケース（既存機能にテストと目視確認を足すだけ）では，このステップは確認だけでよい。

## 4. 比較画像を生成する

```sh
MATFT_IMAGE_SNAPSHOT=1 swift test --filter MatftTests.ImageTest
python3 scripts/image_compare.py --filter '<ケース名の正規表現>'
```

スクリプトが出力する表の `status` を確認する。

- `missing-matft`：Swift 側で `save` が呼ばれていない。`MATFT_IMAGE_SNAPSHOT=1` の付け忘れか，ケース名の不一致。
- `missing-case`：`CASES` に登録されていない。

## 5. 目視確認（Claude）

`compare/<case>.png` を Read ツールで開き，実際に画像を見て判断する。指標だけで合否を決めない。
PSNR が高くても左右反転していれば誤りだし，補間方式が違えば差分があっても正しい。

次の順に見る。

1. **向きと位置**：上下左右の反転や回転の向き，平行移動の方向が，意図した変換と一致しているか。
2. **色**：肌や背景の色味が入力と比べて不自然でないか。R と B の入れ替わり（青っぽい肌）やアルファの扱い（白飛び・黒つぶれ）がないか。
3. **形状**：出力サイズやアスペクト比は OpenCV と同じか。
4. **差分マップ**：差分の**分布の形**を見る。
   - 全体に薄く散らばる → 丸め誤差や補間方式の違い。許容できることが多い。
   - エッジに沿って出る → 補間方式の違い，または半画素のずれ。
   - 領域全体や画像の端が明るい → 座標系・境界処理・チャンネルの取り違えなど，本物のバグの可能性が高い。

指標の目安（あくまで目安）：

| 処理の種類 | 期待 |
|---|---|
| インデックス操作（反転・スライス・チャンネル入れ替え） | `max|diff| = 0` |
| 色変換 | `max|diff| ≤ 2`（丸め誤差） |
| resize，warpAffine | 画素一致は期待しない。PSNR が概ね 30dB 以上で，差分がエッジに限られていれば正常 |

目安から外れたときは，バグと決めつける前に 2. の作法の違い（OpenCV 側の書き方の誤り）を疑い，どちらが正しいかを入力画像と見比べて判断する。

## 6. ユーザーに見せて報告する

```sh
open Tests/MatftTests/files/images/compare/<case>.png   # 複数あればまとめて渡す
```

報告には次を含める。

- 追加したテストと，assert している内容
- スクリプトの出力した表（ケースごとの指標）
- 目視で確認した内容：何が正しく見えたか，差分がどこに出ていて，なぜ許容できると判断したか（または何がおかしいか）

最終的に正しいかどうかはユーザーに判断してもらう。

## 7. コミット（ユーザーの指示があるときだけ）

テストと一緒に `files/images/{matft,opencv,compare}/<case>.png` をコミットする。
既存のケースの画像が意図せず変わっていないか，`git status` で確認する。変わっていたら，その差分もユーザーに伝える。
