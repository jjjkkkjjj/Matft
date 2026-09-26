---
name: docs
description: Matft のドキュメント（Docusaurus サイト website/ と，Swift-DocC で API リファレンスになる公開 API のドキュメントコメント）を書く・更新する手順。関数や型を追加・変更したときのドキュメント追従，ガイドページや NumPy 対応表の追加・修正，/// や /** */ コメントの書き直し，DocC の警告修正，サイトのビルド確認に使う。「ドキュメント書いて」「docs 更新して」「API コメント直して」「NumPy 対応表に追加して」「ガイドにページ追加」「DocC の警告消して」「サイトに反映して」など，Matft のドキュメントやコメントの話が出たら，明示的に "skill" と言われなくても必ずこのスキルを使うこと。新機能の実装 PR でドキュメントを更新するときにも使う。
---

# Matft ドキュメントの書き方

Matft のドキュメントは 2 層になっている。

| 層 | 置き場所 | 役割 |
|---|---|---|
| サイト（Docusaurus） | `website/docs/` | 読み物：ガイド，NumPy 対応表，性能，貢献方法 |
| API リファレンス（Swift-DocC） | `Sources/Matft/**/*.swift` のドキュメントコメント + `Sources/Matft/Matft.docc/Matft.md` | 全公開シンボルの仕様 |

どちらも `.github/workflows/docs.yml` がビルドして GitHub Pages（https://jjjkkkjjj.github.io/Matft/ ，API は `/Matft/api/documentation/matft`）に公開する。CI は **DocC の警告をエラー扱い**，**サイトのリンク切れもエラー**にしているので，ローカルで同じチェックを通してから PR にする。

README は入口だけ（概要・例・インストール・リンク）。詳細を README に書き足さず，サイトに書いてリンクする。

## 1. 何を更新するか決める

変更の種類ごとに，追従が必要な場所は次のとおり。漏れやすいのは NumPy 対応表と `Matft.md` の Topics。

| 変更 | 更新先 |
|---|---|
| 公開関数・メソッドの追加／シグネチャ変更 | そのシンボルのドキュメントコメント（2.），`website/docs/numpy-mapping/<カテゴリ>.md` の表に 1 行 |
| 挙動の変更（型，戻り値，Numpy との差） | コメント，ガイドの該当ページのコード例と出力，対応表の Method / Complex 列 |
| 公開型（enum / struct / class）の追加 | コメント（型と全 case），`Sources/Matft/Matft.docc/Matft.md` の `## Topics` の適切なグループ |
| 目玉機能の追加 | ガイドにページか節を追加（3.），必要なら `website/docs/intro.md` の Features と README の Features 1 行 |
| 画像処理のケース追加 | `image-visual-check` スキルで比較画像を作り，`website/docs/guide/image.md` に載せる |
| ベンチ表 | `benchmark` スキル（`--update-docs`）。手で書き換えない |

## 2. ドキュメントコメント（API リファレンス）

### 書く前に実装を読む

コメントは「実装が実際にどう動くか」を書く。シグネチャや旧コメントから推測で書くと，DocC 上で嘘の仕様が公開される。特に次を実装から確認する。

- 対応する型，結果の `mftype`（整数入力が Float になる，など）
- complex 対応か：`unsupport_complex(...)` を呼んでいれば非対応 → `- Precondition:` に書く
- `axis` / `keepDims` などの既定値の意味，axis 省略時の挙動
- 戻り値が **view（元配列とメモリ共有）かコピーか**
- `throws` なら投げる `MfError` の case（実際に throw している case だけ）
- Numpy（scipy / cv2 / PIL / librosa）との違い

実装とコメントが食い違っていて，どちらが意図か判断できないとき（＝バグの疑い）は，**コードは直さず**コメントを実際の挙動に合わせ，疑いとしてユーザーに報告する。修正は CLAUDE.md の TDD ルールに従って別 PR で行う。ドキュメント作業の中でついでにコードを直すと，テストのない挙動変更が紛れ込むため。

### 形式

ファイルごとの既存形式（`/** ... */` か `///`）に合わせる。混在させない。

```swift
/**
   Return the indices of the elements that are non-zero.

   Equivalent to `numpy.nonzero`. NaN counts as non-zero. The indices are listed in row-major order.

   - Parameters:
        - mfarray: The input array.
   - Returns: One 1-d `.Int` array per dimension of `mfarray`, holding the indices of the non-zero elements along that dimension.
   - Precondition: Complex arrays are not supported.
*/
public static func nonzero(_ mfarray: MfArray) -> [MfArray]{
```

- 1 行目：1 文の要約（DocC の一覧に出る）。空行のあと詳細。
- 対応物があれば `Equivalent to \`numpy.xxx\`.`（cv2 / PIL / transformers / librosa / scipy も同様）。
- `- Parameters:`（大文字 P）の下に全引数。**名前はシグネチャの内部名と一致**させる（ずれると DocC 警告 → CI 失敗）。`mfarray: mfarray` のような無意味な説明は書かない。
- `- Returns:` / `- Throws:` / `- Precondition:` / `- Note:`（Numpy との差や注意点）。
- メソッド版は `Method version of \`Matft.transpose(_:axes:)\`.` と書き，要点だけ繰り返す。
- 演算子は Numpy の対応を書く（`*&` は `@`，`===` は要素ごとの `==`，`==` は `numpy.array_equal`）。
- 偶然 public になっている内部ヘルパーには `- Note: This is an implementation detail of Matft and may change.`。アクセスレベルは変えない。
- プロトコル要件は要件側に書く。`Int` / `Float` などの各準拠実装には書かなくてよい（DocC が要件の説明を継承する）。
- ` ``Symbol`` ` の二重バッククォートリンクは解決できる確信があるときだけ。解決できないと警告になるので，普通は `code` で書く。
- 英語で書く。

### コード例

主要な入口（生成関数，よく使う演算，画像・音声の前処理など）にだけ短い ```` ```swift ```` 例を付ける。**出力を載せるなら，テストにある値をそのまま写すか，4. の方法で実際に実行した結果だけ**。出力を推測で書かない。

## 3. サイト（website/）

### 構成

```
website/
  docs/intro.md, performance.md, contributing.md
  docs/getting-started/   installation, quick-start
  docs/guide/             mfarray, indexing, views, manipulation, arithmetic, math-and-stats, linalg, complex, image, audio, mlx
  docs/numpy-mapping/     index（凡例）+ カテゴリ別の対応表
  sidebars.ts             ← ページを足したら必ず登録（docsSidebar / mappingSidebar）
  docusaurus.config.ts    navbar・footer・baseUrl=/Matft/
  src/pages/index.tsx     トップページ（Numpy vs Matft のコード比較と特徴カード）
  scripts/copy-assets.mjs Tests/MatftTests/files/images/compare → static/img/compare（ビルド時にコピー，git 管理外）
```

### 書き方の決まり

- `.md` は **CommonMark** として解釈される（`markdown.format: 'detect'`）。JSX / MDX 構文は使えない（使うなら `.mdx`）。その代わり表中の `<`，`{`，HTML コメント（`BENCHMARK` マーカー）がそのまま書ける。
- 注記は admonition：`:::note` / `:::caution` / `:::warning` / `:::info Beta` … `:::`。
- 他ページへのリンクは相対の `.md` パス（例：`../numpy-mapping/math.md`，`./views.md#copy`）。ビルド時にリンク切れを検出できるように，URL ではなくファイルパスで書く。
- 比較画像は `![alt](/img/compare/<case>.png)`。画像を website 側にコピーしてコミットしない。
- API リファレンスへのリンクは `pathname:///api/documentation/matft`（末尾スラッシュなし。`trailingSlash: false` のため）。
- 新しいページには front matter の `title:` を付け，`sidebars.ts` に追加する。

### NumPy 対応表

`website/docs/numpy-mapping/*.md` の表は次の 4 列。

```markdown
| Matft | Numpy | Method | Complex |
| --- | --- | :---: | :---: |
| `Matft.stats.median` | `numpy.median` |  |  |
| `Matft.transpose` | `numpy.transpose` | ✓ | ✓ |
| `MfArray.toArray` | `numpy.ndarray.tolist` | only |  |
```

- Method：`✓` = メソッド版もある（`a.transpose()`），`only` = メソッド版のみ。
- Complex：complex 配列対応なら `✓`。
- Numpy 以外が対応物ならその名前を書く（`cv2.GaussianBlur`，`librosa.stft` など）。該当なしは `n/a`。
- 1 セルに関数と演算子を並べるときは `<br />` で区切る（例：`` `Matft.matmul`<br />`*&` ``）。

## 4. コード例の出力を検証する

ガイドや Quick Start に載せる出力は，実際に動かして確かめる。一時テストで print して写す。

```sh
cat > Tests/MatftTests/TmpDocsSnippetTest.swift <<'EOF'
import XCTest
@testable import Matft

final class TmpDocsSnippetTest: XCTestCase {
    func testSnippets() {
        print("SNIP")
        let a = Matft.arange(start: 0, to: 6, by: 1, shape: [2, 3])
        print(a.sum(axis: 0))
    }
}
EOF
swift test --filter MatftTests.TmpDocsSnippetTest 2>&1 | sed -n '/^SNIP/,/^◇/p'
rm Tests/MatftTests/TmpDocsSnippetTest.swift   # 終わったら必ず消す（コミットしない）
```

- 出力のタブ・空白は Matft の print 結果をそのままコピーする。
- 既存の例が今の実装と合わなくなっていたら（挙動変更の PR 後など），例と出力の両方を直す。

## 5. ビルドして確認する

```sh
DOCC_WARNINGS_AS_ERRORS=1 ./scripts/build-docs.sh               # API リファレンス → website/static/api
python3 .claude/skills/docs/scripts/undocumented_symbols.py     # コメントのない公開シンボル（0 件であること）

cd website
npm ci                  # 初回のみ
npm run build           # リンク切れがあると失敗する
npx docusaurus serve --port 3210 --no-open    # 目視確認するとき（http://localhost:3210/Matft/）
```

- `build-docs.sh` は swift-docc-plugin を使わず，`swift build` の symbol graph を `docc convert` にかける。Package.swift に DocC 用の依存を足さないこと（利用者の依存が増えるため）。API だけ見るなら `./scripts/build-docs.sh --preview`。
- `undocumented_symbols.py` は `build-docs.sh` が出力した symbol graph を読むので，先に `build-docs.sh` を実行する。
- DocC の警告は `warning: Parameter 'x' is missing documentation` / `not found in ... declaration` がほとんど。コメントの引数リストをシグネチャに合わせれば消える。
- 目視確認は，変えたページと API の該当シンボルのページを開く。serve が `/api/documentation/matft/` をリダイレクトするのは `trailingSlash: false` のためで，本番（GitHub Pages）では問題にならない。

## 6. 報告

- 更新したページ・ファイル，追加した対応表の行
- DocC 警告数と未記述シンボル数（ともに 0 であること），サイトのビルド結果
- 実行して確かめたコード例
- コメントを書く中で見つけた挙動の疑い（ファイル:行，何が Numpy / コメントと違うか）。直していないことを明記する

ドキュメントだけの変更は TDD の対象外。ただし `scripts/benchmark.py` など**スクリプトを変えるときはテストを先に書く**（`scripts/test_benchmark.py`）。
